#include "bankstore.h"

#include "bankimporter.h"
#include "statement.h"
#include "themes.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QLocale>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QUuid>
#include <QVariantMap>

namespace {
const QString kPointerFile = QStringLiteral("current.txt");
}

BankStore::BankStore(const QString &banksRoot, QObject *parent)
    : QObject(parent)
    , m_banksRoot(banksRoot)
{
    QDir().mkpath(m_banksRoot);
}

QString BankStore::imagesDir() const
{
    return m_dir.isEmpty() ? QString() : QDir(m_dir).filePath(BankImporter::imagesFolderName());
}

bool BankStore::openCurrent()
{
    QFile f(QDir(m_banksRoot).filePath(kPointerFile));
    if (!f.open(QIODevice::ReadOnly))
        return false;
    const QString name = QString::fromUtf8(f.readAll()).trimmed();
    if (name.isEmpty() || name.contains(QLatin1Char('/')) || name.contains(QLatin1Char('\\')))
        return false;
    return load(QDir(m_banksRoot).filePath(name));
}

bool BankStore::switchTo(const QString &bankDir)
{
    if (!load(bankDir))
        return false;
    QFile f(QDir(m_banksRoot).filePath(kPointerFile));
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        f.write(QFileInfo(bankDir).fileName().toUtf8());
    f.close();
    // Remove previous banks (best effort: a file still in use is simply retried next time).
    const QFileInfoList dirs = QDir(m_banksRoot).entryInfoList({QStringLiteral("bank-*")}, QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QFileInfo &fi : dirs) {
        if (QFileInfo(fi.absoluteFilePath()) != QFileInfo(bankDir))
            QDir(fi.absoluteFilePath()).removeRecursively();
    }
    return true;
}

bool BankStore::load(const QString &dir)
{
    const QString dbPath = QDir(dir).filePath(BankImporter::databaseFileName());
    if (!QFileInfo::exists(dbPath))
        return false;

    QVector<Question> questions;
    QHash<int, int> index;
    QHash<int, QVector<int>> byTheme;
    QVector<Series> series;
    QString version, source, importedAt;
    int images = 0;

    const QString connection = QStringLiteral("bank-%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    bool ok = false;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection);
        db.setDatabaseName(dbPath);
        db.setConnectOptions(QStringLiteral("QSQLITE_OPEN_READONLY"));
        if (db.open()) {
            QSqlQuery q(db);
            const bool hasDisplay = q.exec(QStringLiteral("SELECT display_text, text_only FROM questions LIMIT 1"));
            const QString sql = hasDisplay
                ? QStringLiteral("SELECT num, ref, text, options, answer, theme, comment, course, image, display_text, text_only FROM questions ORDER BY num")
                : QStringLiteral("SELECT num, ref, text, options, answer, theme, comment, course, image FROM questions ORDER BY num");
            if (q.exec(sql)) {
                while (q.next()) {
                    Question qu;
                    qu.num = q.value(0).toInt();
                    qu.ref = q.value(1).toString();
                    qu.text = q.value(2).toString();
                    const QJsonArray arr = QJsonDocument::fromJson(q.value(3).toString().toUtf8()).array();
                    for (const QJsonValue &v : arr)
                        qu.options << v.toString();
                    qu.answer = q.value(4).toInt();
                    qu.theme = q.value(5).toInt();
                    qu.comment = q.value(6).toString();
                    qu.course = q.value(7).toString();
                    qu.image = q.value(8).toString();
                    qu.displayText = hasDisplay ? q.value(9).toString() : Statement::displayText(qu.text);
                    qu.textOnly = hasDisplay ? q.value(10).toInt() != 0 : qu.image.isEmpty();
                    if (!qu.image.isEmpty())
                        ++images;
                    index.insert(qu.num, questions.size());
                    byTheme[qu.theme].push_back(qu.num);
                    questions.push_back(qu);
                }
                ok = !questions.isEmpty();
            }
            if (ok && q.exec(QStringLiteral("SELECT id, name, num, type FROM series ORDER BY id"))) {
                QHash<int, int> seriesPos;
                while (q.next()) {
                    Series s;
                    s.name = q.value(1).toString();
                    s.num = q.value(2).toInt();
                    s.type = q.value(3).toString();
                    seriesPos.insert(q.value(0).toInt(), series.size());
                    series.push_back(s);
                }
                if (q.exec(QStringLiteral("SELECT series_id, num FROM series_questions ORDER BY series_id, pos"))) {
                    while (q.next()) {
                        const int pos = seriesPos.value(q.value(0).toInt(), -1);
                        const int num = q.value(1).toInt();
                        if (pos >= 0 && index.contains(num))
                            series[pos].questions.push_back(num);
                    }
                }
            }
            bool currentFormat = false;
            if (ok && q.exec(QStringLiteral("SELECT key, value FROM meta"))) {
                while (q.next()) {
                    const QString k = q.value(0).toString();
                    // Banks built before the answer numbering fix (no "answer_base") must be rebuilt.
                    if (k == QLatin1String("answer_base"))
                        currentFormat = true;
                    if (k == QLatin1String("version"))
                        version = q.value(1).toString();
                    else if (k == QLatin1String("source"))
                        source = q.value(1).toString();
                    else if (k == QLatin1String("imported_at"))
                        importedAt = q.value(1).toString();
                }
            }
            ok = ok && currentFormat;
            db.close();
        }
        db = QSqlDatabase();
    }
    QSqlDatabase::removeDatabase(connection);
    if (!ok)
        return false;

    m_dir = QDir(dir).absolutePath();
    m_questions = questions;
    m_index = index;
    m_byTheme = byTheme;
    m_series = series;
    m_version = version;
    m_source = source;
    m_importedAt = importedAt;
    m_imageCount = images;
    emit changed();
    return true;
}

