// Filterable list of the whole question bank ("Base de questions" page).
#pragma once

#include <QAbstractListModel>
#include <QVector>

class BankStore;
class UserStore;

class BrowserModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString search READ search WRITE setSearch NOTIFY filterChanged)
    Q_PROPERTY(int theme READ theme WRITE setTheme NOTIFY filterChanged)          // 0 = all, 2 = technique, 3 = regulation, else theme id
    Q_PROPERTY(bool savedOnly READ savedOnly WRITE setSavedOnly NOTIFY filterChanged)
    Q_PROPERTY(bool wrongOnly READ wrongOnly WRITE setWrongOnly NOTIFY filterChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        NumRole = Qt::UserRole + 1,
        RefRole,
        TextRole,
        ImageRole,
        OptionsRole,
        AnswerRole,
        ThemeIdRole,
        ThemeNameRole,
        CommentRole,
        CourseRole,
        SavedRole,
        TextOnlyRole,
    };

    BrowserModel(BankStore *bank, UserStore *user, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString search() const { return m_search; }
    void setSearch(const QString &s);
    int theme() const { return m_theme; }
    void setTheme(int t);
    bool savedOnly() const { return m_savedOnly; }
    void setSavedOnly(bool v);
    bool wrongOnly() const { return m_wrongOnly; }
    void setWrongOnly(bool v);
    int count() const { return m_rows.size(); }

    Q_INVOKABLE int rowOfNum(int num) const;
    Q_INVOKABLE void refresh() { rebuild(); }

    static QString fold(const QString &s); // lower case, accents removed

signals:
    void filterChanged();
    void countChanged();

private:
    void rebuild();
    void rebuildIndex();

    BankStore *m_bank;
    UserStore *m_user;
    QString m_search;
    int m_theme = 0;
    bool m_savedOnly = false;
    bool m_wrongOnly = false;
    QVector<int> m_rows;          // positions in bank->questions()
    QVector<QString> m_haystack;  // folded searchable text, same order as bank->questions()
};
