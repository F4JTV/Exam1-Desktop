// Builds a new question bank directory (SQLite + images) from the files published
// by the REF for the Exam'1 web and Android versions:
//   questions.json, series.json, questions.zip
// The import is done into a fresh directory so a failed import never damages the
// bank currently in use. Runs on a worker thread.
#pragma once

#include <QString>
#include <functional>

struct ImportSource {
    QString questionsJson;      // required
    QString seriesJson;         // optional
    QString imagesZip;          // optional
    QString imagesDir;          // optional: folder holding <num>.png files
    QString fallbackImagesDir;  // images of the current bank, reused if no new images are given
    QString label;              // where the data comes from, stored in the bank metadata
};

struct ImportResult {
    bool ok = false;
    QString error;
    QString bankDir;
    QString version;
    int questions = 0;
    int series = 0;
    int images = 0;
};

namespace BankImporter {

using Progress = std::function<void(double fraction, const QString &step)>;

ImportResult run(const ImportSource &source, const QString &banksRoot, const Progress &progress);

// Light validation used by the updater before installing anything.
bool inspectQuestionsJson(const QByteArray &data, QString *version, int *count, QString *error);

QString databaseFileName();   // "bank.sqlite"
QString imagesFolderName();   // "images"

} // namespace BankImporter
