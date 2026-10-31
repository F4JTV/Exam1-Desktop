// New versions of the application itself, published as releases of the GitHub repository
// (EXAM1_RELEASES_REPO in CMakeLists.txt). Separate from the question bank updates (Updater).
#pragma once

#include <QDateTime>
#include <QJsonArray>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QObject>
#include <QPointer>
#include <QString>

class AppSettings;
class QNetworkReply;

class AppUpdate : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool checking READ checking NOTIFY changed)
    Q_PROPERTY(bool checked READ checked NOTIFY changed)            // a check has been answered
    Q_PROPERTY(bool available READ available NOTIFY changed)        // a newer version is published
    Q_PROPERTY(QString currentVersion READ currentVersion CONSTANT)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY changed)
    Q_PROPERTY(QString releaseUrl READ releaseUrl NOTIFY changed)    // release page (what is new)
    Q_PROPERTY(QString downloadUrl READ downloadUrl NOTIFY changed)  // package for this system, or the release page
    Q_PROPERTY(QString downloadName READ downloadName NOTIFY changed) // its file name, empty for the release page
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(QString lastCheckLabel READ lastCheckLabel NOTIFY changed)
    Q_PROPERTY(bool appImage READ appImage CONSTANT)                 // running from an AppImage (Linux)

public:
    AppUpdate(AppSettings *settings, bool portable, QObject *parent = nullptr);

    bool checking() const { return !m_reply.isNull(); }
    bool checked() const { return m_checked; }
    bool available() const { return m_available; }
    QString currentVersion() const;
    QString latestVersion() const { return m_latest; }
    QString releaseUrl() const { return m_releaseUrl; }
    QString downloadUrl() const { return m_downloadUrl.isEmpty() ? m_releaseUrl : m_downloadUrl; }
    QString downloadName() const { return m_downloadName; }
    QString error() const { return m_error; }
    QString lastCheckLabel() const;
    bool appImage() const { return runningAppImage(); }

    // Asks GitHub for the latest published release. Silent: no error shown (start-up check).
    Q_INVOKABLE void check(bool silent = false);
    // Start-up check, a few seconds after launch, if enabled in the settings.
    void autoStart();

    // -1, 0 or 1, comparing "4.0.10" and "v4.0.2"; an unreadable version is older than any other.
    static int compareVersions(const QString &a, const QString &b);
    // The package of this system among the release assets: installer or portable zip on Windows,
    // disk image on macOS, APK on Android. On Linux: the AppImage when running from one, otherwise
    // the .deb of the distribution (e.g. "ubuntu24.04"), or the AppImage when it has none.
    static QJsonObject pickAsset(const QJsonArray &assets, const QString &platform, bool portable, const QString &distro,
                                 bool appImage = false);
    static QString platform();
    static QString linuxDistro();
    static bool runningAppImage();   // the AppImage runtime sets APPIMAGE to the file's path

signals:
    void changed();

private:
    void finished(QNetworkReply *reply, bool silent);

    AppSettings *m_settings;
    bool m_portable;
    QNetworkAccessManager m_nam;
    QPointer<QNetworkReply> m_reply;
    bool m_checked = false;
    bool m_available = false;
    QString m_latest;
    QString m_releaseUrl;
    QString m_downloadUrl;
    QString m_downloadName;
    QString m_error;
    QDateTime m_lastCheck;
};
