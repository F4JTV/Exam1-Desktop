#include "userstore.h"

#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariantMap>

UserStore::UserStore(const QString &dbPath, QObject *parent)
    : QObject(parent)
    , m_connection(QStringLiteral("userdata"))
{
    QDir().mkpath(QFileInfo(dbPath).absolutePath());
    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connection);
    m_db.setDatabaseName(dbPath);
    if (!m_db.open()) {
        qWarning() << "Cannot open user database" << dbPath << m_db.lastError().text();
        return;
    }
    ensureSchema();
    m_current = QSettings().value(QStringLiteral("candidate/current"), 0).toInt();
    ensureCandidate();
    loadSaved();
}

UserStore::~UserStore()
{
    m_db.close();
    m_db = QSqlDatabase();
    QSqlDatabase::removeDatabase(m_connection);
}

void UserStore::ensureSchema()
{
    QSqlQuery q(m_db);
    const QStringList ddl = {
        QStringLiteral("PRAGMA foreign_keys = ON"),
        QStringLiteral("CREATE TABLE IF NOT EXISTS candidates(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, created TEXT)"),
        QStringLiteral("CREATE TABLE IF NOT EXISTS results(id INTEGER PRIMARY KEY AUTOINCREMENT, candidate INTEGER NOT NULL,"
                       " started TEXT, finished TEXT, mode TEXT, category TEXT, title TEXT, scheme TEXT,"
                       " total INTEGER, correct INTEGER, wrong INTEGER, blank INTEGER, score INTEGER, max_score INTEGER,"
                       " passed INTEGER, seconds_used INTEGER, seconds_allowed INTEGER, bank_version TEXT, details TEXT)"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS idx_results_candidate ON results(candidate, finished)"),
        QStringLiteral("CREATE TABLE IF NOT EXISTS saved(candidate INTEGER NOT NULL, num INTEGER NOT NULL, added TEXT,"
                       " PRIMARY KEY(candidate, num))"),
        QStringLiteral("CREATE TABLE IF NOT EXISTS asked(candidate INTEGER NOT NULL, num INTEGER NOT NULL, times INTEGER,"
                       " correct INTEGER, wrong INTEGER, last TEXT, last_ok INTEGER, PRIMARY KEY(candidate, num))"),
    };
    for (const QString &s : ddl)
        if (!q.exec(s))
            qWarning() << "User schema error" << q.lastError().text();
}

void UserStore::ensureCandidate()
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT id FROM candidates WHERE id = ?"));
    q.addBindValue(m_current);
    if (q.exec() && q.next())
        return;
    if (q.exec(QStringLiteral("SELECT id FROM candidates ORDER BY id LIMIT 1")) && q.next()) {
        setCurrentCandidate(q.value(0).toInt());
        return;
    }
    setCurrentCandidate(addCandidate(QStringLiteral("Candidat")));
}

void UserStore::bump()
{
    ++m_revision;
    emit dataChanged();
}

void UserStore::setCurrentCandidate(int id)
{
    if (id == m_current && id != 0)
        return;
    m_current = id;
    QSettings().setValue(QStringLiteral("candidate/current"), id);
    loadSaved();
    emit currentCandidateChanged();
    emit savedChanged();
    bump();
}

QString UserStore::currentCandidateName() const
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT name FROM candidates WHERE id = ?"));
    q.addBindValue(m_current);
    if (q.exec() && q.next())
        return q.value(0).toString();
    return QString();
}

QVariantList UserStore::candidates() const
{
    QVariantList out;
    QSqlQuery q(m_db);
    q.exec(QStringLiteral("SELECT c.id, c.name, COUNT(r.id), SUM(r.passed) FROM candidates c"
                          " LEFT JOIN results r ON r.candidate = c.id GROUP BY c.id ORDER BY c.name COLLATE NOCASE"));
    while (q.next()) {
        QVariantMap m;
        m.insert(QStringLiteral("id"), q.value(0).toInt());
        m.insert(QStringLiteral("name"), q.value(1).toString());
        m.insert(QStringLiteral("exams"), q.value(2).toInt());
        m.insert(QStringLiteral("passed"), q.value(3).toInt());
        out << m;
    }
    return out;
}

