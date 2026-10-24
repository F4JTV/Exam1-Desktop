import QtQuick
import QtQuick.Controls
import Exam1App

// Button with the application's variants: primary, accent, secondary, ghost, danger, dark.
Button {
    id: b
    property string variant: "primary"
    property string iconName: ""
    property bool compact: false
    property color tint: b.fgColor

    readonly property color fgColor: {
        switch (variant) {
        case "primary": return "#FFFFFF"
        case "danger": return "#FFFFFF"
        case "accent": return Style.slate
        case "ghost": return Style.blue
        case "dark": return Style.slateText
        default: return Style.text
        }
    }
    readonly property color bgColor: {
        var p = b.down, h = b.hovered
        switch (variant) {
        case "primary": return p ? "#123C70" : h ? "#174C8E" : Style.blueStrong
        case "danger": return p ? "#7F1B15" : h ? "#9A221A" : "#B3261E"
        case "accent": return p ? "#E6BE00" : h ? "#FFDE33" : Style.yellow
        case "ghost": return p ? Style.line : h ? Style.surfaceAlt : "transparent"
        case "dark": return p ? Style.slate : h ? Style.slateLine : Style.slateHi
        default: return p ? Style.line : h ? Style.surfaceAlt : Style.surface
        }
    }

    font.family: Style.family
    font.pixelSize: compact ? Style.fS : Style.fM
    font.bold: variant !== "ghost"
    hoverEnabled: true
    topPadding: compact ? 7 : 11
    bottomPadding: compact ? 7 : 11
    leftPadding: compact ? 12 : 20
    rightPadding: compact ? 12 : 20
    opacity: enabled ? 1 : 0.45

    contentItem: Item {
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8
            Icon {
                visible: b.iconName.length > 0
                name: b.iconName
                color: b.tint
                size: b.compact ? 16 : 18
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: b.text
                font: b.font
                color: b.tint
                visible: text.length > 0
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    background: Rectangle {
        implicitHeight: b.compact ? 34 : 44
        radius: Style.r2
        color: b.bgColor
        border.width: (b.variant === "secondary") ? 1 : (b.variant === "dark" ? 1 : 0)
        border.color: b.variant === "dark" ? Style.slateLine : Style.line
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: Style.r2 + 3
            color: "transparent"
            border.width: 2
            border.color: Style.focus
            visible: b.visualFocus
        }
    }
}
