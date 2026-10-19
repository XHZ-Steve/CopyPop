#pragma once
#include "core/Config.h"
#include "core/MotionFollower.h"
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
    Q_PROPERTY(QVariantMap performanceStats READ performanceStats NOTIFY performanceChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString clipboardType READ clipboardType NOTIFY statusChanged)
    Q_PROPERTY(QString lastApplication READ lastApplication NOTIFY statusChanged)
    Q_PROPERTY(QString diagnostics READ diagnostics NOTIFY statusChanged)
    Q_PROPERTY(QString notice READ notice NOTIFY noticeChanged)
    Q_PROPERTY(bool reducedMotion READ reducedMotion NOTIFY statusChanged)
public:
    App(Config *config,QQmlEngine *engine,bool testing = false,QObject *parent = nullptr);
    ~App();
    QString status() const { return m_status; }
    QString clipboardType() const { return m_kind; }
    QString lastApplication() const { return m_recentPath; }
    QString diagnostics() const;
    QVariantMap performanceStats() const;
    QString notice() const { return m_notice; }
    bool reducedMotion() const;
    Q_INVOKABLE qint64 monotonicTime() const { return m_uptime.elapsed(); }
    Q_INVOKABLE QVariantMap effectMetrics(const QVariantList &regions,const QVariantMap &settings) const;
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
    void performanceChanged();
    void noticeChanged();
private:
    friend class UiTests;
    void refresh();
    bool allowed() const;
    void clipboard();
    void beginCopy(HWND clipboardOwner,bool inputHint);
    void selection(const SelectionSnapshot &snapshot);
    void copyFallback();
    void showCopyToast();
    QRectF toastRect() const;
    void animate(const QList<QRectF> &rects,bool caret = false,bool fallback = false);
    void cancel(bool keepHost = false);
    void tick();
    void followToast(double seconds);
    void query(QueryReason reason);
    void scheduleFocus();
    void trayUpdate();
    void notify(const QString &message);
    void log(const QString &event);
    QWindow *createWindow(const QString &source);
    Config *m_config;
    QQmlEngine *m_engine;
    WindowsEvents m_events;
    ClipboardClassifier m_classifier;
    SelectionTracker m_tracker;
    OverlayRenderer m_renderer;
    MotionFollower m_toastMotion;
    QSystemTrayIcon m_tray;
    std::unique_ptr<QMenu> m_menu;
    QPointer<QWindow> m_settings, m_welcome;
    QTimer m_guardTimer, m_attachedTimer, m_resumeTimer, m_copyDeadline, m_snapshotDebounce, m_focusProbe, m_performanceTimer;
    QElapsedTimer m_animationClock, m_followClock, m_uptime;
    HWND m_foreground = nullptr, m_owner = nullptr;
    QString m_path, m_recentPath, m_status, m_kind = "other", m_notice;
    QVariantMap m_effective;
    QVariantList m_games;
    SelectionSnapshot m_snapshot;
    QList<QRectF> m_rects;
    QRect m_ownerRect;
    QPointF m_lastMotion;
    bool m_guarded = false, m_paused = false, m_caret = false, m_fallback = false, m_copyPending = false, m_copyHint = false, m_testing = false;
    DWORD m_sequence = 0;
    qint64 m_copyAt = 0, m_lastGeometry = 0;
    int m_effectDuration = 700, m_focusAttempts = 0;
    qint64 m_lastInputAt = 0;
    quint64 m_lastCpuTicks = 0;
    qint64 m_lastCpuAt = 0;
    double m_cpuPercent = 0, m_memoryMb = 0, m_privateMb = 0;
    quint64 m_updates = 0, m_animations = 0, m_timeouts = 0;
};