int UserStore::addCandidate(const QString &name)
{
    const QString n = name.trimmed().isEmpty() ? QStringLiteral("Candidat") : name.trimmed();
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("INSERT INTO candidates(name, created) VALUES(?, ?)"));
    q.addBindValue(n);
    q.addBindValue(QDateTime::currentDateTime().toString(Qt::ISODate));
    if (!q.exec())
        return 0;
    bump();
    return q.lastInsertId().toInt();
}

bool UserStore::renameCandidate(int id, const QString &name)
{
    if (name.trimmed().isEmpty())
        return false;
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("UPDATE candidates SET name = ? WHERE id = ?"));
    q.addBindValue(name.trimmed());
    q.addBindValue(id);
    const bool ok = q.exec();
    if (ok) {
        if (id == m_current)
            emit currentCandidateChanged();
        bump();
    }
    return ok;
}

bool UserStore::removeCandidate(int id)
{
    QSqlQuery q(m_db);
    m_db.transaction();
    for (const char *table : {"results", "saved", "asked"}) {
        q.prepare(QStringLiteral("DELETE FROM %1 WHERE candidate = ?").arg(QLatin1String(table)));
        q.addBindValue(id);
        q.exec();
    }
    q.prepare(QStringLiteral("DELETE FROM candidates WHERE id = ?"));
    q.addBindValue(id);
    const bool ok = q.exec();
    m_db.commit();
    if (id == m_current) {
        m_current = 0;
        ensureCandidate();
    }
    bump();
    return ok;
}

int UserStore::addResult(const ResultRecord &r)
{
    QJsonArray details;
    for (const AnswerRecord &a : r.answers) {
        QJsonObject o;
        o.insert(QStringLiteral("n"), a.num);
        o.insert(QStringLiteral("c"), a.chosen);
        o.insert(QStringLiteral("a"), a.answer);
        if (a.pinned)
            o.insert(QStringLiteral("p"), true);
        details.append(o);
    }
    const QString now = QDateTime::currentDateTime().toString(Qt::ISODate);
    QSqlQuery q(m_db);
    m_db.transaction();
    q.prepare(QStringLiteral("INSERT INTO results(candidate, started, finished, mode, category, title, scheme, total, correct, wrong,"
                             " blank, score, max_score, passed, seconds_used, seconds_allowed, bank_version, details)"
                             " VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"));
    q.addBindValue(m_current);
    q.addBindValue(r.started);
    q.addBindValue(now);
    q.addBindValue(r.mode);
    q.addBindValue(r.category);
    q.addBindValue(r.title);
    q.addBindValue(r.scheme);
    q.addBindValue(r.total);
    q.addBindValue(r.correct);
    q.addBindValue(r.wrong);
    q.addBindValue(r.blank);
    q.addBindValue(r.score);
    q.addBindValue(r.maxScore);
    q.addBindValue(r.passed ? 1 : 0);
    q.addBindValue(r.secondsUsed);
    q.addBindValue(r.secondsAllowed);
    q.addBindValue(r.bankVersion);
    q.addBindValue(QString::fromUtf8(QJsonDocument(details).toJson(QJsonDocument::Compact)));
    int id = 0;
    if (q.exec())
        id = q.lastInsertId().toInt();
    else
        qWarning() << "Cannot save result" << q.lastError().text();

    QSqlQuery u(m_db);
    u.prepare(QStringLiteral("INSERT INTO asked(candidate, num, times, correct, wrong, last, last_ok) VALUES(?,?,1,?,?,?,?)"
                             " ON CONFLICT(candidate, num) DO UPDATE SET times = times + 1, correct = correct + excluded.correct,"
                             " wrong = wrong + excluded.wrong, last = excluded.last, last_ok = excluded.last_ok"));
    for (const AnswerRecord &a : r.answers) {
        const bool ok = a.chosen == a.answer;
        u.addBindValue(m_current);
        u.addBindValue(a.num);
        u.addBindValue(ok ? 1 : 0);
        u.addBindValue(ok ? 0 : 1);
        u.addBindValue(now);
        u.addBindValue(ok ? 1 : 0);
        if (!u.exec())
            qWarning() << "Cannot update statistics" << u.lastError().text();
    }
    m_db.commit();
    bump();
    return id;
}

