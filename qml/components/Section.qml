import QtQuick
import QtQuick.Layouts
import Exam1App

// A titled block of content on a surface.
Rectangle {
    id: sec
    property string title: ""
    property string subtitle: ""
    property int contentPadding: Style.pad
    default property alias content: body.data

    color: Style.surface
    radius: Style.r2
    border.color: Style.line
    border.width: 1
    implicitHeight: col.implicitHeight + 2 * contentPadding
    implicitWidth: 320

    ColumnLayout {
        id: col
        x: sec.contentPadding
        y: sec.contentPadding
        width: sec.width - 2 * sec.contentPadding
        spacing: 14
        ColumnLayout {
            visible: sec.title.length > 0
            spacing: 4
            Layout.fillWidth: true
            Text {
                text: sec.title
                font.family: Style.family
                font.pixelSize: Style.fL
                font.bold: true
                color: Style.text
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            Text {
                visible: sec.subtitle.length > 0
                text: sec.subtitle
                font.family: Style.family
                font.pixelSize: Style.fS
                color: Style.muted
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 12
        }
    }
}
