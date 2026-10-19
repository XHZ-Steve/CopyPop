#pragma once
#include <QObject>
#include <QRect>
#include <QVariantList>
#include <QStringView>
#include <memory>
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
QString clipboardFormatKind(); // Does not request delayed clipboard payloads.
QString classifyFormats(bool files,bool image,bool text,QStringView snippet = {},bool complete = true);
bool probableCopy();
QRectF copyToastRect(QPoint cursor,const QRect &area,const QVariantMap &settings,double scale);
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
    static constexpr UINT ClipboardClassified = WM_APP + 44;
signals:
    void clipboardChanged();
    void clipboardClassified();
    void foregroundChanged();
    void focusChanged();
    void geometryChanged();
    void inputChanged();
    void caretChanged();
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

class ClipboardClassifier {
public:
    explicit ClipboardClassifier(HWND notificationWindow);
    ~ClipboardClassifier();
    void request(DWORD sequence);
    QString receive(DWORD sequence);
private:
    struct Shared;
    std::shared_ptr<Shared> m_shared;
};
