import QtQuick
import QtQuick.Controls
import Exam1App

// Checkbox with a label and an optional explanatory line.
CheckBox {
    id: c
    property string detail: ""
    property color labelColor: Style.text

    font.family: Style.family
    font.pixelSize: Style.fM
    hoverEnabled: true
    spacing: 12
    padding: 6
    // Short labels size to their text; labels with a detail line get a fixed width and wrap,
    // so wrapped text never drives the layout width (avoids polish loops).
    implicitWidth: detail.length > 0 ? 280 : Math.ceil(metrics.advanceWidth) + 22 + spacing + leftPadding + rightPadding + 4
    TextMetrics {
        id: metrics
        font: c.font
        text: c.text
    }
    implicitHeight: Math.max(34, contentItem.implicitHeight + topPadding + bottomPadding)

    indicator: Rectangle {
        x: c.leftPadding
        y: c.topPadding + 2
        implicitWidth: 22
        implicitHeight: 22
        radius: 5
        color: c.checked ? Style.blueStrong : Style.surface
        border.width: c.checked ? 0 : 2
        border.color: c.hovered ? Style.blue : Style.muted
        Icon {
            anchors.centerIn: parent
            name: "check"
            color: "#FFFFFF"
            size: 16
            visible: c.checked
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 8
            color: "transparent"
            border.width: 2
            border.color: Style.focus
            visible: c.visualFocus
        }
    }

    contentItem: Column {
        leftPadding: c.indicator.width + c.spacing
        spacing: 2
        Text {
            text: c.text
            font: c.font
            color: c.labelColor
            width: c.availableWidth - c.indicator.width - c.spacing
            wrapMode: Text.WordWrap
        }
        Text {
            visible: c.detail.length > 0
            text: c.detail
            font.family: Style.family
            font.pixelSize: Style.fS
            color: Style.muted
            width: c.availableWidth - c.indicator.width - c.spacing
            wrapMode: Text.WordWrap
        }
    }
}
