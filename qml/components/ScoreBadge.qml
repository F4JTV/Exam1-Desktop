import QtQuick
import Exam1App

// Mark out of 20 in large type, coloured by the pass/fail outcome.
Row {
    id: sb
    property real note: 0
    property bool passed: false
    property int size: 96
    spacing: 4
    Text {
        id: big
        text: (Math.round(sb.note * 10) / 10).toLocaleString(Qt.locale("fr_FR"), "f", sb.note % 1 === 0 ? 0 : 1)
        font.family: Style.family
        font.pixelSize: sb.size
        font.bold: true
        color: sb.passed ? Style.green : Style.red
    }
    Text {
        text: "/20"
        font.family: Style.family
        font.pixelSize: sb.size * 0.38
        font.bold: true
        color: Style.muted
        anchors.baseline: big.baseline
    }
}
