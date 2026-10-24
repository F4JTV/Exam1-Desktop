// In-memory representation of one question of the bank.
#pragma once

#include <QString>
#include <QStringList>

struct Question {
    int num = 0;            // numeric id (e.g. 20003); also the image key
    QString ref;            // 5-digit reference as published ("00037", "20003")
    QString text;           // statement text as published (also used for search)
    QString displayText;    // cleaned statement for display
    bool textOnly = false;  // shown without picture on the exam screen (picture holds only this text)
    QStringList options;    // propositions, in published order
    int answer = 0;         // 1-based index of the correct proposition
    int theme = 0;          // family id (201..210 technique, 301..310 regulation)
    QString comment;        // explanation, may be empty
    QString course;         // link to the matching section of the online course
    QString image;          // file name inside the bank "images" folder, empty if none
};
