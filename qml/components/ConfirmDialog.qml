import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1App

// Modal confirmation.
Popup {
    id: dlg
    property string title: ""
    property string message: ""
    property string acceptText: "Confirmer"
    property string rejectText: "Annuler"
    property string acceptVariant: "primary"
    default property alias extra: extraCol.data
    signal accepted()
    signal rejected()

    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(560, (parent ? parent.width : 600) - 48)
    padding: 28
    closePolicy: Popup.CloseOnEscape
    onClosed: if (!_accepted) rejected()
    onOpened: { _accepted = false; acceptButton.forceActiveFocus() }
    property bool _accepted: false

    Overlay.modal: Rectangle { color: "#99101820" }

    background: Rectangle {
        color: Style.surface
        radius: Style.r3
        border.color: Style.line
    }

    contentItem: ColumnLayout {
        spacing: 16
        Text {
            text: dlg.title
            font.family: Style.family
            font.pixelSize: Style.fXl
            font.bold: true
            color: Style.text
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        Text {
            visible: dlg.message.length > 0
            text: dlg.message
            font.family: Style.family
            font.pixelSize: Style.fM
            color: Style.text
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            lineHeight: 1.15
        }
        ColumnLayout {
            id: extraCol
            Layout.fillWidth: true
            spacing: 8
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 12
            Item { Layout.fillWidth: true }
            ActionButton {
                text: dlg.rejectText
                variant: "secondary"
                visible: dlg.rejectText.length > 0
                onClicked: dlg.close()
            }
            ActionButton {
                id: acceptButton
                text: dlg.acceptText
                variant: dlg.acceptVariant
                onClicked: {
                    dlg._accepted = true
                    dlg.close()
                    dlg.accepted()
                }
            }
        }
    }
}
