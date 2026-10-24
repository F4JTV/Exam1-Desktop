import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

// Exam screen reproducing the ANFR examination interface (Evalbox): grey header with the
// candidate, last autosave, answered count, "Finaliser l'examen" and the numbered question
// buttons; below, every question in a single vertical list with check boxes and a pin.
Page {
    id: page
    property bool immersive: true
    property int current: 0
    readonly property bool official: Exam.mode === "official"
    readonly property string family: App.systemFontFamily
    readonly property real k: Prefs.textScale
    readonly property int remaining: Exam.remainingSeconds
    readonly property bool lowTime: Exam.timed && remaining <= 300
    readonly property bool criticalTime: Exam.timed && remaining <= 60
    readonly property int containerWidth: Math.min(1140, width - 32)

    // Evalbox palette (sampled from the ANFR exam screens)
    readonly property color barGrey: "#AEB3B9"
    readonly property color navGrey: "#8E9196"
    readonly property color navGreen: "#3CC478"
    readonly property color pinOrange: "#FE9F43"
    readonly property color teal: "#007A9F"
    readonly property color ink: "#212529"

    background: Rectangle { color: "#FFFFFF" }
    focus: true

    Connections {
        target: Exam
        function onStateChanged() {
            if (Exam.finished && Nav.window)
                Nav.window.showResult()
        }
        function onTimeUp() {
            if (Nav.window)
                Nav.window.toast("Temps écoulé : l'examen a été finalisé automatiquement.")
        }
    }

    function jumpTo(row) {
        var it = sheets.itemAt(row)
        if (!it)
            return
        scrollAnim.to = Math.max(0, Math.min(flick.contentHeight - flick.height, it.y + column.y - 12))
        scrollAnim.restart()
        current = row
    }
    function updateCurrent() {
        var probe = flick.contentY - column.y + 40
        for (var i = 0; i < sheets.count; ++i) {
            var it = sheets.itemAt(i)
            if (it && probe < it.y + it.height) {
                current = i
                return
            }
        }
    }
    function askFinalize() { finalizeDialog.open() }

    Keys.onPressed: (event) => {
        var map = { "a": 0, "b": 1, "c": 2, "d": 3, "1": 0, "2": 1, "3": 2, "4": 3 }
        var t = event.text.toLowerCase()
        if (map[t] !== undefined) {
            Exam.select(current, map[t])
            event.accepted = true
        } else if (t === "p") {
            Exam.togglePin(current)
            event.accepted = true
        } else if (event.key === Qt.Key_Space || t === "n") {
            jumpTo(Math.min(Exam.count - 1, current + 1))
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            flick.contentY = Math.min(Math.max(0, flick.contentHeight - flick.height), flick.contentY + 80)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            flick.contentY = Math.max(0, flick.contentY - 80)
            event.accepted = true
        } else if (event.key === Qt.Key_PageDown) {
            flick.contentY = Math.min(Math.max(0, flick.contentHeight - flick.height), flick.contentY + flick.height * 0.9)
            event.accepted = true
        } else if (event.key === Qt.Key_PageUp) {
            flick.contentY = Math.max(0, flick.contentY - flick.height * 0.9)
            event.accepted = true
        }
    }

    // Header ----------------------------------------------------------------------------------------
    header: Rectangle {
        implicitHeight: headerCol.implicitHeight + Math.round(34 * page.k)
        color: page.barGrey
        Rectangle {
            anchors.top: parent.bottom
            width: parent.width
            height: 6
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#40000000" }
                GradientStop { position: 1.0; color: "#00000000" }
            }
        }

        ColumnLayout {
            id: headerCol
            width: page.containerWidth
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(10 * page.k)
            spacing: Math.round(8 * page.k)

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                // Accessibility menu
                AbstractButton {
                    id: a11y
                    implicitWidth: a11yRow.implicitWidth + 8
                    implicitHeight: 30
                    hoverEnabled: true
                    onClicked: a11yMenu.open()
                    Accessible.name: "Options d'accessibilité"
                    background: Rectangle { radius: 4; color: a11y.hovered ? "#BEC3C9" : "transparent" }
                    contentItem: Item {
                        Row {
                            id: a11yRow
                            anchors.centerIn: parent
                            spacing: 2
                            Icon { name: "accessibility"; color: "#3A3F45"; size: 18; anchors.verticalCenter: parent.verticalCenter }
                            Icon { name: "caret-down"; color: "#3A3F45"; size: 14; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                    Menu {
                        id: a11yMenu
                        y: a11y.height
                        font.family: page.family
                        MenuItem { text: "Texte plus grand"; enabled: Prefs.textScale < 1.6; onTriggered: Prefs.textScale = Math.min(1.6, Prefs.textScale + 0.1) }
                        MenuItem { text: "Texte plus petit"; enabled: Prefs.textScale > 0.9; onTriggered: Prefs.textScale = Math.max(0.9, Prefs.textScale - 0.1) }
                        MenuItem { text: "Taille normale"; onTriggered: Prefs.textScale = 1.0 }
                        MenuSeparator {}
                        MenuItem { text: page.official ? "Abandonner l'examen" : "Quitter sans terminer"; onTriggered: quitDialog.open() }
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: User.currentCandidateName
                        font.family: page.family
                        font.pixelSize: Math.round(17 * page.k)
                        font.italic: true
                        color: page.ink
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: Exam.lastSavedLabel.length > 0 ? "dernière sauvegarde " + Exam.lastSavedLabel : Exam.title
                        font.family: page.family
                        font.pixelSize: Math.round(14 * page.k)
                        color: "#6C737B"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Remaining time (the real exam is timed; the ANFR demo is not)
                Rectangle {
                    visible: Exam.timed
                    implicitWidth: timeRow.implicitWidth + 20
                    implicitHeight: Math.round(32 * page.k)
                    radius: 4
                    color: page.criticalTime ? "#DC3545" : page.lowTime ? "#FD7E14" : "#C6CACF"
                    Row {
                        id: timeRow
                        anchors.centerIn: parent
                        spacing: 8
                        Icon {
                            name: "clock"
                            size: Math.round(16 * page.k)
                            color: page.lowTime ? "#FFFFFF" : page.ink
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: App.formatDuration(page.remaining)
                            font.family: page.family
                            font.pixelSize: Math.round(16 * page.k)
                            font.bold: true
                            color: page.lowTime ? "#FFFFFF" : page.ink
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Accessible.name: "Temps restant " + App.formatDuration(page.remaining)
                }

                Text {
                    textFormat: Text.StyledText
                    text: "<font color='" + (Exam.answeredCount === 0 ? "#DC3545" : Exam.answeredCount < Exam.count ? "#FFC107" : "#198754") + "'>"
                          + Exam.answeredCount + "</font> / " + Exam.count + " questions"
                    font.family: page.family
                    font.pixelSize: Math.round(16 * page.k)
                    color: "#FFFFFF"
                }

                AbstractButton {
                    id: finalizeButton
                    implicitHeight: Math.round(38 * page.k)
                    implicitWidth: finalizeText.implicitWidth + 24
                    hoverEnabled: true
                    onClicked: finalizeDialog.open()
                    background: Rectangle {
                        radius: 4
                        color: finalizeButton.down ? "#005A75" : finalizeButton.hovered ? "#006684" : page.teal
                    }
                    contentItem: Text {
                        id: finalizeText
                        text: page.official ? "Finaliser l'examen »" : "Terminer »"
                        font.family: page.family
                        font.pixelSize: Math.round(16 * page.k)
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Question buttons
            Flow {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: Exam
                    delegate: AbstractButton {
                        id: nb
                        required property int index
                        required property int position
                        required property int selection
                        required property bool pinned
                        required property int status
                        readonly property bool isCurrent: page.current === index
                        implicitWidth: Math.max(Math.round(32 * page.k), numText.implicitWidth + 18)
                        implicitHeight: Math.round(28 * page.k)
                        hoverEnabled: true
                        focusPolicy: Qt.NoFocus
                        onClicked: page.jumpTo(index)
                        Accessible.name: "Question " + position + (selection !== 0 ? ", répondue" : "") + (pinned ? ", épinglée" : "")
                        background: Rectangle {
                            radius: 3
                            color: nb.status === 1 ? "#198754" : nb.status === 2 ? "#DC3545"
                                   : nb.selection !== 0 ? page.navGreen
                                   : nb.hovered ? "#7C8085" : page.navGrey
                            border.width: nb.pinned ? 3 : 1
                            border.color: nb.pinned ? page.pinOrange : "#9EA2A7"
                        }
                        contentItem: Text {
                            id: numText
                            text: nb.position
                            font.family: page.family
                            font.pixelSize: Math.round(15 * page.k)
                            font.underline: nb.isCurrent
                            font.bold: nb.isCurrent
                            color: "#FFFFFF"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }

    // Questions ---------------------------------------------------------------------------------------
    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: column.y + column.implicitHeight + 80
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }
        onContentYChanged: page.updateCurrent()

        NumberAnimation on contentY {
            id: scrollAnim
            running: false
            duration: 200
            easing.type: Easing.OutCubic
        }

        Column {
            id: column
            y: Math.round(36 * page.k)
            width: page.containerWidth
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(34 * page.k)

            Text {
                width: parent.width
                text: Exam.title
                font.family: page.family
                font.pixelSize: Math.round(28 * page.k)
                font.weight: Font.Medium
                color: page.ink
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                bottomPadding: Math.round(14 * page.k)
            }

            Repeater {
                id: sheets
                model: Exam
                delegate: EvalQuestion {
                    id: block
                    required property int index
                    required position
                    required statement
                    required textOnly
                    required image
                    required options
                    required selection
                    required pinned
                    required revealed
                    required correct
                    required comment
                    required course
                    width: column.width
                    family: page.family
                    k: page.k
                    total: Exam.count
                    training: Exam.instantCorrection || !page.official
                    onToggle: (option) => { page.current = block.index; Exam.select(block.index, option) }
                    onPinRequested: Exam.togglePin(block.index)
                    onNextRequested: page.jumpTo(block.index + 1)
                    onRevealRequested: Exam.reveal(block.index)
                }
            }
        }
    }

    // Dialogs (Bootstrap-like, as on the exam site) --------------------------------------------------
    component EvalDialog: Popup {
        id: d
        property string heading: ""
        property string body: ""
        property string acceptText: "OK"
        property color acceptColor: page.teal
        signal accepted()
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(520, page.width - 40)
        padding: 0
        Overlay.modal: Rectangle { color: "#80000000" }
        background: Rectangle { color: "#FFFFFF"; radius: 6; border.color: "#2D000000" }
        contentItem: ColumnLayout {
            spacing: 0
            Text {
                Layout.fillWidth: true
                Layout.margins: 16
                text: d.heading
                font.family: page.family
                font.pixelSize: 20
                font.weight: Font.Medium
                color: page.ink
                wrapMode: Text.WordWrap
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#DEE2E6" }
            Text {
                Layout.fillWidth: true
                Layout.margins: 16
                text: d.body
                font.family: page.family
                font.pixelSize: 16
                color: page.ink
                wrapMode: Text.WordWrap
                lineHeight: 1.25
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#DEE2E6" }
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 12
                spacing: 8
                Item { Layout.fillWidth: true }
                AbstractButton {
                    id: cancelB
                    implicitHeight: 38
                    implicitWidth: cancelT.implicitWidth + 24
                    hoverEnabled: true
                    onClicked: d.close()
                    background: Rectangle { radius: 4; color: cancelB.hovered ? "#5C636A" : "#6C757D" }
                    contentItem: Text { id: cancelT; text: "Annuler"; font.family: page.family; font.pixelSize: 16; color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                AbstractButton {
                    id: okB
                    implicitHeight: 38
                    implicitWidth: okT.implicitWidth + 24
                    hoverEnabled: true
                    onClicked: { d.close(); d.accepted() }
                    background: Rectangle { radius: 4; color: d.acceptColor; opacity: okB.hovered ? 0.88 : 1 }
                    contentItem: Text { id: okT; text: d.acceptText; font.family: page.family; font.pixelSize: 16; color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }
    }

    EvalDialog {
        id: finalizeDialog
        heading: page.official ? "Finaliser l'examen" : "Terminer"
        acceptText: page.official ? "Finaliser l'examen" : "Terminer"
        body: {
            var blank = Exam.count - Exam.answeredCount
            var s = "Vous avez répondu à " + Exam.answeredCount + " question" + (Exam.answeredCount > 1 ? "s" : "") + " sur " + Exam.count + "."
            if (blank > 0)
                s += "\n" + blank + " question" + (blank > 1 ? "s sont" : " est") + " sans réponse."
            if (Exam.pinnedCount > 0)
                s += "\n" + Exam.pinnedCount + " question" + (Exam.pinnedCount > 1 ? "s sont épinglées" : " est épinglée") + "."
            if (Exam.multiCount > 0)
                s += "\n" + Exam.multiCount + " question" + (Exam.multiCount > 1 ? "s ont" : " a") + " plusieurs cases cochées : elle" + (Exam.multiCount > 1 ? "s ne rapporteront" : " ne rapportera") + " aucun point."
            s += "\n\nAprès validation, vos réponses ne pourront plus être modifiées."
            return s
        }
        onAccepted: Exam.finalize()
    }

    EvalDialog {
        id: quitDialog
        heading: page.official ? "Abandonner l'examen" : "Quitter sans terminer"
        body: "Vos réponses ne seront pas enregistrées et aucune note ne sera attribuée."
        acceptText: page.official ? "Abandonner" : "Quitter"
        acceptColor: "#DC3545"
        onAccepted: {
            Exam.abandon()
            Nav.window.go("home")
        }
    }
}
