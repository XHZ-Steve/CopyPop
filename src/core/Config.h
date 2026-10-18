#pragma once
#include <QObject>
#include <QVariantMap>
#include <QJsonObject>

class Config : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap values READ values NOTIFY changed)
    Q_PROPERTY(QVariantList applications READ applications NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
public:
    explicit Config(QString file, QObject *parent = nullptr);
    static QVariantMap defaults();
    static QString normalizePath(QString path);
    static bool validate(QJsonObject &root, QString &error);
    QVariantMap values() const { return m_values; }
    QVariantList applications() const { return m_apps; }
    QString error() const { return m_error; }
    QVariant value(const QString &key) const { return m_values.value(key); }
    QVariantMap effective(const QString &path) const;
    QString fileName() const { return m_file; }
    Q_INVOKABLE bool set(const QString &key, const QVariant &value);
    Q_INVOKABLE bool setRule(const QString &path, const QVariantMap &overrides);
    Q_INVOKABLE void removeRule(int index);
    Q_INVOKABLE bool reset();
    bool importFile(const QString &file);
    bool exportFile(const QString &file);
    bool save();
    void clearError();
signals:
    void changed();
    void errorChanged();
private:
    bool load(const QByteArray &data);
    bool fail(const QString &message);
    QJsonObject json() const;
    QString m_file, m_error;
    QVariantMap m_values;
    QVariantList m_apps;
};
