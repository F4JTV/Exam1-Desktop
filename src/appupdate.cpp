#include "appupdate.h"

#include "appsettings.h"

#include <QCoreApplication>
#include <QJsonDocument>
#include <QLocale>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSysInfo>
#include <QTimer>
#include <QVersionNumber>

#include <functional>

#ifndef EXAM1_RELEASES_REPO
#define EXAM1_RELEASES_REPO "F4JTV/Exam1-Desktop"
#endif

namespace {

QVersionNumber parseVersion(QString v)
{
    v = v.trimmed();
    if (v.startsWith(QLatin1Char('v')) || v.startsWith(QLatin1Char('V')))
        v.remove(0, 1);
    return QVersionNumber::fromString(v);
}

} // namespace

AppUpdate::AppUpdate(AppSettings *settings, bool portable, QObject *parent)
    : QObject(parent)
    , m_settings(settings)
    , m_portable(portable)
{
}

QString AppUpdate::currentVersion() const
{
    return QCoreApplication::applicationVersion();
}

QString AppUpdate::lastCheckLabel() const
{
    if (!m_lastCheck.isValid())
        return QString();
    return QLocale(QLocale::French, QLocale::France).toString(m_lastCheck, QStringLiteral("d MMMM yyyy 'à' HH:mm"));
}

int AppUpdate::compareVersions(const QString &a, const QString &b)
{
    const QVersionNumber va = parseVersion(a), vb = parseVersion(b);
    if (va.isNull() || vb.isNull())
        return va.isNull() == vb.isNull() ? 0 : (va.isNull() ? -1 : 1);
    return QVersionNumber::compare(va, vb) < 0 ? -1 : (QVersionNumber::compare(va, vb) > 0 ? 1 : 0);
}

QString AppUpdate::platform()
{
#if defined(Q_OS_ANDROID)
    return QStringLiteral("android");
#elif defined(Q_OS_WIN)
    return QStringLiteral("windows");
#elif defined(Q_OS_MACOS)
    return QStringLiteral("macos");
#else
    return QStringLiteral("linux");
#endif
}

QString AppUpdate::linuxDistro()
{
    // Same name as the packages: ID and VERSION_ID of /etc/os-release, e.g. "ubuntu24.04", "debian12".
    return QSysInfo::productType() + QSysInfo::productVersion();
}

bool AppUpdate::runningAppImage()
{
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    return !qEnvironmentVariable("APPIMAGE").isEmpty();
#else
    return false;
#endif
}

QJsonObject AppUpdate::pickAsset(const QJsonArray &assets, const QString &platform, bool portable, const QString &distro,
                                 bool appImage)
{
    const auto find = [&assets](const std::function<bool(const QString &)> &match) {
        for (const QJsonValue &v : assets) {
            const QJsonObject a = v.toObject();
            if (match(a.value(QStringLiteral("name")).toString()))
                return a;
        }
        return QJsonObject();
    };
    const auto isAppImage = [](const QString &name) { return name.endsWith(QLatin1String(".AppImage"), Qt::CaseInsensitive); };
    if (platform == QLatin1String("android"))
        return find([](const QString &name) { return name.endsWith(QLatin1String(".apk"), Qt::CaseInsensitive); });
    if (platform == QLatin1String("windows"))
        return find([portable](const QString &name) {
            return portable ? name.endsWith(QLatin1String("_Windows_portable.zip"), Qt::CaseInsensitive)
                            : name.endsWith(QLatin1String("-setup.exe"), Qt::CaseInsensitive);
        });
    if (platform == QLatin1String("macos"))
        return find([](const QString &name) { return name.endsWith(QLatin1String(".dmg"), Qt::CaseInsensitive); });
    if (appImage)
        return find(isAppImage);
    const QJsonObject deb = find([&distro](const QString &name) {
        return name.endsWith(QLatin1String(".deb"), Qt::CaseInsensitive)
               && name.contains(QLatin1Char('_') + distro + QLatin1Char('_'), Qt::CaseInsensitive);
    });
    return deb.isEmpty() ? find(isAppImage) : deb;
}

void AppUpdate::autoStart()
{
    if (m_settings->autoCheckApp())
        QTimer::singleShot(4000, this, [this] { check(true); });
}

void AppUpdate::check(bool silent)
{
    if (checking())
        return;
    // EXAM1_RELEASES_URL: another address answering like the GitHub API (tests).
    QString url = qEnvironmentVariable("EXAM1_RELEASES_URL");
    if (url.isEmpty())
        url = QStringLiteral("https://api.github.com/repos/%1/releases/latest").arg(QLatin1String(EXAM1_RELEASES_REPO));
    QNetworkRequest req{QUrl(url)};
    // GitHub refuses requests without a User-Agent.
    req.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("Exam1-Qt/%1").arg(currentVersion()));
    req.setRawHeader("Accept", "application/vnd.github+json");
    req.setTransferTimeout(20000);
    m_error.clear();
    m_reply = m_nam.get(req);
    QNetworkReply *reply = m_reply;
    connect(reply, &QNetworkReply::finished, this, [this, reply, silent] { finished(reply, silent); });
    emit changed();
}

void AppUpdate::finished(QNetworkReply *reply, bool silent)
{
    reply->deleteLater();
    const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    const QByteArray body = reply->readAll();
    const QNetworkReply::NetworkError netError = reply->error();
    m_reply.clear();
    m_lastCheck = QDateTime::currentDateTime();

    if (status == 404) {
        // No release published yet: nothing newer.
        m_checked = true;
        m_available = false;
        m_latest.clear();
        emit changed();
        return;
    }
    const QJsonObject release = QJsonDocument::fromJson(body).object();
    const QString tag = release.value(QStringLiteral("tag_name")).toString();
    if (netError != QNetworkReply::NoError || tag.isEmpty()) {
        if (!silent)
            m_error = status == 403 ? QStringLiteral("GitHub refuse momentanément la demande : réessayez plus tard.")
                                    : QStringLiteral("Vérification impossible : %1").arg(reply->errorString());
        emit changed();
        return;
    }

    m_checked = true;
    m_latest = tag.startsWith(QLatin1Char('v')) ? tag.mid(1) : tag;
    m_releaseUrl = release.value(QStringLiteral("html_url")).toString();
    const QJsonObject asset = pickAsset(release.value(QStringLiteral("assets")).toArray(), platform(), m_portable, linuxDistro(),
                                       runningAppImage());
    m_downloadUrl = asset.value(QStringLiteral("browser_download_url")).toString();
    m_downloadName = asset.value(QStringLiteral("name")).toString();
    // A development build ("dev") is never told to update.
    m_available = !parseVersion(currentVersion()).isNull() && compareVersions(m_latest, currentVersion()) > 0;
    emit changed();
}
