#pragma once
#include <QList>
#include <QRectF>
#include <QVariantMap>
#include <QObject>
#include <memory>
#include <windows.h>
class QQmlEngine;
class QQuickView;

class IOverlayRenderer {
public:
    virtual ~IOverlayRenderer() = default;
    virtual void show(HWND owner,const QList<QRectF> &physicalRects,const QVariantMap &settings,const QString &kind = {}) = 0;
    virtual void move(const QList<QRectF> &physicalRects) = 0;
    virtual void hide() = 0;
    virtual bool visible() const = 0;
};
class OverlayRenderer final : public QObject, public IOverlayRenderer {
    Q_OBJECT
public:
    explicit OverlayRenderer(QQmlEngine *engine);
    ~OverlayRenderer() override;
    void show(HWND owner,const QList<QRectF> &rects,const QVariantMap &settings,const QString &kind = {}) override;
    void move(const QList<QRectF> &rects) override;
    void hide() override;
    void setPaperOffset(QPointF physicalOffset);
    void updateKind(const QString &kind);
    bool visible() const override;
signals:
    void followFrame(double seconds);
private slots:
    void frame(double seconds);
private:
    void layout(const QList<QRectF> &rects,bool start);
    QQmlEngine *m_engine;
    QList<QQuickView *> m_views;
    HWND m_owner = nullptr;
    QVariantMap m_settings;
    QString m_kind;
};