static QVariantMap resultRow(const QSqlQuery &q)
{
    QVariantMap m;
    m.insert(QStringLiteral("id"), q.value(0).toInt());
    m.insert(QStringLiteral("finished"), q.value(1).toString());
    m.insert(QStringLiteral("dateLabel"), QDateTime::fromString(q.value(1).toString(), Qt::ISODate).toString(QStringLiteral("dd/MM/yyyy HH:mm")));
    m.insert(QStringLiteral("mode"), q.value(2).toString());
    m.insert(QStringLiteral("category"), q.value(3).toString());
    m.insert(QStringLiteral("title"), q.value(4).toString());
    m.insert(QStringLiteral("scheme"), q.value(5).toString());
    m.insert(QStringLiteral("total"), q.value(6).toInt());
    m.insert(QStringLiteral("correct"), q.value(7).toInt());
    m.insert(QStringLiteral("wrong"), q.value(8).toInt());
    m.insert(QStringLiteral("blank"), q.value(9).toInt());
    m.insert(QStringLiteral("score"), q.value(10).toInt());
    m.insert(QStringLiteral("maxScore"), q.value(11).toInt());
    m.insert(QStringLiteral("passed"), q.value(12).toInt() != 0);
    m.insert(QStringLiteral("secondsUsed"), q.value(13).toInt());
    m.insert(QStringLiteral("secondsAllowed"), q.value(14).toInt());
    const int max = q.value(11).toInt();
    m.insert(QStringLiteral("note20"), max > 0 ? qMax(0.0, 20.0 * q.value(10).toDouble() / max) : 0.0);
    return m;
}

QVariantList UserStore::results(const QString &category, int limit) const
{
    QVariantList out;
    QString sql = QStringLiteral("SELECT id, finished, mode, category, title, scheme, total, correct, wrong, blank, score, max_score,"
                                 " passed, seconds_used, seconds_allowed FROM results WHERE candidate = ?");
    if (!category.isEmpty())
        sql += QStringLiteral(" AND category = ?");
    sql += QStringLiteral(" ORDER BY finished DESC, id DESC");
    if (limit > 0)
        sql += QStringLiteral(" LIMIT %1").arg(limit);
    QSqlQuery q(m_db);
    q.prepare(sql);
    q.addBindValue(m_current);
    if (!category.isEmpty())
        q.addBindValue(category);
    if (q.exec())
        while (q.next())
            out << resultRow(q);
    return out;
}

QVariantMap UserStore::resultDetail(int id) const
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT id, finished, mode, category, title, scheme, total, correct, wrong, blank, score, max_score,"
                             " passed, seconds_used, seconds_allowed, details FROM results WHERE id = ?"));
    q.addBindValue(id);
    if (!q.exec() || !q.next())
        return {};
    QVariantMap m = resultRow(q);
    QVariantList answers;
    for (const QJsonValue &v : QJsonDocument::fromJson(q.value(15).toString().toUtf8()).array()) {
        const QJsonObject o = v.toObject();
        QVariantMap a;
        a.insert(QStringLiteral("num"), o.value(QStringLiteral("n")).toInt());
        a.insert(QStringLiteral("chosen"), o.value(QStringLiteral("c")).toInt());
        a.insert(QStringLiteral("answer"), o.value(QStringLiteral("a")).toInt());
        a.insert(QStringLiteral("pinned"), o.value(QStringLiteral("p")).toBool());
        answers << a;
    }
    m.insert(QStringLiteral("answers"), answers);
    return m;
}

bool UserStore::removeResult(int id)
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("DELETE FROM results WHERE id = ? AND candidate = ?"));
    q.addBindValue(id);
    q.addBindValue(m_current);
    const bool ok = q.exec();
    bump();
    return ok;
}

