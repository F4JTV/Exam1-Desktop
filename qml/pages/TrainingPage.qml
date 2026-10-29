import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

Page {
    id: page
    property bool immersive: false
    background: Rectangle { color: Style.bg }

    property var chosen: []
    property int count: Prefs.trainingCount
    property int minutes: Prefs.trainingMinutes
    property bool instant: Prefs.trainingInstant

    Component.onCompleted: {
        var saved = Prefs.trainingThemes
        var list = []
        for (var i = 0; i < saved.length; ++i)
            list.push(Number(saved[i]))
        chosen = list
    }

    function has(id) { return chosen.indexOf(id) >= 0 }
    function toggle(id, on) {
        var list = chosen.slice()
        var i = list.indexOf(id)
        if (on && i < 0) list.push(id)
        if (!on && i >= 0) list.splice(i, 1)
        chosen = list
    }
    function setAll(themes, on) {
        var list = chosen.slice()
        for (var i = 0; i < themes.length; ++i) {
            var j = list.indexOf(themes[i].id)
            if (on && j < 0) list.push(themes[i].id)
            if (!on && j >= 0) list.splice(j, 1)
        }
        chosen = list
    }
    function available() {
        var n = 0
        for (var i = 0; i < chosen.length; ++i)
            n += Bank.themeCount(chosen[i])
        return n
    }
    function start() {
        Prefs.trainingThemes = chosen
        Prefs.trainingCount = count
        Prefs.trainingMinutes = minutes
        Prefs.trainingInstant = instant
        if (Exam.startTraining(chosen, count, minutes, instant))
            Nav.window.startExam()
    }

    component ThemeColumn: Section {
        id: tc
        property var themes: []
        property string heading: ""
        title: heading
        subtitle: themes.length + " thèmes, " + total() + " questions"
        function total() {
            var n = 0
            for (var i = 0; i < themes.length; ++i) n += themes[i].count
            return n
        }
        Flow {
            Layout.fillWidth: true
            spacing: 8
            ActionButton { variant: "ghost"; compact: true; text: "Tout cocher"; leftPadding: 0; onClicked: page.setAll(tc.themes, true) }
            ActionButton { variant: "ghost"; compact: true; text: "Tout décocher"; onClicked: page.setAll(tc.themes, false) }
        }
        Repeater {
            model: tc.themes
            delegate: CheckRow {
                required property var modelData
                Layout.fillWidth: true
                text: modelData.name
                detail: modelData.count + " questions"
                checked: page.has(modelData.id)
                onToggled: page.toggle(modelData.id, checked)
            }
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
            width: Math.min(1240, parent.width - 96)
            spacing: 28

            PageHeader {
                Layout.fillWidth: true
                title: "Entraînement par thèmes"
                subtitle: "Les questions sont réparties équitablement entre les thèmes cochés, puis présentées dans un ordre aléatoire."
            }

            // Three columns on a wide window; on a medium one the two theme lists are stacked
            // beside the settings; on a narrow one everything is stacked.
            GridLayout {
                id: grid
                Layout.fillWidth: true
                readonly property int mode: col.width >= 940 * Style.k ? 3 : (col.width >= 640 * Style.k ? 2 : 1)
                columns: mode
                columnSpacing: 24
                rowSpacing: 24

                ThemeColumn {
                    Layout.row: 0
                    Layout.column: 0
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    heading: "Réglementation"
                    themes: Bank.regulationThemes
                }
                ThemeColumn {
                    Layout.row: grid.mode === 3 ? 0 : 1
                    Layout.column: grid.mode === 3 ? 1 : 0
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    heading: "Technique"
                    themes: Bank.technicalThemes
                }

                Section {
                    Layout.row: grid.mode === 1 ? 2 : 0
                    Layout.column: grid.mode === 3 ? 2 : (grid.mode === 2 ? 1 : 0)
                    Layout.rowSpan: grid.mode === 2 ? 2 : 1
                    Layout.fillWidth: grid.mode === 1
                    Layout.preferredWidth: grid.mode === 1 ? -1 : Math.round(330 * Style.k)
                    Layout.alignment: Qt.AlignTop
                    title: "Réglages"
                    Text { text: "Nombre de questions"; font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text }
                    Spinner {
                        value: page.count
                        from: 1
                        to: 100
                        step: 5
                        onEdited: (v) => page.count = v
                    }
                    Text { text: "Durée"; font.family: Style.family; font.pixelSize: Style.fM; font.bold: true; color: Style.text; Layout.topMargin: 6 }
                    Spinner {
                        value: page.minutes
                        from: 0
                        to: 120
                        step: 5
                        suffix: "min"
                        zeroLabel: "Sans limite"
                        onEdited: (v) => page.minutes = v
                    }
                    CheckRow {
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        text: "Correction immédiate"
                        detail: "La bonne réponse et le commentaire s'affichent dès que vous répondez."
                        checked: page.instant
                        onToggled: page.instant = checked
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Style.line }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.family: Style.family
                        font.pixelSize: Style.fS
                        color: page.chosen.length === 0 ? Style.red : Style.muted
                        text: page.chosen.length === 0 ? "Cochez au moins un thème."
                              : page.chosen.length + " thème" + (page.chosen.length > 1 ? "s" : "") + " coché" + (page.chosen.length > 1 ? "s" : "") + ", " + page.available() + " questions disponibles."
                    }
                    ActionButton {
                        Layout.fillWidth: true
                        text: "Commencer"
                        iconName: "chevron-right"
                        enabled: page.chosen.length > 0 && Bank.ready
                        onClicked: page.start()
                    }
                }
            }
        }
    }
}
