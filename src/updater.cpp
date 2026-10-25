#include "updater.h"

#include "appsettings.h"
#include "bankimporter.h"
#include "bankstore.h"
#include "miniz.h"

#include <cstring>

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QLocale>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QThread>
#include <QTimer>

namespace {
const QString kQuestions = QStringLiteral("questions.json");
const QString kSeries = QStringLiteral("series.json");
const QString kImages = QStringLiteral("questions.zip");

QString readVersion(const QString &questionsJson, int *count = nullptr)
{
    QFile f(questionsJson);
    if (!f.open(QIODevice::ReadOnly))
        return QString();
    QString version, error;
    int n = 0;
    if (!BankImporter::inspectQuestionsJson(f.readAll(), &version, &n, &error))
        return QString();
    if (count)
        *count = n;
    return version.isEmpty() ? QStringLiteral("0") : version;
}
} // namespace

Updater::Updater(BankStore *bank, AppSettings *settings, QObject *parent)
    : QObject(parent)
    , m_bank(bank)
    , m_settings(settings)
{
    m_seedDir = findSeedDir();
    if (!m_seedDir.isEmpty())
        m_seedVersion = readVersion(findInDir(m_seedDir, kQuestions));
}

Updater::~Updater()
{
    if (m_reply)
        m_reply->abort();
    if (m_thread && m_thread->isRunning())
        m_thread->wait();
}

QString Updater::findInDir(const QString &dir, const QString &name)
{
    const QFileInfoList files = QDir(dir).entryInfoList(QDir::Files);
    for (const QFileInfo &fi : files)
        if (fi.fileName().compare(name, Qt::CaseInsensitive) == 0)
            return fi.absoluteFilePath();
    return QString();
}

QString Updater::findSeedDir()
{
    QStringList candidates;
    const QString env = qEnvironmentVariable("EXAM1_DATA_DIR");
    if (!env.isEmpty())
        candidates << env;
    const QString appDir = QCoreApplication::applicationDirPath();
    candidates << QDir(appDir).filePath(QStringLiteral("data"))
               << QDir(appDir).filePath(QStringLiteral("../Resources/data"))    // macOS: Exam1.app/Contents/Resources
               << QDir(appDir).filePath(QStringLiteral("../share/exam1/data"))
               << QStringLiteral("/usr/share/exam1/data");
    for (const QString &c : candidates)
        if (!findInDir(c, kQuestions).isEmpty())
            return QDir(c).absolutePath();
    return QString();
}

QString Updater::remoteVersionLabel() const
{
    return BankStore::formatVersion(m_remoteVersion);
}

QString Updater::seedVersionLabel() const
{
    return BankStore::formatVersion(m_seedVersion);
}

bool Updater::updateAvailable() const
{
    if (m_remoteVersion.isEmpty())
        return false;
    return !m_bank->ready() || m_remoteVersion > m_bank->version();
}

QString Updater::lastCheckLabel() const
{
    if (!m_lastCheck.isValid())
        return QString();
    return QLocale(QLocale::French, QLocale::France).toString(m_lastCheck, QStringLiteral("d MMMM yyyy 'à' HH:mm"));
}

void Updater::setState(State s, const QString &error)
{
    m_state = s;
    m_error = error;
    emit stateChanged();
}

void Updater::setProgress(double p, const QString &status)
{
    m_progress = qBound(0.0, p, 1.0);
    m_status = status;
    emit progressChanged();
}

void Updater::acknowledge()
{
    if (!busy())
        setState(Idle);
}

void Updater::autoStart()
{
    const bool haveBank = m_bank->ready() || m_bank->openCurrent();
    if (!m_seedVersion.isEmpty() && (!haveBank || m_seedVersion > m_bank->version())) {
        m_checkAfterInstall = m_settings->autoCheckUpdates();
        installSeed();
        return;
    }
    if (m_settings->autoCheckUpdates())
        QTimer::singleShot(1500, this, [this] { checkForUpdate(true); });
}

void Updater::installSeed()
{
    if (busy() || m_seedDir.isEmpty())
        return;
    QString imagesDir;
    if (QFileInfo(QDir(m_seedDir).filePath(QStringLiteral("images"))).isDir())
        imagesDir = QDir(m_seedDir).filePath(QStringLiteral("images"));
    startImport(findInDir(m_seedDir, kQuestions), findInDir(m_seedDir, kSeries), findInDir(m_seedDir, kImages), imagesDir,
                QStringLiteral("Base fournie avec le logiciel"), 0.0);
}

void Updater::checkForUpdate(bool silent)
{
    if (busy())
        return;
    m_silent = silent;
    startDownloads({{kQuestions, 0.0, 1.0, false}}, true);
}

void Updater::installUpdate()
{
    if (busy())
        return;
    m_silent = false;
    QList<Download> list;
    if (m_checkedJson.isEmpty() || !QFileInfo::exists(m_checkedJson))
        list << Download{kQuestions, 0.0, 0.06, false};
    list << Download{kSeries, 0.06, 0.08, true} << Download{kImages, 0.08, 0.80, false};
    startDownloads(list, false);
}

