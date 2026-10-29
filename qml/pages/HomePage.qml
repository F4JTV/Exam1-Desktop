import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

Page {
    id: page
    property bool immersive: false
    background: Rectangle { color: Style.bg }

    property var summary: User.summary()
    Connections {
        target: User
        function onDataChanged() { page.summary = User.summary() }
    }

    function lastNote(list) {
        if (!list || list.length === 0)
            return ""
        var n = list[list.length - 1].note20
        return "Dernière note : " + (Math.round(n * 10) / 10).toLocaleString(Qt.locale("fr_FR"), "f", n % 1 === 0 ? 0 : 1) + "/20"
    }

    function startOfficial(cat) {
        if (Exam.startOfficial(cat, Prefs.extendedTime))
            Nav.window.startExam()
    }

    component Plate: AbstractButton {
        id: plate
        property string heading: ""
        property string detail: ""
        property string note: ""
        hoverEnabled: true
        implicitWidth: Math.round(300 * Style.k)
        implicitHeight: Math.max(Math.round(178 * Style.k), col.implicitHeight)
        Accessible.name: heading + ". " + detail
        background: Rectangle {
            radius: Style.r2
            color: Style.sheet
            border.width: plate.hovered || plate.visualFocus ? 4 : 0
            border.color: Style.yellow
        }
        contentItem: ColumnLayout {
            id: col
            spacing: 6
            Text {
                text: "Épreuve de"
                font.family: Style.family
                font.pixelSize: Style.fM
                color: "#4E5A66"
                Layout.leftMargin: 26
                Layout.topMargin: 22
            }
            Text {
                text: plate.heading
                font.family: Style.family
                font.pixelSize: Style.fXl + 6
                font.bold: true
                color: Style.sheetInk
                Layout.leftMargin: 26
            }
            Text {
                text: plate.detail
                font.family: Style.family
                font.pixelSize: Style.fM
                color: Style.sheetInk
                Layout.leftMargin: 26
            }
            Item { Layout.fillHeight: true; Layout.minimumHeight: 16 }
            RowLayout {
                Layout.leftMargin: 26
                Layout.rightMargin: 22
                Layout.bottomMargin: 18
                Layout.fillWidth: true
                Text {
                    text: plate.note
                    font.family: Style.family
                    font.pixelSize: Style.fS
                    color: "#4E5A66"
                    Layout.fillWidth: true
                }
                Text {
                    text: "Commencer"
                    font.family: Style.family
                    font.pixelSize: Style.fM
                    font.bold: true
                    color: Style.blueStrong
                }
                Icon { name: "chevron-right"; color: Style.blueStrong; size: 18 }
            }
        }
    }

    component Pathway: AbstractButton {
        id: pw
        property string iconName: ""
        property string heading: ""
        property string detail: ""
        property string key: ""
        hoverEnabled: true
        Layout.fillWidth: true
        implicitHeight: 78
        onClicked: Nav.window.go(key)
        Accessible.name: heading
        background: Rectangle {
            color: pw.hovered ? Style.surfaceAlt : Style.surface
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Style.line }
            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                color: "transparent"
                border.width: 2
                border.color: Style.focus
                visible: pw.visualFocus
            }
        }
        contentItem: RowLayout {
            spacing: 16
            Rectangle {
                Layout.leftMargin: 20
                width: 40
                height: 40
                radius: 20
                color: Style.blueSoft
                Icon { anchors.centerIn: parent; name: pw.iconName; color: Style.blue; size: 20 }
            }
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Text {
                    text: pw.heading
                    font.family: Style.family
                    font.pixelSize: Style.fL
                    font.bold: true
                    color: Style.text
                }
                Text {
                    text: pw.detail
                    font.family: Style.family
                    font.pixelSize: Style.fS
                    color: Style.muted
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
            Icon { name: "chevron-right"; color: Style.muted; size: 20; Layout.rightMargin: 20 }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 0

            // Unfinished session found on disk (power cut, crash...)
            Rectangle {
                visible: Exam.hasSavedSession
                Layout.fillWidth: true
                implicitHeight: resumeRow.implicitHeight + 28
                color: Style.pinSoft
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Style.pin; opacity: 0.4 }
                readonly property var info: Exam.savedSessionInfo
                RowLayout {
                    id: resumeRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 48
                    anchors.rightMargin: 48
                    spacing: 16
                    Icon { name: "clock"; color: Style.pin; size: 22 }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.family: Style.family
                        font.pixelSize: Style.fM
                        color: Style.text
                        text: {
                            var i = parent.parent.info
                            if (!i || !i.title) return ""
                            return "Une session n'a pas été terminée : " + i.title + ", " + i.answered + " réponse" + (i.answered > 1 ? "s" : "") + " sur " + i.count
                                   + (i.remaining >= 0 ? ", " + App.formatDuration(i.remaining) + " restantes" : "") + " (sauvegarde du " + i.savedAt + ")."
                        }
                    }
                    ActionButton {
                        text: "Reprendre"
                        onClicked: if (Exam.resumeSaved()) Nav.window.startExam()
                    }
                    ActionButton {
                        variant: "secondary"
                        text: "Abandonner"
                        onClicked: Exam.discardSaved()
                    }
                }
            }

            // Hero: the two official tests, as yellow question sheets on the slate desk.
            // Text beside the sheets when there is room for both, above them otherwise; the two
            // sheets side by side when they fit, one above the other on a very narrow window.
            Rectangle {
                id: hero
                Layout.fillWidth: true
                implicitHeight: heroGrid.implicitHeight + 88
                color: Style.slate

                readonly property real room: page.width - 96
                readonly property real platesWidth: 2 * Math.round(300 * Style.k) + 18
                readonly property bool sideBySide: room >= Math.max(platesWidth, 640 * Style.k) + 40 + 340 * Style.k
                readonly property bool platesInRow: room >= platesWidth

                GridLayout {
                    id: heroGrid
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 48
                    anchors.rightMargin: 48
                    columns: hero.sideBySide ? 2 : 1
                    columnSpacing: 40
                    rowSpacing: 28

                    Column {
                        id: heroText
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 14
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
                            width: Math.min(heroText.width, 640 * Style.k)
                            text: "Entraînez-vous au certificat d'opérateur radioamateur dans les conditions de l'examen ANFR : 20 questions par épreuve, un temps limité, une seule réponse juste."
                            font.family: Style.family
                            font.pixelSize: Style.fL
                            color: Style.slateText
                            wrapMode: Text.WordWrap
                            lineHeight: 1.15
                        }
                        Text {
                            width: heroText.width
                            text: "Bonjour " + User.currentCandidateName + "."
                            font.family: Style.family
                            font.pixelSize: Style.fM
                            color: Style.slateTextMuted
                            wrapMode: Text.WordWrap
                        }
                    }

                    ColumnLayout {
                        spacing: 14
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: !hero.sideBySide
                        GridLayout {
                            id: plates
                            Layout.fillWidth: true
                            columns: hero.platesInRow ? 2 : 1
                            columnSpacing: 18
                            rowSpacing: 18
                            Plate {
                                Layout.fillWidth: true
                                heading: "réglementation"
                                detail: "20 questions en " + (Prefs.extendedTime ? 45 : 15) + " minutes"
                                note: page.lastNote(page.summary.reglementation)
                                enabled: Bank.ready
                                onClicked: page.startOfficial("reglementation")
                            }
                            Plate {
                                Layout.fillWidth: true
                                heading: "technique"
                                detail: "20 questions en " + (Prefs.extendedTime ? 90 : 30) + " minutes"
                                note: page.lastNote(page.summary.technique)
                                enabled: Bank.ready
                                onClicked: page.startOfficial("technique")
                            }
                        }
                        // On one line beside the text (the block widens a little if needed), wrapped
                        // onto two lines when the window is too narrow for both.
                        Flow {
                            Layout.fillWidth: true
                            Layout.preferredWidth: Math.max(plates.implicitWidth, extended.implicitWidth + spacing + complete.implicitWidth)
                            spacing: 14
                            CheckRow {
                                id: extended
                                text: "Temps aménagé (durée triplée)"
                                labelColor: Style.slateText
                                checked: Prefs.extendedTime
                                onToggled: Prefs.extendedTime = checked
                                ToolTip.visible: hovered
                                ToolTip.delay: 600
                                ToolTip.text: "Accordé à l'examen aux candidats ayant un taux d'incapacité d'au moins 70 %."
                            }
                            ActionButton {
                                id: complete
                                variant: "dark"
                                compact: true
                                text: "Examen complet : 40 questions en " + (Prefs.extendedTime ? 135 : 45) + " minutes"
                                enabled: Bank.ready
                                onClicked: page.startOfficial("both")
                                ToolTip.visible: hovered
                                ToolTip.delay: 600
                                ToolTip.text: "Les deux épreuves dans une seule liste, comme la démonstration de l'ANFR : questions 1 à 20 en réglementation, 21 à 40 en technique."
                            }
                        }
                    }
                }
            }

            // Below the hero: other ways to practise, and progress (stacked on a narrow window).
            GridLayout {
                Layout.fillWidth: true
                Layout.margins: 40
                Layout.maximumWidth: 1240
                columns: page.width - 80 >= 880 * Style.k ? 2 : 1
                columnSpacing: 32
                rowSpacing: 32

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 3
                    Layout.alignment: Qt.AlignTop
                    spacing: 12
                    Text {
                        text: "S'entraîner autrement"
                        font.family: Style.family
                        font.pixelSize: Style.fXl
                        font.bold: true
                        color: Style.text
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: paths.implicitHeight
                        color: Style.surface
                        radius: Style.r2
                        border.color: Style.line
                        clip: true
                        ColumnLayout {
                            id: paths
                            width: parent.width
                            spacing: 0
                            Pathway {
                                key: "training"
                                iconName: "target"
                                heading: "Entraînement par thèmes"
                                detail: "Choisissez les familles de questions, le nombre de questions et la correction immédiate."
                            }
                            Pathway {
                                key: "series"
                                iconName: "layers"
                                heading: "Séries de questions"
                                detail: Bank.seriesCount > 0 ? Bank.seriesCount + " séries identiques pour tous, idéales en radio-club." : "Séries communes pour travailler en groupe."
                            }
                            Pathway {
                                key: "review"
                                iconName: "bookmark"
                                heading: "Révisions"
                                detail: "Reprenez vos erreurs, vos questions enregistrées ou celles jamais vues."
                            }
                            Pathway {
                                key: "browser"
                                iconName: "search"
                                heading: "Base de questions"
                                detail: Bank.questionCount + " questions consultables avec leur correction et le lien vers le cours."
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 2
                    Layout.alignment: Qt.AlignTop
                    spacing: 12
                    Text {
                        text: "Votre progression"
                        font.family: Style.family
                        font.pixelSize: Style.fXl
                        font.bold: true
                        color: Style.text
                    }
                    Section {
                        Layout.fillWidth: true
                        GridLayout {
                            columns: 2
                            columnSpacing: 24
                            rowSpacing: 8
                            Layout.fillWidth: true
                            Text { text: "Réglementation"; font.family: Style.family; font.pixelSize: Style.fS; font.bold: true; color: Style.text; Layout.fillWidth: true; elide: Text.ElideRight }
                            Text { text: "Technique"; font.family: Style.family; font.pixelSize: Style.fS; font.bold: true; color: Style.text; Layout.fillWidth: true; elide: Text.ElideRight }
                            NoteBar { values: page.summary.reglementation || []; Layout.fillWidth: true; implicitHeight: 70 }
                            NoteBar { values: page.summary.technique || []; Layout.fillWidth: true; implicitHeight: 70 }
                        }
                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            font.family: Style.family
                            font.pixelSize: Style.fS
                            color: Style.muted
                            text: "Dix dernières épreuves blanches. Le trait marque la moyenne de 10/20."
                        }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Style.line }
                        GridLayout {
                            columns: 2
                            columnSpacing: 12
                            rowSpacing: 6
                            Layout.fillWidth: true
                            Text { text: "Épreuves passées"; font.family: Style.family; font.pixelSize: Style.fM; color: Style.muted; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            Text { text: (page.summary.exams || 0) + (page.summary.passed ? "  (" + page.summary.passed + " réussies)" : ""); font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text; Layout.alignment: Qt.AlignRight | Qt.AlignTop }
                            Text { text: "Questions déjà vues"; font.family: Style.family; font.pixelSize: Style.fM; color: Style.muted; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            Text {
                                text: (page.summary.askedDistinct || 0) + " sur " + Bank.questionCount
                                font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text
                                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                            }
                            Text { text: "Questions enregistrées"; font.family: Style.family; font.pixelSize: Style.fM; color: Style.muted; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            Text { text: User.savedCount; font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text; Layout.alignment: Qt.AlignRight | Qt.AlignTop }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 8
                            radius: 4
                            color: Style.surfaceAlt
                            border.color: Style.line
                            Rectangle {
                                height: parent.height
                                radius: 4
                                width: Bank.questionCount > 0 ? parent.width * Math.min(1, (page.summary.askedDistinct || 0) / Bank.questionCount) : 0
                                color: Style.blue
                            }
                        }
                    }

                    Section {
                        Layout.fillWidth: true
                        title: Updates.updateAvailable ? "Nouvelles questions disponibles" : "Base de questions"
                        subtitle: Updates.updateAvailable
                                  ? "Version du " + Updates.remoteVersionLabel + " publiée par le REF (" + Updates.remoteCount + " questions)."
                                  : Bank.questionCount + " questions, version du " + Bank.versionLabel + "."
                        ActionButton {
                            visible: Updates.updateAvailable
                            text: "Installer la mise à jour"
                            iconName: "download"
                            onClicked: { Updates.installUpdate(); Nav.window.go("update") }
                        }
                        ActionButton {
                            visible: !Updates.updateAvailable
                            variant: "secondary"
                            compact: true
                            iconName: "refresh"
                            text: Updates.state === UpdaterState.Checking ? "Vérification…" : "Vérifier les nouvelles questions"
                            enabled: !Updates.busy
                            onClicked: Nav.window.go("update")
                        }
                    }
                }
            }
        }
    }
}
