import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1App

// Bar at the top of phones and narrow windows, where the left rail would take too much room:
// menu button (opens the navigation drawer), Exam'1 wordmark and name of the current section.
Rectangle {
    id: bar
    property string title: ""
    property bool badge: false     // update available, as on the rail
    signal menuRequested()

    color: Style.slate
    implicitHeight: Math.max(56, Math.round(50 * Style.k))

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: Style.margin
        spacing: 6

        AbstractButton {
            id: menuButton
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            Accessible.name: "Menu"
            onClicked: bar.menuRequested()
            background: Rectangle {
                radius: 24
                color: menuButton.down ? Style.slateHi : "transparent"
                border.width: menuButton.visualFocus ? 2 : 0
                border.color: Style.yellow
            }
            contentItem: Item {
                Icon {
                    anchors.centerIn: parent
                    name: "menu"
                    color: Style.slateText
                    size: 24
                }
                Rectangle {
                    visible: bar.badge
                    x: parent.width / 2 + 7
                    y: parent.height / 2 - 13
                    width: 10
                    height: 10
                    radius: 5
                    color: Style.yellow
                    border.color: Style.slate
                    border.width: 2
                }
            }
        }

        Text {
            text: "EXAM'1"
            font.family: Style.family
            font.pixelSize: Math.round(25 * Math.min(Style.k, 1.3))
            font.bold: true
            font.italic: true
            color: Style.yellow
            style: Text.Raised
            styleColor: "#0C1218"
        }

        Text {
            Layout.fillWidth: true
            leftPadding: 8
            text: bar.title
            font.family: Style.family
            font.pixelSize: Style.fM
            color: Style.slateText
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }
}
