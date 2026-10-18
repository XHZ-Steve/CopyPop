#include "OverlayRenderer.h"
#include <QGuiApplication>
#include <QQuickView>
#include <QQuickItem>
#include <QQmlEngine>
#include <QScreen>
#include <QVariantList>

OverlayRenderer::OverlayRenderer(QQmlEngine *engine) : m_engine(engine) {}
OverlayRenderer::~OverlayRenderer() { qDeleteAll(m_views); }
bool OverlayRenderer::visible() const { for (auto *v : m_views) if (v->isVisible()) return true; return false; }
void OverlayRenderer::hide() {
    for (auto *v : m_views) {
        if (v->rootObject()) QMetaObject::invokeMethod(v->rootObject(),"cancel");
        v->hide();
        if (v->handle()) SetWindowLongPtrW(reinterpret_cast<HWND>(v->winId()),GWLP_HWNDPARENT,0);
    }
}
void OverlayRenderer::show(HWND owner,const QList<QRectF> &rects,const QVariantMap &settings,const QString &kind) {
    hide(); m_owner = owner; m_settings = settings; m_kind = kind; layout(rects,true);
}
void OverlayRenderer::move(const QList<QRectF> &rects) { if (visible()) layout(rects,false); }
void OverlayRenderer::frame(double seconds) {
    if(m_kind=="copied" && !m_views.isEmpty() && sender()==m_views.first()->rootObject() && visible()) emit followFrame(seconds);
}
void OverlayRenderer::layout(const QList<QRectF> &rects,bool start) {
    int index = 0;
    for (auto *screen : QGuiApplication::screens()) {
        // UIA/Win32 report physical pixels; Qt reports per-screen logical coordinates.
        MONITORINFOEXW mi{}; mi.cbSize = sizeof(mi);
        // On Windows Qt keeps monitor origins in native desktop coordinates even at mixed DPI.
        // Qt 6.11 can expose a friendly model name instead of the GDI device name.
        struct Search { QString name; QPoint origin; MONITORINFOEXW *mi; bool found = false; } search{screen->name(),screen->geometry().topLeft(),&mi};
        EnumDisplayMonitors(nullptr,nullptr,[](HMONITOR h,HDC,LPRECT,LPARAM lp)->BOOL {
            auto *s = reinterpret_cast<Search *>(lp); MONITORINFOEXW current{}; current.cbSize = sizeof(current);
            if (GetMonitorInfoW(h,&current) && (QString::fromWCharArray(current.szDevice).compare(s->name,Qt::CaseInsensitive) == 0 || QPoint(current.rcMonitor.left,current.rcMonitor.top) == s->origin)) { *s->mi = current; s->found = true; return FALSE; } return TRUE;
        },reinterpret_cast<LPARAM>(&search));
        if (!search.found) continue;
        const QRectF monitor(mi.rcMonitor.left,mi.rcMonitor.top,mi.rcMonitor.right-mi.rcMonitor.left,mi.rcMonitor.bottom-mi.rcMonitor.top);
        const QRectF work(mi.rcWork.left,mi.rcWork.top,mi.rcWork.right-mi.rcWork.left,mi.rcWork.bottom-mi.rcWork.top);
        const double scale = screen->devicePixelRatio();
        QList<QRectF> clipped; QRectF bounds;
        for (const auto &r : rects) { const auto c = r.intersected(monitor); if (!c.isEmpty()) { clipped.append(c); bounds = bounds.united(c); } }
        if (clipped.isEmpty()) continue;
        bounds = bounds.adjusted(-8*scale,-8*scale,8*scale,8*scale).intersected(m_kind.isEmpty()?monitor:work);
        if (bounds.isEmpty()) continue;
        if (index >= m_views.size()) {
            auto *view = new QQuickView(m_engine,nullptr);
            view->setColor(Qt::transparent);
            view->setFlags(Qt::Tool|Qt::FramelessWindowHint|Qt::WindowDoesNotAcceptFocus|Qt::WindowTransparentForInput|Qt::NoDropShadowWindowHint);
            view->setResizeMode(QQuickView::SizeRootObjectToView);
            view->setSource(QUrl("qrc:/qml/Overlay.qml"));
            if(view->rootObject()) connect(view->rootObject(),SIGNAL(frameTick(double)),this,SLOT(frame(double)));
            m_views.append(view);
        }
        auto *view = m_views[index++]; if (!view->rootObject()) continue;
        if (!start && !view->isVisible()) continue; // Never replay a completed animation.
        view->setScreen(screen);
        const auto origin = screen->geometry().topLeft() + QPoint(qRound((bounds.x()-monitor.x())/scale),qRound((bounds.y()-monitor.y())/scale));
        view->setGeometry(QRect(origin,QSize(qCeil(bounds.width()/scale),qCeil(bounds.height()/scale))));
        QVariantList local;
        for (const auto &c : clipped) local.append(QVariantMap{{"x",(c.x()-bounds.x())/scale},{"y",(c.y()-bounds.y())/scale},{"w",c.width()/scale},{"h",c.height()/scale}});
        auto *root = view->rootObject();
        root->setProperty("regions",local);
        if (start) {
            root->setProperty("settings",m_settings);
            root->setProperty("kind",m_kind);
            auto hwnd = reinterpret_cast<HWND>(view->winId());
            auto ex = GetWindowLongPtrW(hwnd,GWL_EXSTYLE);
            SetWindowLongPtrW(hwnd,GWL_EXSTYLE,ex|WS_EX_TRANSPARENT|WS_EX_NOACTIVATE|WS_EX_TOOLWINDOW);
            view->show();
            // Qt establishes native styles during show(); attach the owner afterwards.
            SetWindowLongPtrW(hwnd,GWLP_HWNDPARENT,reinterpret_cast<LONG_PTR>(m_owner));
            // Owned, non-topmost windows only. Revalidate foreground before every movement.
            SetWindowPos(hwnd,m_settings.value("dynamicZ",true).toBool()?HWND_TOP:nullptr,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|(m_settings.value("dynamicZ",true).toBool()?0:SWP_NOZORDER));
            QMetaObject::invokeMethod(root,"play");
        }
    }
    while (index < m_views.size()) {
        auto *view=m_views[index++];
        if(view->rootObject()) QMetaObject::invokeMethod(view->rootObject(),"cancel");
        view->hide();
    }
}
