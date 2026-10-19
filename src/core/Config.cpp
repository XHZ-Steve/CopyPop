#include "Config.h"
#include <QColor>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSaveFile>
#include <QSet>
#include <cmath>

QVariantMap Config::defaults() {
    return {{"enabled",true},{"firstRun",true},{"startup",true},{"theme","system"},{"language","zh-CN"},{"closeToTray",true},
        {"effect","shimmer"},{"preset","ocean"},{"color","#5989e8"},{"opacity",0.65},{"speed",1.0},{"duration",700},{"intensity",0.6},{"curve","outCubic"},{"adaptive",true},{"effectsEnabled",true},{"respectReducedMotion",true},
        {"effectRadius",4},{"effectBorder",0.7},{"shimmerWidth",40},{"shimmerAngle",-10},{"pulseCycles",2},{"dissolveDensity",12},{"dissolveTravel",32},{"effectDebugBounds",false},
        {"durationMode","fixed"},{"adaptiveBaseTime",600},{"adaptiveTimeScale",1.0},
        {"caretEnabled",true},{"caretTypes","text,url,image,files,other"},{"caretSize",22},{"caretOffsetX",12},{"caretOffsetY",18},{"caretDuration",1500},{"caretFade",180},{"caretOpacity",0.85},
        {"fallbackEnabled",true},{"fallbackText","Copied"},{"fallbackTextColor","#f4f7ff"},{"fallbackBackgroundColor","#25334a"},{"fallbackFont","Segoe UI Variable Text"},{"fallbackFontSize",14},{"fallbackBold",false},{"fallbackOpacity",0.95},{"fallbackDuration",900},{"fallbackOffsetX",16},{"fallbackOffsetY",20},{"fallbackRadius",9},
        {"fallbackFadeIn",140},{"fallbackFadeOut",200},{"fallbackFadeCurve","inOutSine"},{"fallbackLift",4},{"fallbackFollowStiffness",700},{"fallbackFollowDamping",1.0},
        {"hybridTracking",true},{"scrollFollow",true},{"predictScroll",false},{"dragFollow",true},{"dynamicZ",true},{"clipRegion",true},
        {"guardFullscreen",true},{"guardGames",true},{"guardPresentation",true},{"diagnostics",false}};
}
QString Config::normalizePath(QString path) { return QDir::cleanPath(QDir::fromNativeSeparators(path.trimmed())).toLower(); }

