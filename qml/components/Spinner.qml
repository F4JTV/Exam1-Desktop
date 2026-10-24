import QtQuick
import QtQuick.Controls
import Exam1App

// Compact numeric stepper: [-] value [+]
Row {
    id: sp
    property int value: 0
    property int from: 0
    property int to: 100
    property int step: 1
    property string suffix: ""
    property string zeroLabel: ""
    signal edited(int value)

    spacing: 0
    function setValue(v) {
        var n = Math.max(from, Math.min(to, v))
        if (n !== value) {
            value = n
            edited(n)
        }
    }

    ActionButton {
        variant: "secondary"
        compact: true
        text: "−"
        width: 40
        enabled: sp.value > sp.from
        onClicked: sp.setValue(sp.value - sp.step)
        Accessible.name: "Diminuer"
    }
    Rectangle {
        width: Math.max(96, valueText.implicitWidth + 24)
        height: 34
        color: Style.surface
        border.color: Style.line
        Text {
            id: valueText
            anchors.centerIn: parent
            text: (sp.value === 0 && sp.zeroLabel.length > 0) ? sp.zeroLabel : sp.value + (sp.suffix.length ? " " + sp.suffix : "")
            font.family: Style.family
            font.pixelSize: Style.fM
            font.bold: true
            color: Style.text
        }
    }
    ActionButton {
        variant: "secondary"
        compact: true
        text: "+"
        width: 40
        enabled: sp.value < sp.to
        onClicked: sp.setValue(sp.value + sp.step)
        Accessible.name: "Augmenter"
    }
}
