#pragma once
#include <QList>
#include <QRectF>
#include <QVariantMap>
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
class OverlayRenderer final : public IOverlayRenderer {
public:
    explicit OverlayRenderer(QQmlEngine *engine);
    ~OverlayRenderer() override;
    void show(HWND owner,const QList<QRectF> &rects,const QVariantMap &settings,const QString &kind = {}) override;
    void move(const QList<QRectF> &rects) override;
    void hide() override;
    bool visible() const override;
private:
    void layout(const QList<QRectF> &rects,bool start);
    QQmlEngine *m_engine;
    QList<QQuickView *> m_views;
    HWND m_owner = nullptr;
    QVariantMap m_settings;
    QString m_kind;
};
