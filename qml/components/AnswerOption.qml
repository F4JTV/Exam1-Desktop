import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1App

// One proposition of a question. feedback: 0 none, 1 chosen and correct,
// 2 chosen and wrong, 3 correct answer that was not chosen.
AbstractButton {
    id: opt
    property string letter: "A"
    property string label: ""
    property bool selected: false
    property int feedback: 0
    property bool locked: false

    readonly property color edge: feedback === 1 || feedback === 3 ? Style.green
                                : feedback === 2 ? Style.red
                                : selected ? Style.blue
                                : hovered && !locked ? Style.blue : Style.line
    readonly property color fill: feedback === 1 ? Style.greenSoft
                                : feedback === 2 ? Style.redSoft
                                : selected ? Style.blueSoft
                                : hovered && !locked ? Style.surfaceAlt : Style.surface

    leftPadding: 16
    rightPadding: 16
    topPadding: 11
    bottomPadding: 11
    hoverEnabled: !locked
    focusPolicy: locked ? Qt.NoFocus : Qt.StrongFocus
    implicitHeight: Math.max(54, row.implicitHeight + topPadding + bottomPadding)
    Accessible.role: Accessible.RadioButton
    Accessible.name: letter + ". " + label
    Accessible.checked: selected

    background: Rectangle {
        radius: Style.r2
        color: opt.fill
        border.width: (opt.selected || opt.feedback > 0) ? 2 : 1
        border.color: opt.edge
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: Style.r2 + 3
            color: "transparent"
            border.width: 2
            border.color: Style.focus
            visible: opt.visualFocus
        }
    }

    contentItem: RowLayout {
        id: row
        spacing: 14
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 22
            height: 22
            radius: 11
            color: "transparent"
            border.width: 2
            border.color: opt.selected ? (opt.feedback === 2 ? Style.red : opt.feedback === 1 ? Style.green : Style.blue) : Style.muted
            Rectangle {
                anchors.centerIn: parent
                width: 12
                height: 12
                radius: 6
                visible: opt.selected
                color: parent.border.color
            }
        }
        Text {
            text: opt.letter
            font.family: Style.family
            font.pixelSize: Style.fL
            font.bold: true
            color: Style.muted
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 18
        }
        Text {
            text: opt.label
            font.family: Style.family
            font.pixelSize: Style.fL
            color: Style.text
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            visible: opt.feedback === 3
            text: "Bonne réponse"
            font.family: Style.family
            font.pixelSize: Style.fS
            font.bold: true
            color: Style.green
            Layout.alignment: Qt.AlignVCenter
        }
        Icon {
            visible: opt.feedback === 1 || opt.feedback === 2
            name: opt.feedback === 1 ? "check" : "cross"
            color: opt.feedback === 1 ? Style.green : Style.red
            size: 22
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
