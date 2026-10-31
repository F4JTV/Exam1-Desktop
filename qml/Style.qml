pragma Singleton
import QtQuick
import Exam1.Core

// Design tokens. The pale-yellow "sheet" is the colour of the Exam'1 question screens:
// every question is shown on it, so the published question images blend in seamlessly.
QtObject {
    readonly property bool dark: Prefs.colorScheme === "dark"
    readonly property real k: Prefs.textScale

    // Fixed brand colours
    readonly property color slate: "#1D2733"
    readonly property color slateHi: "#2B3746"
    readonly property color slateLine: "#3A4757"
    readonly property color slateText: "#E8EDF2"
    readonly property color slateTextMuted: "#A3B0BD"
    readonly property color yellow: "#FFD400"
    readonly property color sheet: "#FFFECE"
    readonly property color sheetEdge: "#E6DF9C"
    readonly property color sheetInk: "#1D2733"

    // Semantic colours
    readonly property color blue: dark ? "#6EA8FF" : "#1C5BA8"
    readonly property color blueStrong: "#1C5BA8"
    readonly property color blueSoft: dark ? "#203650" : "#E4EDF8"
    readonly property color green: dark ? "#5CCB8A" : "#1C7A43"
    readonly property color greenSoft: dark ? "#1D3A2A" : "#E0F2E7"
    readonly property color red: dark ? "#FF8A80" : "#B3261E"
    readonly property color redSoft: dark ? "#45201E" : "#FBE7E5"
    readonly property color pin: dark ? "#FFB45C" : "#B85C00"
    readonly property color pinSoft: dark ? "#40301A" : "#FFF0DB"

    // Surfaces
    readonly property color bg: dark ? "#141B23" : "#EBEEF1"
    readonly property color surface: dark ? "#1D2631" : "#FFFFFF"
    readonly property color surfaceAlt: dark ? "#242F3C" : "#F4F6F8"
    readonly property color line: dark ? "#334050" : "#D3D9DF"
    readonly property color text: dark ? "#E8EDF2" : "#1D2733"
    readonly property color muted: dark ? "#9DAAB7" : "#58636F"
    readonly property color focus: dark ? "#FFD400" : "#1C5BA8"

    // Exam screen (the Evalbox look of the ANFR exam): white by default, dark on request
    // (Settings > Affichage, or the accessibility menu of the exam).
    readonly property bool examDark: Prefs.examTheme === "dark"
    readonly property color evPage: examDark ? "#161C22" : "#FFFFFF"        // page, dialogs
    readonly property color evField: examDark ? "#232B34" : "#FFFFFF"       // check boxes, buttons
    readonly property color evInk: examDark ? "#E3E7EB" : "#212529"         // text
    readonly property color evMuted: examDark ? "#9AA6B0" : "#6C7B7C"       // secondary text
    readonly property color evFaint: examDark ? "#5E6873" : "#C6C7C9"       // "Choix multiples"
    readonly property color evRule: examDark ? "#55606B" : "#9AA9AC"        // line before "Question 3 / 20"
    readonly property color evDash: examDark ? "#323B45" : "#E5E5E5"        // dashes of the header line
    readonly property color evLine: examDark ? "#36404A" : "#DEE2E6"        // separators
    readonly property color evOutline: examDark ? "#8A949E" : "#6C757D"     // outlined buttons
    readonly property color evBoxLine: examDark ? "#6E7782" : "#BFBFBF"     // empty check box
    readonly property color evLink: examDark ? "#6EA8FF" : "#0A58CA"
    readonly property color evLinkSoft: examDark ? "#203650" : "#E7F1FF"
    readonly property color evSelection: examDark ? "#2B4A72" : "#CFE2FF"
    readonly property color evOk: examDark ? "#5CCB8A" : "#198754"          // answered, right
    readonly property color evBad: examDark ? "#FF8A80" : "#DC3545"
    readonly property color evOkText: examDark ? "#7DDBA3" : "#0F5132"
    readonly property color evBadText: examDark ? "#FF9A90" : "#842029"
    readonly property color evOkSoft: examDark ? "#1D3A2A" : "#D1E7DD"
    readonly property color evOkSofter: examDark ? "#18301F" : "#E9F5EE"
    readonly property color evOkEdge: examDark ? "#2F6B4A" : "#A3CFBB"
    readonly property color evBadSoft: examDark ? "#45201E" : "#F8D7DA"
    readonly property color evWarnSoft: examDark ? "#3D3418" : "#FFF3CD"
    readonly property color evWarnEdge: examDark ? "#6B5A20" : "#FFE69C"
    readonly property color evPinHover: examDark ? "#4A3F1F" : "#FFF6D6"
    readonly property color evLabelDone: examDark ? "#5CCB8A" : "#2B7C57"   // "Question 3 / 20" once answered
    // Top band
    readonly property color evBar: examDark ? "#2E353D" : "#AEB3B9"
    readonly property color evBarHover: examDark ? "#424A54" : "#BEC3C9"
    readonly property color evBarButton: examDark ? "#424A54" : "#C6CACF"
    readonly property color evBarPressed: examDark ? "#545E69" : "#9399A0"
    readonly property color evBarInk: examDark ? "#E3E7EB" : "#212529"
    readonly property color evBarIcon: examDark ? "#D5DAE0" : "#3A3F45"
    readonly property color evBarMuted: examDark ? "#AEB6BF" : "#6C737B"
    readonly property color evNav: examDark ? "#555D66" : "#8E9196"        // question numbers
    readonly property color evNavHover: examDark ? "#66707A" : "#7C8085"
    readonly property color evNavEdge: examDark ? "#6E7782" : "#9EA2A7"

    // Type scale (pixels)
    readonly property string family: "Atkinson Hyperlegible"
    readonly property int fXs: Math.round(12 * k)
    readonly property int fS: Math.round(14 * k)
    readonly property int fM: Math.round(16 * k)
    readonly property int fL: Math.round(19 * k)
    readonly property int fXl: Math.round(24 * k)
    readonly property int fXxl: Math.round(34 * k)
    readonly property int fHero: Math.round(76 * k)

    // Window size, set by Main.qml. Phones and narrow windows get smaller margins, a menu
    // button instead of the left rail, and taller touch targets on a touch screen.
    property real windowWidth: 1320
    readonly property bool touch: App.mobile
    readonly property bool compact: windowWidth < 600
    readonly property int margin: windowWidth < 600 ? 16 : windowWidth < 900 ? 28 : 48   // page side margin
    readonly property int hit: touch ? 44 : 38   // minimum height of buttons and choices

    // Geometry
    readonly property int r1: 4
    readonly property int r2: 8
    readonly property int r3: 14
    readonly property int gap: 16
    readonly property int pad: compact ? 16 : 24
    readonly property int readable: 860   // max width of reading columns

    function iconUrl(name, c) {
        var s = String(c)
        if (s.charAt(0) === "#")
            s = s.substring(1)
        return "image://icon/" + name + "/" + s
    }
}
