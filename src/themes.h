// Theme (question family) catalogue of the Exam'1 question bank.
#pragma once

#include <QList>
#include <QString>

namespace Themes {

enum Category { Other = 0, Technique = 2, Reglementation = 3 };

struct Theme {
    int id;
    QString name;
};

// Official families used to build an exam: 2 questions per family, 10 families per exam.
const QList<Theme> &technique();
const QList<Theme> &reglementation();

QString name(int themeId);
Category category(int themeId);
QString categoryKey(Category c);       // "technique" / "reglementation" / "other"
QString categoryLabel(Category c);     // human readable (French)
Category categoryFromKey(const QString &key);

} // namespace Themes
