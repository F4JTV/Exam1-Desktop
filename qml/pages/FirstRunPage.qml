import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Exam1.Core
import Exam1App

// Shown while no question bank is installed: installing the bundled bank, or downloading it.
Page {
    id: page
    property bool immersive: true
    background: Rectangle { color: Style.slate }

    Connections {
        target: Updates
        function onBankInstalled() {
            if (Nav.window)
                Nav.window.go("home")
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(640, parent.width - 80)
        spacing: 22

        Text {
            text: "EXAM'1"
            font.family: Style.family
            font.pixelSize: Style.fHero
            font.bold: true
            font.italic: true
            color: Style.yellow
            style: Text.Raised
            styleColor: "#0B1117"
        }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.family: Style.family
            font.pixelSize: Style.fL
            color: Style.slateText
            text: Updates.busy ? "Installation de la base de questions…"
                  : "Pour commencer, il faut installer la base de questions de Jean-Luc F6GPX (environ 35 Mo, questions et images)."
        }

        ColumnLayout {
            visible: Updates.busy
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                Layout.fillWidth: true
                height: 10
                radius: 5
                color: Style.slateHi
                Rectangle {
                    width: parent.width * Updates.progress
                    height: parent.height
                    radius: 5
                    color: Style.yellow
                }
            }
            Text {
                text: Updates.status
                font.family: Style.family
                font.pixelSize: Style.fS
                color: Style.slateTextMuted
            }
        }

        Text {
            visible: !Updates.busy && Updates.lastError.length > 0
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.family: Style.family
            font.pixelSize: Style.fM
            color: "#FF9A8F"
            text: Updates.lastError
        }

        Flow {
            visible: !Updates.busy
            Layout.fillWidth: true
            spacing: 12
            ActionButton {
                variant: "accent"
                iconName: "download"
                text: "Télécharger la base (REF)"
                onClicked: Updates.installUpdate()
            }
            ActionButton {
                visible: Updates.seedAvailable
                variant: "dark"
                text: "Installer la base fournie"
                onClicked: Updates.installSeed()
            }
            ActionButton {
                variant: "dark"
                iconName: "folder"
                text: "Importer des fichiers…"
                onClicked: folderDialog.open()
            }
        }
        Text {
            visible: !Updates.busy
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.family: Style.family
            font.pixelSize: Style.fS
            color: Style.slateTextMuted
            text: "Sans Internet : choisissez un dossier contenant questions.json, series.json et questions.zip."
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Dossier contenant questions.json"
        onAccepted: Updates.importLocal(selectedFolder)
    }
}
