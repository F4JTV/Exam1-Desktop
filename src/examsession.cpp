#include "examsession.h"

#include "appsettings.h"
#include "bankstore.h"
#include "themes.h"
#include "userstore.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRandomGenerator>
#include <QSaveFile>
#include <QSet>
#include <QVariantMap>
#include <algorithm>
#include <climits>
#include <map>

namespace {

QString categoryOf(const BankStore *bank, const QVector<int> &nums)
{
    bool reg = false, tech = false;
    for (int n : nums) {
        if (const Question *q = bank->find(n)) {
            const auto c = Themes::category(q->theme);
            reg |= c == Themes::Reglementation;
            tech |= c == Themes::Technique;
        }
    }
    if (reg && !tech)
        return QStringLiteral("reglementation");
    if (tech && !reg)
        return QStringLiteral("technique");
    return QStringLiteral("mixed");
}

QString plural(int n, const QString &one, const QString &many)
{
    return QStringLiteral("%1 %2").arg(n).arg(n > 1 ? many : one);
}

int bitCount(quint32 v)
{
    int n = 0;
    while (v) {
        v &= v - 1;
        ++n;
    }
    return n;
}

int lowestBit(quint32 v)
{
    for (int i = 0; i < 32; ++i)
        if (v & (1u << i))
            return i;
    return -1;
}

} // namespace

ExamSession::ExamSession(BankStore *bank, UserStore *user, AppSettings *settings, QObject *parent)
    : QAbstractListModel(parent)
    , m_bank(bank)
    , m_user(user)
    , m_settings(settings)
{
    m_timer.setInterval(500);
    connect(&m_timer, &QTimer::timeout, this, &ExamSession::tick);
    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(400);
    connect(&m_saveTimer, &QTimer::timeout, this, &ExamSession::saveNow);
    connect(m_user, &UserStore::savedChanged, this, [this] {
        if (!m_items.isEmpty())
            emit dataChanged(index(0), index(m_items.size() - 1), {SavedRole});
    });
}

int ExamSession::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_items.size();
}

QHash<int, QByteArray> ExamSession::roleNames() const
{
    return {
        {PositionRole, "position"}, {NumRole, "num"}, {RefRole, "ref"}, {TextRole, "statement"},
        {ImageRole, "image"}, {OptionsRole, "options"}, {SelectionRole, "selection"}, {SelectedRole, "selected"},
        {PinnedRole, "pinned"}, {RevealedRole, "revealed"}, {CorrectRole, "correct"}, {StatusRole, "status"},
        {ThemeIdRole, "themeId"}, {ThemeNameRole, "themeName"}, {CommentRole, "comment"}, {CourseRole, "course"},
        {SavedRole, "saved"}, {PartRole, "part"}, {TextOnlyRole, "textOnly"},
    };
}

QVariant ExamSession::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return {};
    const Item &it = m_items.at(index.row());
    const Question *q = m_bank->find(it.num);
    if (!q)
        return {};
    const bool shown = it.revealed || m_finished;
    switch (role) {
    case PositionRole: return index.row() + 1;
    case NumRole: return q->num;
    case RefRole: return q->ref;
    case TextRole: return q->displayText;
    case TextOnlyRole: return q->textOnly;
    case ImageRole: return m_bank->imageUrl(*q);
    case OptionsRole: {
        QStringList out;
        for (int i : it.order)
            out << q->options.value(i);
        return out;
    }
    case SelectionRole: return int(it.mask);
    case SelectedRole: return bitCount(it.mask) == 1 ? lowestBit(it.mask) : -1;
    case PinnedRole: return it.pinned;
    case RevealedRole: return shown;
    case CorrectRole: return shown ? displayCorrect(it) : -1;
    case StatusRole: return shown ? int(statusOf(it)) : int(Pending);
    case ThemeIdRole: return q->theme;
    case ThemeNameRole: return Themes::name(q->theme);
    case CommentRole: return q->comment;
    case CourseRole: return q->course;
    case SavedRole: return m_user->isSaved(q->num);
    case PartRole: return partOfRow(index.row());
    default: return {};
    }
}

