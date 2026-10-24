#include "themes.h"

namespace Themes {

// Family names as published by F6GPX in the Exam'1 question table.
const QList<Theme> &technique()
{
    static const QList<Theme> list = {
        {201, QStringLiteral("Code des couleurs des résistances")},
        {202, QStringLiteral("Groupements de résistances")},
        {203, QStringLiteral("Diodes et transistors, classes d'amplification")},
        {204, QStringLiteral("Synoptiques d'émetteurs et de récepteurs")},
        {205, QStringLiteral("Rôle des différents étages RF, haut-parleur, micro")},
        {206, QStringLiteral("Électricité de base")},
        {207, QStringLiteral("Courants alternatifs")},
        {208, QStringLiteral("Condensateurs et bobines")},
        {209, QStringLiteral("Transformateurs, ampli op, filtres RC, LC, RLC")},
        {210, QStringLiteral("Antennes, couplage, propagation, lignes de transmission")},
    };
    return list;
}

const QList<Theme> &reglementation()
{
    static const QList<Theme> list = {
        {301, QStringLiteral("Classes d'émission")},
        {302, QStringLiteral("Indicatifs d'appel français et préfixes européens")},
        {303, QStringLiteral("Abréviations en code Q")},
        {304, QStringLiteral("Table d'épellation internationale")},
        {305, QStringLiteral("Fréquences et puissances autorisées")},
        {306, QStringLiteral("Sanctions, examen, perturbations, bande passante")},
        {307, QStringLiteral("Teneur des messages, matériel obligatoire, exposition")},
        {308, QStringLiteral("Caractéristiques des antennes, longueur d'onde et fréquence")},
        {309, QStringLiteral("Adaptation, ROS, affaiblissement linéique, calculs")},
        {310, QStringLiteral("Gammes d'ondes, décibels, CEM, protection")},
    };
    return list;
}

QString name(int themeId)
{
    for (const Theme &t : technique())
        if (t.id == themeId)
            return t.name;
    for (const Theme &t : reglementation())
        if (t.id == themeId)
            return t.name;
    return QStringLiteral("Thème %1").arg(themeId);
}

Category category(int themeId)
{
    switch (themeId / 100) {
    case 2: return Technique;
    case 3: return Reglementation;
    default: return Other;
    }
}

QString categoryKey(Category c)
{
    switch (c) {
    case Technique: return QStringLiteral("technique");
    case Reglementation: return QStringLiteral("reglementation");
    default: return QStringLiteral("other");
    }
}

QString categoryLabel(Category c)
{
    switch (c) {
    case Technique: return QStringLiteral("Technique");
    case Reglementation: return QStringLiteral("Réglementation");
    default: return QStringLiteral("Divers");
    }
}

Category categoryFromKey(const QString &key)
{
    if (key == QLatin1String("technique"))
        return Technique;
    if (key == QLatin1String("reglementation") || key == QLatin1String("legislation"))
        return Reglementation;
    return Other;
}

} // namespace Themes
