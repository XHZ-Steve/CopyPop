#pragma once
#include <QObject>
#include <QRect>
#include <QVariantList>
#include <QStringView>
#include <windows.h>

namespace Win {
QString processPath(HWND window);
QRect windowRect(HWND window);
QRect clientRect(HWND window);
bool fullscreen(HWND window);
bool presentation();
bool reducedMotion();
bool knownGame(const QString &path, const QVariantList &games);
bool startupEnabled();
bool setStartup(bool enabled);
QString classifyClipboard(); // Caller owns OpenClipboard; reads at most 2048 UTF-16 units.
QString classifyFormats(bool files,bool image,bool text,QStringView snippet = {},bool complete = true);
bool probableCopy();
}

class WindowsEvents : public QObject {
    Q_OBJECT
public:
    explicit WindowsEvents(QObject *parent = nullptr);
    ~WindowsEvents();
    HWND handle() const { return m_window; }
    bool valid() const { return m_clipboardRegistered; }
    static constexpr UINT SelectionReady = WM_APP + 42;
    static constexpr UINT SelectionChanged = WM_APP + 43;
signals:
    void clipboardChanged();
    void foregroundChanged();
    void focusChanged();
    void geometryChanged();
    void inputChanged();
    void selectionReady();
    void selectionChanged();
    void displaysChanged();
private:
    static LRESULT CALLBACK windowProc(HWND,UINT,WPARAM,LPARAM);
    static void CALLBACK eventProc(HWINEVENTHOOK,DWORD,HWND,LONG,LONG,DWORD,DWORD);
    HWND m_window = nullptr;
    QList<HWINEVENTHOOK> m_hooks;
    bool m_clipboardRegistered = false;
    static HWND s_window;
};