int ExamSession::partOfRow(int row) const
{
    for (int p = 0; p < m_parts.size(); ++p)
        if (row >= m_parts.at(p).first && row < m_parts.at(p).first + m_parts.at(p).count)
            return p;
    return 0;
}

int ExamSession::answeredCount() const
{
    return int(std::count_if(m_items.cbegin(), m_items.cend(), [](const Item &it) { return it.mask != 0; }));
}

int ExamSession::pinnedCount() const
{
    return int(std::count_if(m_items.cbegin(), m_items.cend(), [](const Item &it) { return it.pinned; }));
}

int ExamSession::multiCount() const
{
    return int(std::count_if(m_items.cbegin(), m_items.cend(), [](const Item &it) { return bitCount(it.mask) > 1; }));
}

int ExamSession::elapsedSeconds() const
{
    if (m_finished)
        return m_frozenElapsed;
    if (m_items.isEmpty() || !m_clock.isValid())
        return 0;
    return m_elapsedOffset + int(m_clock.elapsed() / 1000);
}

int ExamSession::remainingSeconds() const
{
    if (m_duration <= 0)
        return 0;
    return qMax(0, m_duration - elapsedSeconds());
}

double ExamSession::note20() const
{
    return m_maxScore > 0 ? qMax(0.0, 20.0 * m_score / m_maxScore) : 0.0;
}

QVariantList ExamSession::parts() const
{
    QVariantList out;
    for (const Part &p : m_parts) {
        QVariantMap m;
        m.insert(QStringLiteral("category"), p.category);
        m.insert(QStringLiteral("title"), p.title);
        m.insert(QStringLiteral("first"), p.first);
        m.insert(QStringLiteral("count"), p.count);
        m.insert(QStringLiteral("score"), p.score);
        m.insert(QStringLiteral("maxScore"), p.maxScore);
        m.insert(QStringLiteral("correct"), p.correct);
        m.insert(QStringLiteral("wrong"), p.wrong);
        m.insert(QStringLiteral("blank"), p.blank);
        m.insert(QStringLiteral("passed"), p.passed);
        m.insert(QStringLiteral("note20"), p.maxScore > 0 ? qMax(0.0, 20.0 * p.score / p.maxScore) : 0.0);
        out << m;
    }
    return out;
}

QString ExamSession::schemeLabel() const
{
    return m_scheme == QLatin1String("legacy")
        ? QStringLiteral("Ancien barème : +3 par bonne réponse, −1 par erreur, 0 sans réponse")
        : QStringLiteral("Barème ANFR : 1 point par bonne réponse ; 0 point sans réponse, pour une réponse fausse ou plusieurs cases cochées");
}

QString ExamSession::passMarkLabel() const
{
    if (m_parts.size() > 1)
        return QStringLiteral("Chaque épreuve est réussie à partir de 10 sur 20");
    return QStringLiteral("Réussi à partir de %1 sur %2").arg((m_maxScore + 1) / 2).arg(m_maxScore);
}

// ---------------------------------------------------------------------------------------------
// Drawing questions

QVector<int> ExamSession::pick(QVector<int> pool, int n) const
{
    auto *rng = QRandomGenerator::global();
    std::shuffle(pool.begin(), pool.end(), *rng);
    if (m_settings->favorUnseen()) {
        const QHash<int, int> times = m_user->timesAsked();
        std::stable_sort(pool.begin(), pool.end(), [&](int a, int b) { return times.value(a) < times.value(b); });
    }
    if (n < pool.size())
        pool.resize(n);
    return pool;
}

