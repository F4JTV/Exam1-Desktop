import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1App

// Mutually exclusive choice displayed as joined segments.
// In a layout it takes at most its natural width, and wraps its segments onto several lines
// when there is less room (narrow window, large text): it never pushes the layout wider.
Flow {
    id: seg
    property var options: []      // [{ value: ..., label: "..." }]
    property var value
    signal activated(var value)

    // Width of all the segments on one line.
    readonly property real naturalWidth: {
        var w = 0
        for (var i = 0; i < segments.count; ++i) {
            var item = segments.itemAt(i)
            if (item)
                w += item.implicitWidth
        }
        return w
    }
    Layout.fillWidth: true
    Layout.maximumWidth: naturalWidth

    spacing: 0
    Repeater {
        id: segments
        model: seg.options
        delegate: AbstractButton {
            id: btn
            required property var modelData
            required property int index
            readonly property bool selected: seg.value === modelData.value
            hoverEnabled: true
            focusPolicy: Qt.StrongFocus
            implicitHeight: Math.max(38, label.implicitHeight + 14)
            // Measured in bold so that selecting a segment does not change the widths.
            implicitWidth: Math.ceil(boldMetrics.advanceWidth) + 32
            onClicked: seg.activated(modelData.value)
            TextMetrics {
                id: boldMetrics
                font.family: Style.family
                font.pixelSize: Style.fS
                font.bold: true
                text: btn.modelData.label
            }
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