static bool validValue(const QString &key, const QVariant &value) {
    const auto defs = Config::defaults();
    if (!defs.contains(key)) return false;
    const auto type = defs.value(key).metaType().id();
    if (type == QMetaType::Bool) return value.metaType().id() == QMetaType::Bool;
    static const QMap<QString,QStringList> choices = {
        {"effect",{"shimmer","pulse","dissolve"}}, {"theme",{"system","light","dark"}},
        {"durationMode",{"fixed","adaptive"}},
        {"preset",{"ocean","mint","rose","custom"}}, {"curve",{"linear","outCubic","inOutSine"}}, {"fallbackFadeCurve",{"linear","outCubic","inOutSine"}}, {"language",{"zh-CN","en"}}};
    if (choices.contains(key)) return choices[key].contains(value.toString());
    if (key == "color" || key.endsWith("Color")) return value.metaType().id()==QMetaType::QString && QColor::isValidColorName(value.toString()) && value.toString().size() <= 16;
    if(key=="fallbackText" || key=="fallbackFont") {
        if(value.metaType().id()!=QMetaType::QString) return false;
        const auto text=value.toString();
        return !text.trimmed().isEmpty() && text.size()<=(key=="fallbackText"?80:128) && !text.contains('\n') && !text.contains('\r') && !text.contains(QChar::Null);
    }
    if (key == "caretTypes") {
        if (value.toString().isEmpty()) return true;
        for (const auto &s : value.toString().split(',')) if (!QStringList{"text","url","image","files","other"}.contains(s)) return false;
        return value.toString().size() <= 32;
    }
    static const QMap<QString,QPair<double,double>> bounds = {
        {"opacity",{0.05,1}},{"speed",{0.25,3}},{"duration",{150,2500}},{"intensity",{0.1,1}},
        {"adaptiveBaseTime",{100,2000}},{"adaptiveTimeScale",{0.25,3}},
        {"effectRadius",{0,16}},{"effectBorder",{0,4}},{"shimmerWidth",{10,100}},{"shimmerAngle",{-45,45}},{"pulseCycles",{1,6}},{"dissolveDensity",{4,40}},{"dissolveTravel",{0,100}},
        {"caretSize",{14,48}},{"caretOffsetX",{-80,80}},{"caretOffsetY",{-80,80}},{"caretDuration",{300,4000}},{"caretFade",{50,600}},{"caretOpacity",{0.1,1}},
        {"fallbackFontSize",{10,36}},{"fallbackOpacity",{0.1,1}},{"fallbackDuration",{300,4000}},{"fallbackOffsetX",{-120,120}},{"fallbackOffsetY",{-120,120}},{"fallbackRadius",{0,20}},
        {"fallbackFadeIn",{0,800}},{"fallbackFadeOut",{0,800}},{"fallbackLift",{0,16}},{"fallbackFollowStiffness",{80,2000}},{"fallbackFollowDamping",{0.4,2}}};
    if (bounds.contains(key)) {
        bool ok = false; const double v = value.toDouble(&ok); const auto b = bounds[key];
        return ok && std::isfinite(v) && v >= b.first && v <= b.second;
    }
    return type == QMetaType::QString && value.toString().size() <= 200;
}
bool Config::validate(QJsonObject &root, QString &error) {
    if (!root.contains("schemaVersion")) root["schemaVersion"] = 1;
    if (root["schemaVersion"].toInt() != 1) { error = "不支持此配置版本。"; return false; }
    if (!root["global"].isObject() || !root["applications"].isArray()) { error = "配置需要 global 对象和 applications 数组。"; return false; }
    const auto global = root["global"].toObject();
    for (auto i = global.begin(); i != global.end(); ++i) {
        if (!validValue(i.key(), i.value().toVariant())) { error = "无效设置：" + i.key(); return false; }
    }
    if (root["applications"].toArray().size() > 256) { error = "应用规则过多（最多 256 条）。"; return false; }
    QSet<QString> paths;
    for (const auto &item : root["applications"].toArray()) {
        const auto app = item.toObject(); const auto path = Config::normalizePath(app["path"].toString());
        if (path.size() > 1024 || !QDir::isAbsolutePath(path) || !path.endsWith(".exe") || paths.contains(path) || !app["overrides"].isObject()) { error = "应用规则需要唯一的可执行文件绝对路径。"; return false; }
        paths.insert(path);
        const auto overrides = app["overrides"].toObject();
        for (auto i = overrides.begin(); i != overrides.end(); ++i) {
            if (i.key() == "excluded") { if (i.value().isBool()) continue; }
            static const QSet<QString> allowed = {"enabled","effectsEnabled","effect","color","duration","durationMode","adaptiveBaseTime","adaptiveTimeScale","intensity","opacity","speed","adaptive","caretEnabled","fallbackEnabled","scrollFollow","dragFollow","hybridTracking"};
            if (!allowed.contains(i.key()) || !validValue(i.key(),i.value().toVariant())) { error = "无效应用覆盖：" + i.key(); return false; }
        }
    }
    return true;
}
Config::Config(QString file, QObject *parent) : QObject(parent), m_file(std::move(file)), m_values(defaults()) {
    QFile f(m_file);
    if (f.exists()) {
        if (!f.open(QIODevice::ReadOnly) || f.size() > 1024*1024 || !load(f.readAll())) {
            if (m_error.isEmpty()) fail("无法读取配置，将使用默认设置。原文件已保留。" );
            // Keep the original for recovery before a later settings write.
            QFile::copy(m_file, m_file + ".invalid-backup");
        }
    }
}
QJsonObject Config::json() const { return {{"schemaVersion",1},{"global",QJsonObject::fromVariantMap(m_values)},{"applications",QJsonArray::fromVariantList(m_apps)},{"conditions",QJsonArray{}}}; }
bool Config::fail(const QString &message) { m_error = message; emit errorChanged(); return false; }
void Config::clearError() { m_error.clear(); emit errorChanged(); }
bool Config::load(const QByteArray &data) {
    QJsonParseError e; const auto doc = QJsonDocument::fromJson(data,&e); auto obj = doc.object(); QString error;
    if (e.error != QJsonParseError::NoError || !doc.isObject()) return fail("JSON 配置无效。" );
    if (!validate(obj,error)) return fail(error);
    auto merged = defaults(); const auto global = obj["global"].toObject().toVariantMap();
    for (auto i = global.begin(); i != global.end(); ++i) merged[i.key()] = i.value();
    m_values = merged; m_apps = obj["applications"].toArray().toVariantList();
    for (auto &a : m_apps) { auto m = a.toMap(); m["path"] = normalizePath(m["path"].toString()); a = m; }
    clearError(); emit changed(); return true;
}
bool Config::save() {
    if (!QDir().mkpath(QFileInfo(m_file).absolutePath())) return fail("无法创建配置目录。" );
    QSaveFile f(m_file); if (!f.open(QIODevice::WriteOnly)) return fail("无法写入配置。" );
    if (f.write(QJsonDocument(json()).toJson()) < 0 || !f.commit()) return fail("保存配置失败。" );
    clearError(); return true;
}
bool Config::set(const QString &key, const QVariant &value) {
    if (!validValue(key,value)) return fail("设置值无效：" + key);
    const auto previous = m_values; m_values[key] = value;
    if (!save()) { m_values = previous; emit changed(); return false; }
    emit changed(); return true;
}
QVariantMap Config::effective(const QString &path) const {
    auto result = m_values;
    for (const auto &a : m_apps) {
        const auto app = a.toMap(); if (normalizePath(app["path"].toString()) != normalizePath(path)) continue;
        const auto overrides = app["overrides"].toMap();
        for (auto i = overrides.begin(); i != overrides.end(); ++i) result[i.key()] = i.value();
    }
    return result;
}
bool Config::setRule(const QString &path, const QVariantMap &overrides) {
    auto apps = m_apps; const auto clean = normalizePath(path); bool replaced = false;
    for (auto &a : apps) { if (a.toMap()["path"].toString() == clean) { a = QVariantMap{{"path",clean},{"overrides",overrides}}; replaced = true; break; } }
    if (!replaced) apps.append(QVariantMap{{"path",clean},{"overrides",overrides}});
    auto obj = json(); obj["applications"] = QJsonArray::fromVariantList(apps); QString err;
    if (!validate(obj,err)) return fail(err);
    const auto previous = m_apps; m_apps = apps;
    if (!save()) { m_apps = previous; return false; } emit changed(); return true;
}
void Config::removeRule(int index) {
    if (index < 0 || index >= m_apps.size()) return;
    const auto previous = m_apps; m_apps.removeAt(index);
    if (!save()) m_apps = previous;
    emit changed();
}
bool Config::reset() {
    const auto old = m_values; const auto apps = m_apps;
    m_values = defaults(); m_values["firstRun"] = false; m_apps.clear();
    if (!save()) { m_values = old; m_apps = apps; return false; } emit changed(); return true;
}
bool Config::importFile(const QString &file) {
    QFile f(file); if (!f.open(QIODevice::ReadOnly) || f.size() > 1024*1024) return fail("无法读取配置或文件超过 1 MB。" );
    const auto old = m_values; const auto apps = m_apps;
    if (!load(f.readAll())) return false;
    if (!save()) { m_values = old; m_apps = apps; emit changed(); return false; } return true;
}
bool Config::exportFile(const QString &file) {
    QSaveFile f(file); if (!f.open(QIODevice::WriteOnly) || f.write(QJsonDocument(json()).toJson()) < 0 || !f.commit()) return fail("导出失败。" );
    clearError(); return true;
}