QVector<int> ExamSession::drawFromThemes(const QList<int> &themes, int total) const
{
    QVector<int> picked;
    if (themes.isEmpty() || total <= 0)
        return picked;
    QList<int> order = themes;
    std::shuffle(order.begin(), order.end(), *QRandomGenerator::global());
    const int k = order.size();
    const int base = total / k;
    const int rem = total % k;
    int shortfall = 0;
    for (int i = 0; i < k; ++i) {
        const int want = base + (i < rem ? 1 : 0);
        if (want == 0)
            continue;
        const QVector<int> got = pick(m_bank->numsForTheme(order.at(i)), want);
        picked += got;
        shortfall += want - got.size();
    }
    if (shortfall > 0) {
        // A family is too small: complete from the other selected families.
        const QSet<int> already(picked.cbegin(), picked.cend());
        QVector<int> pool;
        for (int t : themes)
            for (int n : m_bank->numsForTheme(t))
                if (!already.contains(n))
                    pool << n;
        picked += pick(pool, shortfall);
    }
    std::shuffle(picked.begin(), picked.end(), *QRandomGenerator::global());
    return picked;
}

bool ExamSession::begin(const QVector<int> &nums, const QString &mode, const QString &category, const QString &title,
                        const QString &subtitle, int durationSeconds, bool instant, const QVector<Part> &parts)
{
    QVector<Item> items;
    const bool shuffle = m_settings->shuffleAnswers();
    for (int n : nums) {
        const Question *q = m_bank->find(n);
        if (!q)
            continue;
        Item it;
        it.num = n;
        for (int i = 0; i < q->options.size() && i < 32; ++i)
            it.order << i;
        if (shuffle)
            std::shuffle(it.order.begin(), it.order.end(), *QRandomGenerator::global());
        items << it;
    }
    if (items.isEmpty()) {
        emit error(QStringLiteral("Aucune question disponible pour ce choix. Vérifiez que la base de questions est installée."));
        return false;
    }

    m_timer.stop();
    beginResetModel();
    m_items = items;
    m_mode = mode;
    m_category = category;
    m_title = title;
    m_subtitle = subtitle;
    m_duration = durationSeconds;
    m_instant = instant;
    m_finished = false;
    m_timeExpired = false;
    m_score = m_maxScore = m_correct = m_wrong = m_blank = 0;
    m_passed = false;
    m_breakdown.clear();
    m_parts = parts;
    if (m_parts.isEmpty()) {
        Part p;
        p.category = category;
        p.title = title;
        p.first = 0;
        p.count = m_items.size();
        m_parts << p;
    }
    m_started = QDateTime::currentDateTime();
    m_clock.start();
    m_elapsedOffset = 0;
    m_frozenElapsed = 0;
    m_ticks = 0;
    endResetModel();
    m_timer.start();

    emit stateChanged();
    emit progressChanged();
    emit clockChanged();
    emit resultChanged();
    saveNow();
    return true;
}

bool ExamSession::startOfficial(const QString &category, bool extendedTime)
{
    const int factor = extendedTime ? 3 : 1;
    m_extended = extendedTime;
    auto themeIds = [](const QList<Themes::Theme> &list) {
        QList<int> ids;
        for (const Themes::Theme &t : list)
            ids << t.id;
        return ids;
    };
    const QString adjusted = extendedTime ? QStringLiteral(" (temps aménagé)") : QString();

    if (category == QLatin1String("both")) {
        const QVector<int> reg = drawFromThemes(themeIds(Themes::reglementation()), 20);
        const QVector<int> tech = drawFromThemes(themeIds(Themes::technique()), 20);
        Part p1, p2;
        p1.category = QStringLiteral("reglementation");
        p1.title = QStringLiteral("Épreuve de réglementation");
        p1.first = 0;
        p1.count = reg.size();
        p2.category = QStringLiteral("technique");
        p2.title = QStringLiteral("Épreuve de technique");
        p2.first = reg.size();
        p2.count = tech.size();
        const int minutes = 45 * factor;
        return begin(reg + tech, QStringLiteral("official"), QStringLiteral("both"),
                     QStringLiteral("Examen blanc : épreuves de réglementation et de technique"),
                     QStringLiteral("%1 questions en %2 minutes%3").arg(reg.size() + tech.size()).arg(minutes).arg(adjusted),
                     minutes * 60, false, {p1, p2});
    }

    const bool reg = category == QLatin1String("reglementation");
    const int minutes = (reg ? 15 : 30) * factor;
    const QString title = reg ? QStringLiteral("Examen blanc : épreuve de réglementation")
                              : QStringLiteral("Examen blanc : épreuve de technique");
    Part p;
    p.category = reg ? QStringLiteral("reglementation") : QStringLiteral("technique");
    p.title = reg ? QStringLiteral("Épreuve de réglementation") : QStringLiteral("Épreuve de technique");
    const QVector<int> nums = drawFromThemes(themeIds(reg ? Themes::reglementation() : Themes::technique()), 20);
    p.count = nums.size();
    return begin(nums, QStringLiteral("official"), p.category, title,
                 QStringLiteral("20 questions en %1 minutes%2").arg(minutes).arg(adjusted), minutes * 60, false, {p});
}

