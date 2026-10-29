import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

// Correction of the session just finished, or of a past result (resultId).
Page {
    id: page
    property bool immersive: false
    property int resultId: 0
    property int startAt: -1
    property string filter: "all"
    background: Rectangle { color: Style.bg }

    readonly property var detail: resultId > 0 ? User.resultDetail(resultId) : null
    readonly property var allRows: resultId > 0 ? buildFromDetail(detail) : Exam.snapshot()
    readonly property var rows: allRows.filter(function (r) {
        if (filter === "wrong") return r.status === 2
        if (filter === "blank") return r.status === 3
        if (filter === "pinned") return r.pinned
        return true
    })

    function buildFromDetail(d) {
        var out = []
        if (!d || !d.answers)
            return out
        for (var i = 0; i < d.answers.length; ++i) {
            var a = d.answers[i]
            var q = Bank.question(a.num)
            if (!q.num)
                continue
            var options = q.options
            var selection = a.chosen > 0 ? (1 << (a.chosen - 1)) : 0
            var correct = a.answer - 1
            var multiple = a.chosen === -1
            // Since 4.0.2 the order shown and every ticked box are recorded: replay them as seen.
            if (a.order && a.order.length === q.options.length) {
                options = a.order.map(function (k) { return q.options[k] })
                selection = a.mask
                correct = a.order.indexOf(a.answer - 1)
                multiple = false
            }
            out.push({
                index: i, position: i + 1, num: q.num, ref: q.ref, statement: q.text, image: q.image,
                textOnly: q.textOnly, options: options, selection: selection, multiple: multiple,
                correct: correct,
                status: a.chosen === 0 ? 3 : (a.chosen === a.answer ? 1 : 2), pinned: a.pinned,
                themeName: q.themeName, comment: q.comment, course: q.course
            })
        }
        return out
    }

    Component.onCompleted: {
        if (startAt >= 0)
            Qt.callLater(function () { list.positionViewAtIndex(startAt, ListView.Beginning) })
    }

    header: Rectangle {
        implicitHeight: headerGrid.implicitHeight + 28
        color: Style.surface
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Style.line }
        // Filters beside the title on a wide window, under it on a narrow one.
        GridLayout {
            id: headerGrid
            readonly property bool wide: page.width >= 1000 * Style.k
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 28
            anchors.rightMargin: 28
            columns: wide ? 3 : 2
            columnSpacing: 18
            rowSpacing: 10
            ActionButton {
                variant: "ghost"
                iconName: "chevron-left"
                text: "Retour"
                onClicked: Nav.window.back()
            }
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Text {
                    text: "Correction"
                    font.family: Style.family
                    font.pixelSize: Style.fXl
                    font.bold: true
                    color: Style.text
                }
                Text {
                    text: page.resultId > 0 && page.detail ? page.detail.title + ", " + page.detail.dateLabel : Exam.title
                    font.family: Style.family
                    font.pixelSize: Style.fS
                    color: Style.muted
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
            SegmentedChoice {
                Layout.columnSpan: headerGrid.wide ? 1 : 2
                Layout.alignment: headerGrid.wide ? Qt.AlignVCenter : Qt.AlignLeft
                value: page.filter
                options: [
                    { value: "all", label: "Toutes (" + page.allRows.length + ")" },
                    { value: "wrong", label: "Fausses" },
                    { value: "blank", label: "Sans réponse" },
                    { value: "pinned", label: "Épinglées" }
                ]
                onActivated: (v) => page.filter = v
            }
        }
    }

    // Same presentation as the exam screen (Evalbox), with the correction of every question.
    Rectangle {
        anchors.fill: parent
        color: "#FFFFFF"

        ListView {
            id: list
            anchors.fill: parent
            model: page.rows
            spacing: Math.round(36 * Prefs.textScale)
            clip: true
            topMargin: 32
            bottomMargin: 48
            cacheBuffer: 2000
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                width: list.width
                implicitHeight: block.implicitHeight
                EvalQuestion {
                    id: block
                    width: Math.min(1140, list.width - 64)
                    anchors.horizontalCenter: parent.horizontalCenter
                    family: App.systemFontFamily
                    k: Prefs.textScale
                    review: true
                    revealed: true
                    position: row.modelData.position
                    total: page.allRows.length
                    ref: row.modelData.ref
                    showRef: true
                    statement: row.modelData.statement
                    textOnly: row.modelData.textOnly === true
                    image: row.modelData.image
                    options: row.modelData.options
                    selection: row.modelData.selection
                    multiple: row.modelData.multiple === true
                    correct: row.modelData.correct
                    pinned: row.modelData.pinned === true
                    comment: row.modelData.comment
                    course: row.modelData.course
                    themeName: row.modelData.themeName
                    saved: User.savedCount >= 0 && User.isSaved(row.modelData.num)
                    onSaveRequested: User.toggleSaved(row.modelData.num)
                    onNextRequested: {
                        if (row.index + 1 < list.count)
                            list.positionViewAtIndex(row.index + 1, ListView.Beginning)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: "Aucune question dans ce filtre."
                font.family: App.systemFontFamily
                font.pixelSize: Math.round(18 * Prefs.textScale)
                color: "#6C7B7C"
            }
        }
    }
}
