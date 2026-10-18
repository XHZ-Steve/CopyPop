#include "App.h"
#include <QApplication>
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QFont>
#include <QJsonArray>
#include <QJsonDocument>
#include <QMenu>
#include <QMessageBox>
#include <QPainter>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QWindow>
#include <QScreen>

App::App(Config *config,QQmlEngine *engine,bool testing,QObject *parent)
    : QObject(parent),m_config(config),m_engine(engine),m_events(this),m_classifier(m_events.handle()),m_tracker(m_events.handle(),this),m_renderer(engine),m_menu(std::make_unique<QMenu>()),m_testing(testing) {
    QFile games(":/resources/data/games.json"); if (games.open(QIODevice::ReadOnly)) m_games = QJsonDocument::fromJson(games.readAll()).array().toVariantList();
    m_sequence = GetClipboardSequenceNumber();
    m_kind=Win::clipboardFormatKind(); if(m_kind=="text") m_classifier.request(m_sequence);
    m_guardTimer.setInterval(700);
    connect(&m_guardTimer,&QTimer::timeout,this,&App::refresh);
    m_attachedTimer.setInterval(33);
    connect(&m_attachedTimer,&QTimer::timeout,this,&App::tick);
    m_resumeTimer.setSingleShot(true); connect(&m_resumeTimer,&QTimer::timeout,this,&App::resume);
    m_copyDeadline.setSingleShot(true); m_copyDeadline.setInterval(200);
    connect(&m_copyDeadline,&QTimer::timeout,this,&App::copyFallback);
    m_snapshotDebounce.setSingleShot(true); m_snapshotDebounce.setInterval(60);
    connect(&m_snapshotDebounce,&QTimer::timeout,this,[this]{ if (allowed()) query(QueryReason::Snapshot); });
    connect(&m_events,&WindowsEvents::clipboardChanged,this,[this]{ clipboard(); });
    connect(&m_events,&WindowsEvents::clipboardClassified,this,[this]{const auto kind=m_classifier.receive(m_sequence); if(!kind.isEmpty()){m_kind=kind; emit statusChanged();}});
    connect(&m_events,&WindowsEvents::foregroundChanged,this,[this]{ cancel(); m_tracker.invalidate(); m_snapshot = {}; refresh(); if (allowed()) query(QueryReason::Focus); });
    connect(&m_events,&WindowsEvents::focusChanged,this,[this]{ cancel(); m_snapshot = {}; if (allowed()) { m_tracker.invalidate(); query(QueryReason::Focus); } });
    connect(&m_events,&WindowsEvents::selectionChanged,this,[this]{ if (allowed() && !m_copyPending && !m_snapshotDebounce.isActive()) m_snapshotDebounce.start(); });
    connect(&m_events,&WindowsEvents::selectionReady,&m_tracker,&SelectionTracker::receive);
    connect(&m_events,&WindowsEvents::inputChanged,this,[this]{ if (m_caret) cancel(); if (allowed() && !m_snapshotDebounce.isActive()) m_snapshotDebounce.start(); });
    connect(&m_events,&WindowsEvents::geometryChanged,this,[this]{ if (m_renderer.visible()) { tick(); if (allowed() && !m_caret && !m_fallback && m_renderer.visible()) query(QueryReason::Follow); } });
    connect(&m_events,&WindowsEvents::displaysChanged,this,[this]{ cancel(); m_tracker.invalidate(); m_snapshot = {}; });
    connect(&m_tracker,&SelectionTracker::ready,this,&App::selection);
    connect(&m_tracker,&SelectionTracker::budgetExceeded,this,[this]{ ++m_timeouts; if (m_renderer.visible() && !m_caret && !m_fallback) { cancel(); showCopyToast(); } else if (m_copyPending) copyFallback(); emit statusChanged(); });
    connect(config,&Config::changed,this,[this] {
        cancel(); m_tracker.invalidate(); m_snapshot = {};
        if (!m_testing && !m_config->value("firstRun").toBool() && Win::startupEnabled() != m_config->value("startup").toBool() && !Win::setStartup(m_config->value("startup").toBool())) notify("无法更新开机启动，请检查当前用户注册表权限。" );
        refresh();
    });
    m_menu->addAction("打开设置",this,&App::showSettings);
    m_menu->addAction("暂停 / 恢复",this,[this]{ if (m_paused) resume(); else pause(); });
    m_menu->addAction("暂停 30 分钟",this,[this]{ pause(30); });
    m_menu->addAction("排除最近活动的应用",this,&App::excludeRecent);
    m_menu->addSeparator();
    m_menu->addAction("欢迎界面",this,&App::showWelcome);
    m_menu->addAction("关于 CopyPop",this,&App::about);
    m_menu->addAction("退出",this,&App::quit);
    m_tray.setContextMenu(m_menu.get());
    connect(&m_tray,&QSystemTrayIcon::activated,this,[this](QSystemTrayIcon::ActivationReason r){ if (r == QSystemTrayIcon::DoubleClick || r == QSystemTrayIcon::Trigger) showSettings(); });
    refresh();
}
App::~App() { cancel(); m_tracker.invalidate(); if (m_settings) delete m_settings; if (m_welcome) delete m_welcome; }
void App::start(bool background) {
    if (!m_testing && !m_config->value("firstRun").toBool() && !Win::setStartup(m_config->value("startup").toBool())) notify("无法更新开机启动。" );
    m_guardTimer.start(); if (!m_testing) m_tray.show();
    if (m_config->value("firstRun").toBool()) showWelcome(); else if (!background) showSettings();
    if (!m_events.valid()) notify("无法注册剪贴板监听器，请重新启动 CopyPop。" );
}
QWindow *App::createWindow(const QString &source) {
    QQmlComponent component(m_engine,QUrl(source));
    auto *obj = component.create(m_engine->rootContext()); auto *window = qobject_cast<QWindow *>(obj);
    if (!window) { qWarning().noquote() << component.errorString(); delete obj; notify("界面加载失败，请查看诊断。" ); return nullptr; }
    window->setIcon(QIcon(":/resources/icons/copy.svg"));
    connect(window,&QWindow::visibleChanged,this,[window](bool visible){ if (!visible) window->deleteLater(); });
    window->show(); return window;
}
void App::showSettings() { if (!m_settings) m_settings = createWindow("qrc:/qml/Settings.qml"); if (m_settings) { m_settings->showNormal(); m_settings->raise(); m_settings->requestActivate(); } }
void App::showWelcome() { if (!m_welcome) m_welcome = createWindow("qrc:/qml/Welcome.qml"); if (m_welcome) { m_welcome->showNormal(); m_welcome->raise(); m_welcome->requestActivate(); } }
void App::finishWelcome() { if (!m_config->set("firstRun",false)) return; if (m_welcome) m_welcome->close(); showSettings(); }
void App::pause(int minutes) { m_paused = true; if (minutes > 0) m_resumeTimer.start(minutes*60000); else m_resumeTimer.stop(); cancel(); m_tracker.invalidate(); refresh(); }
void App::resume() { m_paused = false; m_resumeTimer.stop(); refresh(); }
void App::excludeRecent() {
    if (m_recentPath.isEmpty()) { notify("尚无最近活动的外部应用。请先切换到需要排除的应用。" ); return; }
    auto overrides = QVariantMap{};
    for (const auto &a : m_config->applications()) if (a.toMap()["path"].toString() == m_recentPath) overrides = a.toMap()["overrides"].toMap();
    overrides["excluded"] = true;
    if (m_config->setRule(m_recentPath,overrides)) notify("已排除 " + QFileInfo(m_recentPath).fileName());
}
void App::chooseApplication() {
    const auto file = QFileDialog::getOpenFileName(nullptr,"选择应用程序",{},"Windows 应用 (*.exe)");
    if (!file.isEmpty()) m_config->setRule(file,{});
}
void App::importConfig() {
    const auto file = QFileDialog::getOpenFileName(nullptr,"导入 CopyPop 配置",{},"JSON 配置 (*.json)");
    if (!file.isEmpty() && m_config->importFile(file)) notify("已导入配置。" );
}
void App::exportConfig() {
    const auto file = QFileDialog::getSaveFileName(nullptr,"导出 CopyPop 配置","CopyPop-config.json","JSON 配置 (*.json)");
    if (!file.isEmpty() && m_config->exportFile(file)) notify("已导出配置。" );
}
void App::resetConfig() { if (m_config->reset()) notify("已恢复默认设置。" ); }
static QString logPath() { return QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) + "/logs"; }
void App::openLogs() { QDir().mkpath(logPath()); QDesktopServices::openUrl(QUrl::fromLocalFile(logPath())); }
void App::clearLogs() { QFile::remove(logPath()+"/diagnostics.log"); QFile::remove(logPath()+"/diagnostics.previous.log"); notify("诊断日志已清除。" ); }
void App::log(const QString &event) {
    if (m_testing || !m_config->value("diagnostics").toBool()) return;
    QDir().mkpath(logPath()); const auto path = logPath()+"/diagnostics.log";
    if (QFileInfo(path).size() > 256*1024) { QFile::remove(logPath()+"/diagnostics.previous.log"); QFile::rename(path,logPath()+"/diagnostics.previous.log"); }
    QFile f(path); if (f.open(QIODevice::Append)) f.write((QDateTime::currentDateTimeUtc().toString(Qt::ISODate)+" "+event+"\n").toUtf8());
}
void App::about() { QMessageBox::about(nullptr,"关于 CopyPop","CopyPop 1.0.0\nInvisible until useful.\n\nC++20 · Qt " QT_VERSION_STR " · Windows UI Automation\nMIT License · Lucide ISC · Qt LGPLv3\n\n不保存剪贴板历史，不上传内容。\nhttps://github.com/XHZ-Steve/CopyPop"); }
void App::quit() { cancel(); qApp->quit(); }
void App::notify(const QString &message) { m_notice = message; emit noticeChanged(); }
void App::dismissNotice() { m_notice.clear(); m_config->clearError(); emit noticeChanged(); }
void App::preset(const QString &name) {
    const QMap<QString,QString> colors{{"ocean","#5989e8"},{"mint","#34a88a"},{"rose","#d477a0"}};
    if (colors.contains(name)) { m_config->set("preset",name); m_config->set("color",colors[name]); }
}
bool App::allowed() const {
    return !m_guarded && !m_paused && m_config->value("enabled").toBool() && m_effective.value("enabled",true).toBool() && !m_effective.value("excluded",false).toBool() && m_foreground && !m_path.isEmpty() && IsWindow(m_foreground);
}
void App::refresh() {
    const auto foreground = GetForegroundWindow();
    if (m_foreground != foreground) { cancel(); m_tracker.invalidate(); m_snapshot = {}; m_foreground = foreground; m_path = Win::processPath(foreground); }
    m_effective = m_config->effective(m_path);
    const bool guard = (m_config->value("guardFullscreen").toBool() && Win::fullscreen(foreground)) || (m_config->value("guardPresentation").toBool() && Win::presentation()) || (m_config->value("guardGames").toBool() && Win::knownGame(m_path,m_games));
    if (guard != m_guarded) { cancel(); m_tracker.invalidate(); m_guarded = guard; log(guard?"guard-enter":"guard-leave"); }
    DWORD pid = 0; GetWindowThreadProcessId(foreground,&pid);
    if (pid != GetCurrentProcessId() && !m_path.isEmpty() && m_recentPath != m_path) m_recentPath = m_path;
    if (!allowed()) { cancel(); m_snapshotDebounce.stop(); }
    const auto status = !m_events.valid()?QString("监听不可用"):(!m_config->value("enabled").toBool() || m_paused)?QString("已暂停"):m_guarded?QString("专注保护中"):m_effective.value("excluded").toBool()?QString("应用已排除"):QString("正在运行");
    if (m_status != status) { m_status = status; trayUpdate(); } emit statusChanged();
}
void App::trayUpdate() {
    QPixmap pixmap(32,32); pixmap.fill(Qt::transparent); QPainter p(&pixmap); p.setRenderHint(QPainter::Antialiasing);
    p.setPen(QPen(m_status=="正在运行"?QColor("#5989e8"):QColor("#929aa8"),2.8));
    p.drawRoundedRect(QRectF(6,8,17,19),4,4); p.drawRoundedRect(QRectF(11,3,16,18),4,4);
    if (m_status != "正在运行") { p.setPen(QPen(QColor("#dcad62"),3)); p.drawLine(22,23,22,29); p.drawLine(28,23,28,29); }
    p.end(); m_tray.setIcon(QIcon(pixmap)); m_tray.setToolTip("CopyPop · " + m_status);
}
void App::clipboard() {
    const auto sequence = GetClipboardSequenceNumber();
    if (sequence == m_sequence) return;
    cancel(); m_tracker.invalidate(); m_copyPending = false; m_copyHint = Win::probableCopy(); m_copyAt = QDateTime::currentMSecsSinceEpoch();
    m_kind=Win::clipboardFormatKind(); if(m_kind=="text") m_classifier.request(sequence);
    const auto owner = GetAncestor(GetClipboardOwner(),GA_ROOT);
    m_sequence = sequence; ++m_updates; refresh(); emit statusChanged(); log("clipboard-update");
    DWORD pid = 0; GetWindowThreadProcessId(m_foreground,&pid);
    if (!allowed() || pid == GetCurrentProcessId() || (!m_effective.value("effectsEnabled").toBool() && !m_effective.value("fallbackEnabled").toBool())) return;
    // An update is not proof of Ctrl+C: require input evidence or a recent selection in the source window.
    const bool recentSelection = m_snapshot.window == m_foreground && m_snapshot.selection && !m_snapshot.protectedControl && m_copyAt-m_snapshot.requestedAt < 900;
    if (!m_copyHint && owner != m_foreground) return;
    if (recentSelection) log("copy-selection-evidence");
    m_copyPending = true; m_copyDeadline.start(); query(QueryReason::Copy);
}
void App::query(QueryReason reason) {
    if (!allowed() || !m_effective.value("hybridTracking").toBool()) { if (reason == QueryReason::Copy) copyFallback(); return; }
    m_tracker.request(m_foreground,reason,m_path);
}
void App::selection(const SelectionSnapshot &s) {
    if (!allowed() || s.window != m_foreground) return;
    if (s.protectedControl) { m_snapshot = {}; if (m_copyPending) { m_copyPending = false; m_copyDeadline.stop(); } cancel(); return; }
    m_snapshot = s;
    if (m_copyPending) {
        m_copyPending = false; m_copyDeadline.stop();
        if (QDateTime::currentMSecsSinceEpoch()-m_copyAt > 240) return;
        if (!m_copyHint && !s.selection) return;
        if (s.level=="L3" && !s.rectangles.isEmpty() && m_effective.value("effectsEnabled").toBool()) animate(s.rectangles);
        else showCopyToast();
    } else if (s.reason == QueryReason::Focus && s.editable && !s.caret.isEmpty() && m_effective.value("caretEnabled").toBool() && m_config->value("caretTypes").toString().split(',').contains(m_kind)) {
        const auto scale = double(GetDpiForWindow(s.window))/96.0;
        const auto size = m_config->value("caretSize").toInt()*scale;
        const auto p = s.caret.bottomLeft()+QPointF(m_config->value("caretOffsetX").toInt()*scale,m_config->value("caretOffsetY").toInt()*scale);
        if (Win::clientRect(s.window).contains(p.toPoint())) animate({QRectF(p,QSizeF(size,size))},true);
    } else if (s.reason == QueryReason::Follow && m_renderer.visible() && !m_caret && !m_fallback) {
        if (!s.selection || s.rectangles.isEmpty()) { cancel(); return; }
        if(s.level!="L3") {cancel(); showCopyToast(); return;}
        const auto delta = s.rectangles.first().topLeft()-m_rects.first().topLeft();
        if (!m_effective.value("scrollFollow").toBool() && delta.manhattanLength() > 3) { cancel(); return; }
        m_lastMotion = delta; m_lastGeometry = QDateTime::currentMSecsSinceEpoch(); m_rects = s.rectangles; m_renderer.move(m_rects);
    }
    emit statusChanged();
}
void App::copyFallback() {
    const bool pending = m_copyPending; m_copyPending = false; m_copyDeadline.stop();
    if (!allowed() || !m_copyHint || QDateTime::currentMSecsSinceEpoch()-m_copyAt > 260 || (!pending && m_renderer.visible())) return;
    showCopyToast();
}
QRectF App::toastRect() const {
    POINT p{}; GetCursorPos(&p);
    if (GetAncestor(WindowFromPoint(p),GA_ROOT) != m_foreground) return {};
    MONITORINFO monitor{}; monitor.cbSize=sizeof(monitor);
    if(!GetMonitorInfoW(MonitorFromPoint(p,MONITOR_DEFAULTTONEAREST),&monitor)) return {};
    const QRect work(monitor.rcWork.left,monitor.rcWork.top,monitor.rcWork.right-monitor.rcWork.left,monitor.rcWork.bottom-monitor.rcWork.top);
    double scale=1;
    for(auto *screen:QGuiApplication::screens()) if(screen->geometry().topLeft()==QPoint(monitor.rcMonitor.left,monitor.rcMonitor.top)) {scale=screen->devicePixelRatio();break;}
    return Win::copyToastRect(QPoint(p.x,p.y),work.intersected(Win::clientRect(m_foreground)),m_effective,scale);
}
void App::showCopyToast() {
    if(!allowed() || !m_effective.value("fallbackEnabled").toBool()) return;
    const auto rect=toastRect(); if(!rect.isEmpty()) animate({rect},false,true);
}
bool App::reducedMotion() const {return m_config->value("respectReducedMotion").toBool() && Win::reducedMotion();}
void App::animate(const QList<QRectF> &rects,bool caret,bool fallback) {
    if (!allowed() || rects.isEmpty()) return;
    auto settings = m_effective;
    settings["reducedMotion"]=reducedMotion();
    if (m_config->value("respectReducedMotion").toBool() && Win::reducedMotion()) { settings["effect"] = "pulse"; settings["duration"] = 250; settings["intensity"] = 0.2; }
    m_owner = m_foreground; m_ownerRect = Win::windowRect(m_owner); m_rects = rects; m_caret = caret; m_fallback=fallback;
    m_animationClock.start(); m_followClock.start(); m_lastGeometry = QDateTime::currentMSecsSinceEpoch(); m_lastMotion = {};
    m_renderer.show(m_owner,rects,settings,fallback?QString("copied"):caret?m_kind:QString());
    m_attachedTimer.start(); ++m_animations;
}
void App::cancel() { m_renderer.hide(); m_attachedTimer.stop(); m_rects.clear(); m_caret = false; m_fallback=false; m_copyPending = false; m_copyDeadline.stop(); }
void App::tick() {
    if (!m_renderer.visible() || !allowed() || GetForegroundWindow() != m_owner || !IsWindowVisible(m_owner) || IsIconic(m_owner) || (Win::fullscreen(m_owner) && m_config->value("guardFullscreen").toBool())) { cancel(); return; }
    const auto maxDuration = m_fallback?m_effective.value("fallbackDuration").toInt():m_caret?m_config->value("caretDuration").toInt():qRound(m_effective.value("duration").toDouble()/m_effective.value("speed").toDouble());
    if (m_animationClock.elapsed() > maxDuration+60) { cancel(); return; }
    if (m_caret) {
        // Geometry/value WinEvents cover most typing; short-lived key-state observation closes provider gaps. No hook or key recording.
        if (!(GetAsyncKeyState(VK_CONTROL)&0x8000)) for (int key = 0x20; key <= 0xFE; ++key) {
            if (((key >= 0x30 && key <= 0x5A) || key == VK_BACK || key == VK_DELETE || key == VK_SPACE || key == VK_PROCESSKEY || key == VK_RETURN) && (GetAsyncKeyState(key)&0x8000)) { cancel(); return; }
        }
    }
    const auto rect = Win::windowRect(m_owner);
    if (rect.size() != m_ownerRect.size()) { cancel(); m_tracker.invalidate(); return; }
    const auto delta = rect.topLeft()-m_ownerRect.topLeft();
    if(m_fallback) {
        const auto tip=toastRect(); if(tip.isEmpty()) {cancel();return;}
        m_rects={tip}; m_ownerRect=rect; m_renderer.move(m_rects);
    } else if (!delta.isNull()) {
        if (!m_effective.value("dragFollow").toBool()) { cancel(); return; }
        for (auto &r : m_rects) r.translate(delta);
        m_ownerRect = rect; m_renderer.move(m_rects);
    }
    const auto client = Win::clientRect(m_owner);
    for (const auto &r : m_rects) {
        if (m_effective.value("clipRegion").toBool() && !QRectF(client).contains(r)) { cancel(); return; }
        const auto inset=r.adjusted(0.5,0.5,-0.5,-0.5);
        for(const auto &p : {inset.topLeft(),inset.topRight(),inset.bottomLeft(),inset.bottomRight(),inset.center()}) {
            const POINT point{LONG(p.x()),LONG(p.y())};
            const auto hit=WindowFromPoint(point);
            if(hit && GetAncestor(hit,GA_ROOT)!=m_owner) { cancel(); return; }
        }
    }
    if (!m_caret && !m_fallback && m_snapshot.level == "L3" && m_followClock.elapsed() >= 90) {
        m_followClock.restart(); query(QueryReason::Follow);
        const auto age = QDateTime::currentMSecsSinceEpoch()-m_lastGeometry;
        if (age > 210) { cancel(); return; }
        if (m_effective.value("predictScroll").toBool() && age > 95 && m_lastMotion.manhattanLength() < 80) {
            auto predicted = m_rects; for (auto &r : predicted) r.translate(m_lastMotion*0.25); m_renderer.move(predicted);
        }
    }
}
QString App::diagnostics() const {
    return QString("CopyPop 1.0.0 · Qt %1\n剪贴板监听：%2\n选区能力：%3\n剪贴板更新：%4 · 动画：%5 · 查询超时：%6\nUIA 预算：180 ms · 单个 MTA 工作线程\n配置：%7\n日志：%8\n启动项：%9").arg(QT_VERSION_STR,m_events.valid()?"已注册":"失败",m_tracker.status()).arg(m_updates).arg(m_animations).arg(m_timeouts).arg(m_config->fileName(),logPath(),Win::startupEnabled()?"已启用":"未启用");
}
void App::captureWindow(const QString &file) { auto *window = qobject_cast<QQuickWindow *>(m_settings?m_settings.data():m_welcome.data()); if (window) window->grabWindow().save(file); }
bool App::nativeSelfTest() {
    // Run against this process's own native window; no input is sent to other applications.
    if (!m_settings) showSettings();
    if (!m_settings) return false;
    const auto foreground=GetForegroundWindow();
    const auto owner = reinterpret_cast<HWND>(m_settings->winId()); const auto area = Win::clientRect(owner);
    m_renderer.show(owner,{QRectF(area.x()+100,area.y()+150,200,24)},m_config->values());
    bool found = false; bool ok = true;
    for (auto *w : QGuiApplication::allWindows()) if ((w->flags()&Qt::WindowTransparentForInput) && w->isVisible()) {
        found = true; auto h = reinterpret_cast<HWND>(w->winId()); const auto ex = GetWindowLongPtrW(h,GWL_EXSTYLE);
        ok = ok && (ex&WS_EX_NOACTIVATE) && (ex&WS_EX_TRANSPARENT) && (ex&WS_EX_TOOLWINDOW) && !(ex&WS_EX_TOPMOST) && GetWindow(h,GW_OWNER)==owner;
    }
    ok=ok && GetForegroundWindow()==foreground;
    m_renderer.hide(); return found && ok && !m_renderer.visible();
}
