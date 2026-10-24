pragma Singleton
import QtQuick

// Global access to the main window's navigation functions (go, open, back, startExam,
// showResult, toast). Set by Main.qml; more reliable than the ApplicationWindow attached
// property for pages created before they are parented to the window.
QtObject {
    property var window: null
}
