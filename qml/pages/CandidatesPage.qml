import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

// Several candidates can share one computer (radio club, family): each has his own
// results, saved questions and statistics.
Page {
    id: page
    property bool immersive: false
    background: Rectangle { color: Style.bg }

    readonly property var list: User.revision >= 0 ? User.candidates() : []
    property int renameId: 0
    property int deleteId: 0
    property string deleteName: ""

    Flickable {
        anchors.fill: parent
        contentHeight: col.implicitHeight + 80
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        ColumnLayout {
            id: col
            x: 48
            y: 40
            width: Math.min(900, parent.width - 96)
            spacing: 24

            PageHeader {
                Layout.fillWidth: true
                title: "Candidats"
                subtitle: "Chaque candidat a ses propres notes, erreurs et questions enregistrées. Pratique en radio-club ou en famille."
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                TextField2 {
                    id: newName
                    Layout.fillWidth: true
                    Layout.maximumWidth: 420
                    placeholderText: "Nom du nouveau candidat"
                    onAccepted: addButton.clicked()
                }
                ActionButton {
                    id: addButton
                    text: "Ajouter"
                    enabled: newName.text.trim().length > 0
                    onClicked: {
                        var id = User.addCandidate(newName.text)
                        if (id > 0)
                            User.currentCandidate = id
                        newName.text = ""
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: listCol.implicitHeight
                color: Style.surface
                radius: Style.r2
                border.color: Style.line
                clip: true
                ColumnLayout {
                    id: listCol
                    width: parent.width
                    spacing: 0
                    Repeater {
                        model: page.list
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool isCurrent: modelData.id === User.currentCandidate
                            // Narrow window: the actions go under the name.
                            readonly property bool narrow: width < 600 * Style.k
                            Layout.fillWidth: true
                            implicitHeight: Math.max(68, candRow.implicitHeight + 24)
                            color: isCurrent ? Style.blueSoft : (index % 2 ? Style.surfaceAlt : Style.surface)
                            GridLayout {
                                id: candRow
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 20
                                anchors.rightMargin: 12
                                columns: narrow ? 2 : 3
                                columnSpacing: 14
                                rowSpacing: 6
                                Rectangle {
                                    Layout.row: 0
                                    Layout.column: 0
                                    width: 36
                                    height: 36
                                    radius: 18
                                    color: isCurrent ? Style.blueStrong : Style.line
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name.charAt(0).toUpperCase()
                                        font.family: Style.family
                                        font.pixelSize: Style.fL
                                        font.bold: true
                                        color: isCurrent ? "#FFFFFF" : Style.text
                                    }
                                }
                                ColumnLayout {
                                    Layout.row: 0
                                    Layout.column: 1
                                    spacing: 2
                                    Layout.fillWidth: true
                                    Text {
                                        text: modelData.name
                                        font.family: Style.family
                                        font.pixelSize: Style.fL
                                        font.bold: true
                                        color: Style.text
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.exams + " épreuve" + (modelData.exams > 1 ? "s" : "") + ", dont " + (modelData.passed || 0) + " réussie" + ((modelData.passed || 0) > 1 ? "s" : "")
                                        font.family: Style.family
                                        font.pixelSize: Style.fS
                                        color: Style.muted
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                                RowLayout {
                                    Layout.row: narrow ? 1 : 0
                                    Layout.column: narrow ? 1 : 2
                                    spacing: 14
                                    Text {
                                        visible: isCurrent
                                        text: "Candidat actuel"
                                        font.family: Style.family
                                        font.pixelSize: Style.fS
                                        font.bold: true
                                        color: Style.blue
                                    }
                                    ActionButton {
                                        visible: !isCurrent
                                        variant: "secondary"
                                        compact: true
                                        text: "Choisir"
                                        onClicked: User.currentCandidate = modelData.id
                                    }
                                    ActionButton {
                                        variant: "ghost"
                                        compact: true
                                        iconName: "edit"
                                        text: "Renommer"
                                        onClicked: {
                                            page.renameId = modelData.id
                                            renameField.text = modelData.name
                                            renameDialog.open()
                                        }
                                    }
                                    ActionButton {
                                        variant: "ghost"
                                        compact: true
                                        iconName: "trash"
                                        tint: Style.muted
                                        text: ""
                                        Accessible.name: "Supprimer " + modelData.name
                                        onClicked: {
                                            page.deleteId = modelData.id
                                            page.deleteName = modelData.name
                                            deleteDialog.open()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ConfirmDialog {
        id: renameDialog
        title: "Renommer le candidat"
        acceptText: "Renommer"
        TextField2 {
            id: renameField
            Layout.fillWidth: true
        }
        onAccepted: User.renameCandidate(page.renameId, renameField.text)
    }

    ConfirmDialog {
        id: deleteDialog
        title: "Supprimer " + page.deleteName + " ?"
        message: "Toutes ses notes, ses questions enregistrées et ses statistiques seront effacées définitivement."
        acceptText: "Supprimer"
        acceptVariant: "danger"
        onAccepted: User.removeCandidate(page.deleteId)
    }
}