bool ExamSession::startTraining(const QVariantList &themes, int questionCount, int minutes, bool instantCorrection)
{
    QList<int> ids;
    for (const QVariant &v : themes)
        ids << v.toInt();
    const QVector<int> nums = drawFromThemes(ids, qMax(1, questionCount));
    m_extended = false;
    const QString subtitle = QStringLiteral("%1 sur %2").arg(plural(nums.size(), QStringLiteral("question"), QStringLiteral("questions")),
                                                              plural(ids.size(), QStringLiteral("thème"), QStringLiteral("thèmes")));
    return begin(nums, QStringLiteral("training"), categoryOf(m_bank, nums), QStringLiteral("Entraînement par thèmes"), subtitle,
                 qMax(0, minutes) * 60, instantCorrection);
}

bool ExamSession::startSeries(const QString &name, bool timed, bool instantCorrection)
{
    const BankStore::Series *s = m_bank->findSeries(name);
    if (!s) {
        emit error(QStringLiteral("Série %1 introuvable.").arg(name));
        return false;
    }
    const QString cat = categoryOf(m_bank, s->questions);
    int minutes = 0;
    if (timed)
        minutes = cat == QLatin1String("reglementation") ? 15 : cat == QLatin1String("technique") ? 30 : 45;
    m_extended = false;
    const QString n = plural(s->questions.size(), QStringLiteral("question"), QStringLiteral("questions"));
    const QString subtitle = timed ? QStringLiteral("%1 en %2 minutes").arg(n).arg(minutes) : n;
    return begin(s->questions, QStringLiteral("series"), cat, QStringLiteral("Série %1").arg(name), subtitle, minutes * 60,
                 instantCorrection);
}

int ExamSession::reviewAvailable(const QString &source) const
{
    if (source == QLatin1String("saved")) {
        int n = 0;
        for (int num : m_user->savedNums())
            n += m_bank->find(num) ? 1 : 0;
        return n;
    }
    if (source == QLatin1String("wrong")) {
        int n = 0;
        for (int num : m_user->wrongNums())
            n += m_bank->find(num) ? 1 : 0;
        return n;
    }
    if (source == QLatin1String("unseen")) {
        const QSet<int> asked = m_user->askedNums();
        int n = 0;
        for (const Question &q : m_bank->questions())
            n += asked.contains(q.num) ? 0 : 1;
        return n;
    }
    return m_bank->questionCount();
}

