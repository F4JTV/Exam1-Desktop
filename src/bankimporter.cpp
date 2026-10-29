#include "bankimporter.h"

#include "miniz.h"
#include "statement.h"

#include <algorithm>
#include <cstring>
#include <optional>

#include <QDateTime>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QImage>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QUuid>

namespace {

const QStringList kImageSuffixes = {QStringLiteral("png"), QStringLiteral("jpg"), QStringLiteral("jpeg"),
                                    QStringLiteral("gif"), QStringLiteral("bmp"), QStringLiteral("webp")};

int jsonInt(const QJsonValue &v, int fallback = 0)
{
    if (v.isDouble())
        return v.toInt(fallback);
    if (v.isString()) {
        bool ok = false;
        const int n = v.toString().trimmed().toInt(&ok);
        return ok ? n : fallback;
    }
    return fallback;
}

QString jsonText(const QJsonValue &v)
{
    if (v.isString())
        return v.toString().trimmed();
    if (v.isDouble())
        return QString::number(v.toDouble());
    return QString();
}

bool readFile(const QString &path, QByteArray *out, QString *error)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        if (error)
            *error = QStringLiteral("Impossible de lire %1 : %2").arg(QDir::toNativeSeparators(path), f.errorString());
        return false;
    }
    *out = f.readAll();
    return true;
}

// Normalises an image file name: "images/00037.PNG" -> "37.png" (key = numeric value).
QString normalisedImageName(const QString &entryName, int *key)
{
    const QFileInfo fi(entryName);
    const QString suffix = fi.suffix().toLower();
    if (!kImageSuffixes.contains(suffix))
        return QString();
    const QString stem = fi.completeBaseName();
    static const QRegularExpression digits(QStringLiteral("^\\d{1,7}$"));
    if (!digits.match(stem).hasMatch())
        return QString();
    *key = stem.toInt();
    return QString::number(*key) + QLatin1Char('.') + suffix;
}

struct ParsedQuestion {
    int num;
    QString ref;
    QString text;
    QString displayText;
    bool textOnly = false;
    QStringList options;
    int answer;
    int theme;
    QString comment;
    QString course;
    std::optional<bool> needsPicture; // "imageNecessaire" field, when the file has it
};

} // namespace

