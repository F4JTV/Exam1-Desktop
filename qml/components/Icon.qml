import QtQuick
import Exam1App

// Monochrome SVG icon tinted through the "icon" image provider.
Item {
    id: icon
    property string name: ""
    property color color: Style.text
    property int size: 20

    width: size
    height: size
    implicitWidth: size
    implicitHeight: size

    Image {
        anchors.fill: parent
        sourceSize: Qt.size(icon.size * 2, icon.size * 2)
        source: icon.name.length > 0 ? Style.iconUrl(icon.name, icon.color) : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
}
