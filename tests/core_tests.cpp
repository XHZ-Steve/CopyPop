#include "core/Config.h"
#include "platform/Windows.h"
#include <QTest>
#include <QTemporaryDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>

class CoreTests : public QObject {
    Q_OBJECT
private slots:
    void roundtripAndRules() {
        QTemporaryDir d; QVERIFY(d.isValid()); Config c(d.filePath("config.json"));
        QVERIFY(c.value("guardFullscreen").toBool()); QVERIFY(!c.value("predictScroll").toBool());
        QVERIFY(c.set("duration",950)); QVERIFY(!c.set("duration",-1));
        QVERIFY(!c.set("enabled","yes")); QVERIFY(!c.set("effect","unknown"));
        QVERIFY(c.setRule("C:\\Apps\\Editor.exe",{{"effect","pulse"},{"excluded",true}}));
        const auto e = c.effective("c:/apps/EDITOR.exe"); QCOMPARE(e["effect"].toString(),"pulse"); QVERIFY(e["excluded"].toBool()); QCOMPARE(e["duration"].toInt(),950);
        QCOMPARE(c.effective("c:/other/editor.exe")["effect"].toString(),"shimmer");
        QVERIFY(!c.setRule("editor.exe",{})); QVERIFY(!c.setRule("c:/a.exe",{{"guardFullscreen",false}}));
        Config reload(d.filePath("config.json")); QCOMPARE(reload.value("duration").toInt(),950); QCOMPARE(reload.applications().size(),1);
        QVERIFY(reload.exportFile(d.filePath("export.json"))); QVERIFY(reload.reset()); QVERIFY(reload.applications().isEmpty());
        QVERIFY(reload.importFile(d.filePath("export.json"))); QCOMPARE(reload.applications().size(),1);
    }
    void malformedAndFutureVersions() {
        QTemporaryDir d; Config c(d.filePath("config.json"));
        QFile f(d.filePath("bad.json")); QVERIFY(f.open(QIODevice::WriteOnly)); f.write("{invalid"); f.close();
        QVERIFY(!c.importFile(f.fileName())); QVERIFY(c.value("enabled").toBool());
        QVERIFY(f.open(QIODevice::WriteOnly|QIODevice::Truncate)); f.write("{\"schemaVersion\":99,\"global\":{},\"applications\":[]}"); f.close(); QVERIFY(!c.importFile(f.fileName()));
        QJsonObject legacy{{"global",QJsonObject{{"duration",800}}},{"applications",QJsonArray{}}}; QString err;
        QVERIFY(Config::validate(legacy,err)); QCOMPARE(legacy["schemaVersion"].toInt(),1);
    }
    void pathsAndGames() {
        const QVariantList games{QVariantMap{{"suffix","/steamapps/common/example/bin/game.exe"}}};
        QVERIFY(Win::knownGame("D:/Steam/steamapps/common/example/bin/game.exe",games));
        QVERIFY(!Win::knownGame("C:/Work/game.exe",games));
        QCOMPARE(Config::normalizePath("C:\\Apps\\A.exe"),"c:/apps/a.exe");
    }
    void clipboardTypesAndPriority() {
        const QString url="https://example.org/test";
        QCOMPARE(Win::classifyFormats(false,false,true,url),"url");
        QCOMPARE(Win::classifyFormats(false,false,true,QStringLiteral("ordinary text")),"text");
        QCOMPARE(Win::classifyFormats(false,true,true,url),"image");
        QCOMPARE(Win::classifyFormats(true,true,true,url),"files");
        QCOMPARE(Win::classifyFormats(false,false,false),"other");
        QCOMPARE(Win::classifyFormats(false,false,true,url,false),"text");
        QCOMPARE(Win::classifyFormats(false,false,true,QStringLiteral("https://example.org\nextra")),"text");
    }
};
QTEST_MAIN(CoreTests)
#include "core_tests.moc"
