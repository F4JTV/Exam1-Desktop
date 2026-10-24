// Keeps the question bank current with the files published by the REF for the Exam'1
// web and Android versions (updated every quarter with F6GPX's new questions).
// Also installs the bank bundled with the installer and imports local files (offline PCs).
#pragma once

#include <QDateTime>
#include <QFile>
#include <QNetworkAccessManager>
#include <QObject>
#include <QPointer>
#include <QTemporaryDir>
#include <QUrl>
#include <memory>

class BankStore;
class AppSettings;
class QNetworkReply;
class QThread;

class Updater : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int state READ state NOTIFY stateChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY stateChanged)
    Q_PROPERTY(double progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString status READ status NOTIFY progressChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY stateChanged)
    Q_PROPERTY(QString remoteVersion READ remoteVersion NOTIFY stateChanged)
    Q_PROPERTY(QString remoteVersionLabel READ remoteVersionLabel NOTIFY stateChanged)
    Q_PROPERTY(int remoteCount READ remoteCount NOTIFY stateChanged)
    Q_PROPERTY(bool updateAvailable READ updateAvailable NOTIFY stateChanged)
    Q_PROPERTY(QString lastCheckLabel READ lastCheckLabel NOTIFY stateChanged)
    Q_PROPERTY(bool seedAvailable READ seedAvailable CONSTANT)
    Q_PROPERTY(QString seedVersionLabel READ seedVersionLabel CONSTANT)

public:
    enum State { Idle, Checking, Downloading, Installing, Failed, Installed, UpToDate };
    Q_ENUM(State)

    Updater(BankStore *bank, AppSettings *settings, QObject *parent = nullptr);
    ~Updater() override;

    int state() const { return m_state; }
    bool busy() const { return m_state == Checking || m_state == Downloading || m_state == Installing; }
    double progress() const { return m_progress; }
    QString status() const { return m_status; }
    QString lastError() const { return m_error; }
    QString remoteVersion() const { return m_remoteVersion; }
    QString remoteVersionLabel() const;
    int remoteCount() const { return m_remoteCount; }
    bool updateAvailable() const;
    QString lastCheckLabel() const;
    bool seedAvailable() const { return !m_seedDir.isEmpty(); }
    QString seedVersionLabel() const;

    // Startup: installs the bundled bank when needed, then checks online if enabled.
    void autoStart();

    Q_INVOKABLE void checkForUpdate(bool silent = false);
    Q_INVOKABLE void installUpdate();
    Q_INVOKABLE void importLocal(const QUrl &location);
    Q_INVOKABLE void installSeed();
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void acknowledge(); // back to Idle after a final state was displayed

signals:
    void stateChanged();
    void progressChanged();
    void bankInstalled();

private:
    struct Download {
        QString file;
        double from;
        double to;
        bool optional;
    };

    void setState(State s, const QString &error = QString());
    void setProgress(double p, const QString &status);
    void startDownloads(const QList<Download> &list, bool checkOnly);
    void downloadNext();
    void onDownloadFinished();
    void finishCheck();
    void startImport(const QString &questions, const QString &series, const QString &zip, const QString &imagesDir,
                     const QString &label, double from);
    static QString findSeedDir();
    static QString findInDir(const QString &dir, const QString &name);

    BankStore *m_bank;
    AppSettings *m_settings;
    QNetworkAccessManager m_nam;
    State m_state = Idle;
    double m_progress = 0;
    QString m_status;
    QString m_error;
    QString m_remoteVersion;
    int m_remoteCount = 0;
    QDateTime m_lastCheck;
    bool m_silent = false;
    bool m_checkOnly = false;

    std::unique_ptr<QTemporaryDir> m_tmp;
    QList<Download> m_queue;
    Download m_current{};
    QPointer<QNetworkReply> m_reply;
    std::unique_ptr<QFile> m_file;
    QString m_checkedJson; // questions.json downloaded by the last check, reused by install

    QString m_seedDir;
    QString m_seedVersion;
    bool m_checkAfterInstall = false;
    QPointer<QThread> m_thread;
};