const Question *BankStore::find(int num) const
{
    const auto it = m_index.constFind(num);
    return it == m_index.constEnd() ? nullptr : &m_questions.at(it.value());
}

QVector<int> BankStore::numsForCategory(int category) const
{
    QVector<int> out;
    for (const Question &q : m_questions)
        if (Themes::category(q.theme) == category)
            out.push_back(q.num);
    return out;
}

QUrl BankStore::imageUrl(const Question &q) const
{
    if (q.image.isEmpty())
        return QUrl();
    return QUrl::fromLocalFile(QDir(imagesDir()).filePath(q.image));
}

const BankStore::Series *BankStore::findSeries(const QString &name) const
{
    for (const Series &s : m_series)
        if (s.name == name)
            return &s;
    return nullptr;
}

QString BankStore::formatVersion(const QString &iso)
{
    if (iso.isEmpty())
        return QStringLiteral("inconnue");
    const QDateTime dt = QDateTime::fromString(iso, Qt::ISODate);
    if (!dt.isValid())
        return iso;
    return QLocale(QLocale::French, QLocale::France).toString(dt.toLocalTime().date(), QStringLiteral("d MMMM yyyy"));
}

QString BankStore::versionLabel() const
{
    return formatVersion(m_version);
}

QString BankStore::importedAtLabel() const
{
    return formatVersion(m_importedAt);
}

QString BankStore::themeName(int theme) const
{
    return Themes::name(theme);
}

QVariantList BankStore::themeList(int category) const
{
    QVariantList out;
    const QList<Themes::Theme> &list = category == Themes::Technique ? Themes::technique() : Themes::reglementation();
    for (const Themes::Theme &t : list) {
        QVariantMap m;
        m.insert(QStringLiteral("id"), t.id);
        m.insert(QStringLiteral("name"), t.name);
        m.insert(QStringLiteral("count"), m_byTheme.value(t.id).size());
        out << m;
    }
    return out;
}

QVariantList BankStore::technicalThemes() const { return themeList(Themes::Technique); }
QVariantList BankStore::regulationThemes() const { return themeList(Themes::Reglementation); }

QVariantList BankStore::seriesList(const QString &type) const
{
    QVariantList out;
    for (const Series &s : m_series) {
        if (!type.isEmpty() && s.type != type)
            continue;
        QVariantMap m;
        m.insert(QStringLiteral("name"), s.name);
        m.insert(QStringLiteral("type"), s.type);
        m.insert(QStringLiteral("count"), s.questions.size());
        int reg = 0, tech = 0;
        for (int n : s.questions) {
            if (const Question *q = find(n)) {
                if (Themes::category(q->theme) == Themes::Reglementation)
                    ++reg;
                else if (Themes::category(q->theme) == Themes::Technique)
                    ++tech;
            }
        }
        m.insert(QStringLiteral("regulation"), reg);
        m.insert(QStringLiteral("technique"), tech);
        out << m;
    }
    return out;
}

QVariantMap BankStore::question(int num) const
{
    QVariantMap m;
    const Question *q = find(num);
    if (!q)
        return m;
    m.insert(QStringLiteral("num"), q->num);
    m.insert(QStringLiteral("ref"), q->ref);
    m.insert(QStringLiteral("text"), q->displayText);
    m.insert(QStringLiteral("textOnly"), q->textOnly);
    m.insert(QStringLiteral("options"), q->options);
    m.insert(QStringLiteral("answer"), q->answer);
    m.insert(QStringLiteral("theme"), q->theme);
    m.insert(QStringLiteral("themeName"), Themes::name(q->theme));
    m.insert(QStringLiteral("comment"), q->comment);
    m.insert(QStringLiteral("course"), q->course);
    m.insert(QStringLiteral("image"), imageUrl(*q));
    return m;
}
