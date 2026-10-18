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
#include <QFont>
#include <QDateTime>

class UiTests : public QObject {
    Q_OBJECT
    static QQuickItem *findItem(QQuickItem *root,const QString &name) {
        if(root->objectName()==name) return root;
        for(auto *child:root->childItems()) if(auto *result=findItem(child,name)) return result;
        return nullptr;
    }
private slots:
    void initTestCase() { QTest::failOnWarning(QRegularExpression("qrc:.*")); }
    void pickersNavigationAndFallback() {
        QTemporaryDir directory; Config config(directory.filePath("config.json")); QQmlEngine engine; App app(&config,&engine,true);
        engine.rootContext()->setContextProperty("Config",&config); engine.rootContext()->setContextProperty("App",&app); engine.rootContext()->setContextProperty("TestPage",QVariant(0));
        QQmlComponent component(&engine,QUrl("qrc:/qml/Settings.qml")); std::unique_ptr<QObject> object(component.create());
        QVERIFY2(object,qPrintable(component.errorString())); auto *window=qobject_cast<QQuickWindow *>(object.get()); QVERIFY(window);
        window->show(); QVERIFY(QTest::qWaitForWindowExposed(window)); window->requestActivate(); QTest::qWait(80);
        auto *navigation=findItem(window->contentItem(),"sidebar-navigation"); QVERIFY(navigation);
        auto *hover=findItem(navigation,"sidebar-hover-fill"); auto *selected=findItem(navigation,"sidebar-selection-fill"); QVERIFY(hover && selected);
        auto point=[](QQuickItem *item){return item->mapToScene(QPointF(item->width()/2,item->height()/2)).toPoint();};
        QTest::mouseMove(window,point(findItem(navigation,"sidebar-item-0"))); QTest::qWait(250);
        QTest::mouseMove(window,point(findItem(navigation,"sidebar-item-7"))); QTest::qWait(60);
        if(!app.reducedMotion()) QVERIFY(hover->y()>0 && hover->y()<7*46);
        QCOMPARE(window->property("page").toInt(),0);
        QTest::mouseMove(window,point(findItem(navigation,"sidebar-item-4")));
        QTest::mouseMove(window,point(findItem(navigation,"sidebar-item-2"))); QTest::qWait(260); QCOMPARE(qRound(hover->y()),2*46);
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,point(findItem(navigation,"sidebar-item-2"))); QTest::qWait(55);
        if(!app.reducedMotion()) QVERIFY(selected->y()>0 && selected->y()<2*46);
        QTest::qWait(260); QCOMPARE(qRound(selected->y()),2*46); QCOMPARE(window->property("page").toInt(),2);
        auto *preview=findItem(window->contentItem(),"fallback-preview"); QVERIFY(preview);
        QVERIFY(config.set("fallbackText",QStringLiteral("已复制 <test>")));
        auto *caption=findItem(preview,"copy-toast-text"); QVERIFY(caption); QCOMPARE(caption->property("text").toString(),QStringLiteral("已复制 <test>"));
        QVERIFY(config.set("fallbackTextColor","#faab55")); QCOMPARE(caption->property("color").value<QColor>(),QColor("#faab55"));
        QVERIFY(config.set("fallbackDuration",300)); QVERIFY(QMetaObject::invokeMethod(preview,"play")); QVERIFY(preview->property("running").toBool());
        QTest::qWait(360); QVERIFY(!preview->property("running").toBool()); QVERIFY(preview->isVisible());
        auto *fallbackToggle=findItem(window->contentItem(),"fallbackEnabled-switch"); QVERIFY(fallbackToggle);
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,point(fallbackToggle)); QVERIFY(!config.value("fallbackEnabled").toBool());
        window->setProperty("page",1); QTest::qWait(80);
        auto *scroll=findItem(window->contentItem(),"settings-scroll"); QVERIFY(scroll);
        auto *flick=qvariant_cast<QQuickItem *>(scroll->property("contentItem")); QVERIFY(flick); flick->setProperty("contentY",270); QTest::qWait(40);
        auto *picker=findItem(window->contentItem(),"color-picker"); QVERIFY(picker);
        auto *row=findItem(window->contentItem(),"color-row"); QVERIFY(row);
        auto *dialog=row->findChild<QObject *>("color-color-dialog"); QVERIFY(dialog);
        const auto before=config.value("color").toString();
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,point(picker)); QTest::qWait(120); QVERIFY(dialog->property("visible").toBool());
        QVERIFY(dialog->setProperty("selectedColor",QColor("#dd6677"))); QVERIFY(QMetaObject::invokeMethod(dialog,"rejected")); QVERIFY(QMetaObject::invokeMethod(dialog,"close"));
        QCOMPARE(config.value("color").toString(),before);
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,point(picker)); QTest::qWait(100);
        QVERIFY(dialog->setProperty("selectedColor",QColor("#883377aa"))); QVERIFY(QMetaObject::invokeMethod(dialog,"accepted")); QVERIFY(QMetaObject::invokeMethod(dialog,"close"));
        QCOMPARE(QColor(config.value("color").toString()),QColor("#883377aa")); QCOMPARE(config.value("preset").toString(),"custom");
        flick->setProperty("contentY",0); QTest::qWait(40);
        auto *combo=findItem(window->contentItem(),"effect-combo"); QVERIFY(combo);
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,point(combo)); QTest::keyClick(window,Qt::Key_Down); QTest::keyClick(window,Qt::Key_Return); QTest::qWait(40);
        QCOMPARE(config.value("effect").toString(),"pulse");
        flick->setProperty("contentY",420); QTest::qWait(40);
        auto *slider=findItem(window->contentItem(),"speed-slider"); QVERIFY(slider); const auto speed=config.value("speed").toDouble();
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,slider->mapToScene(QPointF(slider->width()*0.8,slider->height()/2)).toPoint());
        QVERIFY(config.value("speed").toDouble()!=speed);
        window->setProperty("page",2); flick->setProperty("contentY",450); QTest::qWait(60);
        auto *fontPicker=findItem(window->contentItem(),"fallbackFont-font-picker"); QVERIFY(fontPicker);
        const auto oldFont=config.value("fallbackFont").toString();
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,point(fontPicker)); QTest::keyClick(window,Qt::Key_Home); QTest::keyClick(window,Qt::Key_Return); QTest::qWait(40);
        QCOMPARE(config.value("fallbackFont").toString(),fontPicker->property("currentText").toString()); QVERIFY(config.value("fallbackFont").toString()!=oldFont);
        window->setProperty("page",3); flick->setProperty("contentY",450); QTest::qWait(60);
        auto *types=findItem(window->contentItem(),"caret-types"); QVERIFY(types);
        auto *check=findItem(types,"caret-type-text"); QVERIFY(check); const bool hadText=config.value("caretTypes").toString().split(',').contains("text");
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,point(check)); QCOMPARE(config.value("caretTypes").toString().split(',').contains("text"),!hadText);
        // Exercise the actual controller routes with synthetic geometry, without modifying the user's clipboard.
        window->requestActivate(); QVERIFY(QTest::qWaitForWindowActive(window));
        QTest::mouseMove(window,QPoint(420,160)); app.refresh(); app.m_tracker.invalidate(); app.m_snapshotDebounce.stop();
        QVERIFY(config.set("fallbackEnabled",true));
        SelectionSnapshot s; s.window=reinterpret_cast<HWND>(window->winId()); s.protectedControl=false; s.selection=true; s.level="L2"; s.rectangles={QRectF(Win::clientRect(s.window).adjusted(80,80,-80,-80))};
        auto pending=[&]{app.m_copyPending=true; app.m_copyHint=true; app.m_copyAt=QDateTime::currentMSecsSinceEpoch();};
        pending(); app.selection(s); QVERIFY(app.m_fallback); QVERIFY(app.m_renderer.visible());
        pending(); s.level="L3"; app.selection(s); QVERIFY(!app.m_fallback); QVERIFY(app.m_renderer.visible());
        app.cancel(); pending(); app.copyFallback(); QVERIFY(app.m_fallback);
        QVERIFY(config.set("fallbackEnabled",false)); pending(); s.level="L2"; app.selection(s); QVERIFY(!app.m_renderer.visible());
        QVERIFY(config.set("fallbackEnabled",true)); pending(); s.protectedControl=true; app.selection(s); QVERIFY(!app.m_renderer.visible());
        app.pause(); pending(); app.copyFallback(); QVERIFY(!app.m_renderer.visible());
    }
    void pagesInteractionsAndOverlay() {
        QTemporaryDir directory; Config config(directory.filePath("config.json")); QQmlEngine engine;
        App app(&config,&engine,true);
        engine.rootContext()->setContextProperty("Config",&config); engine.rootContext()->setContextProperty("App",&app); engine.rootContext()->setContextProperty("TestPage",QVariant(0));
        QQmlComponent component(&engine,QUrl("qrc:/qml/Settings.qml"));
        std::unique_ptr<QObject> object(component.create()); QVERIFY2(object,qPrintable(component.errorString()));
        auto *window=qobject_cast<QQuickWindow *>(object.get()); QVERIFY(window); window->show(); QVERIFY(QTest::qWaitForWindowExposed(window));
        for(int page=0;page<8;++page){ QVERIFY(window->setProperty("page",page)); QTest::qWait(20); }
        window->setProperty("page",0); QTest::qWait(30);
        auto *toggle=findItem(window->contentItem(),"enabled-switch"); QVERIFY(toggle);
        const auto pos=toggle->mapToScene(QPointF(toggle->width()/2,toggle->height()/2)).toPoint();
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,pos); QCOMPARE(config.value("enabled").toBool(),false);
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,pos); QCOMPARE(config.value("enabled").toBool(),true);
        window->setProperty("page",1); QTest::qWait(30);
        auto *preview=findItem(window->contentItem(),"live-preview"); QVERIFY(preview); QVERIFY(QMetaObject::invokeMethod(preview,"play")); QTest::qWait(80);
        for(const QString effect: {"shimmer","pulse","dissolve"}) { QVERIFY(config.set("effect",effect)); QVERIFY(QMetaObject::invokeMethod(preview,"play")); QTest::qWait(60); }
        QVERIFY(config.setRule("C:/Applications/test.exe",{{"effect","pulse"}})); window->setProperty("page",6); QTest::qWait(30);
        auto *editor=window->findChild<QObject *>("rule-editor"); QVERIFY(editor);
        QVERIFY(QMetaObject::invokeMethod(editor,"edit",Q_ARG(QVariant,QVariant("C:/Applications/test.exe")),Q_ARG(QVariant,QVariant(QVariantMap{{"effect","pulse"}}))));
        QTest::qWait(60); QVERIFY(editor->property("visible").toBool()); QVERIFY(QMetaObject::invokeMethod(editor,"accept"));
        QCOMPARE(config.effective("C:/Applications/test.exe")["effect"].toString(),"pulse");
        QVERIFY(config.set("theme","light")); QTest::qWait(30); QVERIFY(config.set("theme","dark")); QTest::qWait(30);
        // The application creates its own settings window for this native ownership/style test.
        QVERIFY(app.nativeSelfTest());
        {
            OverlayRenderer renderer(&engine);
            const auto owner=reinterpret_cast<HWND>(window->winId()); const auto area=Win::clientRect(owner);
            for(const QString kind:{"text","url","image","files","other","copied"}) {
                renderer.show(owner,{QRectF(area.x()+60,area.y()+60,24,24)},config.values(),kind);
                QTest::qWait(30); QVERIFY(renderer.visible());
            }
            renderer.hide(); QVERIFY(!renderer.visible());
        }
        QVERIFY(config.set("theme","light"));
        QQmlComponent welcome(&engine,QUrl("qrc:/qml/Welcome.qml")); std::unique_ptr<QObject> greeting(welcome.create()); QVERIFY2(greeting,qPrintable(welcome.errorString()));
        auto *welcomeWindow=qobject_cast<QQuickWindow *>(greeting.get()); QVERIFY(welcomeWindow); welcomeWindow->show(); QVERIFY(QTest::qWaitForWindowExposed(welcomeWindow));
        QVERIFY(welcomeWindow->flags()&Qt::FramelessWindowHint);
        auto *start=findItem(welcomeWindow->contentItem(),"welcome-start"); QVERIFY(start);
        auto *label=qvariant_cast<QQuickItem *>(start->property("contentItem")); QVERIFY(label);
        QCOMPARE(label->property("color").value<QColor>(),QColor("#ffffff"));
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
            QTRY_VERIFY_WITH_TIMEOUT(tracker.initialized(),4000);
            QVERIFY(tracker.request(window,QueryReason::Copy,Win::processPath(window)));
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
