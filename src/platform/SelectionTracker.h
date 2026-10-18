#pragma once
#include <QObject>
#include <QRectF>
#include <QTimer>
#include <QMap>
#include <memory>
#include <windows.h>

enum class QueryReason { Snapshot, Copy, Focus, Follow };
struct SelectionSnapshot {
    HWND window = nullptr;
    quint64 generation = 0;
    qint64 requestedAt = 0;
    QueryReason reason = QueryReason::Snapshot;
    QList<QRectF> rectangles;
    QRectF caret, control;
    bool protectedControl = true;
    bool editable = false;
    bool selection = false;
    QString controlId;
    QString level = "L0";
};
Q_DECLARE_METATYPE(SelectionSnapshot)

class SelectionTracker : public QObject {
    Q_OBJECT
public:
    SelectionTracker(HWND notificationWindow,QObject *parent = nullptr);
    ~SelectionTracker();
    bool request(HWND window, QueryReason reason, const QString &path);
    bool initialized() const;
    void invalidate();
    void receive();
    QString status() const { return m_status; }
signals:
    void ready(const SelectionSnapshot &snapshot);
    void budgetExceeded();
private:
    struct Shared;
    std::shared_ptr<Shared> m_shared;
    quint64 m_generation = 0;
    QTimer m_budget;
    QString m_status = "尚未检测";
    QString m_path;
    QMap<QString,QPair<qint64,QString>> m_capabilities;
};
