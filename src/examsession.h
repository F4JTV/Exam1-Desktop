// One exam or training session. Exposed to QML both as a list model (one row per
// question, used by the Evalbox-style vertical question list) and as an object
// holding the timer, counters, autosave and final results.
//
// As on the ANFR / Evalbox exam, propositions are check boxes: several can be ticked,
// and a question only scores when exactly the right proposition is ticked.
#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QElapsedTimer>
#include <QTimer>
#include <QUrl>
#include <QVariantList>
#include <QVector>

class BankStore;
class UserStore;
class AppSettings;

class ExamSession : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool active READ active NOTIFY stateChanged)
    Q_PROPERTY(bool finished READ finished NOTIFY stateChanged)
    Q_PROPERTY(QString mode READ mode NOTIFY stateChanged)
    Q_PROPERTY(QString category READ category NOTIFY stateChanged)
    Q_PROPERTY(QString title READ title NOTIFY stateChanged)
    Q_PROPERTY(QString subtitle READ subtitle NOTIFY stateChanged)
    Q_PROPERTY(int count READ count NOTIFY stateChanged)
    Q_PROPERTY(bool multipleChoice READ multipleChoice NOTIFY stateChanged)
    Q_PROPERTY(int answeredCount READ answeredCount NOTIFY progressChanged)
    Q_PROPERTY(int pinnedCount READ pinnedCount NOTIFY progressChanged)
    Q_PROPERTY(int multiCount READ multiCount NOTIFY progressChanged)
    Q_PROPERTY(bool timed READ timed NOTIFY stateChanged)
    Q_PROPERTY(int durationSeconds READ durationSeconds NOTIFY stateChanged)
    Q_PROPERTY(int remainingSeconds READ remainingSeconds NOTIFY clockChanged)
    Q_PROPERTY(int elapsedSeconds READ elapsedSeconds NOTIFY clockChanged)
    Q_PROPERTY(bool instantCorrection READ instantCorrection NOTIFY stateChanged)
    Q_PROPERTY(bool extendedTime READ extendedTime NOTIFY stateChanged)
    Q_PROPERTY(QString lastSavedLabel READ lastSavedLabel NOTIFY savedStateChanged)
    Q_PROPERTY(bool hasSavedSession READ hasSavedSession NOTIFY savedStateChanged)
    Q_PROPERTY(QVariantMap savedSessionInfo READ savedSessionInfo NOTIFY savedStateChanged)
    // Results (valid once finished)
    Q_PROPERTY(int score READ score NOTIFY resultChanged)
    Q_PROPERTY(int maxScore READ maxScore NOTIFY resultChanged)
    Q_PROPERTY(double note20 READ note20 NOTIFY resultChanged)
    Q_PROPERTY(int correctCount READ correctCount NOTIFY resultChanged)
    Q_PROPERTY(int wrongCount READ wrongCount NOTIFY resultChanged)
    Q_PROPERTY(int blankCount READ blankCount NOTIFY resultChanged)
    Q_PROPERTY(bool passed READ passed NOTIFY resultChanged)
    Q_PROPERTY(QVariantList parts READ parts NOTIFY resultChanged)
    Q_PROPERTY(QString schemeLabel READ schemeLabel NOTIFY resultChanged)
    Q_PROPERTY(QString passMarkLabel READ passMarkLabel NOTIFY resultChanged)
    Q_PROPERTY(QVariantList themeBreakdown READ themeBreakdown NOTIFY resultChanged)
    Q_PROPERTY(bool timeExpired READ timeExpired NOTIFY resultChanged)