void Updater::startDownloads(const QList<Download> &list, bool checkOnly)
{
    m_checkOnly = checkOnly;
    if (!m_tmp || !m_tmp->isValid()) {
        m_tmp = std::make_unique<QTemporaryDir>();
        m_checkedJson.clear();
    }
    if (!m_tmp->isValid()) {
        setState(Failed, QStringLiteral("Impossible de créer un dossier temporaire."));
        return;
    }
    m_queue = list;
    setState(checkOnly ? Checking : Downloading);
    downloadNext();
}

void Updater::downloadNext()
{
    if (m_queue.isEmpty()) {
        if (m_checkOnly) {
            finishCheck();
        } else {
            const QString q = m_checkedJson.isEmpty() ? m_tmp->filePath(kQuestions) : m_checkedJson;
            const QString s = QFileInfo::exists(m_tmp->filePath(kSeries)) ? m_tmp->filePath(kSeries) : QString();
            startImport(q, s, m_tmp->filePath(kImages), QString(),
                        QStringLiteral("REF %1").arg(QUrl(m_settings->updateBaseUrl()).host()), 0.80);
        }
        return;
    }
    m_current = m_queue.takeFirst();
    const QUrl url = QUrl(m_settings->updateBaseUrl()).resolved(QUrl(m_current.file));
    m_file = std::make_unique<QFile>(m_tmp->filePath(m_current.file));
    if (!m_file->open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        setState(Failed, QStringLiteral("Écriture impossible : %1").arg(m_file->errorString()));
        return;
    }
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("Exam1-Qt/%1").arg(QCoreApplication::applicationVersion()));
    req.setTransferTimeout(30000);
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    m_reply = m_nam.get(req);
    setProgress(m_current.from, QStringLiteral("Téléchargement de %1").arg(m_current.file));
    connect(m_reply, &QNetworkReply::readyRead, this, [this] {
        if (m_reply && m_file)
            m_file->write(m_reply->readAll());
    });
    connect(m_reply, &QNetworkReply::downloadProgress, this, [this](qint64 rec, qint64 total) {
        if (total > 0) {
            const double f = m_current.from + (m_current.to - m_current.from) * double(rec) / double(total);
            setProgress(f, QStringLiteral("Téléchargement de %1 (%2 Mo / %3 Mo)")
                               .arg(m_current.file)
                               .arg(rec / 1048576.0, 0, 'f', 1)
                               .arg(total / 1048576.0, 0, 'f', 1));
        }
    });
    connect(m_reply, &QNetworkReply::finished, this, &Updater::onDownloadFinished);
}

void Updater::onDownloadFinished()
{
    QNetworkReply *reply = m_reply;
    if (!reply)
        return;
    reply->deleteLater();
    m_reply = nullptr;
    if (m_file) {
        m_file->write(reply->readAll());
        m_file->close();
    }
    const int http = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    if (reply->error() != QNetworkReply::NoError || http != 200) {
        const QString reason = reply->error() == QNetworkReply::OperationCanceledError
            ? QStringLiteral("Téléchargement annulé.")
            : QStringLiteral("Échec du téléchargement de %1 : %2").arg(m_current.file, http ? QStringLiteral("HTTP %1").arg(http) : reply->errorString());
        if (m_current.optional && reply->error() != QNetworkReply::OperationCanceledError) {
            QFile::remove(m_tmp->filePath(m_current.file));
            downloadNext();
            return;
        }
        m_queue.clear();
        if (m_checkOnly && m_silent) {
            m_error = reason;
            setState(Idle, reason);
        } else {
            setState(Failed, reason);
        }
        return;
    }
    if (m_current.file == kQuestions)
        m_checkedJson = m_tmp->filePath(kQuestions);
    downloadNext();
}

void Updater::finishCheck()
{
    m_lastCheck = QDateTime::currentDateTime();
    int count = 0;
    const QString version = readVersion(m_checkedJson, &count);
    if (version.isEmpty()) {
        m_checkedJson.clear();
        const QString err = QStringLiteral("Le fichier publié n'est pas une base de questions valide.");
        setState(m_silent ? Idle : Failed, err);
        return;
    }
    m_remoteVersion = version;
    m_remoteCount = count;
    setProgress(1.0, QString());
    setState(updateAvailable() ? Idle : (m_silent ? Idle : UpToDate));
}

