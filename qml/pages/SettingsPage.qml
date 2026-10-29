import QtQuick
import QtQuick.Controls
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
            x: 48
            y: 40
            width: Math.min(900, parent.width - 96)
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
                    text: "Énoncé pendant l'examen"
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
                    text: "Comme à l'examen, seules les questions avec un schéma, une formule ou un dessin affichent une image ; les autres sont présentées en texte. Ces questions sont repérées par Jean-Luc F6GPX dans son fichier de la base."
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
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Style.family
                    font.pixelSize: Style.fS
                    color: Style.muted
                    text: "L'écran d'examen reste clair, comme celui de l'ANFR."
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
            }

            Section {
                Layout.fillWidth: true
                title: "Données"
                subtitle: (App.portable ? "Mode portable : les données sont enregistrées à côté du logiciel, dans " : "Vos notes, candidats et la base de questions sont enregistrés dans ") + App.dataDir
                ActionButton {
                    variant: "secondary"
                    iconName: "folder"
                    text: "Ouvrir le dossier"
                    onClicked: App.openDataFolder()
                }
            }
        }
    }
}
