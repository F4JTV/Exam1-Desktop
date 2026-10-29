#include "appsettings.h"

AppSettings::AppSettings(QObject *parent)
    : QObject(parent)
{
}

QString AppSettings::defaultUpdateBaseUrl()
{
    return QStringLiteral("https://exam1.r-e-f.org/assets/");
}

void AppSettings::put(const QString &key, const QVariant &value)
{
    if (m_s.value(key) == value)
        return;
    m_s.setValue(key, value);
    emit changed();
}

QString AppSettings::scheme() const
{
    const QString v = m_s.value(QStringLiteral("exam/scheme"), QStringLiteral("anfr2021")).toString();
    return v == QLatin1String("legacy") ? v : QStringLiteral("anfr2021");
}
void AppSettings::setScheme(const QString &v) { put(QStringLiteral("exam/scheme"), v); }

bool AppSettings::shuffleAnswers() const { return m_s.value(QStringLiteral("exam/shuffleAnswers"), true).toBool(); }
void AppSettings::setShuffleAnswers(bool v) { put(QStringLiteral("exam/shuffleAnswers"), v); }

bool AppSettings::favorUnseen() const { return m_s.value(QStringLiteral("exam/favorUnseen"), false).toBool(); }
void AppSettings::setFavorUnseen(bool v) { put(QStringLiteral("exam/favorUnseen"), v); }

bool AppSettings::extendedTime() const { return m_s.value(QStringLiteral("exam/extendedTime"), false).toBool(); }
void AppSettings::setExtendedTime(bool v) { put(QStringLiteral("exam/extendedTime"), v); }

QString AppSettings::colorScheme() const { return m_s.value(QStringLiteral("ui/colorScheme"), QStringLiteral("light")).toString(); }
void AppSettings::setColorScheme(const QString &v) { put(QStringLiteral("ui/colorScheme"), v); }

double AppSettings::textScale() const { return qBound(0.9, m_s.value(QStringLiteral("ui/textScale"), 1.0).toDouble(), 1.6); }
void AppSettings::setTextScale(double v) { put(QStringLiteral("ui/textScale"), qBound(0.9, v, 1.6)); }

bool AppSettings::autoCheckUpdates() const { return m_s.value(QStringLiteral("update/autoCheck"), true).toBool(); }
void AppSettings::setAutoCheckUpdates(bool v) { put(QStringLiteral("update/autoCheck"), v); }

QString AppSettings::updateBaseUrl() const
{
    QString v = m_s.value(QStringLiteral("update/baseUrl"), defaultUpdateBaseUrl()).toString().trimmed();
    if (v.isEmpty())
        v = defaultUpdateBaseUrl();
    if (!v.endsWith(QLatin1Char('/')))
        v += QLatin1Char('/');
    return v;
}
void AppSettings::setUpdateBaseUrl(const QString &v) { put(QStringLiteral("update/baseUrl"), v.trimmed()); }

bool AppSettings::showStatementText() const { return m_s.value(QStringLiteral("ui/showStatementText"), false).toBool(); }
void AppSettings::setShowStatementText(bool v) { put(QStringLiteral("ui/showStatementText"), v); }

int AppSettings::trainingCount() const { return qBound(1, m_s.value(QStringLiteral("training/count"), 20).toInt(), 200); }
void AppSettings::setTrainingCount(int v) { put(QStringLiteral("training/count"), qBound(1, v, 200)); }

int AppSettings::trainingMinutes() const { return qBound(0, m_s.value(QStringLiteral("training/minutes"), 0).toInt(), 300); }
void AppSettings::setTrainingMinutes(int v) { put(QStringLiteral("training/minutes"), qBound(0, v, 300)); }

bool AppSettings::trainingInstant() const { return m_s.value(QStringLiteral("training/instant"), true).toBool(); }
void AppSettings::setTrainingInstant(bool v) { put(QStringLiteral("training/instant"), v); }

QVariantList AppSettings::trainingThemes() const { return m_s.value(QStringLiteral("training/themes")).toList(); }
void AppSettings::setTrainingThemes(const QVariantList &v) { put(QStringLiteral("training/themes"), v); }

QString AppSettings::statementMode() const
{
    const QString v = m_s.value(QStringLiteral("ui/statementMode"), QStringLiteral("auto")).toString();
    return v == QLatin1String("image") ? v : QStringLiteral("auto");
}
void AppSettings::setStatementMode(const QString &v) { put(QStringLiteral("ui/statementMode"), v); }

QString AppSettings::questionNumbers() const
{
    const QString v = m_s.value(QStringLiteral("ui/questionNumbers"), QStringLiteral("training")).toString();
    return v == QLatin1String("always") || v == QLatin1String("never") ? v : QStringLiteral("training");
}
void AppSettings::setQuestionNumbers(const QString &v) { put(QStringLiteral("ui/questionNumbers"), v); }
