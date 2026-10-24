// Per-user data, kept apart from the question bank so bank updates never touch it:
// candidates, exam results, saved questions and per-question statistics.
#pragma once

#include <QObject>
#include <QSet>
#include <QSqlDatabase>
#include <QVariantList>
#include <QVector>

class UserStore : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int currentCandidate READ currentCandidate WRITE setCurrentCandidate NOTIFY currentCandidateChanged)
    Q_PROPERTY(QString currentCandidateName READ currentCandidateName NOTIFY currentCandidateChanged)
    Q_PROPERTY(int savedCount READ savedCount NOTIFY savedChanged)
    Q_PROPERTY(int revision READ revision NOTIFY dataChanged)

public:
    explicit UserStore(const QString &dbPath, QObject *parent = nullptr);
    ~UserStore() override;

    bool isOpen() const { return m_db.isOpen(); }

    int currentCandidate() const { return m_current; }
    void setCurrentCandidate(int id);
    QString currentCandidateName() const;
    int revision() const { return m_revision; }

    // Candidates
    Q_INVOKABLE QVariantList candidates() const;
    Q_INVOKABLE int addCandidate(const QString &name);
    Q_INVOKABLE bool renameCandidate(int id, const QString &name);
    Q_INVOKABLE bool removeCandidate(int id);

    // Results
    struct AnswerRecord {
        int num;
        int chosen;   // 1-based proposition chosen, 0 = no answer
        int answer;   // 1-based correct proposition
        bool pinned;
    };
    struct ResultRecord {
        QString mode;        // official, training, series, review
        QString category;    // reglementation, technique, mixed
        QString title;
        QString scheme;      // anfr2021, legacy
        int total = 0, correct = 0, wrong = 0, blank = 0;
        int score = 0, maxScore = 0;
        bool passed = false;
        int secondsUsed = 0, secondsAllowed = 0;
        QString bankVersion;
        QString started;
        QVector<AnswerRecord> answers;
    };
    int addResult(const ResultRecord &r);
    Q_INVOKABLE QVariantList results(const QString &category = QString(), int limit = 0) const;
    Q_INVOKABLE QVariantMap resultDetail(int id) const;
    Q_INVOKABLE bool removeResult(int id);
    Q_INVOKABLE QVariantMap summary() const;

    // Saved questions
    int savedCount() const;
    Q_INVOKABLE bool isSaved(int num) const { return m_saved.contains(num); }
    Q_INVOKABLE void setSaved(int num, bool saved);
    Q_INVOKABLE void toggleSaved(int num) { setSaved(num, !isSaved(num)); }
    QVector<int> savedNums() const;

    // Statistics
    QVector<int> wrongNums() const;          // last answer was wrong or blank
    QSet<int> askedNums() const;
    QHash<int, int> timesAsked() const;
    Q_INVOKABLE QVariantMap questionStats(int num) const;
    Q_INVOKABLE void resetStatistics();

signals:
    void currentCandidateChanged();
    void savedChanged();
    void dataChanged();

private:
    void ensureSchema();
    void ensureCandidate();
    void loadSaved();
    void bump();

    QSqlDatabase m_db;
    QString m_connection;
    int m_current = 0;
    QSet<int> m_saved;
    int m_revision = 0;
};
