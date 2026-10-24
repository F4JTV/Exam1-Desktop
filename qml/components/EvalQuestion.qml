import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

// One question block of the Evalbox exam page:
//   ——  Question 3 / 40  [pin]  - - - - - - - - - - - - - - - -  Choix multiples
//   [image]
//   statement
//   [ ] proposition ...
//                                                              [⌄⌄]
Item {
    id: q
    property int position: 1
    property int total: 1
    property url image
    property string statement: ""
    property bool textOnly: false
    property var options: []
    property int selection: 0
    property bool pinned: false
    property bool revealed: false
    property int correct: -1
    property string comment: ""
    property string course: ""
    property bool training: false
    property string family: ""
    property real k: 1.0

    signal toggle(int option)
    signal pinRequested()
    signal nextRequested()
    signal revealRequested()

    readonly property bool answered: selection !== 0
    readonly property bool hasImage: String(image).length > 0
    // As on the ANFR exam: a picture only for questions with a diagram, a formula or a drawing.
    // textOnly is computed when the bank is installed (see src/statement.cpp).
    readonly property bool showImage: hasImage && (Prefs.statementMode === "image" || !textOnly)
    readonly property bool showText: !showImage && statement.length > 0
    readonly property int bits: {
        var n = 0, v = selection
        while (v) { n += v & 1; v = v >> 1 }
        return n
    }

    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        width: q.width
        spacing: Math.round(14 * q.k)

        // Header line
        Item {
            Layout.fillWidth: true
            implicitHeight: Math.round(34 * q.k)
            Rectangle {
                id: lead
                width: 32
                height: 2
                color: "#9AA9AC"
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                id: label
                anchors.left: lead.right
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "Question " + q.position + " / " + q.total
                font.family: q.family
                font.pixelSize: Math.round(16 * q.k)
                color: q.answered ? "#2B7C57" : "#6C7B7C"
            }
            AbstractButton {
                id: pinButton
                anchors.left: label.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(30 * q.k)
                height: width
                hoverEnabled: true
                onClicked: q.pinRequested()
                Accessible.name: q.pinned ? "Retirer l'épingle" : "Épingler la question"
                ToolTip.visible: hovered
                ToolTip.delay: 500
                ToolTip.text: q.pinned ? "Retirer l'épingle" : "Épingler pour y revenir"
                background: Rectangle {
                    radius: 4
                    color: q.pinned ? "#FFCA2C" : (pinButton.hovered ? "#FFF6D6" : "#FFFFFF")
                    border.width: 1
                    border.color: "#FFC107"
                }
                contentItem: Item {
                    Icon {
                        anchors.centerIn: parent
                        name: q.pinned ? "pin-filled" : "pin"
                        color: q.pinned ? "#212529" : "#E0B23A"
                        size: Math.round(15 * q.k)
                    }
                }
            }
            Canvas {
                id: dashes
                anchors.left: pinButton.right
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 2
                onWidthChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.fillStyle = "#E5E5E5"
                    for (var x = 0; x < width; x += 22)
                        ctx.fillRect(x, 0, 14, 2)
                }
            }
            Text {
                anchors.right: parent.right
                anchors.bottom: dashes.top
                anchors.bottomMargin: 4
                text: "Choix multiples"
                font.family: q.family
                font.pixelSize: Math.max(9, Math.round(10 * q.k))
                color: "#C6C7C9"
            }
        }

        Image {
            visible: q.showImage
            Layout.alignment: Qt.AlignHCenter
            source: q.showImage ? q.image : ""
            Layout.preferredWidth: sourceSize.width > 0 ? Math.min(sourceSize.width * q.k, col.width) : 0
            Layout.preferredHeight: sourceSize.width > 0 ? Layout.preferredWidth * sourceSize.height / sourceSize.width : 0
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            asynchronous: true
            Accessible.role: Accessible.Graphic
            Accessible.name: q.statement
        }

        Text {
            visible: q.showText
            Layout.fillWidth: true
            text: q.statement
            font.family: q.family
            font.pixelSize: Math.round(16 * q.k)
            color: "#212529"
            wrapMode: Text.WordWrap
            lineHeight: 1.25
        }

        Column {
            Layout.fillWidth: true
            Layout.leftMargin: 2
            spacing: Math.round(4 * q.k)
            Repeater {
                model: q.options
                delegate: EvalCheck {
                    required property string modelData
                    required property int index
                    width: parent.width
                    family: q.family
                    k: q.k
                    label: modelData
                    ticked: (q.selection >> index) & 1
                    locked: q.revealed && q.training
                    feedback: !q.revealed ? 0
                              : index === q.correct ? (ticked ? 1 : 3)
                              : ticked ? 2 : 0
                    onClicked: q.toggle(index)
                }
            }
        }

        // Correction shown during training with immediate correction (not part of the real exam).
        Rectangle {
            visible: q.training && q.revealed
            Layout.fillWidth: true
            implicitHeight: corr.implicitHeight + 24
            radius: 4
            color: q.bits === 1 && ((q.selection >> q.correct) & 1) ? "#D1E7DD" : "#FFF3CD"
            border.color: q.bits === 1 && ((q.selection >> q.correct) & 1) ? "#A3CFBB" : "#FFE69C"
            ColumnLayout {
                id: corr
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: q.family
                    font.pixelSize: Math.round(16 * q.k)
                    font.bold: true
                    color: "#212529"
                    text: q.selection === 0 ? "Sans réponse. La bonne réponse est : " + q.options[q.correct]
                          : q.bits === 1 && ((q.selection >> q.correct) & 1) ? "Bonne réponse."
                          : "Réponse fausse. La bonne réponse est : " + q.options[q.correct]
                }
                Text {
                    visible: q.comment.length > 0
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: q.family
                    font.pixelSize: Math.round(15 * q.k)
                    color: "#212529"
                    text: q.comment
                    lineHeight: 1.2
                }
                Text {
                    visible: q.course.length > 0
                    font.family: q.family
                    font.pixelSize: Math.round(15 * q.k)
                    color: "#0A58CA"
                    font.underline: courseArea.containsMouse
                    text: "Revoir ce point dans le cours de F6KGL"
                    MouseArea {
                        id: courseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: App.openUrl(q.course)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Item { Layout.fillWidth: true }
            AbstractButton {
                id: showBtn
                visible: q.training && !q.revealed
                implicitHeight: Math.round(31 * q.k)
                implicitWidth: showText.implicitWidth + 24
                hoverEnabled: true
                onClicked: q.revealRequested()
                background: Rectangle { radius: 4; color: showBtn.hovered ? "#6C757D" : "#FFFFFF"; border.color: "#6C757D" }
                contentItem: Text {
                    id: showText
                    text: "Voir la réponse"
                    font.family: q.family
                    font.pixelSize: Math.round(14 * q.k)
                    color: showBtn.hovered ? "#FFFFFF" : "#6C757D"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            AbstractButton {
                id: nextBtn
                implicitHeight: Math.round(31 * q.k)
                implicitWidth: Math.round(31 * q.k)
                hoverEnabled: true
                visible: q.position < q.total
                onClicked: q.nextRequested()
                Accessible.name: "Question suivante"
                ToolTip.visible: hovered
                ToolTip.delay: 500
                ToolTip.text: "Question suivante"
                background: Rectangle { radius: 4; color: nextBtn.hovered ? "#6C757D" : "#FFFFFF"; border.color: "#6C757D" }
                contentItem: Item {
                    Icon {
                        anchors.centerIn: parent
                        name: "chevrons-down"
                        color: nextBtn.hovered ? "#FFFFFF" : "#6C757D"
                        size: Math.round(16 * q.k)
                    }
                }
            }
        }
    }
}
