// Per-user data, kept apart from the question bank so bank updates never touch it:
// candidates, exam results, saved questions and per-question statistics.
#pragma once

#include <QObject>
#include <QHash>
#include <QSet>
#include <QSqlDatabase>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>
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
        int chosen;   // 1-based proposition chosen, 0 = no answer, -1 = several boxes ticked
        int answer;   // 1-based correct proposition
        bool pinned;
        QVector<int> order = {};  // display position -> proposition index (0-based), as shown
        quint32 mask = 0;         // ticked display positions
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
    // "Mes erreurs", reviewed with spaced repetition: a question answered wrong is to be reviewed
    // the same day; each right answer on or after its review day puts it off (1, 3, then 7 days),
    // and the 4th takes it out of the list. A wrong answer starts it again.
    QVector<int> wrongNums() const;          // all the questions of the list, the first due first
    QVector<int> dueNums() const;            // those to review today
    Q_INVOKABLE QVariantMap reviewSummary() const; // pending, due, nextLabel (next review day)
    static int reviewInterval(int box); // days before the next review, after a right answer
    struct AnswerCounts {
        int correct = 0;
        int wrong = 0;      // wrong or blank
        bool lastOk = false;
    };
    QHash<int, AnswerCounts> answerCounts() const; // the questions already asked
    QSet<int> askedNums() const;
    QHash<int, int> timesAsked() const;
    Q_INVOKABLE QVariantMap questionStats(int num) const;
    Q_INVOKABLE void resetStatistics();

    // Backup and transfer: all the user data (candidates, results, statistics, errors to review,
    // saved questions) in one file, to keep it or to carry it to another computer or phone.
    Q_INVOKABLE QString exportFileName() const;              // "Exam1-sauvegarde-2026-10-31.exam1"
    Q_INVOKABLE QString exportData(const QUrl &target);      // empty on success, else the error
    // Import in two steps: the chosen file is copied and checked (candidates, results, error),
    // then, once confirmed, it replaces the data of this device. A copy of the replaced data is
    // kept next to it (user-avant-import.sqlite).
    Q_INVOKABLE QVariantMap prepareImport(const QUrl &source);
    Q_INVOKABLE QString commitImport();
    Q_INVOKABLE void cancelImport();
    Q_INVOKABLE QVariantMap contentSummary() const;          // candidates, names, results of this device
    static constexpr int schemaVersion = 1;

signals:
    void currentCandidateChanged();
    void savedChanged();
    void dataChanged();

private:
    bool open();
    QString stagingPath() const;
    void ensureSchema();
    void updateReview(int num, bool right, const QString &today);
    void ensureCandidate();
    void loadSaved();
    void bump();

    QSqlDatabase m_db;
    QString m_connection;
    QString m_path;
    int m_current = 0;
    QSet<int> m_saved;
    int m_revision = 0;
};
