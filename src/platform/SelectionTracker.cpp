#include "SelectionTracker.h"
#include "Windows.h"
#include <QDateTime>
#include <objbase.h>
#include <uiautomation.h>
#include <atomic>
#include <condition_variable>
#include <mutex>
#include <optional>
#include <thread>
#include <cmath>
#include <chrono>
#include <functional>

template<class T> struct Com {
    T *p = nullptr;
    ~Com() { if (p) p->Release(); }
    T **out() { return &p; }
    T *operator->() const { return p; }
    explicit operator bool() const { return p != nullptr; }
};
struct SelectionTracker::Shared {
    std::mutex mutex;
    std::condition_variable wake;
    bool stop = false;
    std::atomic_bool initialized{false};
    HWND notify = nullptr;
    std::optional<SelectionSnapshot> pending, result;
};

static QList<QRectF> rectangles(IUIAutomationTextRange *range) {
    QList<QRectF> out; SAFEARRAY *a = nullptr;
    if (FAILED(range->GetBoundingRectangles(&a)) || !a) return out;
    if (SafeArrayGetDim(a) == 1 && SafeArrayGetElemsize(a) == sizeof(double)) {
        LONG low = 0, high = -1; SafeArrayGetLBound(a,1,&low); SafeArrayGetUBound(a,1,&high);
        double *p = nullptr;
        if (SUCCEEDED(SafeArrayAccessData(a,reinterpret_cast<void **>(&p)))) {
            for (LONG i = 0; i+3 <= high-low && out.size() < 128; i += 4) {
                QRectF r(p[i],p[i+1],p[i+2],p[i+3]);
                if (std::isfinite(r.x()) && std::isfinite(r.y()) && r.width() > 0 && r.height() > 0 && r.width() < 100000 && r.height() < 100000) out.append(r);
            }
            SafeArrayUnaccessData(a);
        }
    } SafeArrayDestroy(a); return out;
}

// An event only requests a fresh geometry query. No text or COM element leaves this MTA.
class SelectionEvent final : public IUIAutomationEventHandler {
    std::atomic<ULONG> refs{1}; std::function<void()> notify;
public:
    explicit SelectionEvent(std::function<void()> callback) : notify(std::move(callback)) {}
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID id,void **out) override {
        if (!out) return E_POINTER;
        *out = nullptr;
        if (IsEqualIID(id,IID_IUnknown) || IsEqualIID(id,__uuidof(IUIAutomationEventHandler))) { *out = this; AddRef(); return S_OK; } return E_NOINTERFACE;
    }
    ULONG STDMETHODCALLTYPE AddRef() override { return ++refs; }
    ULONG STDMETHODCALLTYPE Release() override { const ULONG n = --refs; if (!n) delete this; return n; }
    HRESULT STDMETHODCALLTYPE HandleAutomationEvent(IUIAutomationElement *,EVENTID) override { notify(); return S_OK; }
};

