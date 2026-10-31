import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Exam1.Core
import Exam1App

Page {
    id: page
    property bool immersive: false
    background: Rectangle { color: Style.bg }

    Flickable {
        anchors.fill: parent
        contentHeight: col.implicitHeight + 80
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        ColumnLayout {
            id: col
            x: Style.margin
            y: Style.compact ? 20 : 40
            width: Math.min(900, parent.width - 2 * Style.margin)
            spacing: 24

            PageHeader {
                Layout.fillWidth: true
                title: "Paramètres"
            }

            Section {
                Layout.fillWidth: true
                title: "Notation"
                subtitle: "Depuis juin 2021, l'ANFR compte 1 point par bonne réponse et 0 point sinon, y compris quand plusieurs cases sont cochées. Il faut 10/20 à chaque épreuve."
                SegmentedChoice {
                    value: Prefs.scheme
                    options: [
                        { value: "anfr2021", label: "Barème ANFR actuel" },
                        { value: "legacy", label: "Ancien barème (+3 / −1)" }
                    ]
                    onActivated: (v) => Prefs.scheme = v
                }
            }

            Section {
                Layout.fillWidth: true
                title: "Questions"
                CheckRow {
                    Layout.fillWidth: true
                    text: "Mélanger l'ordre des réponses"
                    detail: "Les propositions sont présentées dans un ordre différent à chaque tirage."
                    checked: Prefs.shuffleAnswers
                    onToggled: Prefs.shuffleAnswers = checked
                }
                CheckRow {
                    Layout.fillWidth: true
                    text: "Privilégier les questions les moins vues"
                    detail: "Le tirage choisit d'abord les questions qui vous ont été posées le moins souvent."
                    checked: Prefs.favorUnseen
                    onToggled: Prefs.favorUnseen = checked
                }
                Text {
                    text: "Énoncé des questions"
                    font.family: Style.family
                    font.pixelSize: Style.fM
                    font.bold: true
                    color: Style.text
                    Layout.topMargin: 8
                }
                SegmentedChoice {
                    value: Prefs.statementMode
                    options: [
                        { value: "auto", label: "Comme à l'examen ANFR" },
                        { value: "image", label: "Toujours l'image d'Exam'1" }
                    ]
                    onActivated: (v) => Prefs.statementMode = v
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Style.family
                    font.pixelSize: Style.fS
                    color: Style.muted
                    text: "Comme à l'examen, seules les questions avec un schéma, une formule ou un dessin affichent une image ; les autres sont présentées en texte, aux épreuves, à l'entraînement, dans les corrections et dans la base de questions. Ces questions sont repérées par Jean-Luc F6GPX dans son fichier de la base."
                }
                Text {
                    text: "Numéro des questions"
                    font.family: Style.family
                    font.pixelSize: Style.fM
                    font.bold: true
                    color: Style.text
                    Layout.topMargin: 8
                }
                SegmentedChoice {
                    value: Prefs.questionNumbers
                    options: [
                        { value: "training", label: "À l'entraînement" },
                        { value: "always", label: "Toujours" },
                        { value: "never", label: "Jamais" }
                    ]
                    onActivated: (v) => Prefs.questionNumbers = v
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Style.family
                    font.pixelSize: Style.fS
                    color: Style.muted
                    text: "Le numéro de la question dans la base (par exemple n° 20003) s'affiche à côté de « Question 11 / 20 ». Notez-le pour retravailler la question plus tard : il se recherche dans « Base de questions ». En examen blanc, il n'apparaît qu'avec « Toujours » : l'examen ANFR ne l'affiche pas."
                }
            }

            Section {
                Layout.fillWidth: true
                title: "Affichage"
                Text { text: "Thème"; font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text }
                SegmentedChoice {
                    value: Prefs.colorScheme
                    options: [
                        { value: "light", label: "Clair" },
                        { value: "dark", label: "Sombre" }
                    ]
                    onActivated: (v) => Prefs.colorScheme = v
                }
                Text { text: "Écran d'examen et corrections"; font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text; Layout.topMargin: 8 }
                SegmentedChoice {
                    value: Prefs.examTheme
                    options: [
                        { value: "light", label: "Clair, comme à l'ANFR" },
                        { value: "dark", label: "Sombre" }
                    ]
                    onActivated: (v) => Prefs.examTheme = v
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Style.family
                    font.pixelSize: Style.fS
                    color: Style.muted
                    text: "L'examen de l'ANFR se passe sur un écran blanc : gardez « Clair » pour vous y habituer. « Sombre » repose les yeux le soir ; il se change aussi pendant l'examen, dans le menu d'accessibilité."
                }
                Text { text: "Taille du texte"; font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text; Layout.topMargin: 8 }
                SegmentedChoice {
                    value: Math.round(Prefs.textScale * 10) / 10
                    options: [
                        { value: 0.9, label: "Petite" },
                        { value: 1.0, label: "Normale" },
                        { value: 1.2, label: "Grande" },
                        { value: 1.4, label: "Très grande" }
                    ]
                    onActivated: (v) => Prefs.textScale = v
                }
            }

            Section {
                Layout.fillWidth: true
                title: "Mises à jour"
                CheckRow {
                    Layout.fillWidth: true
                    text: "Rechercher les nouvelles questions au démarrage"
                    detail: "Une vérification rapide (environ 1 Mo). Rien n'est installé sans votre accord."
                    checked: Prefs.autoCheckUpdates
                    onToggled: Prefs.autoCheckUpdates = checked
                }
                CheckRow {
                    Layout.fillWidth: true
                    text: "Rechercher les nouvelles versions de l'application au démarrage"
                    detail: "Exam'1 demande à GitHub le numéro de la dernière version publiée. Rien n'est téléchargé sans votre accord."
                    checked: Prefs.autoCheckApp
                    onToggled: Prefs.autoCheckApp = checked
                }
            }

            Section {
                Layout.fillWidth: true
                title: "Données"
                subtitle: App.mobile
                          ? "Vos notes, candidats et questions enregistrées restent sur cet appareil. Ils sont conservés lors des mises à jour de l'application, font partie de la sauvegarde Android si elle est activée, et sont effacés si vous désinstallez l'application : exportez-les avant."
                          : (App.portable ? "Mode portable : les données sont enregistrées à côté du logiciel, dans " : "Vos notes, candidats et la base de questions sont enregistrés dans ") + App.dataDir
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    text: "Sauvegarde et transfert"
                    font.family: Style.family
                    font.pixelSize: Style.fM
                    font.bold: true
                    color: Style.text
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Style.family
                    font.pixelSize: Style.fS
                    color: Style.muted
                    text: "Exportez vos candidats, résultats, statistiques et questions enregistrées dans un fichier, pour les garder ou les retrouver sur un autre ordinateur ou téléphone. Importer ce fichier remplace les données de l'appareil."
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 12
                    ActionButton {
                        width: Math.min(implicitWidth, parent.width)
                        variant: "secondary"
                        iconName: "download"
                        text: "Exporter mes données"
                        onClicked: page.openExport()
                    }
                    ActionButton {
                        width: Math.min(implicitWidth, parent.width)
                        variant: "secondary"
                        iconName: "refresh"
                        text: "Importer une sauvegarde"
                        onClicked: importDialog.open()
                    }
                    ActionButton {
                        width: Math.min(implicitWidth, parent.width)
                        visible: !App.mobile
                        variant: "ghost"
                        iconName: "folder"
                        text: "Ouvrir le dossier"
                        onClicked: App.openDataFolder()
                    }
                }
            }
        }
    }

    function plural(n, one, many) { return n + " " + (n > 1 ? many : one) }
    function describe(info) {
        var s = plural(info.candidates, "candidat", "candidats")
        if (info.names)
            s += " (" + info.names + ")"
        return s + ", " + plural(info.results, "résultat", "résultats") + " et " + plural(info.asked, "question vue", "questions vues")
    }
    function showError(title, message) {
        errorDialog.title = title
        errorDialog.message = message
        errorDialog.open()
    }
    // The dialog proposes "Exam1-sauvegarde-<date>.exam1", in the documents folder on a computer.
    function openExport() {
        if (!App.mobile)
            exportDialog.currentFolder = StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        exportDialog.selectedFile = (App.mobile ? "" : exportDialog.currentFolder + "/") + User.exportFileName()
        exportDialog.open()
    }
    function exportTo(url) {
        var err = User.exportData(url)
        if (err.length > 0) {
            showError("Exportation impossible", err)
            return
        }
        var s = url.toString()
        Nav.window.toast(s.indexOf("content:") === 0 ? "Données exportées."
                         : "Données exportées : " + decodeURIComponent(s.substring(s.lastIndexOf("/") + 1)))
    }
    // The file is checked first, then the replacement is confirmed (or cancelled).
    function importFrom(url) {
        var info = User.prepareImport(url)
        if (!info.ok) {
            showError("Importation impossible", info.error)
            return
        }
        importConfirm.message = "La sauvegarde contient " + describe(info) + ".\n\nElle remplacera les données de cet appareil : "
                                + describe(User.contentSummary()) + ". Une copie de ces données est conservée dans le dossier de l'application."
        importConfirm.open()
    }

    // On a phone the system picker shows every file: a ".exam1" filter would hide the backups.
    FileDialog {
        id: exportDialog
        title: "Exporter mes données"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "exam1"
        acceptLabel: "Exporter"
        nameFilters: App.mobile ? [] : ["Sauvegarde Exam'1 (*.exam1)"]
        onAccepted: page.exportTo(selectedFile)
    }

    FileDialog {
        id: importDialog
        title: "Importer une sauvegarde"
        fileMode: FileDialog.OpenFile
        acceptLabel: "Importer"
        nameFilters: App.mobile ? [] : ["Sauvegarde Exam'1 (*.exam1)", "Tous les fichiers (*)"]
        onAccepted: page.importFrom(selectedFile)
    }

    ConfirmDialog {
        id: importConfirm
        title: "Remplacer les données de cet appareil ?"
        acceptText: "Importer"
        acceptVariant: "danger"
        onRejected: User.cancelImport()
        onAccepted: {
            var err = User.commitImport()
            if (err.length > 0)
                page.showError("Importation impossible", err)
            else
                Nav.window.toast("Sauvegarde importée : " + User.currentCandidateName)
        }
    }

    ConfirmDialog {
        id: errorDialog
        rejectText: ""
        acceptText: "OK"
    }
}
