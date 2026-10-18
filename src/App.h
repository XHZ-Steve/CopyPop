#pragma once
#include "core/Config.h"
#include "platform/Windows.h"
#include "platform/SelectionTracker.h"
#include "render/OverlayRenderer.h"
#include <QElapsedTimer>
#include <QPointer>
#include <QSystemTrayIcon>
#include <QTimer>
class QQmlEngine;
class QWindow;
class QMenu;

class App : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString clipboardType READ clipboardType NOTIFY statusChanged)
    Q_PROPERTY(QString lastApplication READ lastApplication NOTIFY statusChanged)
    Q_PROPERTY(QString diagnostics READ diagnostics NOTIFY statusChanged)
    Q_PROPERTY(QString notice READ notice NOTIFY noticeChanged)
public:
    App(Config *config,QQmlEngine *engine,bool testing = false,QObject *parent = nullptr);
    ~App();
    QString status() const { return m_status; }
    QString clipboardType() const { return m_kind; }
    QString lastApplication() const { return m_recentPath; }
    QString diagnostics() const;
    QString notice() const { return m_notice; }
    void start(bool background);
    Q_INVOKABLE void showSettings();
    Q_INVOKABLE void showWelcome();
    Q_INVOKABLE void finishWelcome();
    Q_INVOKABLE void pause(int minutes = 0);
    Q_INVOKABLE void resume();
    Q_INVOKABLE void excludeRecent();
    Q_INVOKABLE void chooseApplication();
    Q_INVOKABLE void importConfig();
    Q_INVOKABLE void exportConfig();
    Q_INVOKABLE void resetConfig();
    Q_INVOKABLE void openLogs();
    Q_INVOKABLE void clearLogs();
    Q_INVOKABLE void about();
    Q_INVOKABLE void quit();
    Q_INVOKABLE void dismissNotice();
    Q_INVOKABLE void preset(const QString &name);
    Q_INVOKABLE void captureWindow(const QString &file);
    Q_INVOKABLE bool nativeSelfTest();
signals:
    void statusChanged();
    void noticeChanged();
private:
    void refresh();
    bool allowed() const;
    void clipboard(int attempt = 0);
    void selection(const SelectionSnapshot &snapshot);
    void copyFallback();
    void animate(const QList<QRectF> &rects,bool caret = false);
    void cancel();
    void tick();
    void query(QueryReason reason);
    void trayUpdate();
    void notify(const QString &message);
    void log(const QString &event);
    QWindow *createWindow(const QString &source);
    Config *m_config;
    QQmlEngine *m_engine;
    WindowsEvents m_events;
    SelectionTracker m_tracker;
    OverlayRenderer m_renderer;
    QSystemTrayIcon m_tray;
    std::unique_ptr<QMenu> m_menu;
    QPointer<QWindow> m_settings, m_welcome;
    QTimer m_guardTimer, m_attachedTimer, m_resumeTimer, m_copyDeadline, m_snapshotDebounce;
    QElapsedTimer m_animationClock, m_followClock;
    HWND m_foreground = nullptr, m_owner = nullptr;
    QString m_path, m_recentPath, m_status, m_kind = "other", m_notice;
    QVariantMap m_effective;
    QVariantList m_games;
    SelectionSnapshot m_snapshot;
    QList<QRectF> m_rects;
    QRect m_ownerRect;
    QPointF m_lastMotion;
    bool m_guarded = false, m_paused = false, m_caret = false, m_copyPending = false, m_copyHint = false, m_testing = false;
    DWORD m_sequence = 0;
    qint64 m_copyAt = 0, m_lastGeometry = 0;
    quint64 m_updates = 0, m_animations = 0, m_timeouts = 0;
};
