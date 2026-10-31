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
    readonly property var themes: User.revision + Bank.questionCount >= 0
        ? [{ cat: "reglementation", label: "Réglementation", list: Exam.themeStats("reglementation") },
           { cat: "technique", label: "Technique", list: Exam.themeStats("technique") }]
        : []
    readonly property int weakCount: themes.reduce((n, c) => n + c.list.filter(t => t.weak).length, 0)
    readonly property bool anyAnswer: themes.some(c => c.list.some(t => t.answers > 0))

    Flickable {
        anchors.fill: parent
        contentHeight: col.implicitHeight + 80
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        ColumnLayout {
            id: col
            x: Style.margin
            y: Style.compact ? 20 : 40
            width: Math.min(1240, parent.width - 2 * Style.margin)
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

            Section {
                Layout.fillWidth: true
                title: "Réussite par thème"
                subtitle: page.anyAnswer
                    ? "Part des bonnes réponses dans chaque thème, toutes épreuves et révisions confondues. En rouge, les thèmes faibles : moins de 75 % de réussite, sur 5 réponses au moins."
                    : "Le taux de réussite de chaque thème apparaîtra ici dès vos premières réponses."

                GridLayout {
                    Layout.fillWidth: true
                    visible: page.anyAnswer
                    columns: col.width >= 900 * Style.k ? 2 : 1
                    columnSpacing: 32
                    rowSpacing: 20
                    Repeater {
                        model: page.themes
                        delegate: ColumnLayout {
                            id: catCol
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 10
                            Text {
                                text: catCol.modelData.label
                                font.family: Style.family
                                font.pixelSize: Style.fM
                                font.bold: true
                                color: Style.text
                            }
                            Repeater {
                                model: catCol.modelData.list
                                delegate: GridLayout {
                                    id: themeRow
                                    required property var modelData
                                    readonly property bool none: modelData.answers === 0
                                    readonly property color tone: none ? Style.muted : (modelData.weak ? Style.red : (modelData.answers < 5 ? Style.blue : Style.green))
                                    Layout.fillWidth: true
                                    columns: 2
                                    columnSpacing: 12
                                    rowSpacing: 4
                                    Text {
                                        Layout.fillWidth: true
                                        text: themeRow.modelData.name
                                        font.family: Style.family
                                        font.pixelSize: Style.fS
                                        color: Style.text
                                        wrapMode: Text.WordWrap
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                        text: themeRow.none ? "—" : Math.round(themeRow.modelData.rate * 100) + " %"
                                        font.family: Style.family
                                        font.pixelSize: Style.fS
                                        font.bold: true
                                        color: themeRow.tone
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 8
                                        radius: 4
                                        color: Style.surfaceAlt
                                        border.color: Style.line
                                        Rectangle {
                                            width: themeRow.none ? 0 : Math.max(height, parent.width * themeRow.modelData.rate)
                                            height: parent.height
                                            radius: 4
                                            color: themeRow.tone
                                        }
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignRight
                                        text: themeRow.modelData.seen + "/" + themeRow.modelData.questions + " vues"
                                        font.family: Style.family
                                        font.pixelSize: Style.fXs
                                        color: Style.muted
                                    }
                                }
                            }
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    visible: page.anyAnswer
                    spacing: 12
                    ActionButton {
                        width: Math.min(implicitWidth, parent.width)
                        iconName: "target"
                        enabled: page.weakCount > 0
                        text: page.weakCount > 0
                              ? "Réviser mes thèmes faibles (" + page.weakCount + ")"
                              : "Aucun thème faible"
                        onClicked: Nav.window.go("review")
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
                            // Wide: one line. Narrow: date, figures and duration under the title.
                            // Phone: the buttons on a second line.
                            GridLayout {
                                id: rowLine
                                readonly property bool phone: table.width < 560 * Style.k
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Style.compact ? 14 : 20
                                anchors.rightMargin: Style.compact ? 8 : 12
                                columns: phone ? 3 : (rowItem.compact ? 4 : 7)
                                columnSpacing: Style.compact ? 12 : 16
                                rowSpacing: 0
                                Rectangle {
                                    Layout.row: 0
                                    Layout.column: 0
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: modelData.passed ? Style.green : Style.red
                                }
                                Text {
                                    visible: !rowItem.compact
                                    Layout.row: 0
                                    Layout.column: 1
                                    text: modelData.dateLabel
                                    font.family: Style.family
                                    font.pixelSize: Style.fS
                                    color: Style.muted
                                    Layout.preferredWidth: Math.round(130 * Style.k)
                                }
                                ColumnLayout {
                                    Layout.row: 0
                                    Layout.column: rowItem.compact ? 1 : 2
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
                                    Layout.row: 0
                                    Layout.column: 3
                                    text: rowItem.figures
                                    font.family: Style.family
                                    font.pixelSize: Style.fS
                                    color: Style.muted
                                    Layout.preferredWidth: Math.round(230 * Style.k)
                                }
                                Text {
                                    visible: !rowItem.compact
                                    Layout.row: 0
                                    Layout.column: 4
                                    text: App.formatDuration(modelData.secondsUsed)
                                    font.family: Style.family
                                    font.pixelSize: Style.fS
                                    color: Style.muted
                                    Layout.preferredWidth: Math.round(56 * Style.k)
                                }
                                Text {
                                    Layout.row: 0
                                    Layout.column: rowItem.compact ? 2 : 5
                                    text: page.fmt(modelData.note20) + "/20"
                                    font.family: Style.family
                                    font.pixelSize: Style.fL
                                    font.bold: true
                                    color: modelData.passed ? Style.green : Style.red
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: Math.round(72 * Style.k)
                                }
                                Row {
                                    Layout.row: rowLine.phone ? 1 : 0
                                    Layout.column: rowLine.phone ? 1 : (rowItem.compact ? 3 : 6)
                                    Layout.columnSpan: rowLine.phone ? 2 : 1
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    spacing: 4
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
