#include "App.h"
#include <QApplication>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickStyle>
#include <QStandardPaths>
#include <QLocalServer>
#include <QLocalSocket>
#include <QLockFile>
#include <QCommandLineParser>
#include <QFile>
#include <QDir>
#include <QTextStream>
#include <QFont>
#include <QFontDatabase>
#include <QCryptographicHash>
#include <cstdio>

int main(int argc,char **argv) {
    QApplication application(argc,argv);
    QCoreApplication::setOrganizationName("CopyPop"); QCoreApplication::setApplicationName("CopyPop"); QCoreApplication::setApplicationVersion("1.0.0");
    application.setQuitOnLastWindowClosed(false);
    application.setWindowIcon(QIcon(":/resources/icons/app.svg"));
    QFont font("Segoe UI Variable Text"); font.setFamilies({"Segoe UI Variable Text","Segoe UI","Microsoft YaHei UI"}); font.setPixelSize(14); application.setFont(font); QGuiApplication::setFont(font);
#if QT_VERSION >= QT_VERSION_CHECK(6,8,0)
    QFontDatabase::addApplicationFallbackFontFamily(QChar::Script_Han,"Microsoft YaHei UI");
#endif
    QQuickStyle::setStyle("Basic");
    QCommandLineParser parser; parser.setApplicationDescription("CopyPop clipboard micro-interactions"); parser.addHelpOption(); parser.addVersionOption();
    parser.addOptions({{"background","Start in the notification area"},{"welcome","Open the welcome window"},{"smoke-test","Open settings, verify native overlay and exit"},{"screenshot","Save window screenshot", "file"},{"test-config","Use isolated config (does not modify startup)","file"},{"test-instance","Exercise IPC using an isolated test configuration"},{"test-page","Select settings page in smoke test","number","0"}}); parser.process(application);
    const bool testing = parser.isSet("test-config") || parser.isSet("smoke-test");
    if (testing) qInstallMessageHandler([](QtMsgType,const QMessageLogContext &,const QString &message){ const auto bytes=message.toUtf8(); std::fprintf(stderr,"%s\n",bytes.constData()); std::fflush(stderr); });
    const auto directory = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation); QDir().mkpath(directory);
    const auto configFile = parser.isSet("test-config")?parser.value("test-config"):directory+"/config.json";
    std::unique_ptr<QLockFile> lock;
    QLocalServer server;
    const auto serverName = "CopyPop-V1-" + (testing?QString(QCryptographicHash::hash(configFile.toUtf8(),QCryptographicHash::Sha256).toHex().left(16)):qEnvironmentVariable("USERNAME"));
    if (!testing || parser.isSet("test-instance")) {
        auto wakeExisting=[&] { QLocalSocket socket; socket.connectToServer(serverName); if(!socket.waitForConnected(350)) return false; socket.write("settings"); socket.waitForBytesWritten(350); return true; };
        if (wakeExisting()) return 0;
        lock = std::make_unique<QLockFile>(testing?configFile+".instance.lock":directory+"/instance.lock"); lock->setStaleLockTime(0);
        if (!lock->tryLock(500)) return wakeExisting()?0:1;
        server.setSocketOptions(QLocalServer::UserAccessOption);
        QLocalServer::removeServer(serverName); if (!server.listen(serverName)) return 2;
    }
    Config config(configFile); QQmlEngine engine;
    App app(&config,&engine,testing);
    engine.rootContext()->setContextProperty("App",&app); engine.rootContext()->setContextProperty("Config",&config);
    engine.rootContext()->setContextProperty("TestPage",parser.value("test-page").toInt());
    QObject::connect(&server,&QLocalServer::newConnection,&app,[&]{ while (auto *s = server.nextPendingConnection()) { QObject::connect(s,&QLocalSocket::disconnected,s,&QObject::deleteLater); s->disconnectFromServer(); app.showSettings(); } });
    if (parser.isSet("smoke-test")) {
        if(parser.isSet("welcome")) app.showWelcome(); else app.showSettings();
        QTimer::singleShot(1800,&app,[&]{
            if (parser.isSet("screenshot")) app.captureWindow(parser.value("screenshot"));
            const bool ok = app.nativeSelfTest();
            QFile result(configFile+".smoke-result"); if (result.open(QIODevice::WriteOnly)) result.write(ok?"PASS\n":"FAIL\n");
            application.exit(ok?0:3);
        });
    } else { app.start(parser.isSet("background")); if(parser.isSet("welcome")) app.showWelcome(); if (parser.isSet("screenshot")) QTimer::singleShot(1600,&app,[&]{ app.captureWindow(parser.value("screenshot")); }); }
    return application.exec();
}
