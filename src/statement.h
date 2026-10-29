// Decides how a question is presented on the exam screen.
//
// On the ANFR (Evalbox) exam, only questions with a diagram, a formula or a drawing show a
// picture; the others are plain text. In the Exam'1 bank every question has a picture
// (the statement rendered on a yellow card), and for the drawn questions the text field
// is only a short description.
//
// F6GPX marks those questions in the Excel file of the bank: their statement starts with "- ".
// The REF conversion to questions.json drops the marker, so the list taken from his file is
// bundled with the application (resources/bank/marks.json, built by tools/f6gpx_marks.py).
// In order of authority:
//   1. question without picture                 -> text
//   2. markers carried by the questions file ("imageNecessaire" field, or "- " kept at the
//      start of the statement)          -> they decide
//   3. F6GPX's bundled list                      -> it decides
//   4. question added after that list            -> picture analysis below: text only when the
//      picture holds nothing but text and the text reads as a complete statement.
#pragma once

#include <QHash>
#include <QImage>
#include <QSet>
#include <QString>
#include <optional>

namespace Statement {

class Marks
{
public:
    // List bundled with the application (empty if the resource is missing).
    static const Marks &bundled();
    explicit Marks(const QByteArray &json = QByteArray());

    bool isEmpty() const { return m_picture.isEmpty() && m_text.isEmpty(); }
    QString source() const { return m_source; }
    bool covers(int num) const { return m_picture.contains(num) || m_text.contains(num); }
    bool needsPicture(int num) const { return m_picture.contains(num); }

    // The REF conversion cuts a few characters off some statements ("Un mélangeu",
    // "Ension aux bornes"). Returns the full statement from F6GPX's file when `text` is such
    // a truncated piece of it, otherwise `text` unchanged (e.g. a statement corrected since).
    QString repair(int num, const QString &text) const;

private:
    QString m_source;
    QSet<int> m_picture;
    QSet<int> m_text;
    QHash<int, QString> m_statements;
};

// True when the statement itself starts with F6GPX's marker "- ".
bool hasPictureMarker(const QString &raw);

// Rules 2 and 3 above: true = text only, false = picture, nullopt = not covered by the markers.
std::optional<bool> textOnlyFromMarks(int num, const QString &raw, bool fileHasMarkers,
                                      const Marks &marks = Marks::bundled());

// Statement text cleaned for display ("* " markers and doubled apostrophes removed).
QString displayText(const QString &raw);

// True when the text reads as a complete, self-sufficient statement.
bool textIsComplete(const QString &raw);

struct ImageTraits {
    bool graphic = true;   // diagram, formula layout or colour drawing detected
    int longestRun = 0;    // longest straight dark run (pixels, horizontal or vertical)
    double vivid = 0.0;    // share of strongly coloured pixels
};
ImageTraits analyseImage(const QImage &image);

} // namespace Statement
