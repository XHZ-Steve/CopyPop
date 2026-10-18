#include "Windows.h"
#include "core/Config.h"
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QSettings>
#include <QUrl>
#include <shellapi.h>
#include <dwmapi.h>

QString Win::processPath(HWND window) {
    DWORD pid = 0; GetWindowThreadProcessId(window,&pid);
    HANDLE p = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION,FALSE,pid);
    if (!p) return {};
    wchar_t path[32768]; DWORD n = 32768;
    const bool ok = QueryFullProcessImageNameW(p,0,path,&n); CloseHandle(p);
    return ok ? Config::normalizePath(QString::fromWCharArray(path,int(n))) : QString();
}
QRect Win::windowRect(HWND window) { RECT r{}; if (!GetWindowRect(window,&r)) return {}; return {r.left,r.top,r.right-r.left,r.bottom-r.top}; }
QRect Win::clientRect(HWND window) {
    RECT r{}; if (!GetClientRect(window,&r)) return {}; POINT p{r.left,r.top};
    if (!ClientToScreen(window,&p)) return {};
    return {p.x,p.y,r.right-r.left,r.bottom-r.top};
}
bool Win::fullscreen(HWND window) {
    if (!window || !IsWindowVisible(window) || IsIconic(window)) return false;
    wchar_t cls[128]{}; GetClassNameW(window,cls,128);
    if (wcscmp(cls,L"Progman") == 0 || wcscmp(cls,L"WorkerW") == 0 || wcscmp(cls,L"Shell_TrayWnd") == 0) return false;
    MONITORINFO mi{}; mi.cbSize = sizeof(mi); if (!GetMonitorInfoW(MonitorFromWindow(window,MONITOR_DEFAULTTONEAREST),&mi)) return false;
    RECT r{}; if (FAILED(DwmGetWindowAttribute(window,DWMWA_EXTENDED_FRAME_BOUNDS,&r,sizeof(r)))) GetWindowRect(window,&r);
    return r.left <= mi.rcMonitor.left && r.top <= mi.rcMonitor.top && r.right >= mi.rcMonitor.right && r.bottom >= mi.rcMonitor.bottom;
}
bool Win::presentation() {
    QUERY_USER_NOTIFICATION_STATE state{};
    return SUCCEEDED(SHQueryUserNotificationState(&state)) && (state == QUNS_PRESENTATION_MODE || state == QUNS_RUNNING_D3D_FULL_SCREEN || state == QUNS_BUSY);
}
bool Win::reducedMotion() { BOOL enabled = TRUE; SystemParametersInfoW(SPI_GETCLIENTAREAANIMATION,0,&enabled,0); return !enabled; }
bool Win::knownGame(const QString &path, const QVariantList &games) {
    const auto clean = Config::normalizePath(path);
    for (const auto &g : games) { const auto row = g.toMap();
        if (clean.endsWith(row["suffix"].toString(),Qt::CaseInsensitive) && !row["suffix"].toString().isEmpty()) return true;
    } return false;
}
static QString runKey() { return "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"; }
bool Win::startupEnabled() { return QSettings(runKey(),QSettings::NativeFormat).contains("CopyPop"); }
bool Win::setStartup(bool enabled) {
    QSettings s(runKey(),QSettings::NativeFormat);
    if (enabled) s.setValue("CopyPop",'"' + QDir::toNativeSeparators(QCoreApplication::applicationFilePath()) + "\" --background");
    else s.remove("CopyPop");
    s.sync(); return s.status() == QSettings::NoError;
}
QString Win::classifyFormats(bool files,bool image,bool text,QStringView snippet,bool complete) {
    if(files) return "files";
    if(image) return "image";
    if(!text) return "other";
    const auto candidate=snippet.trimmed(); const QUrl url(candidate.toString(),QUrl::StrictMode);
    const bool link=complete && !candidate.contains(QChar(' ')) && !candidate.contains(QChar('\n')) && url.isValid() && !url.host().isEmpty() && (url.scheme()=="https" || url.scheme()=="http" || url.scheme()=="ftp");
    return link?"url":"text";
}
QString Win::classifyClipboard() {
    const bool files=IsClipboardFormatAvailable(CF_HDROP);
    const bool image=IsClipboardFormatAvailable(CF_DIBV5) || IsClipboardFormatAvailable(CF_DIB) || IsClipboardFormatAvailable(CF_BITMAP) || IsClipboardFormatAvailable(RegisterClipboardFormatW(L"PNG"));
    if(files || image) return classifyFormats(files,image,false);
    if (IsClipboardFormatAvailable(CF_UNICODETEXT)) {
        const auto handle = GetClipboardData(CF_UNICODETEXT);
        if (handle) {
            const auto size = GlobalSize(handle) / sizeof(wchar_t);
            const auto p = static_cast<const wchar_t *>(GlobalLock(handle));
            if (p) {
                const auto limit = qMin<size_t>(size,2048); size_t n = 0;
                while (n < limit && p[n]) ++n;
                // Only temporary URL classification; never expose or persist the text.
                const auto text = QString::fromWCharArray(p,int(n)).trimmed();
                GlobalUnlock(handle); return classifyFormats(false,false,true,text,n<2048);
            }
        } return "text";
    }
    if (IsClipboardFormatAvailable(CF_TEXT)) return "text";
    return "other";
}
bool Win::probableCopy() {
    return ((GetAsyncKeyState(VK_CONTROL)&0x8000) && ((GetAsyncKeyState('C')&0x8000)||(GetAsyncKeyState(VK_INSERT)&0x8000))) || (GetAsyncKeyState(VK_RBUTTON)&0x8000);
}
HWND WindowsEvents::s_window = nullptr;
WindowsEvents::WindowsEvents(QObject *parent) : QObject(parent) {
    WNDCLASSW wc{}; wc.hInstance = GetModuleHandleW(nullptr); wc.lpszClassName = L"CopyPopEventsV1"; wc.lpfnWndProc = windowProc;
    RegisterClassW(&wc);
    // Hidden top-level window receives display broadcasts as well as clipboard notifications.
    m_window = CreateWindowExW(WS_EX_TOOLWINDOW|WS_EX_NOACTIVATE,wc.lpszClassName,L"CopyPop events",WS_POPUP,0,0,0,0,nullptr,nullptr,wc.hInstance,this);
    s_window = m_window; m_clipboardRegistered = m_window && AddClipboardFormatListener(m_window);
    const QList<QPair<DWORD,DWORD>> ranges = {{EVENT_SYSTEM_FOREGROUND,EVENT_SYSTEM_FOREGROUND},{EVENT_SYSTEM_MOVESIZESTART,EVENT_SYSTEM_MOVESIZEEND},{EVENT_SYSTEM_SCROLLINGSTART,EVENT_SYSTEM_SCROLLINGEND},{EVENT_SYSTEM_MINIMIZESTART,EVENT_SYSTEM_MINIMIZEEND},{EVENT_OBJECT_FOCUS,EVENT_OBJECT_FOCUS},{EVENT_OBJECT_SELECTION,EVENT_OBJECT_SELECTIONWITHIN},{EVENT_OBJECT_LOCATIONCHANGE,EVENT_OBJECT_VALUECHANGE},{EVENT_OBJECT_DESTROY,EVENT_OBJECT_HIDE}};
    for (auto range : ranges) { auto hook = SetWinEventHook(range.first,range.second,nullptr,eventProc,0,0,WINEVENT_OUTOFCONTEXT|WINEVENT_SKIPOWNPROCESS); if (hook) m_hooks.append(hook); }
}
WindowsEvents::~WindowsEvents() { s_window = nullptr; for (auto h : m_hooks) UnhookWinEvent(h); if (m_window) { RemoveClipboardFormatListener(m_window); DestroyWindow(m_window); } }
LRESULT CALLBACK WindowsEvents::windowProc(HWND w,UINT msg,WPARAM wp,LPARAM lp) {
    if (msg == WM_NCCREATE) SetWindowLongPtrW(w,GWLP_USERDATA,reinterpret_cast<LONG_PTR>(reinterpret_cast<CREATESTRUCTW *>(lp)->lpCreateParams));
    auto self = reinterpret_cast<WindowsEvents *>(GetWindowLongPtrW(w,GWLP_USERDATA));
    if (self) switch (msg) {
        case WM_CLIPBOARDUPDATE: emit self->clipboardChanged(); return 0;
        case WM_DISPLAYCHANGE: case WM_DPICHANGED: emit self->displaysChanged(); break;
        case SelectionReady: emit self->selectionReady(); return 0;
        case SelectionChanged: emit self->selectionChanged(); return 0;
        case WM_APP+1: emit self->foregroundChanged(); return 0;
        case WM_APP+2: emit self->focusChanged(); return 0;
        case WM_APP+3: emit self->geometryChanged(); return 0;
        case WM_APP+4: emit self->inputChanged(); return 0;
    }
    return DefWindowProcW(w,msg,wp,lp);
}
void CALLBACK WindowsEvents::eventProc(HWINEVENTHOOK,DWORD event,HWND w,LONG object,LONG,DWORD,DWORD) {
    if (!s_window) return;
    if (event == EVENT_SYSTEM_FOREGROUND) { PostMessageW(s_window,WM_APP+1,0,0); return; }
    if (!w || GetAncestor(w,GA_ROOT) != GetForegroundWindow()) return;
    if (event == EVENT_OBJECT_FOCUS) PostMessageW(s_window,WM_APP+2,0,0);
    else if (event >= EVENT_OBJECT_SELECTION && event <= EVENT_OBJECT_SELECTIONWITHIN) PostMessageW(s_window,SelectionChanged,0,0);
    else if (event == EVENT_OBJECT_VALUECHANGE || (event == EVENT_OBJECT_LOCATIONCHANGE && object == OBJID_CARET)) PostMessageW(s_window,WM_APP+4,0,0);
    else PostMessageW(s_window,WM_APP+3,0,0);
}
