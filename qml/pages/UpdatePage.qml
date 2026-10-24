import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Exam1.Core
import Exam1App

// Question bank status and updates. New questions are published every quarter by
// Jean-Luc F6GPX; the REF hosts them for the web and Android versions of Exam'1.
Page {
    id: page
    property bool immersive: false
    background: Rectangle { color: Style.bg }

    readonly property bool busy: Updates.busy

    Flickable {
        anchors.fill: parent
        contentHeight: col.implicitHeight + 80
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        ColumnLayout {
            id: col
            x: 48
            y: 40
            width: Math.min(960, parent.width - 96)
            spacing: 24

            PageHeader {
                Layout.fillWidth: true
                title: "Mise à jour des questions"
                subtitle: "Jean-Luc F6GPX ajoute chaque trimestre les questions rapportées par les candidats. La base est publiée par le REF et installée ici en un clic."
            }

            // Installed bank ------------------------------------------------------------------------
            Section {
                Layout.fillWidth: true
                title: "Base installée"
                GridLayout {
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 8
                    Layout.fillWidth: true
                    Text { text: "Version"; font.family: Style.family; font.pixelSize: Style.fM; color: Style.muted }
                    Text { text: Bank.ready ? Bank.versionLabel : "aucune"; font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text }
                    Text { text: "Questions"; font.family: Style.family; font.pixelSize: Style.fM; color: Style.muted }
                    Text { text: Bank.questionCount + " dont " + Bank.imageCount + " avec image"; font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text }
                    Text { text: "Séries"; font.family: Style.family; font.pixelSize: Style.fM; color: Style.muted }
                    Text { text: Bank.seriesCount; font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text }
                    Text { text: "Origine"; font.family: Style.family; font.pixelSize: Style.fM; color: Style.muted }
                    Text { text: Bank.source.length ? Bank.source + ", installée le " + Bank.importedAtLabel : "-"; font.family: Style.family; font.pixelSize: Style.fM; color: Style.text; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
            }

            // Online update ---------------------------------------------------------------------------
            Section {
                Layout.fillWidth: true
                title: "Mise à jour en ligne"
                subtitle: "Source : " + Prefs.updateBaseUrl

                Rectangle {
                    Layout.fillWidth: true
                    visible: Updates.remoteVersion.length > 0 || Updates.lastError.length > 0
                    implicitHeight: statusCol.implicitHeight + 28
                    radius: Style.r2
                    color: Updates.lastError.length > 0 ? Style.redSoft : Updates.updateAvailable ? Style.pinSoft : Style.greenSoft
                    ColumnLayout {
                        id: statusCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 16
                        spacing: 4
                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            font.family: Style.family
                            font.pixelSize: Style.fM
                            font.bold: true
                            color: Updates.lastError.length > 0 ? Style.red : Updates.updateAvailable ? Style.pin : Style.green
                            text: Updates.lastError.length > 0 ? Updates.lastError
                                  : Updates.updateAvailable ? "Nouvelle version disponible : base du " + Updates.remoteVersionLabel + " (" + Updates.remoteCount + " questions)."
                                  : "Votre base est à jour (version publiée : " + Updates.remoteVersionLabel + ")."
                        }
                        Text {
                            visible: Updates.lastCheckLabel.length > 0
                            text: "Dernière vérification le " + Updates.lastCheckLabel
                            font.family: Style.family
                            font.pixelSize: Style.fS
                            color: Style.muted
                        }
                    }
                }

                ColumnLayout {
                    visible: page.busy || Updates.state === UpdaterState.Installed
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: Updates.state === UpdaterState.Installed ? "Installation terminée : " + Updates.status : Updates.status
                        font.family: Style.family
                        font.pixelSize: Style.fM
                        color: Updates.state === UpdaterState.Installed ? Style.green : Style.text
                        font.bold: Updates.state === UpdaterState.Installed
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    Rectangle {
                        visible: page.busy
                        Layout.fillWidth: true
                        height: 10
                        radius: 5
                        color: Style.surfaceAlt
                        border.color: Style.line
                        Rectangle {
                            width: parent.width * Updates.progress
                            height: parent.height
                            radius: 5
                            color: Style.blue
                            Behavior on width { NumberAnimation { duration: 150 } }
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 12
                    ActionButton {
                        text: Updates.state === UpdaterState.Checking ? "Vérification…" : "Vérifier les nouvelles questions"
                        iconName: "refresh"
                        variant: Updates.updateAvailable ? "secondary" : "primary"
                        enabled: !page.busy
                        onClicked: Updates.checkForUpdate(false)
                    }
                    ActionButton {
                        visible: Updates.updateAvailable || !Bank.ready
                        text: "Télécharger et installer"
                        iconName: "download"
                        enabled: !page.busy
                        onClicked: Updates.installUpdate()
                    }
                    ActionButton {
                        visible: page.busy && Updates.state !== UpdaterState.Installing
                        variant: "secondary"
                        text: "Annuler"
                        onClicked: Updates.cancel()
                    }
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Style.family
                    font.pixelSize: Style.fS
                    color: Style.muted
                    text: "Le téléchargement complet pèse environ 35 Mo (questions, séries et images). Vos notes, vos candidats et vos questions enregistrées sont conservés."
                }
            }

            // Offline import ------------------------------------------------------------------------------
            Section {
                Layout.fillWidth: true
                title: "Installer depuis des fichiers"
                subtitle: "Pour un ordinateur sans Internet : copiez questions.json, series.json et questions.zip (récupérés sur un autre poste) dans un dossier ou une archive ZIP, puis choisissez-le ici."
                Flow {
                    Layout.fillWidth: true
                    spacing: 12
                    ActionButton {
                        variant: "secondary"
                        iconName: "folder"
                        text: "Choisir un dossier…"
                        enabled: !page.busy
                        onClicked: folderDialog.open()
                    }
                    ActionButton {
                        variant: "secondary"
                        iconName: "folder"
                        text: "Choisir une archive ZIP…"
                        enabled: !page.busy
                        onClicked: fileDialog.open()
                    }
                    ActionButton {
                        visible: Updates.seedAvailable
                        variant: "ghost"
                        text: "Réinstaller la base fournie (" + Updates.seedVersionLabel + ")"
                        enabled: !page.busy
                        onClicked: Updates.installSeed()
                    }
                }
            }

            Section {
                Layout.fillWidth: true
                title: "Adresse de téléchargement"
                subtitle: "À ne modifier que si la base est publiée ailleurs (miroir de club, serveur local)."
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    TextField2 {
                        id: urlField
                        Layout.fillWidth: true
                        text: Prefs.updateBaseUrl
                        onEditingFinished: Prefs.updateBaseUrl = text
                    }
                    ActionButton {
                        variant: "ghost"
                        text: "Adresse d'origine"
                        onClicked: { Prefs.resetUpdateBaseUrl(); urlField.text = Prefs.updateBaseUrl }
                    }
                }
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Dossier contenant questions.json"
        onAccepted: Updates.importLocal(selectedFolder)
    }
    FileDialog {
        id: fileDialog
        title: "Archive ou fichier questions.json"
        nameFilters: ["Base de questions (*.zip *.json)", "Tous les fichiers (*)"]
        onAccepted: Updates.importLocal(selectedFile)
    }
}
