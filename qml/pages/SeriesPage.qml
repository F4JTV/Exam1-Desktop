import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

// Fixed series published with the question bank: everybody gets the same questions,
// which makes them convenient for group sessions in a radio club.
Page {
    id: page
    property bool immersive: false
    background: Rectangle { color: Style.bg }

    property string type: "legislation"
    property bool timed: true
    property bool instant: false

    readonly property var series: Bank.seriesCount >= 0 ? Bank.seriesList(type === "progression" ? "progression" : type) : []
    readonly property var done: {
        var map = {}
        var r = User.revision >= 0 ? User.results("", 0) : []
        for (var i = r.length - 1; i >= 0; --i)
            if (r[i].mode === "series")
                map[r[i].title] = r[i]
        return map
    }

    function start(name) {
        if (Exam.startSeries(name, timed, instant))
            Nav.window.startExam()
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
            width: Math.min(1240, parent.width - 96)
            spacing: 24

            PageHeader {
                Layout.fillWidth: true
                title: "Séries de questions"
                subtitle: "Chaque série propose les mêmes questions à tous les candidats : pratique pour corriger ensemble en radio-club."
            }

            // Wraps onto several lines on a narrow window.
            Flow {
                Layout.fillWidth: true
                spacing: 24
                SegmentedChoice {
                    value: page.type
                    options: [
                        { value: "legislation", label: "Réglementation" },
                        { value: "technique", label: "Technique" },
                        { value: "progression", label: "Progression" }
                    ]
                    onActivated: (v) => page.type = v
                }
                CheckRow {
                    text: "Chronométrer"
                    checked: page.timed
                    onToggled: page.timed = checked
                }
                CheckRow {
                    text: "Correction immédiate"
                    checked: page.instant
                    onToggled: page.instant = checked
                }
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.family: Style.family
                font.pixelSize: Style.fS
                color: Style.muted
                text: page.type === "progression"
                      ? "Les séries de progression (C et P) mélangent les thèmes pour suivre l'avancement d'une formation."
                      : "Séries de 20 questions, " + (page.type === "technique" ? "30" : "15") + " minutes quand elles sont chronométrées, comme à l'examen."
            }

            GridLayout {
                Layout.fillWidth: true
                visible: page.series.length > 0
                columns: Math.max(1, Math.floor((col.width + 12) / (Math.round(170 * Style.k) + 12)))
                columnSpacing: 12
                rowSpacing: 12
                Repeater {
                    model: page.series
                    delegate: AbstractButton {
                        id: tile
                        required property var modelData
                        readonly property var last: page.done["Série " + modelData.name]
                        Layout.fillWidth: true
                        implicitHeight: 86
                        hoverEnabled: true
                        onClicked: page.start(modelData.name)
                        Accessible.name: "Série " + modelData.name
                        background: Rectangle {
                            radius: Style.r2
                            color: tile.hovered ? Style.sheet : Style.surface
                            border.width: tile.visualFocus ? 2 : 1
                            border.color: tile.visualFocus ? Style.focus : (tile.hovered ? Style.sheetEdge : Style.line)
                        }
                        contentItem: ColumnLayout {
                            spacing: 2
                            Text {
                                text: tile.modelData.name
                                font.family: Style.family
                                font.pixelSize: Style.fXl
                                font.bold: true
                                color: tile.hovered ? Style.sheetInk : Style.text
                                Layout.leftMargin: 16
                            }
                            Text {
                                text: tile.last ? "Dernière note " + Math.round(tile.last.note20) + "/20" : tile.modelData.count + " questions"
                                font.family: Style.family
                                font.pixelSize: Style.fS
                                color: tile.last ? (tile.last.passed ? Style.green : Style.red) : (tile.hovered ? "#4E5A66" : Style.muted)
                                font.bold: !!tile.last
                                Layout.leftMargin: 16
                            }
                        }
                    }
                }
            }

            Section {
                visible: page.series.length === 0
                Layout.fillWidth: true
                title: Bank.seriesCount === 0 ? "Aucune série dans la base installée" : "Aucune série de ce type"
                subtitle: "Les séries sont publiées avec les questions par le REF. Mettez la base à jour pour les obtenir."
                ActionButton {
                    text: "Aller à la mise à jour"
                    iconName: "refresh"
                    onClicked: Nav.window.go("update")
                }
            }
        }
    }
}
