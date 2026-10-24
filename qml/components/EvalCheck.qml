import QtQuick
import QtQuick.Controls
import Exam1App

// Proposition rendered like the Evalbox check boxes. feedback (training only):
// 0 none, 1 ticked and correct, 2 ticked and wrong, 3 correct but not ticked.
AbstractButton {
    id: chk
    property string label: ""
    property bool ticked: false
    property int feedback: 0
    property bool locked: false
    property string family: ""
    property real k: 1.0

    checkable: false
    hoverEnabled: !locked
    focusPolicy: locked ? Qt.NoFocus : Qt.StrongFocus
    implicitHeight: Math.max(26 * k, labelText.implicitHeight + 6)
    implicitWidth: box.width + 10 + labelText.implicitWidth
    Accessible.role: Accessible.CheckBox
    Accessible.checked: ticked
    Accessible.name: label

    background: Rectangle {
        color: chk.feedback === 1 ? "#D1E7DD" : chk.feedback === 2 ? "#F8D7DA" : chk.feedback === 3 ? "#E9F5EE" : "transparent"
        radius: 3
        anchors.fill: parent
        anchors.leftMargin: -6
        anchors.rightMargin: -6
    }

    contentItem: Item {
        Rectangle {
            id: box
            width: Math.round(16 * chk.k)
            height: width
            radius: 3
            anchors.verticalCenter: parent.verticalCenter
            color: chk.ticked ? "#0D6EFD" : "#FFFFFF"
            border.width: 1
            border.color: chk.ticked ? "#0D6EFD" : (chk.hovered ? "#86B7FE" : "#BFBFBF")
            Icon {
                anchors.centerIn: parent
                visible: chk.ticked
                name: "check"
                color: "#FFFFFF"
                size: Math.round(12 * chk.k)
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: 5
                color: "transparent"
                border.width: 3
                border.color: "#8086B7FE"
                visible: chk.visualFocus
            }
        }
        Text {
            id: labelText
            anchors.left: box.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: chk.label
            font.family: chk.family
            font.pixelSize: Math.round(16 * chk.k)
            color: chk.feedback === 1 || chk.feedback === 3 ? "#0F5132" : chk.feedback === 2 ? "#842029" : "#212529"
            font.bold: chk.feedback === 1 || chk.feedback === 3
            wrapMode: Text.WordWrap
        }
    }
}