void Updater::importLocal(const QUrl &location)
{
    if (busy())
        return;
    QString path = location.isLocalFile() ? location.toLocalFile() : location.toString();
    QFileInfo fi(path);
    const QString origin = QDir::toNativeSeparators(fi.absoluteFilePath());
    QString dir = fi.isDir() ? fi.absoluteFilePath() : fi.absolutePath();

    // A single archive holding questions.json (+ series.json, questions.zip or images) is accepted too.
    if (fi.isFile() && fi.suffix().compare(QLatin1String("zip"), Qt::CaseInsensitive) == 0 && findInDir(dir, kQuestions).isEmpty()) {
        m_tmp = std::make_unique<QTemporaryDir>();
        QFile zf(path);
        if (!zf.open(QIODevice::ReadOnly)) {
            setState(Failed, QStringLiteral("Lecture impossible : %1").arg(zf.errorString()));
            return;
        }
        const QByteArray data = zf.readAll();
        mz_zip_archive zip;
        memset(&zip, 0, sizeof(zip));
        if (!mz_zip_reader_init_mem(&zip, data.constData(), size_t(data.size()), 0)) {
            setState(Failed, QStringLiteral("Archive ZIP illisible."));
            return;
        }
        QDir out(m_tmp->path());
        out.mkpath(QStringLiteral("images"));
        for (mz_uint i = 0; i < mz_zip_reader_get_num_files(&zip); ++i) {
            mz_zip_archive_file_stat st;
            if (!mz_zip_reader_file_stat(&zip, i, &st) || st.m_is_directory)
                continue;
            const QString name = QFileInfo(QString::fromUtf8(st.m_filename)).fileName();
            const QString lower = name.toLower();
            const bool known = lower == kQuestions || lower == kSeries || lower == kImages;
            const QString target = known ? out.filePath(lower) : out.filePath(QStringLiteral("images/") + name);
            if (!known && !QStringList{QStringLiteral("png"), QStringLiteral("jpg"), QStringLiteral("jpeg"), QStringLiteral("gif")}
                               .contains(QFileInfo(name).suffix().toLower()))
                continue;
            size_t size = 0;
            void *p = mz_zip_reader_extract_to_heap(&zip, i, &size, 0);
            if (p) {
                QFile f(target);
                if (f.open(QIODevice::WriteOnly))
                    f.write(static_cast<const char *>(p), qint64(size));
                mz_free(p);
            }
        }
        mz_zip_reader_end(&zip);
        if (findInDir(out.path(), kQuestions).isEmpty()) {
            if (QDir(out.filePath(QStringLiteral("images"))).isEmpty())
                setState(Failed, QStringLiteral("Cette archive ne contient pas de fichier questions.json."));
            else
                setState(Failed, QStringLiteral("Cette archive ne contient que des images : choisissez le dossier contenant questions.json."));
            return;
        }
        dir = out.path();
    }

    const QString questions = findInDir(dir, kQuestions);
    if (questions.isEmpty()) {
        setState(Failed, QStringLiteral("Aucun fichier questions.json dans %1.").arg(QDir::toNativeSeparators(dir)));
        return;
    }
    QString imagesDir;
    if (QFileInfo(QDir(dir).filePath(QStringLiteral("images"))).isDir())
        imagesDir = QDir(dir).filePath(QStringLiteral("images"));
    startImport(questions, findInDir(dir, kSeries), findInDir(dir, kImages), imagesDir,
                QStringLiteral("Import local (%1)").arg(origin), 0.0);
}

void Updater::startImport(const QString &questions, const QString &series, const QString &zip, const QString &imagesDir,
                          const QString &label, double from)
{
    ImportSource src;
    src.questionsJson = questions;
    src.seriesJson = series;
    src.imagesZip = QFileInfo::exists(zip) ? zip : QString();
    src.imagesDir = imagesDir;
    src.fallbackImagesDir = m_bank->imagesDir();
    src.label = label;
    const QString root = m_bank->banksRoot();

    setState(Installing);
    setProgress(from, QStringLiteral("Installation de la base"));

    auto result = std::make_shared<ImportResult>();
    QPointer<Updater> self(this);
    QThread *thread = QThread::create([src, root, from, result, self] {
        *result = BankImporter::run(src, root, [from, self](double f, const QString &step) {
            QMetaObject::invokeMethod(
                self.data(), [self, from, f, step] {
                    if (self)
                        self->setProgress(from + (1.0 - from) * f, step);
                },
                Qt::QueuedConnection);
        });
    });
    connect(thread, &QThread::finished, this, [this, thread, result] {
        thread->deleteLater();
        m_thread = nullptr;
        m_tmp.reset();
        m_checkedJson.clear();
        if (!result->ok) {
            setState(Failed, result->error);
            return;
        }
        if (!m_bank->switchTo(result->bankDir)) {
            setState(Failed, QStringLiteral("La nouvelle base a été créée mais ne peut pas être ouverte."));
            return;
        }
        setProgress(1.0, QStringLiteral("%1 questions, %2 images, %3 séries installées")
                             .arg(result->questions)
                             .arg(result->images)
                             .arg(result->series));
        setState(Installed);
        emit bankInstalled();
        if (m_checkAfterInstall) {
            m_checkAfterInstall = false;
            QTimer::singleShot(1500, this, [this] { checkForUpdate(true); });
        }
    });
    m_thread = thread;
    thread->start();
}

void Updater::cancel()
{
    m_queue.clear();
    if (m_reply)
        m_reply->abort();
}