bool ExamSession::startReview(const QString &source, int questionCount, bool instantCorrection)
{
    QVector<int> pool;
    QString title;
    if (source == QLatin1String("saved")) {
        pool = m_user->savedNums();
        title = QStringLiteral("Révision des questions enregistrées");
    } else if (source == QLatin1String("wrong")) {
        pool = m_user->wrongNums();
        title = QStringLiteral("Révision des erreurs");
    } else {
        const QSet<int> asked = m_user->askedNums();
        for (const Question &q : m_bank->questions())
            if (!asked.contains(q.num))
                pool << q.num;
        title = QStringLiteral("Questions jamais posées");
    }
    pool.erase(std::remove_if(pool.begin(), pool.end(), [this](int n) { return !m_bank->find(n); }), pool.end());
    const int n = questionCount > 0 ? qMin(questionCount, pool.size()) : pool.size();
    const QVector<int> nums = pick(pool, n);
    m_extended = false;
    return begin(nums, QStringLiteral("review"), categoryOf(m_bank, nums), title,
                 plural(nums.size(), QStringLiteral("question"), QStringLiteral("questions")), 0, instantCorrection);
}

// ---------------------------------------------------------------------------------------------
// Answering

void ExamSession::emitRow(int row)
{
    const QModelIndex i = index(row);
    emit dataChanged(i, i);
}

void ExamSession::select(int row, int option)
{
    if (m_finished || row < 0 || row >= m_items.size())
        return;
    Item &it = m_items[row];
    if (option < 0 || option >= it.order.size())
        return;
    if (m_instant) {
        if (it.revealed)
            return;
        it.mask = 1u << option;
        it.revealed = true;
    } else {
        it.mask ^= 1u << option; // check boxes, as on Evalbox
    }
    emitRow(row);
    emit progressChanged();
    scheduleSave();
}

void ExamSession::clearAnswer(int row)
{
    if (m_finished || row < 0 || row >= m_items.size())
        return;
    Item &it = m_items[row];
    if (it.revealed)
        return;
    it.mask = 0;
    emitRow(row);
    emit progressChanged();
    scheduleSave();
}

void ExamSession::togglePin(int row)
{
    if (m_finished || row < 0 || row >= m_items.size())
        return;
    m_items[row].pinned = !m_items[row].pinned;
    emitRow(row);
    emit progressChanged();
    scheduleSave();
}

void ExamSession::reveal(int row)
{
    if (m_finished || m_mode == QLatin1String("official") || row < 0 || row >= m_items.size())
        return;
    m_items[row].revealed = true;
    emitRow(row);
    scheduleSave();
}

void ExamSession::toggleSaved(int row)
{
    if (row < 0 || row >= m_items.size())
        return;
    m_user->toggleSaved(m_items.at(row).num);
}

int ExamSession::firstUnanswered() const
{
    for (int i = 0; i < m_items.size(); ++i)
        if (m_items.at(i).mask == 0)
            return i;
    return -1;
}

QVariantList ExamSession::pinnedRows() const
{
    QVariantList out;
    for (int i = 0; i < m_items.size(); ++i)
        if (m_items.at(i).pinned)
            out << i;
    return out;
}

QVariantList ExamSession::snapshot() const
{
    QVariantList out;
    const QHash<int, QByteArray> roles = roleNames();
    for (int r = 0; r < m_items.size(); ++r) {
        QVariantMap m;
        const QModelIndex i = index(r);
        for (auto it = roles.cbegin(); it != roles.cend(); ++it)
            m.insert(QString::fromLatin1(it.value()), data(i, it.key()));
        m.insert(QStringLiteral("index"), r);
        out << m;
    }
    return out;
}

int ExamSession::displayCorrect(const Item &it) const
{
    const Question *q = m_bank->find(it.num);
    if (!q)
        return -1;
    for (int i = 0; i < it.order.size(); ++i)
        if (it.order.at(i) == q->answer - 1)
            return i;
    return -1;
}

ExamSession::Status ExamSession::statusOf(const Item &it) const
{
    if (it.mask == 0)
        return Blank;
    const int c = displayCorrect(it);
    return (c >= 0 && it.mask == (1u << c)) ? Correct : Wrong;
}

void ExamSession::tick()
{
    if (m_finished || m_items.isEmpty()) {
        m_timer.stop();
        return;
    }
    emit clockChanged();
    if (++m_ticks % 30 == 0) // every 15 s, keep the remaining time on disk
        saveNow();
    if (m_duration > 0 && remainingSeconds() <= 0) {
        m_timeExpired = true;
        finalize();
        emit timeUp();
    }
}

