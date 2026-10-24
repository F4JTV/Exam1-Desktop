// Read access to the installed question bank (one directory with bank.sqlite + images).
// The whole bank (~3000 questions) is kept in memory for instant drawing and searching.
#pragma once

#include "question.h"

#include <QHash>
#include <QObject>
#include <QUrl>
#include <QVariantList>
#include <QVector>

class BankStore : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool ready READ ready NOTIFY changed)
    Q_PROPERTY(int questionCount READ questionCount NOTIFY changed)
    Q_PROPERTY(int seriesCount READ seriesCount NOTIFY changed)
    Q_PROPERTY(int imageCount READ imageCount NOTIFY changed)
    Q_PROPERTY(QString version READ version NOTIFY changed)
    Q_PROPERTY(QString versionLabel READ versionLabel NOTIFY changed)
    Q_PROPERTY(QString source READ source NOTIFY changed)
    Q_PROPERTY(QString importedAtLabel READ importedAtLabel NOTIFY changed)
    Q_PROPERTY(QVariantList technicalThemes READ technicalThemes NOTIFY changed)
    Q_PROPERTY(QVariantList regulationThemes READ regulationThemes NOTIFY changed)

public:
    explicit BankStore(const QString &banksRoot, QObject *parent = nullptr);

    bool ready() const { return !m_questions.isEmpty(); }
    int questionCount() const { return m_questions.size(); }
    int seriesCount() const { return m_series.size(); }
    int imageCount() const { return m_imageCount; }
    QString version() const { return m_version; }
    QString versionLabel() const;
    QString source() const { return m_source; }
    QString importedAtLabel() const;
    QVariantList technicalThemes() const;
    QVariantList regulationThemes() const;
    QString banksRoot() const { return m_banksRoot; }
    QString currentDir() const { return m_dir; }
    QString imagesDir() const;

    // Opens the bank referenced by the "current" pointer file. Returns false if none.
    bool openCurrent();
    // Makes bankDir the current bank, then removes older bank directories.
    bool switchTo(const QString &bankDir);

    const QVector<Question> &questions() const { return m_questions; }
    const Question *find(int num) const;
    QVector<int> numsForTheme(int theme) const { return m_byTheme.value(theme); }
    QVector<int> numsForCategory(int category) const; // Themes::Category
    QUrl imageUrl(const Question &q) const;

    struct Series {
        QString name;
        int num = 0;
        QString type;
        QVector<int> questions;
    };
    const Series *findSeries(const QString &name) const;

    Q_INVOKABLE QVariantList seriesList(const QString &type = QString()) const;
    Q_INVOKABLE QVariantMap question(int num) const;
    Q_INVOKABLE int themeCount(int theme) const { return m_byTheme.value(theme).size(); }
    Q_INVOKABLE QString themeName(int theme) const;

    static QString formatVersion(const QString &iso);

signals:
    void changed();

private:
    bool load(const QString &dir);
    QVariantList themeList(int category) const;

    QString m_banksRoot;
    QString m_dir;
    QVector<Question> m_questions;
    QHash<int, int> m_index;              // num -> position in m_questions
    QHash<int, QVector<int>> m_byTheme;   // theme -> nums
    QVector<Series> m_series;
    QString m_version;
    QString m_source;
    QString m_importedAt;
    int m_imageCount = 0;
};
