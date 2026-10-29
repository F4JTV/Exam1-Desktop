import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

Page {
    id: page
    property bool immersive: false
    background: Rectangle { color: Style.bg }

    property int count: 20
    property bool instant: true
    readonly property int rev: User.revision + Bank.questionCount

    function start(source) {
        if (Exam.startReview(source, count, instant))
            Nav.window.startExam()
    }

    component Source: Rectangle {
        id: src
        property string key: ""
        property string heading: ""
        property string detail: ""
        property string iconName: ""
        property int available: 0
        Layout.fillWidth: true
        implicitHeight: row.implicitHeight + 40
        radius: Style.r2
        color: Style.surface
        border.color: Style.line
        // Narrow window: the count and the button go under the text.
        readonly property bool narrow: width < 640 * Style.k
        GridLayout {
            id: row
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 20
            columns: src.narrow ? 2 : 3
            columnSpacing: 18
            rowSpacing: 12
            Rectangle {
                Layout.row: 0
                Layout.column: 0
                Layout.alignment: Qt.AlignTop
                width: 48
                height: 48
                radius: 24
                color: Style.blueSoft
                Icon { anchors.centerIn: parent; name: src.iconName; color: Style.blue; size: 22 }
            }
            ColumnLayout {
                Layout.row: 0
                Layout.column: 1
                Layout.fillWidth: true
                spacing: 4
                Text { text: src.heading; font.family: Style.family; font.pixelSize: Style.fL; font.bold: true; color: Style.text; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                Text { text: src.detail; font.family: Style.family; font.pixelSize: Style.fS; color: Style.muted; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
            RowLayout {
                Layout.row: src.narrow ? 1 : 0
                Layout.column: src.narrow ? 1 : 2
                spacing: 18
                Text {
                    text: src.available + (src.available > 1 ? " questions" : " question")
                    font.family: Style.family
                    font.pixelSize: Style.fM
                    font.bold: true
                    color: src.available > 0 ? Style.text : Style.muted
                }
                ActionButton {
                    text: "Réviser"
                    enabled: src.available > 0
                    onClicked: page.start(src.key)
                }
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: col.implicitHeight + 80
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        ColumnLayout {
            id: col
            x: 48
            y: 40
            width: Math.min(1000, parent.width - 96)
            spacing: 20

            PageHeader {
                Layout.fillWidth: true
                title: "Révisions"
                subtitle: "Retravaillez les questions qui vous ont posé problème, jusqu'à ce qu'elles n'en posent plus."
            }

            Flow {
                Layout.fillWidth: true
                spacing: 24
                Text { text: "Questions par session"; font.family: Style.family; font.pixelSize: Style.fM; color: Style.text; height: Math.max(implicitHeight, sessionCount.implicitHeight); verticalAlignment: Text.AlignVCenter }
                Spinner {
                    id: sessionCount
                    value: page.count
                    from: 0
                    to: 200
                    step: 5
                    zeroLabel: "Toutes"
                    onEdited: (v) => page.count = v
                }
                CheckRow {
                    text: "Correction immédiate"
                    checked: page.instant
                    onToggled: page.instant = checked
                }
            }

            Source {
                key: "wrong"
                iconName: "cross"
                heading: "Mes erreurs"
                detail: "Questions dont la dernière réponse était fausse ou absente. Une bonne réponse les retire de la liste."
                available: page.rev >= 0 ? Exam.reviewAvailable("wrong") : 0
            }
            Source {
                key: "saved"
                iconName: "bookmark"
                heading: "Questions enregistrées"
                detail: "Celles que vous avez mises de côté pendant une correction ou dans la base de questions."
                available: page.rev >= 0 ? Exam.reviewAvailable("saved") : 0
            }
            Source {
                key: "unseen"
                iconName: "eye"
                heading: "Questions jamais posées"
                detail: "Pour parcourir toute la base sans retomber sur les mêmes questions."
                available: page.rev >= 0 ? Exam.reviewAvailable("unseen") : 0
            }

            Flow {
                Layout.topMargin: 8
                Layout.fillWidth: true
                spacing: 12
                ActionButton {
                    variant: "secondary"
                    iconName: "search"
                    text: "Voir mes questions enregistrées"
                    onClicked: {
                        Browser.wrongOnly = false
                        Browser.savedOnly = true
                        Nav.window.go("browser")
                    }
                }
                ActionButton {
                    variant: "ghost"
                    text: "Remettre les statistiques à zéro"
                    onClicked: resetDialog.open()
                }
            }
        }
    }

    ConfirmDialog {
        id: resetDialog
        title: "Remettre les statistiques à zéro ?"
        message: "Les questions déjà vues et vos erreurs seront oubliées pour " + User.currentCandidateName + ". Vos notes et vos questions enregistrées sont conservées."
        acceptText: "Remettre à zéro"
        acceptVariant: "danger"
        onAccepted: User.resetStatistics()
    }
}
