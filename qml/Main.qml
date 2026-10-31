import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Exam1.Core
import Exam1App

ApplicationWindow {
    id: win
    width: 1320
    height: 880
    // Small enough for a phone-sized window: below 880 px the rail becomes a menu (TopBar + drawer).
    minimumWidth: 360
    minimumHeight: 480
    visible: true
    // Full screen on Android, as in FT891Remote: the status and navigation bars are hidden, and come
    // back for a moment with a swipe from the edge of the screen. Unchanged on the desktop.
    visibility: Qt.platform.os === "android" ? Window.FullScreen : Window.AutomaticVisibility
    title: immersive ? "Exam'1 - " + Exam.title : "Exam'1"
    color: Style.bg
    font.family: Style.family
    font.pixelSize: Style.fM

    property string section: "home"
    readonly property bool immersive: stack.currentItem !== null && stack.currentItem.immersive === true
    // Left rail on wide windows; on phones, portrait tablets and narrow windows, a top bar with a
    // menu button opening the same navigation in a drawer.
    readonly property bool railMode: width - App.safeLeft - App.safeRight >= Math.round(880 + 110 * Math.max(0, Style.k - 1))
    readonly property bool showNav: !immersive && Bank.ready

    readonly property var sectionTitles: ({
        home: "Accueil", training: "Entraînement", series: "Séries", review: "Révisions",
        browser: "Base de questions", history: "Résultats", candidates: "Candidats",
        update: "Mises à jour", settings: "Paramètres", about: "À propos"
    })

    Binding { target: Style; property: "windowWidth"; value: win.width - App.safeLeft - App.safeRight }

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
        drawer.close()
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

    // Android "Back" button or gesture: closes the menu, goes back one screen, then to the home
    // screen; on the home screen it leaves the application. During an exam the exam page asks.
    function handleBack() {
        if (drawer.opened) {
            drawer.close()
            return true
        }
        var page = stack.currentItem
        if (page && typeof page.handleBack === "function" && page.handleBack())
            return true
        if (immersive)
            return Bank.ready
        if (stack.depth > 1) {
            stack.pop()
            return true
        }
        if (section !== "home" && Bank.ready) {
            go("home")
            return true
        }
        return false
    }
    onClosing: (close) => {
        if (Qt.platform.os === "android" && handleBack())
            close.accepted = false
    }

    function toast(message) {
        toastText.text = message
        toastBox.opacity = 1
        toastTimer.restart()
    }

    // Parts of the screen the content must stay clear of (App.safe*): on Android, a camera cutout on
    // the side of a phone held sideways; EXAM1_SAFE_AREA on a computer. Bands of the bar colour.
    Rectangle {
        z: 1
        anchors.top: parent.top
        width: parent.width
        height: App.safeTop
        color: Style.slate
        visible: height > 0
    }
    Rectangle {
        z: 1
        anchors.left: parent.left
        width: App.safeLeft
        height: parent.height
        color: Style.slate
        visible: width > 0
    }
    Rectangle {
        z: 1
        anchors.right: parent.right
        width: App.safeRight
        height: parent.height
        color: Style.slate
        visible: width > 0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: App.safeTop
        anchors.bottomMargin: App.safeBottom
        anchors.leftMargin: App.safeLeft
        anchors.rightMargin: App.safeRight
        spacing: 0

        // Always visible, above the pages, except during an exam or a training session.
        TopBar {
            z: 1
            Layout.fillWidth: true
            visible: win.showNav && !win.railMode
            title: stack.currentItem && stack.currentItem.navTitle ? stack.currentItem.navTitle : (win.sectionTitles[win.section] || "")
            badge: Updates.updateAvailable || AppUpdate.available
            onMenuRequested: drawer.open()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            NavRail {
                Layout.fillHeight: true
                visible: win.showNav && win.railMode
                current: win.section
                onNavigate: (key) => win.go(key)
            }

            StackView {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                focus: true
                // A scrolled page stays between the top bar and the navigation bar of the phone.
                clip: true
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
    }

    // Navigation drawer of the top bar (same content as the rail).
    Drawer {
        id: drawer
        edge: Qt.LeftEdge
        width: Math.min(Math.round(300 + 110 * Math.max(0, Style.k - 1)), win.width - 48)
        height: win.height
        interactive: win.showNav && !win.railMode
        padding: 0
        background: Rectangle { color: Style.slate }
        NavRail {
            anchors.fill: parent
            anchors.topMargin: App.safeTop
            anchors.bottomMargin: App.safeBottom
            anchors.leftMargin: App.safeLeft
            current: win.section
            onNavigate: (key) => win.go(key)
        }
    }
    onRailModeChanged: if (railMode) drawer.close()

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
        anchors.bottomMargin: 32 + App.safeBottom
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
    function findFlickable(item) {
        if (!item)
            return null
        if (item.contentY !== undefined && item.flickableDirection !== undefined)
            return item
        for (var i = 0; i < item.children.length; ++i) {
            var found = findFlickable(item.children[i])
            if (found)
                return found
        }
        return null
    }
    function scrollCurrentPage(dy) {
        var f = findFlickable(stack.currentItem)
        if (f)
            f.contentY = Math.max(0, Math.min(f.contentHeight - f.height, dy))
    }
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
        if (tourName === "scroll") {
            // Each section scrolled down: the content must stay under the top bar and the status bar.
            var keys = ["home", "training", "series", "review", "history", "update", "settings", "about"]
            if (step >= 2 * keys.length)
                return ""
            var key = keys[Math.floor(step / 2)]
            if (step % 2 === 0) {
                go(key)
                return "s-" + key
            }
            scrollCurrentPage(400)
            return "s-" + key + "-scrolled"
        }
        if (tourName === "nav") {
            // Phone navigation: drawer and the Android "Back" button (handleBack).
            var results = User.results("", 0)
            switch (step) {
            case 0: go("training"); return "n-training"
            case 1: drawer.open(); return "n-drawer"
            case 2: handleBack(); return "n-back-drawer"
            case 3: go("history"); open("CorrectionPage", { resultId: results.length ? results[0].id : 0 }); return "n-correction"
            case 4: handleBack(); return "n-back-history"
            case 5: handleBack(); return "n-back-home"
            case 6: Exam.startOfficial("reglementation", false); startExam(); return "n-exam"
            case 7: stack.currentItem.gridOpen = true; return "n-grid"
            case 8: handleBack(); return "n-back-grid"
            case 9: handleBack(); return "n-back-quit"
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
