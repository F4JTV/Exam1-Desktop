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

    // Type scale (pixels)
    readonly property string family: "Atkinson Hyperlegible"
    readonly property int fXs: Math.round(12 * k)
    readonly property int fS: Math.round(14 * k)
    readonly property int fM: Math.round(16 * k)
    readonly property int fL: Math.round(19 * k)
    readonly property int fXl: Math.round(24 * k)
    readonly property int fXxl: Math.round(34 * k)
    readonly property int fHero: Math.round(76 * k)

    // Geometry
    readonly property int r1: 4
    readonly property int r2: 8
    readonly property int r3: 14
    readonly property int gap: 16
    readonly property int pad: 24
    readonly property int readable: 860   // max width of reading columns

    function iconUrl(name, c) {
        var s = String(c)
        if (s.charAt(0) === "#")
            s = s.substring(1)
        return "image://icon/" + name + "/" + s
    }
}
