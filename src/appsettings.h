// User preferences, persisted with QSettings.
#pragma once

#include <QObject>
#include <QSettings>
#include <QVariantList>

class AppSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString scheme READ scheme WRITE setScheme NOTIFY changed)
    Q_PROPERTY(bool shuffleAnswers READ shuffleAnswers WRITE setShuffleAnswers NOTIFY changed)
    Q_PROPERTY(bool favorUnseen READ favorUnseen WRITE setFavorUnseen NOTIFY changed)
    Q_PROPERTY(bool extendedTime READ extendedTime WRITE setExtendedTime NOTIFY changed)
    Q_PROPERTY(QString colorScheme READ colorScheme WRITE setColorScheme NOTIFY changed)
    Q_PROPERTY(double textScale READ textScale WRITE setTextScale NOTIFY changed)
    Q_PROPERTY(bool autoCheckUpdates READ autoCheckUpdates WRITE setAutoCheckUpdates NOTIFY changed)
    Q_PROPERTY(QString updateBaseUrl READ updateBaseUrl WRITE setUpdateBaseUrl NOTIFY changed)
    Q_PROPERTY(bool showStatementText READ showStatementText WRITE setShowStatementText NOTIFY changed)
    Q_PROPERTY(QString statementMode READ statementMode WRITE setStatementMode NOTIFY changed)
    Q_PROPERTY(QString questionNumbers READ questionNumbers WRITE setQuestionNumbers NOTIFY changed)
    Q_PROPERTY(int trainingCount READ trainingCount WRITE setTrainingCount NOTIFY changed)
    Q_PROPERTY(int trainingMinutes READ trainingMinutes WRITE setTrainingMinutes NOTIFY changed)
    Q_PROPERTY(bool trainingInstant READ trainingInstant WRITE setTrainingInstant NOTIFY changed)
    Q_PROPERTY(QVariantList trainingThemes READ trainingThemes WRITE setTrainingThemes NOTIFY changed)

public:
    explicit AppSettings(QObject *parent = nullptr);

    static QString defaultUpdateBaseUrl();

    QString scheme() const;
    void setScheme(const QString &v);
    bool shuffleAnswers() const;
    void setShuffleAnswers(bool v);
    bool favorUnseen() const;
    void setFavorUnseen(bool v);
    bool extendedTime() const;
    void setExtendedTime(bool v);
    QString colorScheme() const;
    void setColorScheme(const QString &v);
    double textScale() const;
    void setTextScale(double v);
    bool autoCheckUpdates() const;
    void setAutoCheckUpdates(bool v);
    QString updateBaseUrl() const;
    void setUpdateBaseUrl(const QString &v);
    bool showStatementText() const;
    void setShowStatementText(bool v);
    QString statementMode() const;   // auto (picture only for diagrams, as on the ANFR exam) or image (always)
    void setStatementMode(const QString &v);
    // Bank number of each question ("20003") next to "Question 11 / 20", so that it can be noted
    // and worked on later: "training" (default: not in mock exams, as at the ANFR), "always", "never".
    QString questionNumbers() const;
    void setQuestionNumbers(const QString &v);
    int trainingCount() const;
    void setTrainingCount(int v);
    int trainingMinutes() const;
    void setTrainingMinutes(int v);
    bool trainingInstant() const;
    void setTrainingInstant(bool v);
    QVariantList trainingThemes() const;
    void setTrainingThemes(const QVariantList &v);

    Q_INVOKABLE void resetUpdateBaseUrl() { setUpdateBaseUrl(defaultUpdateBaseUrl()); }

signals:
    void changed();

private:
    void put(const QString &key, const QVariant &value);
    QSettings m_s;
};