QVariantMap UserStore::summary() const
{
    QVariantMap out;
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT COUNT(*), SUM(passed) FROM results WHERE candidate = ?"));
    q.addBindValue(m_current);
    if (q.exec() && q.next()) {
        out.insert(QStringLiteral("exams"), q.value(0).toInt());
        out.insert(QStringLiteral("passed"), q.value(1).toInt());
    }
    q.prepare(QStringLiteral("SELECT COUNT(*), SUM(times), SUM(correct) FROM asked WHERE candidate = ?"));
    q.addBindValue(m_current);
    if (q.exec() && q.next()) {
        out.insert(QStringLiteral("askedDistinct"), q.value(0).toInt());
        out.insert(QStringLiteral("answersTotal"), q.value(1).toInt());
        out.insert(QStringLiteral("answersCorrect"), q.value(2).toInt());
    }
    for (const QString &cat : {QStringLiteral("reglementation"), QStringLiteral("technique")}) {
        QVariantList last;
        q.prepare(QStringLiteral("SELECT score, max_score, passed FROM results WHERE candidate = ? AND category = ? AND mode = 'official'"
                                 " ORDER BY finished DESC, id DESC LIMIT 10"));
        q.addBindValue(m_current);
        q.addBindValue(cat);
        if (q.exec()) {
            while (q.next()) {
                QVariantMap m;
                const int max = q.value(1).toInt();
                m.insert(QStringLiteral("note20"), max > 0 ? qMax(0.0, 20.0 * q.value(0).toDouble() / max) : 0.0);
                m.insert(QStringLiteral("passed"), q.value(2).toInt() != 0);
                last.prepend(m); // chronological order
            }
        }
        out.insert(cat, last);
    }
    out.insert(QStringLiteral("saved"), m_saved.size());
    return out;
}

void UserStore::loadSaved()
{
    m_saved.clear();
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT num FROM saved WHERE candidate = ?"));
    q.addBindValue(m_current);
    if (q.exec())
        while (q.next())
            m_saved.insert(q.value(0).toInt());
}

int UserStore::savedCount() const
{
    return m_saved.size();
}

void UserStore::setSaved(int num, bool saved)
{
    if (saved == m_saved.contains(num))
        return;
    QSqlQuery q(m_db);
    if (saved) {
        q.prepare(QStringLiteral("INSERT OR IGNORE INTO saved(candidate, num, added) VALUES(?,?,?)"));
        q.addBindValue(m_current);
        q.addBindValue(num);
        q.addBindValue(QDateTime::currentDateTime().toString(Qt::ISODate));
        m_saved.insert(num);
    } else {
        q.prepare(QStringLiteral("DELETE FROM saved WHERE candidate = ? AND num = ?"));
        q.addBindValue(m_current);
        q.addBindValue(num);
        m_saved.remove(num);
    }
    q.exec();
    emit savedChanged();
    bump();
}

QVector<int> UserStore::savedNums() const
{
    QVector<int> out;
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT num FROM saved WHERE candidate = ? ORDER BY added DESC"));
    q.addBindValue(m_current);
    if (q.exec())
        while (q.next())
            out << q.value(0).toInt();
    return out;
}

QVector<int> UserStore::wrongNums() const
{
    QVector<int> out;
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT num FROM asked WHERE candidate = ? AND last_ok = 0 ORDER BY last DESC"));
    q.addBindValue(m_current);
    if (q.exec())
        while (q.next())
            out << q.value(0).toInt();
    return out;
}

QSet<int> UserStore::askedNums() const
{
    QSet<int> out;
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT num FROM asked WHERE candidate = ?"));
    q.addBindValue(m_current);
    if (q.exec())
        while (q.next())
            out.insert(q.value(0).toInt());
    return out;
}

QHash<int, int> UserStore::timesAsked() const
{
    QHash<int, int> out;
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT num, times FROM asked WHERE candidate = ?"));
    q.addBindValue(m_current);
    if (q.exec())
        while (q.next())
            out.insert(q.value(0).toInt(), q.value(1).toInt());
    return out;
}

QVariantMap UserStore::questionStats(int num) const
{
    QVariantMap m;
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT times, correct, wrong, last, last_ok FROM asked WHERE candidate = ? AND num = ?"));
    q.addBindValue(m_current);
    q.addBindValue(num);
    if (q.exec() && q.next()) {
        m.insert(QStringLiteral("times"), q.value(0).toInt());
        m.insert(QStringLiteral("correct"), q.value(1).toInt());
        m.insert(QStringLiteral("wrong"), q.value(2).toInt());
        m.insert(QStringLiteral("lastOk"), q.value(4).toInt() != 0);
    } else {
        m.insert(QStringLiteral("times"), 0);
    }
    return m;
}

void UserStore::resetStatistics()
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("DELETE FROM asked WHERE candidate = ?"));
    q.addBindValue(m_current);
    q.exec();
    bump();
}
