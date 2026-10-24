// Application-level information and small helpers for QML.
#pragma once

#include <QObject>
#include <QString>
#include <QUrl>

class AppInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString qtVersion READ qtVersion CONSTANT)
    Q_PROPERTY(QString dataDir READ dataDir CONSTANT)
    Q_PROPERTY(bool portable READ portable CONSTANT)
    Q_PROPERTY(QString systemFontFamily READ systemFontFamily CONSTANT)

public:
    AppInfo(const QString &dataDir, bool portable, QObject *parent = nullptr);

    QString version() const;
    QString qtVersion() const;
    QString dataDir() const { return m_dataDir; }
    bool portable() const { return m_portable; }
    // Platform UI font (Segoe UI on Windows), as used by the Evalbox web page in a browser.
    QString systemFontFamily() const;

    Q_INVOKABLE QString formatDuration(int seconds) const;  // "14:05" or "1:02:03"
    Q_INVOKABLE void openDataFolder() const;
    Q_INVOKABLE bool openUrl(const QString &url) const;

private:
    QString m_dataDir;
    bool m_portable;
};
