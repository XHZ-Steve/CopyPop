#include <windows.h>

static LRESULT CALLBACK procedure(HWND w,UINT message,WPARAM wp,LPARAM lp) {
    if (message == WM_DESTROY) { PostQuitMessage(0); return 0; }
    return DefWindowProcW(w,message,wp,lp);
}
int WINAPI WinMain(HINSTANCE instance,HINSTANCE,LPSTR command,int) {
    WNDCLASSW wc{}; wc.hInstance=instance; wc.lpszClassName=L"CopyPopTestFixture"; wc.lpfnWndProc=procedure; wc.hbrBackground=reinterpret_cast<HBRUSH>(COLOR_WINDOW+1);
    RegisterClassW(&wc);
    HWND window=CreateWindowExW(0,wc.lpszClassName,L"CopyPop UIA test fixture",WS_OVERLAPPEDWINDOW|WS_VISIBLE,100,100,640,300,nullptr,nullptr,instance,nullptr);
    bool password=strstr(command,"password") != nullptr;
    HWND edit=CreateWindowExW(WS_EX_CLIENTEDGE,L"EDIT",L"CopyPop native selection test.\r\nSecond visible line.\r\nThird visible line.",WS_CHILD|WS_VISIBLE|WS_TABSTOP|ES_AUTOVSCROLL|(password?ES_PASSWORD:ES_MULTILINE),20,30,580,180,window,reinterpret_cast<HMENU>(101),instance,nullptr);
    SendMessageW(edit,WM_SETFONT,reinterpret_cast<WPARAM>(GetStockObject(DEFAULT_GUI_FONT)),TRUE);
    ShowWindow(window,SW_SHOW); SetForegroundWindow(window); SetFocus(edit); SendMessageW(edit,EM_SETSEL,3,48);
    MSG message{}; while (GetMessageW(&message,nullptr,0,0)>0) { TranslateMessage(&message); DispatchMessageW(&message); }
    return 0;
}