void ExamSession::finalize()
{
    if (m_items.isEmpty() || m_finished)
        return;
    m_frozenElapsed = qMin(elapsedSeconds(), m_duration > 0 ? m_duration : INT_MAX);
    m_timer.stop();
    m_finished = true;
    computeAndStore();
    removeSaved();
    emit dataChanged(index(0), index(m_items.size() - 1));
    emit stateChanged();
    emit clockChanged();
    emit resultChanged();
}

void ExamSession::abandon()
{
    m_timer.stop();
    m_saveTimer.stop();
    removeSaved();
    beginResetModel();
    m_items.clear();
    m_parts.clear();
    m_finished = false;
    endResetModel();
    emit stateChanged();
    emit progressChanged();
}

void ExamSession::computeAndStore()
{
    m_scheme = m_settings->scheme();
    const bool legacy = m_scheme == QLatin1String("legacy");
    m_correct = m_wrong = m_blank = 0;
    m_score = m_maxScore = 0;
    std::map<int, QPair<int, int>> perTheme; // theme -> (correct, total), ordered by id

    for (Part &p : m_parts) {
        UserStore::ResultRecord rec;
        p.correct = p.wrong = p.blank = 0;
        for (int r = p.first; r < p.first + p.count && r < m_items.size(); ++r) {
            const Item &it = m_items.at(r);
            const Question *q = m_bank->find(it.num);
            const Status st = statusOf(it);
            if (st == Correct)
                ++p.correct;
            else if (st == Wrong)
                ++p.wrong;
            else
                ++p.blank;
            if (q) {
                auto &slot = perTheme[q->theme];
                slot.second += 1;
                if (st == Correct)
                    slot.first += 1;
                int chosen = 0;
                if (bitCount(it.mask) == 1)
                    chosen = it.order.at(lowestBit(it.mask)) + 1;
                else if (it.mask != 0)
                    chosen = -1; // several boxes ticked
                rec.answers.push_back({q->num, chosen, q->answer, it.pinned, it.order, it.mask});
            }
        }
        p.score = legacy ? 3 * p.correct - p.wrong : p.correct;
        p.maxScore = legacy ? 3 * p.count : p.count;
        p.passed = 2 * p.score >= p.maxScore;

        m_correct += p.correct;
        m_wrong += p.wrong;
        m_blank += p.blank;
        m_score += p.score;
        m_maxScore += p.maxScore;

        rec.mode = m_mode;
        rec.category = p.category;
        rec.title = m_parts.size() > 1 ? p.title + QStringLiteral(" (examen complet)") : m_title;
        rec.scheme = m_scheme;
        rec.total = p.count;
        rec.correct = p.correct;
        rec.wrong = p.wrong;
        rec.blank = p.blank;
        rec.score = p.score;
        rec.maxScore = p.maxScore;
        rec.passed = p.passed;
        rec.secondsUsed = m_frozenElapsed;
        rec.secondsAllowed = m_duration;
        rec.bankVersion = m_bank->version();
        rec.started = m_started.toString(Qt::ISODate);
        m_user->addResult(rec);
    }
    m_passed = std::all_of(m_parts.cbegin(), m_parts.cend(), [](const Part &p) { return p.passed; });

    m_breakdown.clear();
    for (const auto &kv : perTheme) {
        QVariantMap m;
        m.insert(QStringLiteral("themeId"), kv.first);
        m.insert(QStringLiteral("name"), Themes::name(kv.first));
        m.insert(QStringLiteral("correct"), kv.second.first);
        m.insert(QStringLiteral("total"), kv.second.second);
        m_breakdown << m;
    }
}

// ---------------------------------------------------------------------------------------------
// Autosave and resume ("dernière sauvegarde" on the Evalbox screen)