public:
    enum Roles {
        PositionRole = Qt::UserRole + 1,
        NumRole,
        RefRole,
        TextRole,
        ImageRole,
        OptionsRole,
        SelectionRole,
        SelectedRole,
        PinnedRole,
        RevealedRole,
        CorrectRole,
        StatusRole,
        ThemeIdRole,
        ThemeNameRole,
        CommentRole,
        CourseRole,
        SavedRole,
        PartRole,
        TextOnlyRole,
    };
    enum Status { Pending = 0, Correct = 1, Wrong = 2, Blank = 3 };
    Q_ENUM(Status)

    ExamSession(BankStore *bank, UserStore *user, AppSettings *settings, QObject *parent = nullptr);

    void setSavePath(const QString &path) { m_savePath = path; }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    bool active() const { return !m_items.isEmpty() && !m_finished; }
    bool finished() const { return m_finished; }
    QString mode() const { return m_mode; }
    QString category() const { return m_category; }
    QString title() const { return m_title; }
    QString subtitle() const { return m_subtitle; }
    int count() const { return m_items.size(); }
    bool multipleChoice() const { return !m_instant; }
    int answeredCount() const;
    int pinnedCount() const;
    int multiCount() const;
    bool timed() const { return m_duration > 0; }
    int durationSeconds() const { return m_duration; }
    int remainingSeconds() const;
    int elapsedSeconds() const;
    bool instantCorrection() const { return m_instant; }
    bool extendedTime() const { return m_extended; }
    QString lastSavedLabel() const;
    bool hasSavedSession() const;
    QVariantMap savedSessionInfo() const;

    int score() const { return m_score; }
    int maxScore() const { return m_maxScore; }
    double note20() const;
    int correctCount() const { return m_correct; }
    int wrongCount() const { return m_wrong; }
    int blankCount() const { return m_blank; }
    bool passed() const { return m_passed; }
    QVariantList parts() const;
    QString schemeLabel() const;
    QString passMarkLabel() const;
    QVariantList themeBreakdown() const { return m_breakdown; }
    bool timeExpired() const { return m_timeExpired; }

    // Starting a session. Each returns false (and emits error) if the bank cannot supply questions.
    // category: "reglementation", "technique" or "both" (40 questions in one list, as on the ANFR demo).
    Q_INVOKABLE bool startOfficial(const QString &category, bool extendedTime);
    Q_INVOKABLE bool startTraining(const QVariantList &themes, int questionCount, int minutes, bool instantCorrection);
    Q_INVOKABLE bool startSeries(const QString &name, bool timed, bool instantCorrection);
    Q_INVOKABLE bool startReview(const QString &source, int questionCount, bool instantCorrection);
    Q_INVOKABLE int reviewAvailable(const QString &source) const;
    Q_INVOKABLE bool resumeSaved();
    Q_INVOKABLE void discardSaved();

    // During the session
    Q_INVOKABLE void select(int row, int option);
    Q_INVOKABLE void clearAnswer(int row);
    Q_INVOKABLE void togglePin(int row);
    Q_INVOKABLE void reveal(int row);
    Q_INVOKABLE void toggleSaved(int row);
    Q_INVOKABLE int firstUnanswered() const;
    Q_INVOKABLE QVariantList pinnedRows() const;
    Q_INVOKABLE QVariantList snapshot() const;   // all rows as maps (correction page)
    Q_INVOKABLE void finalize();
    Q_INVOKABLE void abandon();

signals:
    void stateChanged();
    void progressChanged();
    void clockChanged();
    void resultChanged();
    void savedStateChanged();
    void timeUp();
    void error(const QString &message);

private:
    struct Item {
        int num = 0;
        QVector<int> order;   // display position -> original proposition index (0-based)
        quint32 mask = 0;     // ticked display positions
        bool pinned = false;
        bool revealed = false;
    };
    struct Part {
        QString category;     // reglementation / technique / mixed
        QString title;
        int first = 0;
        int count = 0;
        int score = 0, maxScore = 0, correct = 0, wrong = 0, blank = 0;
        bool passed = false;
    };

    bool begin(const QVector<int> &nums, const QString &mode, const QString &category, const QString &title,
               const QString &subtitle, int durationSeconds, bool instant, const QVector<Part> &parts = {});
    QVector<int> drawFromThemes(const QList<int> &themes, int total) const;
    QVector<int> pick(QVector<int> pool, int n) const;
    int displayCorrect(const Item &it) const;
    Status statusOf(const Item &it) const;
    int partOfRow(int row) const;
    void tick();
    void computeAndStore();
    void emitRow(int row);
    void scheduleSave();
    void saveNow();
    void removeSaved();

    BankStore *m_bank;
    UserStore *m_user;
    AppSettings *m_settings;

    QVector<Item> m_items;
    QVector<Part> m_parts;
    QString m_mode, m_category, m_title, m_subtitle;
    bool m_instant = false;
    bool m_extended = false;
    bool m_finished = false;
    bool m_timeExpired = false;
    int m_duration = 0;
    QDateTime m_started;
    QElapsedTimer m_clock;
    int m_elapsedOffset = 0;
    int m_frozenElapsed = 0;
    QTimer m_timer;

    QString m_savePath;
    QTimer m_saveTimer;
    QDateTime m_lastSaved;
    int m_ticks = 0;

    int m_score = 0, m_maxScore = 0, m_correct = 0, m_wrong = 0, m_blank = 0;
    bool m_passed = false;
    QString m_scheme;
    QVariantList m_breakdown;
};