static void query(IUIAutomation *automation, SelectionSnapshot &s) {
    if (!automation || GetForegroundWindow() != s.window || !IsWindow(s.window)) return;
    Com<IUIAutomationElement> element;
    if (FAILED(automation->GetFocusedElement(element.out())) || !element) return;
    int pid = 0; DWORD expected = 0; GetWindowThreadProcessId(s.window,&expected);
    if (FAILED(element->get_CurrentProcessId(&pid)) || DWORD(pid) != expected) return;
    BOOL password = TRUE, offscreen = TRUE;
    if (FAILED(element->get_CurrentIsPassword(&password)) || password || FAILED(element->get_CurrentIsOffscreen(&offscreen)) || offscreen) return;
    s.protectedControl = false;
    CONTROLTYPEID type = 0; element->get_CurrentControlType(&type);
    VARIANT readOnly; VariantInit(&readOnly);
    const bool hasReadOnly = SUCCEEDED(element->GetCurrentPropertyValue(UIA_ValueIsReadOnlyPropertyId,&readOnly)) && readOnly.vt == VT_BOOL;
    s.editable = type == UIA_EditControlTypeId && (!hasReadOnly || readOnly.boolVal == VARIANT_FALSE);
    VariantClear(&readOnly);
    RECT r{}; if (SUCCEEDED(element->get_CurrentBoundingRectangle(&r))) s.control = QRectF(r.left,r.top,r.right-r.left,r.bottom-r.top);
    BSTR id = nullptr; if (SUCCEEDED(element->get_CurrentAutomationId(&id)) && id) { s.controlId = QString::fromWCharArray(id).left(128); SysFreeString(id); }
    Com<IUIAutomationTextPattern> text;
    const auto textResult=element->GetCurrentPatternAs(UIA_TextPatternId,__uuidof(IUIAutomationTextPattern),reinterpret_cast<void **>(text.out()));
    if (SUCCEEDED(textResult) && text) {
        Com<IUIAutomationTextRangeArray> ranges;
        const auto selectionResult=text->GetSelection(ranges.out());
        if (SUCCEEDED(selectionResult) && ranges) {
            int n = 0; ranges->get_Length(&n);
            for (int i = 0; i < qMin(n,32); ++i) {
                Com<IUIAutomationTextRange> range; if (FAILED(ranges->GetElement(i,range.out())) || !range) continue;
                int difference = 0;
                if (SUCCEEDED(range->CompareEndpoints(TextPatternRangeEndpoint_Start,range.p,TextPatternRangeEndpoint_End,&difference)) && difference != 0) {
                    s.selection = true; s.rectangles.append(rectangles(range.p));
                    if (s.rectangles.size() >= 128) { s.rectangles = s.rectangles.mid(0,128); break; }
                }
            }
        }
    }
    Com<IUIAutomationTextPattern2> text2;
    if (SUCCEEDED(element->GetCurrentPatternAs(UIA_TextPattern2Id,__uuidof(IUIAutomationTextPattern2),reinterpret_cast<void **>(text2.out()))) && text2) {
        BOOL active = FALSE; Com<IUIAutomationTextRange> range;
        if (SUCCEEDED(text2->GetCaretRange(&active,range.out())) && active && range) {
            const auto rects = rectangles(range.p); if (!rects.isEmpty()) s.caret = rects.first();
            if (type == UIA_DocumentControlTypeId) {
                VARIANT v; VariantInit(&v);
                // UIA_IsReadOnlyAttributeId (40015) is absent in older MinGW headers.
                if (SUCCEEDED(range->GetAttributeValue(40015,&v)) && v.vt == VT_BOOL && v.boolVal == VARIANT_FALSE) s.editable = true;
                VariantClear(&v);
            }
        }
    }
    // Standard Win32 caret is a geometry-only fallback, still gated by the UIA password check.
    GUITHREADINFO info{}; info.cbSize = sizeof(info);
    const bool hasThreadInfo=GetGUIThreadInfo(GetWindowThreadProcessId(s.window,nullptr),&info);
    bool nativeApproximation=false;
    // Some standard Win32 Edit controls expose ValuePattern but no TextPattern.
    // Query only selection indices/positions, never WM_GETTEXT or another process's memory.
    if (s.rectangles.isEmpty() && hasThreadInfo && info.hwndFocus) {
        wchar_t className[64]{}; GetClassNameW(info.hwndFocus,className,64);
        if (_wcsicmp(className,L"Edit")==0 && !(GetWindowLongPtrW(info.hwndFocus,GWL_STYLE)&ES_PASSWORD)) {
            const auto deadline=std::chrono::steady_clock::now()+std::chrono::milliseconds(45);
            auto message=[&](UINT msg,WPARAM wp,LPARAM lp)->std::optional<DWORD_PTR> {
                if(std::chrono::steady_clock::now()>deadline) return {};
                DWORD_PTR result=0;
                if(!SendMessageTimeoutW(info.hwndFocus,msg,wp,lp,SMTO_ABORTIFHUNG|SMTO_BLOCK,12,&result)) return {};
                return result;
            };
            auto selected=message(EM_GETSEL,0,0);
            if(selected && *selected!=DWORD_PTR(-1) && LOWORD(*selected)!=HIWORD(*selected)) {
                s.selection=true;
                const auto begin=message(EM_POSFROMCHAR,LOWORD(*selected),0);
                const auto end=message(EM_POSFROMCHAR,HIWORD(*selected),0);
                if(begin && end && *begin!=DWORD_PTR(-1) && *end!=DWORD_PTR(-1)) {
                    POINT origin{0,0}; ClientToScreen(info.hwndFocus,&origin);
                    HDC dc=GetDC(info.hwndFocus); TEXTMETRICW metrics{};
                    const auto font=message(WM_GETFONT,0,0);
                    HGDIOBJ old=nullptr; if(dc && font && *font) old=SelectObject(dc,reinterpret_cast<HGDIOBJ>(*font));
                    if(dc) GetTextMetricsW(dc,&metrics);
                    if(old) SelectObject(dc,old);
                    if(dc) ReleaseDC(info.hwndFocus,dc);
                    const int height=qMax(12L,metrics.tmHeight);
                    const QPointF a(origin.x+short(LOWORD(*begin)),origin.y+short(HIWORD(*begin)));
                    const QPointF b(origin.x+short(LOWORD(*end)),origin.y+short(HIWORD(*end)));
                    if(a.y()==b.y() && b.x()>a.x()) s.rectangles.append(QRectF(a,QSizeF(b.x()-a.x(),height)));
                    else if(b.y()>a.y() && b.y()-a.y()<2000) {
                        s.rectangles.append(QRectF(a,QSizeF(qMax(1.0,s.control.right()-a.x()),height)));
                        if(b.y()>a.y()+height) s.rectangles.append(QRectF(s.control.x(),a.y()+height,s.control.width(),b.y()-a.y()-height));
                        if(b.x()>s.control.x()) s.rectangles.append(QRectF(s.control.x(),b.y(),b.x()-s.control.x(),height));
                    }
                    nativeApproximation=!s.rectangles.isEmpty();
                }
            }
        }
    }
    if (s.caret.isEmpty() && hasThreadInfo && info.hwndCaret) {
        POINT p{info.rcCaret.left,info.rcCaret.top}; ClientToScreen(info.hwndCaret,&p);
        s.caret = QRectF(p.x,p.y,qMax(1L,info.rcCaret.right-info.rcCaret.left),info.rcCaret.bottom-info.rcCaret.top);
    }
    const auto client = QRectF(Win::clientRect(s.window));
    QList<QRectF> visible;
    for (const auto &rect : s.rectangles) { const auto clipped = rect.intersected(client).intersected(s.control); if (!clipped.isEmpty()) visible.append(clipped); }
    s.rectangles = visible;
    if (!s.rectangles.isEmpty()) s.level = nativeApproximation?"L2":"L3";
    else if (s.selection && !s.control.isEmpty() && s.control.width()*s.control.height() < 140000) { s.level = "L2"; s.rectangles.append(s.control.intersected(client)); }
    else if (!s.caret.isEmpty()) s.level = "L1";
}
SelectionTracker::SelectionTracker(HWND notify,QObject *parent) : QObject(parent), m_shared(std::make_shared<Shared>()) {
    m_shared->notify = notify;
    m_budget.setSingleShot(true); m_budget.setInterval(180);
    connect(&m_budget,&QTimer::timeout,this,[this] {
        ++m_generation; m_status = "超时；安全降级";
        m_capabilities[m_path] = {QDateTime::currentMSecsSinceEpoch()+30000,"timeout"};
        emit budgetExceeded();
    });
    // A provider can block indefinitely. One bounded worker is kept alive by shared state;
    // never terminate a COM call or spawn replacement threads without limit.
    std::thread([state=m_shared] {
        const HRESULT hr = CoInitializeEx(nullptr,COINIT_MULTITHREADED);
        Com<IUIAutomation> automation;
        if (SUCCEEDED(hr)) CoCreateInstance(__uuidof(CUIAutomation),nullptr,CLSCTX_INPROC_SERVER,__uuidof(IUIAutomation),reinterpret_cast<void **>(automation.out()));
        Com<IUIAutomationElement> root;
        Com<IUIAutomationEventHandler> handler;
        if (automation && SUCCEEDED(automation->GetRootElement(root.out())) && root) {
            handler.p = new SelectionEvent([state]{ std::lock_guard lock(state->mutex); if(!state->stop) PostMessageW(state->notify,WindowsEvents::SelectionChanged,0,0); });
            automation->AddAutomationEventHandler(UIA_Text_TextSelectionChangedEventId,root.p,static_cast<TreeScope>(7),nullptr,handler.p);
        }
        state->initialized.store(true);
        while (true) {
            SelectionSnapshot s;
            { std::unique_lock lock(state->mutex); state->wake.wait(lock,[&]{ return state->stop || state->pending.has_value(); });
                if (state->stop) break;
                s = *state->pending; state->pending.reset(); }
            query(automation.p,s);
            { std::lock_guard lock(state->mutex); if (state->stop) break; state->result = std::move(s); PostMessageW(state->notify,WindowsEvents::SelectionReady,0,0); }
        }
        if (automation) automation->RemoveAllEventHandlers();
        // Release interfaces before uninitializing this apartment.
        if (handler.p) { handler.p->Release(); handler.p = nullptr; }
        if (root.p) { root.p->Release(); root.p = nullptr; }
        if (automation.p) { automation.p->Release(); automation.p = nullptr; }
        if (SUCCEEDED(hr)) CoUninitialize();
    }).detach();
}
SelectionTracker::~SelectionTracker() { std::lock_guard lock(m_shared->mutex); m_shared->stop = true; m_shared->wake.notify_one(); }
bool SelectionTracker::initialized() const { return m_shared->initialized.load(); }
bool SelectionTracker::request(HWND window,QueryReason reason,const QString &path) {
    if (!initialized() || m_budget.isActive()) return false;
    const auto now = QDateTime::currentMSecsSinceEpoch();
    const auto cache = m_capabilities.value(path);
    if (cache.first > now && cache.second == "timeout") return false;
    if (reason==QueryReason::Snapshot && cache.first>now && cache.second=="L0") return false;
    if (m_capabilities.size() > 128) m_capabilities.clear();
    SelectionSnapshot s; s.window = window; s.reason = reason; s.generation = ++m_generation; s.requestedAt = now;
    { std::lock_guard lock(m_shared->mutex); m_shared->pending = s; }
    m_path = path; m_budget.start(); m_shared->wake.notify_one(); return true;
}
void SelectionTracker::invalidate() { ++m_generation; m_budget.stop(); std::lock_guard lock(m_shared->mutex); m_shared->pending.reset(); }
void SelectionTracker::receive() {
    std::optional<SelectionSnapshot> result;
    { std::lock_guard lock(m_shared->mutex); result.swap(m_shared->result); }
    if (!result || result->generation != m_generation) return;
    m_budget.stop();
    if (QDateTime::currentMSecsSinceEpoch()-result->requestedAt > 180 || GetForegroundWindow() != result->window) return;
    m_status = result->protectedControl ? "Off · 受保护控件" : result->level;
    m_capabilities[m_path] = {QDateTime::currentMSecsSinceEpoch()+60000,result->level};
    emit ready(*result);
}
