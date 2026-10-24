import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

Page {
    id: page
    property bool immersive: false
    background: Rectangle { color: Style.bg }

    component Credit: RowLayout {
        property string who: ""
        property string what: ""
        Layout.fillWidth: true
        spacing: 16
        Text {
            text: parent.who
            font.family: Style.family
            font.pixelSize: Style.fM
            font.bold: true
            color: Style.text
            Layout.preferredWidth: 260
            wrapMode: Text.WordWrap
        }
        Text {
            text: parent.what
            font.family: Style.family
            font.pixelSize: Style.fM
            color: Style.muted
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }

    component Link: Text {
        property string url: ""
        font.family: Style.family
        font.pixelSize: Style.fM
        color: Style.blue
        font.underline: area.containsMouse
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: App.openUrl(parent.url)
        }
    }

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

            RowLayout {
                spacing: 24
                Image {
                    source: "qrc:/qt/qml/Exam1App/resources/icons/exam1.png"
                    sourceSize: Qt.size(96, 96)
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 96
                }
                ColumnLayout {
                    spacing: 4
                    Text {
                        text: "Exam'1 " + App.version
                        font.family: Style.family
                        font.pixelSize: Style.fXxl
                        font.bold: true
                        color: Style.text
                    }
                    Text {
                        text: "Simulateur de l'examen du certificat d'opérateur du service amateur (radioamateur), Qt " + App.qtVersion + "."
                        font.family: Style.family
                        font.pixelSize: Style.fM
                        color: Style.muted
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            Section {
                Layout.fillWidth: true
                title: "Remerciements"
                Credit { who: "Jean-Luc, F6GPX"; what: "Auteur de la base de questions, mise à jour chaque trimestre à partir des comptes rendus des candidats." }
                Credit { who: "René Bussy, F5AXG, et Arnaud Dussart"; what: "Auteurs du logiciel Exam'1 d'origine pour Windows." }
                Credit { who: "André, F8DEM"; what: "Contributeur historique d'Exam'1." }
                Credit { who: "Valentin, F4HVV"; what: "Version web d'Exam'1 et publication de la base sur les serveurs du REF." }
                Credit { who: "Maxime, F4IQN"; what: "Version Android d'Exam'1." }
                Credit { who: "Radio-club de la Haute Île F6KGL / F5KFF"; what: "Cours en ligne vers lequel renvoient les corrections." }
                Credit { who: "Les candidats"; what: "Qui envoient après l'examen les questions qu'ils ont eues." }
            }

            Section {
                Layout.fillWidth: true
                title: "Liens utiles"
                Link { text: "Page Exam'1 du radio-club F6KGL / F5KFF"; url: "https://f6kgl-f5kff.fr/exam1/" }
                Link { text: "Cours de F6KGL pour préparer l'examen"; url: "http://f6kgl.free.fr/COURS.html" }
                Link { text: "Présentation des épreuves par l'ANFR"; url: "https://www.anfr.fr/gerer/radioamateurs/presentation-des-epreuves-dexamen" }
                Link { text: "Liste examen-radioamateur : comptes rendus d'examen"; url: "https://groups.google.com/forum/#!forum/examen-radioamateur" }
            }

            Section {
                Layout.fillWidth: true
                title: "Envoyer vos questions"
                subtitle: "Après l'examen, notez les questions dont vous vous souvenez et envoyez-les à la liste examen-radioamateur : c'est ainsi que la base reste à jour pour les suivants."
            }

            Section {
                Layout.fillWidth: true
                title: "Clavier pendant l'examen"
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Style.family
                    font.pixelSize: Style.fM
                    color: Style.text
                    text: "A, B, C, D (ou 1 à 4) cochent ou décochent une réponse de la question en haut de l'écran ; P l'épingle ; Espace passe à la question suivante ; flèches et Page haut / bas font défiler."
                }
            }

            Section {
                Layout.fillWidth: true
                title: "Licences"
                subtitle: "Police Atkinson Hyperlegible : SIL Open Font License (Braille Institute). Décompression ZIP : miniz, licence MIT. Interface : Qt 6, LGPL v3. Questions et images : propriété de leurs auteurs, utilisées avec leur accord."
            }
        }
    }
}