void ExamSession::scheduleSave()
{
    m_saveTimer.start();
}

QString ExamSession::lastSavedLabel() const
{
    return m_lastSaved.isValid() ? m_lastSaved.toString(QStringLiteral("HH:mm:ss")) : QString();
}

void ExamSession::saveNow()
{
    if (m_savePath.isEmpty() || m_items.isEmpty() || m_finished)
        return;
    QJsonObject o;
    o.insert(QStringLiteral("format"), 1);
    o.insert(QStringLiteral("candidate"), m_user->currentCandidate());
    o.insert(QStringLiteral("mode"), m_mode);
    o.insert(QStringLiteral("category"), m_category);
    o.insert(QStringLiteral("title"), m_title);
    o.insert(QStringLiteral("subtitle"), m_subtitle);
    o.insert(QStringLiteral("duration"), m_duration);
    o.insert(QStringLiteral("instant"), m_instant);
    o.insert(QStringLiteral("extended"), m_extended);
    o.insert(QStringLiteral("elapsed"), elapsedSeconds());
    o.insert(QStringLiteral("started"), m_started.toString(Qt::ISODate));
    o.insert(QStringLiteral("saved"), QDateTime::currentDateTime().toString(Qt::ISODate));
    QJsonArray parts;
    for (const Part &p : m_parts) {
        QJsonObject po;
        po.insert(QStringLiteral("category"), p.category);
        po.insert(QStringLiteral("title"), p.title);
        po.insert(QStringLiteral("first"), p.first);
        po.insert(QStringLiteral("count"), p.count);
        parts.append(po);
    }
    o.insert(QStringLiteral("parts"), parts);
    QJsonArray items;
    for (const Item &it : m_items) {
        QJsonObject io;
        io.insert(QStringLiteral("n"), it.num);
        QJsonArray order;
        for (int v : it.order)
            order.append(v);
        io.insert(QStringLiteral("o"), order);
        io.insert(QStringLiteral("m"), qint64(it.mask));
        io.insert(QStringLiteral("p"), it.pinned);
        io.insert(QStringLiteral("r"), it.revealed);
        items.append(io);
    }
    o.insert(QStringLiteral("items"), items);

    QSaveFile f(m_savePath);
    if (f.open(QIODevice::WriteOnly) && f.write(QJsonDocument(o).toJson(QJsonDocument::Compact)) > 0 && f.commit()) {
        m_lastSaved = QDateTime::currentDateTime();
        emit savedStateChanged();
    }
}

void ExamSession::removeSaved()
{
    m_saveTimer.stop();
    if (!m_savePath.isEmpty() && QFile::exists(m_savePath))
        QFile::remove(m_savePath);
    emit savedStateChanged();
}

bool ExamSession::hasSavedSession() const
{
    return !active() && !m_savePath.isEmpty() && QFile::exists(m_savePath) && !savedSessionInfo().isEmpty();
}

QVariantMap ExamSession::savedSessionInfo() const
{
    QVariantMap m;
    if (m_savePath.isEmpty())
        return m;
    QFile f(m_savePath);
    if (!f.open(QIODevice::ReadOnly))
        return m;
    const QJsonObject o = QJsonDocument::fromJson(f.readAll()).object();
    if (o.value(QStringLiteral("format")).toInt() != 1)
        return m;
    const QJsonArray items = o.value(QStringLiteral("items")).toArray();
    int answered = 0;
    for (const QJsonValue &v : items)
        answered += v.toObject().value(QStringLiteral("m")).toInteger() != 0 ? 1 : 0;
    const int duration = o.value(QStringLiteral("duration")).toInt();
    const int elapsed = o.value(QStringLiteral("elapsed")).toInt();
    m.insert(QStringLiteral("title"), o.value(QStringLiteral("title")).toString());
    m.insert(QStringLiteral("count"), items.size());
    m.insert(QStringLiteral("answered"), answered);
    m.insert(QStringLiteral("remaining"), duration > 0 ? qMax(0, duration - elapsed) : -1);
    m.insert(QStringLiteral("savedAt"), QDateTime::fromString(o.value(QStringLiteral("saved")).toString(), Qt::ISODate)
                                            .toString(QStringLiteral("dd/MM/yyyy HH:mm")));
    m.insert(QStringLiteral("candidate"), o.value(QStringLiteral("candidate")).toInt());
    return m;
}

