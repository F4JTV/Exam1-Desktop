import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

Page {
    id: page
    property bool immersive: false
    background: Rectangle { color: Style.bg }

    property string filter: "all"
    readonly property var all: User.revision >= 0 ? User.results("", 0) : []
    readonly property var rows: all.filter(function (r) {
        if (filter === "reglementation") return r.mode === "official" && r.category === "reglementation"
        if (filter === "technique") return r.mode === "official" && r.category === "technique"
        if (filter === "training") return r.mode !== "official"
        return true
    })
    function marks(cat) {
        var out = []
        for (var i = all.length - 1; i >= 0; --i)
            if (all[i].mode === "official" && all[i].category === cat)
                out.push({ note20: all[i].note20, passed: all[i].passed })
        return out
    }
    function fmt(n) {
        return (Math.round(n * 10) / 10).toLocaleString(Qt.locale("fr_FR"), "f", n % 1 === 0 ? 0 : 1)
    }
    property int pendingDelete: 0

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
                title: "Résultats"
                subtitle: User.currentCandidateName + " : " + page.all.length + " épreuve" + (page.all.length > 1 ? "s" : "") + " et entraînement" + (page.all.length > 1 ? "s" : "") + " enregistré" + (page.all.length > 1 ? "s" : "") + "."
            }

            // Side by side, or one under the other on a narrow window.
            GridLayout {
                Layout.fillWidth: true
                columns: col.width >= 640 * Style.k ? 2 : 1
                columnSpacing: 24
                rowSpacing: 24
                Repeater {
                    model: [
                        { cat: "reglementation", label: "Épreuves blanches de réglementation" },
                        { cat: "technique", label: "Épreuves blanches de technique" }
                    ]
                    delegate: Section {
                        id: sec
                        required property var modelData
                        Layout.fillWidth: true
                        title: modelData.label
                        readonly property var m: page.marks(modelData.cat)
                        subtitle: m.length === 0 ? "Aucune épreuve passée pour l'instant."
                                  : m.length + " épreuve" + (m.length > 1 ? "s" : "") + ", " + m.filter(function (x) { return x.passed }).length + " réussie" + (m.filter(function (x) { return x.passed }).length > 1 ? "s" : "")
                        NoteBar {
                            Layout.fillWidth: true
                            implicitHeight: 110
                            values: sec.m
                            maxBars: 20
                        }
                    }
                }
            }

            SegmentedChoice {
                value: page.filter
                options: [
                    { value: "all", label: "Tout" },
                    { value: "reglementation", label: "Réglementation" },
                    { value: "technique", label: "Technique" },
                    { value: "training", label: "Entraînements et séries" }
                ]
                onActivated: (v) => page.filter = v
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: table.implicitHeight
                color: Style.surface
                radius: Style.r2
                border.color: Style.line
                clip: true
                visible: page.rows.length > 0

                ColumnLayout {
                    id: table
                    width: parent.width
                    spacing: 0
                    Repeater {
                        model: page.rows
                        delegate: Rectangle {
                            id: rowItem
                            required property var modelData
                            required property int index
                            // Narrow window: date, figures and duration go under the title.
                            readonly property bool compact: table.width < 1100 * Style.k
                            readonly property string figures: modelData.correct + " juste" + (modelData.correct > 1 ? "s" : "") + ", " + modelData.wrong + " fausse" + (modelData.wrong > 1 ? "s" : "") + ", " + modelData.blank + " vide" + (modelData.blank > 1 ? "s" : "")
                            Layout.fillWidth: true
                            implicitHeight: Math.max(64, rowLine.implicitHeight + 20)
                            color: index % 2 ? Style.surfaceAlt : Style.surface
                            RowLayout {
                                id: rowLine
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 12
                                spacing: 16
                                Rectangle {
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: modelData.passed ? Style.green : Style.red
                                }
                                Text {
                                    visible: !rowItem.compact
                                    text: modelData.dateLabel
                                    font.family: Style.family
                                    font.pixelSize: Style.fS
                                    color: Style.muted
                                    Layout.preferredWidth: Math.round(130 * Style.k)
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        text: modelData.title
                                        font.family: Style.family
                                        font.pixelSize: Style.fM
                                        font.bold: true
                                        color: Style.text
                                        elide: rowItem.compact ? Text.ElideNone : Text.ElideRight
                                        wrapMode: rowItem.compact ? Text.WordWrap : Text.NoWrap
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        visible: rowItem.compact
                                        text: modelData.dateLabel + "  ·  " + rowItem.figures + "  ·  " + App.formatDuration(modelData.secondsUsed)
                                        font.family: Style.family
                                        font.pixelSize: Style.fS
                                        color: Style.muted
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                                Text {
                                    visible: !rowItem.compact
                                    text: rowItem.figures
                                    font.family: Style.family
                                    font.pixelSize: Style.fS
                                    color: Style.muted
                                    Layout.preferredWidth: Math.round(230 * Style.k)
                                }
                                Text {
                                    visible: !rowItem.compact
                                    text: App.formatDuration(modelData.secondsUsed)
                                    font.family: Style.family
                                    font.pixelSize: Style.fS
                                    color: Style.muted
                                    Layout.preferredWidth: Math.round(56 * Style.k)
                                }
                                Text {
                                    text: page.fmt(modelData.note20) + "/20"
                                    font.family: Style.family
                                    font.pixelSize: Style.fL
                                    font.bold: true
                                    color: modelData.passed ? Style.green : Style.red
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: Math.round(72 * Style.k)
                                }
                                ActionButton {
                                    variant: "ghost"
                                    compact: true
                                    text: "Correction"
                                    onClicked: Nav.window.open("CorrectionPage", { resultId: modelData.id })
                                }
                                ActionButton {
                                    variant: "ghost"
                                    compact: true
                                    iconName: "trash"
                                    tint: Style.muted
                                    text: ""
                                    Accessible.name: "Supprimer ce résultat"
                                    onClicked: { page.pendingDelete = modelData.id; deleteDialog.open() }
                                }
                            }
                        }
                    }
                }
            }

            Section {
                visible: page.rows.length === 0
                Layout.fillWidth: true
                title: "Rien à afficher"
                subtitle: "Les épreuves et entraînements terminés apparaissent ici automatiquement, avec leur correction."
                ActionButton {
                    text: "Passer une épreuve blanche"
                    onClicked: Nav.window.go("home")
                }
            }
        }
    }

    ConfirmDialog {
        id: deleteDialog
        title: "Supprimer ce résultat ?"
        message: "La note et la correction de cette épreuve seront effacées. Les statistiques par question sont conservées."
        acceptText: "Supprimer"
        acceptVariant: "danger"
        onAccepted: User.removeResult(page.pendingDelete)
    }
}
