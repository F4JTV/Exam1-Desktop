import QtQuick
import QtQuick.Layouts
import Exam1App

// Bars of the latest marks out of 20, with the pass mark (10/20) drawn across.
Item {
    id: nb
    property var values: []     // [{ note20, passed }], oldest first
    property int maxBars: 10
    implicitHeight: 92
    implicitWidth: 260

    readonly property var shown: values.length > maxBars ? values.slice(values.length - maxBars) : values

    Text {
        anchors.centerIn: parent
        visible: nb.shown.length === 0
        text: "Pas encore de note"
        font.family: Style.family
        font.pixelSize: Style.fS
        color: Style.muted
    }

    Row {
        id: bars
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height
        spacing: 6
        Repeater {
            model: nb.shown
            delegate: Item {
                required property var modelData
                required property int index
                width: Math.min(26, (bars.width - (nb.maxBars - 1) * bars.spacing) / nb.maxBars)
                height: bars.height
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(3, parent.height * Math.min(20, modelData.note20) / 20)
                    radius: 2
                    color: modelData.passed ? Style.green : Style.red
                    opacity: index === nb.shown.length - 1 ? 1 : 0.55
                }
            }
        }
    }
    Rectangle {
        visible: nb.shown.length > 0
        anchors.left: parent.left
        anchors.right: parent.right
        y: parent.height / 2
        height: 1
        color: Style.muted
        opacity: 0.6
    }
}
