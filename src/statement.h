// Decides how a question is presented on the exam screen.
//
// On the ANFR (Evalbox) exam, only questions with a diagram, a formula or a drawing show a
// picture; the others are plain text. In the Exam'1 bank every question has a picture
// (the statement rendered on a yellow card), and for the drawn questions the text field
// is only a short description. A question is therefore shown as text only when:
//   - its picture contains nothing but text (no long straight lines, no coloured areas), and
//   - its text is a complete statement (single line, ends like a question, no reference to
//     a figure, no shorthand typical of picture descriptions).
// Any doubt keeps the picture, so no question can lose information.
#pragma once

#include <QImage>
#include <QString>

namespace Statement {

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
