import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

// A question as displayed everywhere in the application: header, the yellow question
// sheet (published image or statement text), the propositions and, once revealed,
// the correction with its comment and course link.
//   mode: "exam"     official test, no correction, pin button
//         "training" free practice, answer can be revealed
//         "review"   correction after a test
//         "browse"   question bank
Item {
    id: qs
    property string mode: "exam"
    property int position: 1
    property int total: 1
    property int num: 0
    property string ref: ""
    property url image
    property string statement: ""
    property var options: []
    property int selection: 0        // ticked propositions (bit mask)
    property bool multiple: false    // several boxes were ticked (past result without detail)
    property int correct: -1
    property bool revealed: false
    property bool pinned: false
    property bool saved: false
    property string themeName: ""
    property string comment: ""
    property string course: ""
    property bool current: false

    signal choose(int option)
    signal clearRequested()
    signal pinRequested()
    signal saveRequested()
    signal revealRequested()

    readonly property bool hasImage: String(image).length > 0
    readonly property bool locked: mode === "review" || mode === "browse" || (revealed && mode !== "exam")
    readonly property string letters: "ABCDEFGH"
    readonly property int bits: {
        var n = 0, v = selection
        while (v) { n += v & 1; v = v >> 1 }
        return n
    }
    readonly property bool gotIt: bits === 1 && ((selection >> correct) & 1) === 1
    function ticked(i) { return ((selection >> i) & 1) === 1 }

    implicitHeight: col.implicitHeight
    implicitWidth: Style.readable

    ColumnLayout {
        id: col
        width: qs.width
        spacing: 14

        // Header --------------------------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                text: qs.mode === "browse" ? "Question n° " + qs.ref : "Question " + qs.position
                font.family: Style.family
                font.pixelSize: Style.fXl
                font.bold: true
                color: Style.text
            }
            Text {
                text: "sur " + qs.total
                font.family: Style.family
                font.pixelSize: Style.fM
                color: Style.muted
                visible: qs.mode !== "browse"
                Layout.alignment: Qt.AlignBaseline
            }
            Rectangle {
                visible: qs.mode === "review" || (qs.mode === "training" && qs.revealed)
                Layout.alignment: Qt.AlignVCenter
                radius: 4
                color: Style.surfaceAlt
                border.color: Style.line
                implicitWidth: refText.implicitWidth + 16
                implicitHeight: refText.implicitHeight + 6
                Text {
                    id: refText
                    anchors.centerIn: parent
                    text: "n° " + qs.ref
                    font.family: Style.family
                    font.pixelSize: Style.fXs
                    font.bold: true
                    color: Style.muted
                }
            }
            Text {
                visible: qs.mode === "review" || qs.mode === "browse" || (qs.mode === "training" && qs.revealed)
                text: qs.themeName
                font.family: Style.family
                font.pixelSize: Style.fS
                color: Style.muted
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }

            ActionButton {
                visible: qs.mode === "exam" || qs.mode === "training"
                variant: qs.pinned ? "secondary" : "ghost"
                compact: true
                iconName: qs.pinned ? "pin-filled" : "pin"
                tint: qs.pinned ? Style.pin : Style.blue
                text: qs.pinned ? "Épinglée" : "Épingler"
                onClicked: qs.pinRequested()
                Accessible.name: qs.pinned ? "Retirer l'épingle de la question " + qs.position : "Épingler la question " + qs.position
            }
            ActionButton {
                visible: qs.mode !== "exam"
                variant: "ghost"
                compact: true
                iconName: qs.saved ? "bookmark-filled" : "bookmark"
                text: qs.saved ? "Enregistrée" : "Enregistrer"
                onClicked: qs.saveRequested()
            }
        }

        // Question sheet ---------------------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: qs.hasImage ? img.height + 2 : statementText.implicitHeight + 48
            color: Style.sheet
            radius: Style.r2
            border.color: qs.current ? Style.blue : Style.sheetEdge
            border.width: qs.current ? 2 : 1
            clip: true
            Image {
                id: img
                visible: qs.hasImage
                source: qs.image
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 1
                width: Math.min(parent.width - 2, sourceSize.width > 0 ? sourceSize.width * 1.25 : parent.width - 2)
                height: sourceSize.width > 0 ? width * sourceSize.height / sourceSize.width : 0
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                asynchronous: true
                Accessible.role: Accessible.Graphic
                Accessible.name: qs.statement
            }
            Text {
                id: statementText
                visible: !qs.hasImage
                anchors.fill: parent
                anchors.margins: 24
                text: qs.statement
                font.family: Style.family
                font.pixelSize: Style.fXl
                font.bold: true
                color: Style.sheetInk
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
        Text {
            visible: qs.hasImage && Prefs.showStatementText && qs.statement.length > 0
            text: qs.statement
            font.family: Style.family
            font.pixelSize: Style.fS
            color: Style.muted
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // Propositions --------------------------------------------------------------------------
        Repeater {
            model: qs.options
            delegate: AnswerOption {
                required property string modelData
                required property int index
                Layout.fillWidth: true
                letter: qs.letters.charAt(index)
                label: modelData
                selected: qs.ticked(index)
                locked: qs.locked
                feedback: !qs.revealed ? 0
                          : index === qs.correct ? (qs.ticked(index) ? 1 : 3)
                          : qs.ticked(index) ? 2 : 0
                onClicked: if (!qs.locked) qs.choose(index)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: (qs.mode === "exam" || qs.mode === "training") && !qs.locked
            spacing: 12
            ActionButton {
                variant: "ghost"
                compact: true
                text: "Effacer ma réponse"
                visible: qs.selection !== 0
                onClicked: qs.clearRequested()
            }
            Item { Layout.fillWidth: true }
            ActionButton {
                visible: qs.mode === "training" && !qs.revealed
                variant: "secondary"
                compact: true
                iconName: "eye"
                text: "Voir la réponse"
                onClicked: qs.revealRequested()
            }
        }

        // Correction ------------------------------------------------------------------------------
        Rectangle {
            visible: qs.revealed && (qs.comment.length > 0 || qs.course.length > 0 || qs.mode !== "browse")
            Layout.fillWidth: true
            implicitHeight: corr.implicitHeight + 32
            radius: Style.r2
            color: Style.surfaceAlt
            border.color: Style.line
            ColumnLayout {
                id: corr
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 10
                Text {
                    visible: qs.mode !== "browse"
                    text: (qs.multiple || qs.bits > 1) ? "Plusieurs cases cochées : aucun point. La bonne réponse est " + qs.letters.charAt(qs.correct) + "."
                          : qs.bits === 0 ? "Sans réponse. La bonne réponse est " + qs.letters.charAt(qs.correct) + "."
                          : qs.gotIt ? "Bonne réponse."
                          : "Réponse incorrecte. La bonne réponse est " + qs.letters.charAt(qs.correct) + "."
                    font.family: Style.family
                    font.pixelSize: Style.fM
                    font.bold: true
                    color: qs.gotIt ? Style.green : ((qs.bits === 0 && !qs.multiple) ? Style.muted : Style.red)
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                Text {
                    visible: qs.comment.length > 0
                    text: qs.comment
                    font.family: Style.family
                    font.pixelSize: Style.fM
                    color: Style.text
                    wrapMode: Text.WordWrap
                    lineHeight: 1.2
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                }
                ActionButton {
                    visible: qs.course.length > 0
                    variant: "ghost"
                    compact: true
                    iconName: "book"
                    text: "Ouvrir le cours de F6KGL sur ce point"
                    onClicked: App.openUrl(qs.course)
                    leftPadding: 0
                }
            }
        }
    }
}