namespace BankImporter {

QString databaseFileName() { return QStringLiteral("bank.sqlite"); }
QString imagesFolderName() { return QStringLiteral("images"); }

bool inspectQuestionsJson(const QByteArray &data, QString *version, int *count, QString *error)
{
    QJsonParseError pe;
    const QJsonDocument doc = QJsonDocument::fromJson(data, &pe);
    if (pe.error != QJsonParseError::NoError || !doc.isObject()) {
        if (error)
            *error = QStringLiteral("Fichier de questions illisible (JSON invalide : %1).").arg(pe.errorString());
        return false;
    }
    const QJsonObject root = doc.object();
    const QJsonArray list = root.value(QStringLiteral("questions")).toArray();
    if (list.isEmpty()) {
        if (error)
            *error = QStringLiteral("Le fichier ne contient aucune question.");
        return false;
    }
    if (version)
        *version = root.value(QStringLiteral("version")).toString();
    if (count)
        *count = list.size();
    return true;
}

ImportResult run(const ImportSource &source, const QString &banksRoot, const Progress &progress)
{
    ImportResult result;
    auto report = [&](double f, const QString &step) {
        if (progress)
            progress(f, step);
    };

    // 1. Parse questions -----------------------------------------------------
    report(0.0, QStringLiteral("Lecture des questions"));
    QByteArray raw;
    if (!readFile(source.questionsJson, &raw, &result.error))
        return result;

    QJsonParseError pe;
    const QJsonDocument qdoc = QJsonDocument::fromJson(raw, &pe);
    if (pe.error != QJsonParseError::NoError || !qdoc.isObject()) {
        result.error = QStringLiteral("questions.json est invalide : %1").arg(pe.errorString());
        return result;
    }
    const QJsonObject qroot = qdoc.object();
    result.version = qroot.value(QStringLiteral("version")).toString();

    QVector<ParsedQuestion> parsed;
    int skipped = 0;
    const QJsonArray qarr = qroot.value(QStringLiteral("questions")).toArray();
    parsed.reserve(qarr.size());
    for (const QJsonValue &v : qarr) {
        const QJsonObject o = v.toObject();
        ParsedQuestion q;
        const QJsonValue numValue = o.value(QStringLiteral("num"));
        q.num = jsonInt(numValue, -1);
        q.ref = numValue.isString() ? numValue.toString().trimmed()
                                    : QStringLiteral("%1").arg(q.num, 5, 10, QLatin1Char('0'));
        q.text = jsonText(o.value(QStringLiteral("question")));
        for (const QJsonValue &p : o.value(QStringLiteral("propositions")).toArray())
            q.options << jsonText(p);
        q.answer = jsonInt(o.value(QStringLiteral("reponse")));
        q.theme = jsonInt(o.value(QStringLiteral("themeNum")));
        q.comment = jsonText(o.value(QStringLiteral("commentaire")));
        q.course = jsonText(o.value(QStringLiteral("cours")));
        const QJsonValue mark = o.value(QStringLiteral("imageNecessaire"));
        if (mark.isBool())
            q.needsPicture = mark.toBool();
        if (q.num < 0 || q.options.size() < 2) {
            ++skipped;
            continue;
        }
        parsed.push_back(q);
    }

    // The REF files number the correct proposition from 0. Accept 1-based files too: they
    // never contain 0 and do contain the last position.
    int zeros = 0, lastPos = 0;
    for (const ParsedQuestion &q : parsed) {
        zeros += q.answer == 0 ? 1 : 0;
        lastPos += q.answer == q.options.size() ? 1 : 0;
    }
    const bool zeroBased = zeros > 0 || lastPos == 0;
    QVector<ParsedQuestion> valid;
    valid.reserve(parsed.size());
    for (ParsedQuestion q : parsed) {
        if (zeroBased)
            q.answer += 1; // stored 1-based internally
        if (q.answer < 1 || q.answer > q.options.size()) {
            ++skipped;
            continue;
        }
        valid.push_back(q);
    }
    parsed = valid;
    if (parsed.isEmpty()) {
        result.error = QStringLiteral("Aucune question exploitable dans questions.json.");
        return result;
    }
    report(0.08, QStringLiteral("Lecture des séries"));

    // 2. Parse series (optional) -------------------------------------------------
    struct ParsedSeries {
        QString name;
        int num;
        QString type;
        QVector<int> questions;
    };
    QVector<ParsedSeries> series;
    QString seriesVersion;
    if (!source.seriesJson.isEmpty() && QFileInfo::exists(source.seriesJson)) {
        QByteArray sraw;
        if (!readFile(source.seriesJson, &sraw, &result.error))
            return result;
        const QJsonDocument sdoc = QJsonDocument::fromJson(sraw, &pe);
        if (pe.error != QJsonParseError::NoError || !sdoc.isObject()) {
            result.error = QStringLiteral("series.json est invalide : %1").arg(pe.errorString());
            return result;
        }
        seriesVersion = sdoc.object().value(QStringLiteral("version")).toString();
        for (const QJsonValue &v : sdoc.object().value(QStringLiteral("series")).toArray()) {
            const QJsonObject o = v.toObject();
            ParsedSeries s;
            s.name = jsonText(o.value(QStringLiteral("nom")));
            s.num = jsonInt(o.value(QStringLiteral("num")));
            s.type = jsonText(o.value(QStringLiteral("type")));
            for (const QJsonValue &n : o.value(QStringLiteral("questions")).toArray())
                s.questions << jsonInt(n, -1);
            if (!s.name.isEmpty() && !s.questions.isEmpty())
                series.push_back(s);
        }
    }

    // 3. Create the new bank directory -------------------------------------------
    QDir root(banksRoot);
    if (!root.mkpath(QStringLiteral("."))) {
        result.error = QStringLiteral("Impossible de créer le dossier %1").arg(QDir::toNativeSeparators(banksRoot));
        return result;
    }
    const QString dirName = QStringLiteral("bank-%1").arg(QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-HHmmss-zzz")));
    const QString bankDir = root.filePath(dirName);
    QDir bdir(bankDir);
    if (!bdir.mkpath(imagesFolderName())) {
        result.error = QStringLiteral("Impossible de créer le dossier %1").arg(QDir::toNativeSeparators(bankDir));
        return result;
    }
    auto fail = [&](const QString &msg) {
        result.ok = false;
        result.error = msg;
        QDir(bankDir).removeRecursively();
        return result;
    };

    // 4. Images -------------------------------------------------------------------
    QHash<int, QString> imageByNum;
    const QString imagesOut = bdir.filePath(imagesFolderName());
    auto storeImage = [&](const QString &entryName, const QByteArray &bytes) -> bool {
        int key = -1;
        const QString name = normalisedImageName(entryName, &key);
        if (name.isEmpty())
            return true; // not a question image: ignored
        QFile out(QDir(imagesOut).filePath(name));
        if (!out.open(QIODevice::WriteOnly) || out.write(bytes) != bytes.size())
            return false;
        // Prefer PNG when the same question has several images.
        if (!imageByNum.contains(key) || name.endsWith(QLatin1String(".png")))
            imageByNum.insert(key, name);
        return true;
    };

    report(0.12, QStringLiteral("Extraction des images"));
    if (!source.imagesZip.isEmpty() && QFileInfo::exists(source.imagesZip)) {
        QByteArray zipData;
        if (!readFile(source.imagesZip, &zipData, &result.error))
            return fail(result.error);
        mz_zip_archive zip;
        memset(&zip, 0, sizeof(zip));
        if (!mz_zip_reader_init_mem(&zip, zipData.constData(), static_cast<size_t>(zipData.size()), 0))
            return fail(QStringLiteral("L'archive d'images est illisible (%1).")
                            .arg(QString::fromLatin1(mz_zip_get_error_string(mz_zip_get_last_error(&zip)))));
        const mz_uint n = mz_zip_reader_get_num_files(&zip);
        for (mz_uint i = 0; i < n; ++i) {
            mz_zip_archive_file_stat st;
            if (!mz_zip_reader_file_stat(&zip, i, &st) || st.m_is_directory)
                continue;
            const QString entryName = QString::fromUtf8(st.m_filename);
            int dummy = 0;
            if (normalisedImageName(entryName, &dummy).isEmpty())
                continue;
            size_t size = 0;
            void *p = mz_zip_reader_extract_to_heap(&zip, i, &size, 0);
            if (!p) {
                mz_zip_reader_end(&zip);
                return fail(QStringLiteral("Image corrompue dans l'archive : %1").arg(entryName));
            }
            const bool ok = storeImage(entryName, QByteArray::fromRawData(static_cast<const char *>(p), static_cast<int>(size)));
            mz_free(p);
            if (!ok) {
                mz_zip_reader_end(&zip);
                return fail(QStringLiteral("Écriture impossible dans %1").arg(QDir::toNativeSeparators(imagesOut)));
            }
            if (i % 50 == 0)
                report(0.12 + 0.70 * double(i) / double(n), QStringLiteral("Extraction des images"));
        }
        mz_zip_reader_end(&zip);
    } else {
        // No archive: copy loose images from a folder (local import) or from the current bank.
        const QString from = !source.imagesDir.isEmpty() ? source.imagesDir : source.fallbackImagesDir;
        if (!from.isEmpty() && QFileInfo(from).isDir()) {
            const QFileInfoList files = QDir(from).entryInfoList(QDir::Files);
            int i = 0;
            for (const QFileInfo &fi : files) {
                int key = -1;
                const QString name = normalisedImageName(fi.fileName(), &key);
                if (!name.isEmpty() && QFile::copy(fi.absoluteFilePath(), QDir(imagesOut).filePath(name))) {
                    if (!imageByNum.contains(key) || name.endsWith(QLatin1String(".png")))
                        imageByNum.insert(key, name);
                }
                if (++i % 100 == 0)
                    report(0.12 + 0.70 * double(i) / double(files.size()), QStringLiteral("Copie des images"));
            }
        }
    }
    result.images = imageByNum.size();

    // Presentation on the exam screen (see src/statement.h): F6GPX's markers decide; the
    // picture is analysed only for questions they do not cover.
    report(0.82, QStringLiteral("Analyse des énoncés"));
    const Statement::Marks &marks = Statement::Marks::bundled();
    // The questions file may carry F6GPX's markers itself: an "imageNecessaire" field, or the
    // "- " kept at the start of the statement. Then the file decides.
    const bool fileHasField = std::any_of(parsed.cbegin(), parsed.cend(), [](const ParsedQuestion &pq) {
        return pq.needsPicture.has_value();
    });
    const bool fileHasMarkers = !fileHasField && std::any_of(parsed.cbegin(), parsed.cend(), [](const ParsedQuestion &pq) {
        return Statement::hasPictureMarker(pq.text);
    });
    int textOnlyCount = 0;
    for (int i = 0; i < parsed.size(); ++i) {
        ParsedQuestion &pq = parsed[i];
        const std::optional<bool> marked = pq.needsPicture ? std::optional<bool>(!*pq.needsPicture)
                                                           : Statement::textOnlyFromMarks(pq.num, pq.text, fileHasMarkers, marks);
        pq.text = marks.repair(pq.num, pq.text);
        pq.displayText = Statement::displayText(pq.text);
        const QString image = imageByNum.value(pq.num);
        if (image.isEmpty()) {
            pq.textOnly = true;
        } else if (marked) {
            pq.textOnly = *marked;
        } else if (Statement::textIsComplete(pq.text)) {
            const QImage img(QDir(imagesOut).filePath(image));
            pq.textOnly = !Statement::analyseImage(img).graphic;
        }
        textOnlyCount += pq.textOnly ? 1 : 0;
        if (i % 100 == 0)
            report(0.82 + 0.06 * double(i) / double(parsed.size()), QStringLiteral("Analyse des énoncés"));
    }

    // 5. Database -------------------------------------------------------------------
    report(0.85, QStringLiteral("Création de la base"));
    const QString connection = QStringLiteral("import-%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection);
        db.setDatabaseName(bdir.filePath(databaseFileName()));
        if (!db.open()) {
            const QString err = db.lastError().text();
            db = QSqlDatabase();
            QSqlDatabase::removeDatabase(connection);
            return fail(QStringLiteral("Base SQLite impossible à créer : %1").arg(err));
        }
        QSqlQuery q(db);
        const QStringList ddl = {
            QStringLiteral("CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT)"),
            QStringLiteral("CREATE TABLE questions(num INTEGER PRIMARY KEY, ref TEXT, text TEXT, options TEXT,"
                           " answer INTEGER, theme INTEGER, comment TEXT, course TEXT, image TEXT,"
                           " display_text TEXT, text_only INTEGER)"),
            QStringLiteral("CREATE TABLE series(id INTEGER PRIMARY KEY, name TEXT UNIQUE, num INTEGER, type TEXT)"),
            QStringLiteral("CREATE TABLE series_questions(series_id INTEGER, pos INTEGER, num INTEGER)"),
            QStringLiteral("CREATE INDEX idx_q_theme ON questions(theme)"),
        };
        bool ok = true;
        QString err;
        for (const QString &s : ddl) {
            if (!q.exec(s)) {
                ok = false;
                err = q.lastError().text();
                break;
            }
        }
        if (ok) {
            db.transaction();
            QSqlQuery ins(db);
            ins.prepare(QStringLiteral("INSERT OR REPLACE INTO questions(num, ref, text, options, answer, theme, comment, course, image,"
                                       " display_text, text_only) VALUES(?,?,?,?,?,?,?,?,?,?,?)"));
            for (const ParsedQuestion &pq : parsed) {
                ins.addBindValue(pq.num);
                ins.addBindValue(pq.ref);
                ins.addBindValue(pq.text);
                ins.addBindValue(QString::fromUtf8(QJsonDocument(QJsonArray::fromStringList(pq.options)).toJson(QJsonDocument::Compact)));
                ins.addBindValue(pq.answer);
                ins.addBindValue(pq.theme);
                ins.addBindValue(pq.comment);
                ins.addBindValue(pq.course);
                ins.addBindValue(imageByNum.value(pq.num));
                ins.addBindValue(pq.displayText);
                ins.addBindValue(pq.textOnly ? 1 : 0);
                if (!ins.exec()) {
                    ok = false;
                    err = ins.lastError().text();
                    break;
                }
            }
            if (ok) {
                QSqlQuery sins(db), lins(db);
                sins.prepare(QStringLiteral("INSERT OR REPLACE INTO series(id, name, num, type) VALUES(?,?,?,?)"));
                lins.prepare(QStringLiteral("INSERT INTO series_questions(series_id, pos, num) VALUES(?,?,?)"));
                int id = 0;
                for (const ParsedSeries &s : series) {
                    ++id;
                    sins.addBindValue(id);
                    sins.addBindValue(s.name);
                    sins.addBindValue(s.num);
                    sins.addBindValue(s.type);
                    if (!sins.exec()) {
                        ok = false;
                        err = sins.lastError().text();
                        break;
                    }
                    for (int pos = 0; pos < s.questions.size(); ++pos) {
                        lins.addBindValue(id);
                        lins.addBindValue(pos);
                        lins.addBindValue(s.questions.at(pos));
                        lins.exec();
                    }
                }
            }
            if (ok) {
                QSqlQuery m(db);
                m.prepare(QStringLiteral("INSERT INTO meta(key, value) VALUES(?,?)"));
                const QList<QPair<QString, QString>> meta = {
                    {QStringLiteral("version"), result.version},
                    {QStringLiteral("series_version"), seriesVersion},
                    {QStringLiteral("questions"), QString::number(parsed.size())},
                    {QStringLiteral("skipped"), QString::number(skipped)},
                    {QStringLiteral("series"), QString::number(series.size())},
                    {QStringLiteral("images"), QString::number(imageByNum.size())},
                    {QStringLiteral("text_only"), QString::number(textOnlyCount)},
                    // Origin of the picture/text decision (see src/statement.h).
                    {QStringLiteral("markers"), fileHasField || fileHasMarkers ? QStringLiteral("file")
                                                : marks.isEmpty() ? QStringLiteral("none") : marks.source()},
                    {QStringLiteral("answer_base"), zeroBased ? QStringLiteral("0") : QStringLiteral("1")},
                    {QStringLiteral("source"), source.label},
                    {QStringLiteral("imported_at"), QDateTime::currentDateTime().toString(Qt::ISODate)},
                };
                for (const auto &kv : meta) {
                    m.addBindValue(kv.first);
                    m.addBindValue(kv.second);
                    m.exec();
                }
            }
            if (ok)
                ok = db.commit();
            else
                db.rollback();
        }
        db.close();
        db = QSqlDatabase();
        QSqlDatabase::removeDatabase(connection);
        if (!ok)
            return fail(QStringLiteral("Erreur SQLite pendant l'import : %1").arg(err));
    }

    result.ok = true;
    result.bankDir = bankDir;
    result.questions = parsed.size();
    result.series = series.size();
    report(1.0, QStringLiteral("Terminé"));
    return result;
}

} // namespace BankImporter
