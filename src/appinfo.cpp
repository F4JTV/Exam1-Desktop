#include "appinfo.h"

#include <QCoreApplication>
#include <QDesktopServices>
#include <QFontDatabase>
#include <QUrl>

AppInfo::AppInfo(const QString &dataDir, bool portable, QObject *parent)
    : QObject(parent)
    , m_dataDir(dataDir)
    , m_portable(portable)
{
}

QString AppInfo::version() const
{
    return QCoreApplication::applicationVersion();
}

QString AppInfo::qtVersion() const
{
    return QString::fromLatin1(qVersion());
}

QString AppInfo::systemFontFamily() const
{
    return QFontDatabase::systemFont(QFontDatabase::GeneralFont).family();
}

QString AppInfo::formatDuration(int seconds) const
{
    seconds = qMax(0, seconds);
    const int h = seconds / 3600;
    const int m = (seconds % 3600) / 60;
    const int s = seconds % 60;
    if (h > 0)
        return QStringLiteral("%1:%2:%3").arg(h).arg(m, 2, 10, QLatin1Char('0')).arg(s, 2, 10, QLatin1Char('0'));
    return QStringLiteral("%1:%2").arg(m, 2, 10, QLatin1Char('0')).arg(s, 2, 10, QLatin1Char('0'));
}

void AppInfo::openDataFolder() const
{
    QDesktopServices::openUrl(QUrl::fromLocalFile(m_dataDir));
}

bool AppInfo::openUrl(const QString &url) const
{
    const QUrl u = QUrl::fromUserInput(url.trimmed());
    if (!u.isValid() || (u.scheme() != QLatin1String("http") && u.scheme() != QLatin1String("https")))
        return false;
    return QDesktopServices::openUrl(u);
}
