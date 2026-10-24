#include "statement.h"

#include <QRegularExpression>
#include <QVector>
#include <algorithm>

namespace Statement {

QString displayText(const QString &raw)
{
    QString s = raw;
    s.replace(QStringLiteral("''"), QStringLiteral("'"));
    static const QRegularExpression lead(QStringLiteral("^[\\s*\\-]+"));
    s.remove(lead);
    s = s.trimmed();
    if (!s.isEmpty())
        s[0] = s.at(0).toUpper();
    return s;
}

bool textIsComplete(const QString &raw)
{
    const QString s = displayText(raw);
    if (s.size() < 12 || s.contains(QLatin1Char('\n')))
        return false;

    // Must end like a full statement: ?, :, . or a call sign / code (e.g. "FC5BWA", "QSY").
    static const QRegularExpression ending(QStringLiteral("([?:.!]|\\b[A-Z0-9/]{2,})\\s*$"));
    if (!ending.match(s).hasMatch())
        return false;

    // References to something drawn.
    static const QRegularExpression visual(
        QStringLiteral("sch[ée]ma|sh[ée]ma|synoptique|figure|ci-contre|ci-dessous|ci-dessus|ci-apr[èe]s|dessin|courbe|"
                       "montage|formule|graphe|graphique|spectre|oscillo|diagramme|tableau|repr[ée]sent|r[ée]pr[ée]sent|"
                       "'-|\\?\\?|\\b[1-4]\\s*[)\\-]|\\(lettre|"
                       "\\b(ce|cet|cette|ces)\\s+(sch|circuit|montage|filtre|symbole|courbe|signal|modulation|composant|"
                       "[ée]tage|antenne|diagramme|graphe|appareil|instrument|alimentation|transfo|ampli)"),
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::UseUnicodePropertiesOption);
    if (visual.match(s).hasMatch())
        return false;

    // Lower-case units right after a number ("14v", "665 ma", "100 hz") are the shorthand used
    // when the text only describes the picture; real statements write V, mA, Hz.
    static const QRegularExpression shorthand(
        QStringLiteral("\\d\\s*(hz|khz|mhz|ghz|w|mw|kw|v|mv|kv|ma|ko|kohms?|mohms?|pf|nf|microf|mh|microh|db|dbi|dbd)\\b"));
    if (shorthand.match(s).hasMatch())
        return false;
    return true;
}

ImageTraits analyseImage(const QImage &source)
{
    ImageTraits t;
    if (source.isNull())
        return t; // unknown: keep the picture
    const QImage img = source.convertToFormat(QImage::Format_RGB32);
    const int w = img.width();
    const int h = img.height();
    if (w < 8 || h < 8)
        return t;

    // Thresholds calibrated on the 770 x 350 Exam'1 cards: text strokes stay below ~30 px,
    // circuit wires, axes, fraction bars and frames are longer.
    const int runThreshold = std::max(40, 50 * w / 770);
    QVector<int> colRun(w, 0);
    int longest = 0;
    qint64 vivid = 0;
    for (int y = 0; y < h; ++y) {
        const QRgb *line = reinterpret_cast<const QRgb *>(img.constScanLine(y));
        int rowRun = 0;
        for (int x = 0; x < w; ++x) {
            const int r = qRed(line[x]), g = qGreen(line[x]), b = qBlue(line[x]);
            const int mx = std::max({r, g, b});
            const int mn = std::min({r, g, b});
            const bool dark = mx < 110;
            if (dark) {
                ++rowRun;
                ++colRun[x];
                longest = std::max({longest, rowRun, colRun[x]});
            } else {
                rowRun = 0;
                colRun[x] = 0;
            }
            if (mx >= 150 && mx - mn >= 120)
                ++vivid;
        }
    }
    t.longestRun = longest;
    t.vivid = double(vivid) / (double(w) * h);
    t.graphic = longest >= runThreshold || t.vivid >= 0.01;
    return t;
}

} // namespace Statement
