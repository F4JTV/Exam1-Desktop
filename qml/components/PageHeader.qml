import QtQuick
import QtQuick.Layouts
import Exam1App

// Title block at the top of a page, with an optional row of actions on the right.
RowLayout {
    id: ph
    property string title: ""
    property string subtitle: ""
    default property alias actions: actionsRow.data

    spacing: Style.gap
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        Text {
            text: ph.title
            font.family: Style.family
            font.pixelSize: Style.fXxl
            font.bold: true
            color: Style.text
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        Text {
            visible: ph.subtitle.length > 0
            text: ph.subtitle
            font.family: Style.family
            font.pixelSize: Style.fM
            color: Style.muted
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }
    Row {
        id: actionsRow
        spacing: 10
        Layout.alignment: Qt.AlignBottom
    }
}
