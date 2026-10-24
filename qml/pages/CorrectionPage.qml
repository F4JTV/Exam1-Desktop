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
            out.push({
                index: i, position: i + 1, num: q.num, ref: q.ref, statement: q.text, image: q.image,
                options: q.options, selection: a.chosen > 0 ? (1 << (a.chosen - 1)) : 0, multiple: a.chosen === -1,
                correct: a.answer - 1,
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
        implicitHeight: 84
        color: Style.surface
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Style.line }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 28
            spacing: 18
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
                }
            }
            SegmentedChoice {
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

    ListView {
        id: list
        anchors.fill: parent
        model: page.rows
        spacing: 28
        clip: true
        topMargin: 32
        bottomMargin: 48
        cacheBuffer: 2000
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }

        delegate: Item {
            required property var modelData
            width: list.width
            implicitHeight: card.implicitHeight
            Rectangle {
                id: card
                width: Math.min(Style.readable + 48, list.width - 64)
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: sheet.implicitHeight + 48
                radius: Style.r2
                color: Style.surface
                border.color: Style.line
                QuestionSheet {
                    id: sheet
                    x: 24
                    y: 24
                    width: parent.width - 48
                    mode: "review"
                    position: modelData.position
                    total: page.allRows.length
                    num: modelData.num
                    ref: modelData.ref
                    statement: modelData.statement
                    image: modelData.image
                    options: modelData.options
                    selection: modelData.selection
                    multiple: modelData.multiple === true
                    correct: modelData.correct
                    revealed: true
                    pinned: modelData.pinned
                    saved: User.savedCount >= 0 && User.isSaved(modelData.num)
                    themeName: modelData.themeName
                    comment: modelData.comment
                    course: modelData.course
                    onSaveRequested: User.toggleSaved(modelData.num)
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            text: "Aucune question dans ce filtre."
            font.family: Style.family
            font.pixelSize: Style.fL
            color: Style.muted
        }
    }
}
