import QtQuick
import QtQuick.Controls
import Exam1App

// Mutually exclusive choice displayed as joined segments.
Row {
    id: seg
    property var options: []      // [{ value: ..., label: "..." }]
    property var value
    signal activated(var value)

    spacing: 0
    Repeater {
        model: seg.options
        delegate: AbstractButton {
            id: btn
            required property var modelData
            required property int index
            readonly property bool selected: seg.value === modelData.value
            hoverEnabled: true
            focusPolicy: Qt.StrongFocus
            implicitHeight: 38
            implicitWidth: label.implicitWidth + 32
            onClicked: seg.activated(modelData.value)
            contentItem: Text {
                id: label
                text: btn.modelData.label
                font.family: Style.family
                font.pixelSize: Style.fS
                font.bold: btn.selected
                color: btn.selected ? "#FFFFFF" : Style.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: btn.selected ? Style.blueStrong : (btn.hovered ? Style.surfaceAlt : Style.surface)
                border.width: 1
                border.color: btn.selected ? Style.blueStrong : Style.line
                radius: 0
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    color: "transparent"
                    border.width: 2
                    border.color: Style.focus
                    visible: btn.visualFocus
                }
            }
        }
    }
}
