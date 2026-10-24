#include "browsermodel.h"

#include "bankstore.h"
#include "themes.h"
#include "userstore.h"

#include <QSet>

BrowserModel::BrowserModel(BankStore *bank, UserStore *user, QObject *parent)
    : QAbstractListModel(parent)
    , m_bank(bank)
    , m_user(user)
{
    connect(m_bank, &BankStore::changed, this, [this] {
        rebuildIndex();
        rebuild();
    });
    connect(m_user, &UserStore::savedChanged, this, [this] {
        if (m_savedOnly)
            rebuild();
        else if (!m_rows.isEmpty())
            emit dataChanged(index(0), index(m_rows.size() - 1), {SavedRole});
    });
    connect(m_user, &UserStore::currentCandidateChanged, this, &BrowserModel::rebuild);
    rebuildIndex();
    rebuild();
}

QString BrowserModel::fold(const QString &s)
{
    const QString d = s.normalized(QString::NormalizationForm_D);
    QString out;
    out.reserve(d.size());
    for (const QChar c : d) {
        if (c.category() == QChar::Mark_NonSpacing)
            continue;
        out.append(c.toLower());
    }
    return out;
}

void BrowserModel::rebuildIndex()
{
    m_haystack.clear();
    const QVector<Question> &qs = m_bank->questions();
    m_haystack.reserve(qs.size());
    for (const Question &q : qs)
        m_haystack << fold(q.ref + QLatin1Char(' ') + q.text + QLatin1Char(' ') + q.options.join(QLatin1Char(' ')) + QLatin1Char(' ') + q.comment);
}

void BrowserModel::rebuild()
{
    const QVector<Question> &qs = m_bank->questions();
    const QStringList terms = fold(m_search).split(QLatin1Char(' '), Qt::SkipEmptyParts);
    QSet<int> wrong;
    if (m_wrongOnly) {
        const QVector<int> w = m_user->wrongNums();
        wrong = QSet<int>(w.cbegin(), w.cend());
    }
    QVector<int> rows;
    for (int i = 0; i < qs.size(); ++i) {
        const Question &q = qs.at(i);
        if (m_theme == 2 || m_theme == 3) {
            if (Themes::category(q.theme) != m_theme)
                continue;
        } else if (m_theme > 0 && q.theme != m_theme) {
            continue;
        }
        if (m_savedOnly && !m_user->isSaved(q.num))
            continue;
        if (m_wrongOnly && !wrong.contains(q.num))
            continue;
        bool match = true;
        for (const QString &t : terms) {
            if (!m_haystack.value(i).contains(t)) {
                match = false;
                break;
            }
        }
        if (match)
            rows << i;
    }
    beginResetModel();
    m_rows = rows;
    endResetModel();
    emit countChanged();
}

void BrowserModel::setSearch(const QString &s)
{
    if (s == m_search)
        return;
    m_search = s;
    rebuild();
    emit filterChanged();
}

void BrowserModel::setTheme(int t)
{
    if (t == m_theme)
        return;
    m_theme = t;
    rebuild();
    emit filterChanged();
}

void BrowserModel::setSavedOnly(bool v)
{
    if (v == m_savedOnly)
        return;
    m_savedOnly = v;
    rebuild();
    emit filterChanged();
}

void BrowserModel::setWrongOnly(bool v)
{
    if (v == m_wrongOnly)
        return;
    m_wrongOnly = v;
    rebuild();
    emit filterChanged();
}

int BrowserModel::rowOfNum(int num) const
{
    const QVector<Question> &qs = m_bank->questions();
    for (int r = 0; r < m_rows.size(); ++r)
        if (qs.at(m_rows.at(r)).num == num)
            return r;
    return -1;
}

int BrowserModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_rows.size();
}

QHash<int, QByteArray> BrowserModel::roleNames() const
{
    return {
        {NumRole, "num"}, {RefRole, "ref"}, {TextRole, "statement"}, {ImageRole, "image"},
        {OptionsRole, "options"}, {AnswerRole, "answer"}, {ThemeIdRole, "themeId"}, {ThemeNameRole, "themeName"},
        {CommentRole, "comment"}, {CourseRole, "course"}, {SavedRole, "saved"}, {TextOnlyRole, "textOnly"},
    };
}

QVariant BrowserModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_rows.size())
        return {};
    const QVector<Question> &qs = m_bank->questions();
    const int pos = m_rows.at(index.row());
    if (pos < 0 || pos >= qs.size())
        return {};
    const Question &q = qs.at(pos);
    switch (role) {
    case NumRole: return q.num;
    case RefRole: return q.ref;
    case TextRole: return q.displayText;
    case TextOnlyRole: return q.textOnly;
    case ImageRole: return m_bank->imageUrl(q);
    case OptionsRole: return q.options;
    case AnswerRole: return q.answer - 1;
    case ThemeIdRole: return q.theme;
    case ThemeNameRole: return Themes::name(q.theme);
    case CommentRole: return q.comment;
    case CourseRole: return q.course;
    case SavedRole: return m_user->isSaved(q.num);
    default: return {};
    }
}
