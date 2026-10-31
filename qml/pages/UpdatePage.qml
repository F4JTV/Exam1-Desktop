import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Exam1.Core
import Exam1App

// New versions of the application (GitHub releases), and question bank status and updates. New
// questions are published every quarter by Jean-Luc F6GPX; the REF hosts them for the web and
// Android versions of Exam'1.
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
            x: Style.margin
            y: Style.compact ? 20 : 40
            width: Math.min(960, parent.width - 2 * Style.margin)
            spacing: 24

            PageHeader {
                Layout.fillWidth: true
                title: "Mises à jour"
                subtitle: "Nouvelles versions de l'application, et de la base de questions : Jean-Luc F6GPX ajoute chaque trimestre les questions rapportées par les candidats, la base est publiée par le REF et installée ici en un clic."
            }

            // Application -------------------------------------------------------------------------
            Section {
                Layout.fillWidth: true
                title: "Application"
                GridLayout {
                    columns: 2
                    columnSpacing: Style.compact ? 14 : 24
                    rowSpacing: 8
                    Layout.fillWidth: true
                    Text { text: "Version installée"; font.family: Style.family; font.pixelSize: Style.fM; color: Style.muted }
                    Text { text: AppUpdate.currentVersion; font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text; Layout.fillWidth: true }
                    Text { text: "Dernière version"; font.family: Style.family; font.pixelSize: Style.fM; color: Style.muted }
                    Text {
                        text: AppUpdate.checking ? "vérification…" : (AppUpdate.latestVersion.length ? AppUpdate.latestVersion : (AppUpdate.checked ? "aucune version publiée" : "pas encore vérifiée"))
                        font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text
                        wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    visible: AppUpdate.error.length > 0 || (AppUpdate.checked && !AppUpdate.checking)
                    implicitHeight: appStatus.implicitHeight + 28
                    radius: Style.r2
                    color: AppUpdate.error.length > 0 ? Style.redSoft : AppUpdate.available ? Style.pinSoft : Style.greenSoft
                    ColumnLayout {
                        id: appStatus
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
                            color: AppUpdate.error.length > 0 ? Style.red : AppUpdate.available ? Style.pin : Style.green
                            text: AppUpdate.error.length > 0 ? AppUpdate.error
                                  : AppUpdate.available ? "Exam'1 " + AppUpdate.latestVersion + " est disponible."
                                  : "Vous avez la dernière version d'Exam'1."
                        }
                        Text {
                            visible: AppUpdate.lastCheckLabel.length > 0
                            text: "Dernière vérification le " + AppUpdate.lastCheckLabel
                            font.family: Style.family
                            font.pixelSize: Style.fS
                            color: Style.muted
                        }
                    }
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 12
                    ActionButton {
                        width: Math.min(implicitWidth, parent.width)
                        visible: AppUpdate.available
                        text: "Télécharger Exam'1 " + AppUpdate.latestVersion
                        iconName: "download"
                        onClicked: App.openUrl(AppUpdate.downloadUrl)
                    }
                    ActionButton {
                        width: Math.min(implicitWidth, parent.width)
                        text: AppUpdate.checking ? "Vérification…" : "Vérifier les nouvelles versions"
                        iconName: "refresh"
                        variant: AppUpdate.available ? "secondary" : "primary"
                        enabled: !AppUpdate.checking
                        onClicked: AppUpdate.check(false)
                    }
                    ActionButton {
                        width: Math.min(implicitWidth, parent.width)
                        visible: AppUpdate.releaseUrl.length > 0
                        variant: "ghost"
                        text: "Nouveautés"
                        onClicked: App.openUrl(AppUpdate.releaseUrl)
                    }
                }
                Text {
                    visible: AppUpdate.available
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Style.family
                    font.pixelSize: Style.fS
                    color: Style.muted
                    text: Qt.platform.os === "android"
                          ? "Le fichier APK se télécharge dans le navigateur : ouvrez-le pour installer la nouvelle version par-dessus l'ancienne. Vos candidats et résultats sont conservés."
                          : Qt.platform.os === "windows"
                          ? (App.portable ? "Décompressez l'archive et remplacez les fichiers du dossier Exam1, en gardant le dossier userdata : vos candidats et résultats sont conservés."
                                          : "Lancez l'installeur téléchargé : il remplace l'ancienne version, et vos candidats et résultats sont conservés.")
                          : Qt.platform.os === "osx" || Qt.platform.os === "macos"
                          ? "Ouvrez l'image disque et glissez Exam'1 dans Applications pour remplacer l'ancienne version. Vos candidats et résultats sont conservés."
                          : AppUpdate.downloadName.endsWith(".AppImage")
                          ? "Rendez le fichier téléchargé exécutable (clic droit, Propriétés, ou chmod +x " + AppUpdate.downloadName + "), puis lancez-le à la place de l'ancien. Vos candidats et résultats sont conservés."
                          : AppUpdate.downloadName.length > 0
                          ? "Installez le paquet téléchargé avec : sudo apt install ./" + AppUpdate.downloadName + ". Vos candidats et résultats sont conservés."
                          : "Aucun paquet pour votre distribution dans cette version : la page des nouveautés liste ceux qui sont disponibles."
                }
            }

            // Installed bank ------------------------------------------------------------------------
            Section {
                Layout.fillWidth: true
                title: "Base installée"
                GridLayout {
                    columns: 2
                    columnSpacing: Style.compact ? 14 : 24
                    rowSpacing: 8
                    Layout.fillWidth: true
                    Text { text: "Version"; font.family: Style.family; font.pixelSize: Style.fM; color: Style.muted }
                    Text { text: Bank.ready ? Bank.versionLabel : "aucune"; font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Text { text: "Questions"; font.family: Style.family; font.pixelSize: Style.fM; color: Style.muted }
                    Text { text: Bank.questionCount + " dont " + Bank.imageCount + " avec image"; font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text; wrapMode: Text.WordWrap; Layout.fillWidth: true }
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
                        width: Math.min(implicitWidth, parent.width)
                        text: Updates.state === UpdaterState.Checking ? "Vérification…" : "Vérifier les nouvelles questions"
                        iconName: "refresh"
                        variant: Updates.updateAvailable ? "secondary" : "primary"
                        enabled: !page.busy
                        onClicked: Updates.checkForUpdate(false)
                    }
                    ActionButton {
                        width: Math.min(implicitWidth, parent.width)
                        visible: Updates.updateAvailable || !Bank.ready
                        text: "Télécharger et installer"
                        iconName: "download"
                        enabled: !page.busy
                        onClicked: Updates.installUpdate()
                    }
                    ActionButton {
                        width: Math.min(implicitWidth, parent.width)
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
                subtitle: App.mobile
                          ? "Sans connexion Internet : copiez sur l'appareil une archive ZIP contenant questions.json, series.json et questions.zip (récupérés sur un ordinateur), puis choisissez-la ici."
                          : "Pour un ordinateur sans Internet : copiez questions.json, series.json et questions.zip (récupérés sur un autre poste) dans un dossier ou une archive ZIP, puis choisissez-le ici."
                Flow {
                    Layout.fillWidth: true
                    spacing: 12
                    ActionButton {
                        width: Math.min(implicitWidth, parent.width)
                        visible: !App.mobile   // Android lets the application open single files only
                        variant: "secondary"
                        iconName: "folder"
                        text: "Choisir un dossier…"
                        enabled: !page.busy
                        onClicked: folderDialog.open()
                    }
                    ActionButton {
                        width: Math.min(implicitWidth, parent.width)
                        variant: "secondary"
                        iconName: "folder"
                        text: "Choisir une archive ZIP…"
                        enabled: !page.busy
                        onClicked: fileDialog.open()
                    }
                    ActionButton {
                        width: Math.min(implicitWidth, parent.width)
                        visible: Updates.seedAvailable
                        variant: "ghost"
                        text: Style.compact ? "Réinstaller la base fournie" : "Réinstaller la base fournie (" + Updates.seedVersionLabel + ")"
                        enabled: !page.busy
                        onClicked: Updates.installSeed()
                    }
                }
            }

            Section {
                Layout.fillWidth: true
                title: "Adresse de téléchargement"
                subtitle: "À ne modifier que si la base est publiée ailleurs (miroir de club, serveur local)."
                GridLayout {
                    Layout.fillWidth: true
                    columns: Style.compact ? 1 : 2
                    columnSpacing: 12
                    rowSpacing: 8
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
        nameFilters: App.mobile ? ["Archive ZIP (*.zip)"] : ["Base de questions (*.zip *.json)", "Tous les fichiers (*)"]
        onAccepted: Updates.importLocal(selectedFile)
    }
}
