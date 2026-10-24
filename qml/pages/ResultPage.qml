import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

Page {
    id: page
    property bool immersive: false
    background: Rectangle { color: Style.bg }

    readonly property var rows: Exam.snapshot()
    readonly property var partList: Exam.parts
    readonly property bool official: Exam.mode === "official"

    function fmt(n) {
        return (Math.round(n * 10) / 10).toLocaleString(Qt.locale("fr_FR"), "f", n % 1 === 0 ? 0 : 1)
    }
    function verdict() {
        if (partList.length > 1) {
            var ok = partList.filter(function (p) { return p.passed }).length
            if (ok === partList.length) return "Les deux épreuves sont réussies"
            if (ok === 0) return "Les deux épreuves sont à retravailler"
            return partList[0].passed ? "Réglementation réussie, technique à retravailler" : "Technique réussie, réglementation à retravailler"
        }
        if (Exam.passed) return page.official ? "Épreuve réussie" : "Objectif atteint"
        return page.official ? "Épreuve non réussie" : "Encore un effort"
    }
    function restart() {
        var ok = false
        if (Exam.mode === "official")
            ok = Exam.startOfficial(Exam.category, Exam.extendedTime)
        if (ok)
            Nav.window.startExam()
        else
            Nav.window.go(Exam.mode === "series" ? "series" : Exam.mode === "review" ? "review" : "training")
    }

    Flickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight + 80
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        ColumnLayout {
            id: content
            x: 48
            y: 40
            width: Math.min(1100, parent.width - 96)
            spacing: 28

            // Verdict ---------------------------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: verdictCol.implicitHeight + 56
                radius: Style.r2
                color: Style.surface
                border.color: Style.line
                Rectangle {
                    width: 6
                    height: parent.height
                    radius: 3
                    color: Exam.passed ? Style.green : Style.red
                }
                ColumnLayout {
                    id: verdictCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 40
                    anchors.rightMargin: 40
                    spacing: 18

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            Text {
                                text: Exam.title
                                font.family: Style.family
                                font.pixelSize: Style.fL
                                font.bold: true
                                color: Style.muted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            Text {
                                text: page.verdict()
                                font.family: Style.family
                                font.pixelSize: Style.fXl + 4
                                font.bold: true
                                color: Exam.passed ? Style.green : Style.red
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                        Text {
                            text: "Durée " + App.formatDuration(Exam.elapsedSeconds) + (Exam.timed ? " sur " + App.formatDuration(Exam.durationSeconds) : "")
                                  + (Exam.timeExpired ? "\nTemps écoulé" : "")
                            font.family: Style.family
                            font.pixelSize: Style.fM
                            color: Style.muted
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 56
                        Repeater {
                            model: page.partList
                            delegate: ColumnLayout {
                                required property var modelData
                                spacing: 6
                                Text {
                                    visible: page.partList.length > 1 || page.official
                                    text: modelData.title
                                    font.family: Style.family
                                    font.pixelSize: Style.fM
                                    font.bold: true
                                    color: Style.text
                                }
                                ScoreBadge {
                                    note: modelData.note20
                                    passed: modelData.passed
                                    size: page.partList.length > 1 ? 80 : 104
                                }
                                Text {
                                    text: modelData.correct + " bonne" + (modelData.correct > 1 ? "s" : "") + " réponse" + (modelData.correct > 1 ? "s" : "") + " sur " + modelData.count
                                    font.family: Style.family
                                    font.pixelSize: Style.fM
                                    color: Style.text
                                }
                                Text {
                                    text: modelData.wrong + " fausse" + (modelData.wrong > 1 ? "s" : "") + ", " + modelData.blank + " sans réponse"
                                    font.family: Style.family
                                    font.pixelSize: Style.fS
                                    color: Style.muted
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }

                    Text {
                        text: Exam.passMarkLabel + ". " + Exam.schemeLabel + "."
                        font.family: Style.family
                        font.pixelSize: Style.fS
                        color: Style.muted
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Actions ------------------------------------------------------------------------------------
            Flow {
                Layout.fillWidth: true
                spacing: 12
                ActionButton {
                    text: "Voir la correction"
                    iconName: "eye"
                    onClicked: Nav.window.open("CorrectionPage")
                }
                ActionButton {
                    variant: "secondary"
                    text: page.official ? "Repasser un examen blanc" : "Nouvelle session"
                    iconName: "refresh"
                    onClicked: page.restart()
                }
                ActionButton {
                    variant: "ghost"
                    text: "Accueil"
                    iconName: "home"
                    onClicked: Nav.window.go("home")
                }
            }

            // Question strip --------------------------------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                Text {
                    text: "Vos réponses, question par question"
                    font.family: Style.family
                    font.pixelSize: Style.fXl
                    font.bold: true
                    color: Style.text
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: page.rows
                        delegate: AbstractButton {
                            id: cell
                            required property var modelData
                            implicitWidth: 46
                            implicitHeight: 46
                            hoverEnabled: true
                            onClicked: Nav.window.open("CorrectionPage", { startAt: modelData.index })
                            ToolTip.visible: hovered
                            ToolTip.text: modelData.themeName
                            Accessible.name: "Question " + modelData.position + (modelData.status === 1 ? ", juste" : modelData.status === 2 ? ", fausse" : ", sans réponse")
                            background: Rectangle {
                                radius: Style.r1
                                color: cell.modelData.status === 1 ? Style.green : cell.modelData.status === 2 ? Style.red : Style.surface
                                border.color: cell.modelData.status === 3 ? Style.muted : "transparent"
                                border.width: cell.hovered ? 3 : 1
                            }
                            contentItem: Text {
                                text: cell.modelData.position
                                font.family: Style.family
                                font.pixelSize: Style.fM
                                font.bold: true
                                color: cell.modelData.status === 3 ? Style.text : "#FFFFFF"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
                RowLayout {
                    spacing: 18
                    Repeater {
                        model: [
                            { c: Style.green, l: "Juste" },
                            { c: Style.red, l: "Fausse ou plusieurs cases" },
                            { c: Style.surface, l: "Sans réponse" }
                        ]
                        delegate: RowLayout {
                            required property var modelData
                            spacing: 6
                            Rectangle { width: 14; height: 14; radius: 3; color: modelData.c; border.color: Style.muted }
                            Text { text: modelData.l; font.family: Style.family; font.pixelSize: Style.fS; color: Style.muted }
                        }
                    }
                }
            }

            // By theme ------------------------------------------------------------------------------------
            Section {
                Layout.fillWidth: true
                title: "Résultat par thème"
                subtitle: "Les thèmes avec des erreurs sont ceux à retravailler en priorité."
                Repeater {
                    model: Exam.themeBreakdown
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 16
                        Text {
                            text: modelData.name
                            font.family: Style.family
                            font.pixelSize: Style.fM
                            color: Style.text
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.preferredWidth: 420
                        }
                        Rectangle {
                            Layout.preferredWidth: 220
                            height: 10
                            radius: 5
                            color: Style.redSoft
                            visible: modelData.total > 0
                            Rectangle {
                                width: parent.width * modelData.correct / modelData.total
                                height: parent.height
                                radius: 5
                                color: Style.green
                            }
                        }
                        Text {
                            text: modelData.correct + " / " + modelData.total
                            font.family: Style.family
                            font.pixelSize: Style.fM
                            font.bold: true
                            color: modelData.correct === modelData.total ? Style.green : Style.text
                            Layout.preferredWidth: 52
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
    }
}