bool ExamSession::resumeSaved()
{
    QFile f(m_savePath);
    if (m_savePath.isEmpty() || !f.open(QIODevice::ReadOnly))
        return false;
    const QJsonObject o = QJsonDocument::fromJson(f.readAll()).object();
    f.close();
    if (o.value(QStringLiteral("format")).toInt() != 1)
        return false;

    QVector<Item> items;
    for (const QJsonValue &v : o.value(QStringLiteral("items")).toArray()) {
        const QJsonObject io = v.toObject();
        Item it;
        it.num = io.value(QStringLiteral("n")).toInt();
        const Question *q = m_bank->find(it.num);
        if (!q) {
            emit error(QStringLiteral("L'épreuve sauvegardée utilise une question absente de la base actuelle : elle ne peut pas être reprise."));
            return false;
        }
        for (const QJsonValue &ov : io.value(QStringLiteral("o")).toArray())
            it.order << ov.toInt();
        if (it.order.size() != q->options.size()) {
            it.order.clear();
            for (int i = 0; i < q->options.size(); ++i)
                it.order << i;
        }
        it.mask = quint32(io.value(QStringLiteral("m")).toInteger());
        it.pinned = io.value(QStringLiteral("p")).toBool();
        it.revealed = io.value(QStringLiteral("r")).toBool();
        items << it;
    }
    if (items.isEmpty())
        return false;
    QVector<Part> parts;
    for (const QJsonValue &v : o.value(QStringLiteral("parts")).toArray()) {
        const QJsonObject po = v.toObject();
        Part p;
        p.category = po.value(QStringLiteral("category")).toString();
        p.title = po.value(QStringLiteral("title")).toString();
        p.first = po.value(QStringLiteral("first")).toInt();
        p.count = po.value(QStringLiteral("count")).toInt();
        parts << p;
    }

    const int candidate = o.value(QStringLiteral("candidate")).toInt();
    if (candidate > 0 && candidate != m_user->currentCandidate())
        m_user->setCurrentCandidate(candidate);

    m_timer.stop();
    beginResetModel();
    m_items = items;
    m_parts = parts;
    if (m_parts.isEmpty()) {
        Part p;
        p.category = o.value(QStringLiteral("category")).toString();
        p.title = o.value(QStringLiteral("title")).toString();
        p.count = m_items.size();
        m_parts << p;
    }
    m_mode = o.value(QStringLiteral("mode")).toString();
    m_category = o.value(QStringLiteral("category")).toString();
    m_title = o.value(QStringLiteral("title")).toString();
    m_subtitle = o.value(QStringLiteral("subtitle")).toString();
    m_duration = o.value(QStringLiteral("duration")).toInt();
    m_instant = o.value(QStringLiteral("instant")).toBool();
    m_extended = o.value(QStringLiteral("extended")).toBool();
    m_started = QDateTime::fromString(o.value(QStringLiteral("started")).toString(), Qt::ISODate);
    m_finished = false;
    m_timeExpired = false;
    m_breakdown.clear();
    m_score = m_maxScore = m_correct = m_wrong = m_blank = 0;
    m_passed = false;
    m_elapsedOffset = o.value(QStringLiteral("elapsed")).toInt();
    m_frozenElapsed = 0;
    m_clock.start();
    m_ticks = 0;
    endResetModel();
    m_timer.start();
    emit stateChanged();
    emit progressChanged();
    emit clockChanged();
    emit resultChanged();
    saveNow();
    return true;
}

void ExamSession::discardSaved()
{
    removeSaved();
}
