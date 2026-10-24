import QtQuick
import QtQuick.Controls
import Exam1App

TextField {
    id: tf
    font.family: Style.family
    font.pixelSize: Style.fM
    color: Style.text
    placeholderTextColor: Style.muted
    selectByMouse: true
    leftPadding: 12
    rightPadding: 12
    background: Rectangle {
        implicitHeight: 40
        implicitWidth: 240
        radius: Style.r2
        color: Style.surface
        border.width: tf.activeFocus ? 2 : 1
        border.color: tf.activeFocus ? Style.focus : Style.line
    }
}
