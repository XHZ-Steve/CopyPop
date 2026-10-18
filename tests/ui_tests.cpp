#include "App.h"
#include <QTest>
#include <QTemporaryDir>
#include <QQmlEngine>
#include <QQmlContext>
#include <QQmlComponent>
#include <QQuickWindow>
#include <QQuickItem>
#include <QQuickStyle>
#include <QProcess>
#include <QSignalSpy>
#include <QApplication>
#include <QRegularExpression>

class UiTests : public QObject {
    Q_OBJECT
    static QQuickItem *findItem(QQuickItem *root,const QString &name) {
        if(root->objectName()==name) return root;
        for(auto *child:root->childItems()) if(auto *result=findItem(child,name)) return result;
        return nullptr;
    }
private slots:
    void initTestCase() { QTest::failOnWarning(QRegularExpression("qrc:.*")); }
    void pagesInteractionsAndOverlay() {
        QTemporaryDir directory; Config config(directory.filePath("config.json")); QQmlEngine engine;
        App app(&config,&engine,true);
        engine.rootContext()->setContextProperty("Config",&config); engine.rootContext()->setContextProperty("App",&app); engine.rootContext()->setContextProperty("TestPage",QVariant(0));
        QQmlComponent component(&engine,QUrl("qrc:/qml/Settings.qml"));
        std::unique_ptr<QObject> object(component.create()); QVERIFY2(object,qPrintable(component.errorString()));
        auto *window=qobject_cast<QQuickWindow *>(object.get()); QVERIFY(window); window->show(); QVERIFY(QTest::qWaitForWindowExposed(window));
        for(int page=0;page<7;++page){ QVERIFY(window->setProperty("page",page)); QTest::qWait(20); }
        window->setProperty("page",0); QTest::qWait(30);
        auto *toggle=findItem(window->contentItem(),"enabled-switch"); QVERIFY(toggle);
        const auto pos=toggle->mapToScene(QPointF(toggle->width()/2,toggle->height()/2)).toPoint();
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,pos); QCOMPARE(config.value("enabled").toBool(),false);
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,pos); QCOMPARE(config.value("enabled").toBool(),true);
        window->setProperty("page",1); QTest::qWait(30);
        auto *preview=findItem(window->contentItem(),"live-preview"); QVERIFY(preview); QVERIFY(QMetaObject::invokeMethod(preview,"play")); QTest::qWait(80);
        for(const QString effect: {"shimmer","pulse","dissolve"}) { QVERIFY(config.set("effect",effect)); QVERIFY(QMetaObject::invokeMethod(preview,"play")); QTest::qWait(60); }
        QVERIFY(config.setRule("C:/Applications/test.exe",{{"effect","pulse"}})); window->setProperty("page",5); QTest::qWait(30);
        QVERIFY(config.set("theme","light")); QTest::qWait(30); QVERIFY(config.set("theme","dark")); QTest::qWait(30);
        // The application creates its own settings window for this native ownership/style test.
        QVERIFY(app.nativeSelfTest());
        QQmlComponent welcome(&engine,QUrl("qrc:/qml/Welcome.qml")); std::unique_ptr<QObject> greeting(welcome.create()); QVERIFY2(greeting,qPrintable(welcome.errorString()));
        auto *welcomeWindow=qobject_cast<QQuickWindow *>(greeting.get()); QVERIFY(welcomeWindow); welcomeWindow->show(); QVERIFY(QTest::qWaitForWindowExposed(welcomeWindow));
        QVERIFY(welcomeWindow->flags()&Qt::FramelessWindowHint);
    }
    void nativeSelectionAndPassword() {
        qRegisterMetaType<SelectionSnapshot>();
        for(bool password: {false,true}) {
            QProcess fixture; fixture.start(QCoreApplication::applicationDirPath()+"/uia_fixture.exe",password?QStringList{"password"}:QStringList{}); QVERIFY(fixture.waitForStarted());
            HWND window=nullptr;
            QTRY_VERIFY_WITH_TIMEOUT((window=FindWindowW(L"CopyPopTestFixture",L"CopyPop UIA test fixture")) != nullptr,2000);
            QTRY_COMPARE_WITH_TIMEOUT(GetForegroundWindow(),window,2000);
            WindowsEvents events; SelectionTracker tracker(events.handle());
            connect(&events,&WindowsEvents::selectionReady,&tracker,&SelectionTracker::receive);
            QSignalSpy results(&tracker,&SelectionTracker::ready);
            QTest::qWait(650); QVERIFY(tracker.request(window,QueryReason::Copy,Win::processPath(window)));
            QTRY_VERIFY_WITH_TIMEOUT(!results.isEmpty(),2000);
            const auto snapshot=qvariant_cast<SelectionSnapshot>(results.last()[0]);
            QCOMPARE(snapshot.window,window);
            if(password){ QVERIFY(snapshot.protectedControl); QVERIFY(snapshot.rectangles.isEmpty()); QVERIFY(snapshot.caret.isEmpty()); }
            else { QVERIFY(!snapshot.protectedControl); QVERIFY(snapshot.selection); QVERIFY(!snapshot.rectangles.isEmpty()); QVERIFY(snapshot.level=="L3" || snapshot.level=="L2"); }
            QVERIFY(!Win::fullscreen(window));
            if(!password) {
                MONITORINFO monitor{}; monitor.cbSize=sizeof(monitor); QVERIFY(GetMonitorInfoW(MonitorFromWindow(window,MONITOR_DEFAULTTONEAREST),&monitor));
                const auto style=GetWindowLongPtrW(window,GWL_STYLE); SetWindowLongPtrW(window,GWL_STYLE,WS_POPUP|WS_VISIBLE);
                SetWindowPos(window,nullptr,monitor.rcMonitor.left,monitor.rcMonitor.top,monitor.rcMonitor.right-monitor.rcMonitor.left,monitor.rcMonitor.bottom-monitor.rcMonitor.top,SWP_NOZORDER|SWP_FRAMECHANGED);
                QTest::qWait(80); QVERIFY(Win::fullscreen(window));
                SetWindowLongPtrW(window,GWL_STYLE,style); SetWindowPos(window,nullptr,100,100,640,300,SWP_NOZORDER|SWP_FRAMECHANGED);
            }
            PostMessageW(window,WM_CLOSE,0,0); QVERIFY(fixture.waitForFinished(2000));
        }
    }
};
int main(int argc,char **argv) {
    QApplication application(argc,argv); application.setQuitOnLastWindowClosed(false); QQuickStyle::setStyle("Basic");
    UiTests tests; return QTest::qExec(&tests,argc,argv);
}
#include "ui_tests.moc"
