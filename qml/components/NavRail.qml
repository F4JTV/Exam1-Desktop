import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

// Left navigation rail on the slate "desk" colour, with the Exam'1 wordmark.
Rectangle {
    id: rail
    property string current: "home"
    signal navigate(string key)

    color: Style.slate
    // Wider with a larger text size, so that no label is cut.
    implicitWidth: Math.round(236 + 110 * Math.max(0, Style.k - 1))

    readonly property var mainItems: [
        { key: "home", icon: "home", label: "Accueil" },
        { key: "training", icon: "target", label: "Entraînement" },
        { key: "series", icon: "layers", label: "Séries" },
        { key: "review", icon: "bookmark", label: "Révisions" },
        { key: "browser", icon: "search", label: "Base de questions" },
        { key: "history", icon: "chart", label: "Résultats" }
    ]
    readonly property var toolItems: [
        { key: "candidates", icon: "users", label: "Candidats" },
        { key: "update", icon: "refresh", label: "Mise à jour" },
        { key: "settings", icon: "settings", label: "Paramètres" },
        { key: "about", icon: "info", label: "À propos" }
    ]

    component NavItem: AbstractButton {
        id: item
        required property var modelData
        readonly property bool active: rail.current === modelData.key
        Layout.fillWidth: true
        implicitHeight: Math.max(42, label.implicitHeight + 12)
        hoverEnabled: true
        onClicked: rail.navigate(modelData.key)
        Accessible.name: modelData.label
        background: Rectangle {
            color: item.active ? Style.slateHi : (item.hovered ? "#243040" : "transparent")
            Rectangle {
                visible: item.active
                width: 4
                height: parent.height
                color: Style.yellow
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                color: "transparent"
                border.width: 2
                border.color: Style.yellow
                visible: item.visualFocus
            }
        }
        contentItem: RowLayout {
            spacing: 12
            Item { width: 12 }
            Icon {
                name: item.modelData.icon
                color: item.active ? Style.yellow : Style.slateTextMuted
                size: 20
            }
            Text {
                id: label
                text: item.modelData.label
                font.family: Style.family
                font.pixelSize: Style.fM
                font.bold: item.active
                color: item.active ? "#FFFFFF" : Style.slateText
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Rectangle {
                visible: item.modelData.key === "update" && Updates.updateAvailable
                width: 9
                height: 9
                radius: 5
                color: Style.yellow
                Layout.rightMargin: 14
            }
        }
    }

    // Scrolls when the window is not tall enough for the whole menu (large text size).
    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: menu.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        clip: true
        ScrollBar.vertical: ScrollBar { policy: flick.interactive ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }

        ColumnLayout {
            id: menu
            width: flick.width
            height: Math.max(flick.height, implicitHeight)
            spacing: 2

            Column {
                Layout.fillWidth: true
                Layout.leftMargin: 22
                Layout.topMargin: 22
                Layout.bottomMargin: 22
                spacing: 2
                Text {
                    text: "EXAM'1"
                    font.family: Style.family
                    font.pixelSize: 40
                    font.bold: true
                    font.italic: true
                    color: Style.yellow
                    style: Text.Raised
                    styleColor: "#0C1218"
                }
                Text {
                    text: "Examen radioamateur"
                    font.family: Style.family
                    font.pixelSize: Style.fS
                    color: Style.slateTextMuted
                }
            }

            Repeater {
                model: rail.mainItems
                delegate: NavItem {}
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 22
                Layout.rightMargin: 22
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                height: 1
                color: Style.slateLine
            }
            Repeater {
                model: rail.toolItems
                delegate: NavItem {}
            }

            Item { Layout.fillHeight: true }

            AbstractButton {
                id: who
                Layout.fillWidth: true
                Layout.margins: 12
                implicitHeight: whoCol.implicitHeight + 20
                hoverEnabled: true
                onClicked: rail.navigate("candidates")
                Accessible.name: "Candidat : " + User.currentCandidateName
                background: Rectangle {
                    radius: Style.r2
                    color: who.hovered ? Style.slateHi : "transparent"
                    border.color: Style.slateLine
                }
                contentItem: ColumnLayout {
                    id: whoCol
                    spacing: 2
                    Text {
                        text: "Candidat"
                        font.family: Style.family
                        font.pixelSize: Style.fXs
                        color: Style.slateTextMuted
                        Layout.leftMargin: 12
                    }
                    Text {
                        text: User.currentCandidateName
                        font.family: Style.family
                        font.pixelSize: Style.fM
                        font.bold: true
                        color: Style.slateText
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                    }
                }
            }
            Text {
                Layout.leftMargin: 24
                Layout.bottomMargin: 16
                Layout.fillWidth: true
                Layout.rightMargin: 16
                text: Bank.ready ? "Base du " + Bank.versionLabel : "Aucune base installée"
                font.family: Style.family
                font.pixelSize: Style.fXs
                color: Style.slateTextMuted
                wrapMode: Text.WordWrap
            }
        }
    }
}
