import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

ApplicationWindow {
    id: win
    width: 1320
    height: 880
    minimumWidth: 1000
    minimumHeight: 660
    visible: true
    title: immersive ? "Exam'1 - " + Exam.title : "Exam'1"
    color: Style.bg
    font.family: Style.family
    font.pixelSize: Style.fM

    property string section: "home"
    readonly property bool immersive: stack.currentItem !== null && stack.currentItem.immersive === true

    readonly property var pages: ({
        home: "HomePage", training: "TrainingPage", series: "SeriesPage", review: "ReviewPage",
        browser: "BrowserPage", history: "HistoryPage", candidates: "CandidatesPage",
        update: "UpdatePage", settings: "SettingsPage", about: "AboutPage", firstrun: "FirstRunPage"
    })

    function pageUrl(name) { return Qt.resolvedUrl("pages/" + name + ".qml") }

    // Top-level navigation (rail): replaces the whole stack.
    function go(key, props) {
        if (Exam.active && !Exam.finished && stack.currentItem && stack.currentItem.immersive)
            return
        section = key
        stack.replace(null, pageUrl(pages[key]), props || {})
    }
    // Drill-down navigation inside a section.
    function open(name, props) { stack.push(pageUrl(name), props || {}) }
    function back() {
        if (stack.depth > 1)
            stack.pop()
        else
            go("home")
    }
    function startExam() { stack.replace(null, pageUrl("ExamPage")) }
    function showResult() { stack.replace(null, pageUrl("ResultPage")) }

    function toast(message) {
        toastText.text = message
        toastBox.opacity = 1
        toastTimer.restart()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        NavRail {
            Layout.fillHeight: true
            visible: !win.immersive && Bank.ready
            current: win.section
            onNavigate: (key) => win.go(key)
        }

        StackView {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            focus: true
            Component.onCompleted: {
                Nav.window = win
                win.section = Bank.ready ? "home" : "firstrun"
                push(win.pageUrl(Bank.ready ? "HomePage" : "FirstRunPage"), {}, StackView.Immediate)
            }

            pushEnter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 140 } }
            pushExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100 } }
            popEnter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 140 } }
            popExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100 } }
            replaceEnter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 140 } }
            replaceExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100 } }
        }
    }

    Connections {
        target: Exam
        function onError(message) { win.toast(message) }
    }

    // Transient message ----------------------------------------------------------------------
    Rectangle {
        id: toastBox
        z: 100
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        width: Math.min(toastText.implicitWidth + 48, win.width - 80)
        height: toastText.implicitHeight + 28
        radius: Style.r2
        color: Style.slate
        border.color: Style.slateLine
        opacity: 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Text {
            id: toastText
            anchors.centerIn: parent
            width: parent.width - 48
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.family: Style.family
            font.pixelSize: Style.fM
            color: Style.slateText
        }
        Timer {
            id: toastTimer
            interval: 4000
            onTriggered: toastBox.opacity = 0
        }
    }

    // Screenshot tour used during development (EXAM1_CAPTURE_DIR) ---------------------------------
    property string tourName: "main"
    function tourStep(step) {
        if (tourName !== "first" && (!Bank.ready || Updates.busy))
            return "wait"
        if (tourName === "update")
            return updateTourStep(step)
        if (tourName === "resume1")
            return resumeTourStep(step, 1)
        if (tourName === "resume2")
            return resumeTourStep(step, 2)
        if (tourName === "import")
            return importTourStep(step)
        if (tourName === "history") {
            // Correction of the most recent past result, opened from "Résultats".
            var past = User.results("", 0)
            switch (step) {
            case 0: go("history"); return "h-history"
            case 1: open("CorrectionPage", { resultId: past.length ? past[0].id : 0 }); return "h-correction"
            case 2: open("CorrectionPage", { resultId: past.length ? past[past.length - 1].id : 0, filter: "wrong" }); return "h-oldest-wrong"
            case 3: open("CorrectionPage", { resultId: past.length ? past[past.length - 1].id : 0, startAt: 5 }); return "h-oldest-q6"
            case 4: open("CorrectionPage", { resultId: past.length ? past[past.length - 1].id : 0, filter: "pinned" }); return "h-oldest-pinned"
            default: return ""
            }
        }
        if (tourName === "ui") {
            switch (step) {
            case 0: stack.currentItem.startOfficial("technique"); return "ui-exam"
            case 1: stack.currentItem.askFinalize(); return "ui-finalize"
            case 2: Exam.finalize(); return "ui-result"
            case 3: stack.currentItem.restart(); return "ui-restart"
            default: return ""
            }
        }
        if (tourName === "idle" || tourName === "first")
            return step < 6 ? tourName + step : ""
        switch (step) {
        case 0: go("home"); return "home"
        case 1: go("training"); return "training"
        case 2:
            Exam.startOfficial("both", false)
            startExam()
            return "exam-start"
        case 3:
            for (var i = 0; i < 12; ++i)
                Exam.select(i, i % 4)
            Exam.select(5, 2)
            Exam.togglePin(3)
            Exam.togglePin(7)
            if (stack.currentItem && stack.currentItem.jumpTo)
                stack.currentItem.jumpTo(3)
            return "exam-progress"
        case 4:
            if (stack.currentItem && stack.currentItem.askFinalize)
                stack.currentItem.askFinalize()
            return "exam-finalize"
        case 5:
            Exam.finalize()
            showResult()
            return "result"
        case 6: open("CorrectionPage"); return "correction"
        case 7:
            Exam.startTraining([206, 207, 208], 10, 0, true)
            startExam()
            return "training-start"
        case 8:
            Exam.select(0, 1)
            Exam.select(1, 2)
            return "training-feedback"
        case 9: Exam.abandon(); go("series"); return "series"
        case 10: go("review"); return "review"
        case 11: go("browser"); return "browser"
        case 12: go("history"); return "history"
        case 13: go("update"); return "update"
        case 14: go("settings"); return "settings"
        case 15: go("candidates"); return "candidates"
        case 16: go("about"); return "about"
        case 17: Prefs.colorScheme = "dark"; go("home"); return "home-dark"
        case 18:
            Exam.startOfficial("technique", false)
            startExam()
            return "exam-dark"
        case 19: Exam.abandon(); Prefs.colorScheme = "light"; go("home"); return "home-again"
        default: return ""
        }
    }
    function updateTourStep(step) {
        switch (step) {
        case 0: go("update"); Updates.checkForUpdate(false); return "u-checking"
        case 1: return "u-available"
        case 2: go("home"); return "u-home-badge"
        case 3: go("update"); Updates.installUpdate(); return "u-installing"
        case 4: return "u-progress"
        case 5: return "u-progress2"
        case 6: return "u-installed"
        case 7: go("home"); return "u-home-after"
        default: return ""
        }
    }
    function resumeTourStep(step, phase) {
        if (phase === 1) {
            switch (step) {
            case 0:
                Exam.startOfficial("reglementation", false)
                startExam()
                return "r-started"
            case 1:
                Exam.select(0, 1); Exam.select(1, 2); Exam.togglePin(1)
                return "r-answered"
            case 2: Qt.quit(); return "r-quit"
            default: return ""
            }
        }
        switch (step) {
        case 0: return "r-home-banner"
        case 1: Exam.resumeSaved(); startExam(); return "r-resumed"
        default: return ""
        }
    }
    function importTourStep(step) {
        switch (step) {
        case 0: go("update"); Updates.importLocal(Qt.resolvedUrl("file://" + App.dataDir + "/../pack.zip")); return "i-importing"
        case 1: return "i-progress"
        case 2: return "i-done"
        case 3: go("browser"); return "i-browser"
        default: return ""
        }
    }
}
