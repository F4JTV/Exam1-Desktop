import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Exam1.Core
import Exam1App

Page {
    id: page
    property bool immersive: false
    background: Rectangle { color: Style.bg }

    readonly property var themeChoices: {
        var list = [{ text: "Tous les thèmes", value: 0 },
                    { text: "Toute la réglementation", value: 3 },
                    { text: "Toute la technique", value: 2 }]
        var r = Bank.regulationThemes, t = Bank.technicalThemes
        for (var i = 0; i < r.length; ++i) list.push({ text: "R " + r[i].id + " : " + r[i].name, value: r[i].id })
        for (var j = 0; j < t.length; ++j) list.push({ text: "T " + t[j].id + " : " + t[j].name, value: t[j].id })
        return list
    }

    header: Rectangle {
        implicitHeight: headerCol.implicitHeight + 40
        color: Style.surface
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Style.line }
        ColumnLayout {
            id: headerCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 48
            anchors.rightMargin: 48
            spacing: 14
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Base de questions"
                    font.family: Style.family
                    font.pixelSize: Style.fXxl
                    font.bold: true
                    color: Style.text
                    Layout.fillWidth: true
                }
                Text {
                    text: Browser.count + " question" + (Browser.count > 1 ? "s" : "") + " sur " + Bank.questionCount
                    font.family: Style.family
                    font.pixelSize: Style.fM
                    color: Style.muted
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 14
                TextField2 {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.maximumWidth: 460
                    placeholderText: "Rechercher un mot, une valeur ou un numéro (ex. 20003)"
                    text: Browser.search
                    onTextChanged: searchTimer.restart()
                    Timer {
                        id: searchTimer
                        interval: 250
                        onTriggered: Browser.search = searchField.text
                    }
                }
                ComboBox {
                    id: themeBox
                    Layout.preferredWidth: 360
                    model: page.themeChoices
                    textRole: "text"
                    valueRole: "value"
                    font.family: Style.family
                    font.pixelSize: Style.fS
                    background: Rectangle {
                        implicitHeight: 40
                        radius: Style.r2
                        color: Style.surface
                        border.width: themeBox.visualFocus ? 2 : 1
                        border.color: themeBox.visualFocus ? Style.focus : Style.line
                    }
                    contentItem: Text {
                        leftPadding: 12
                        rightPadding: themeBox.indicator.width + 8
                        text: themeBox.displayText
                        font: themeBox.font
                        color: Style.text
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    Component.onCompleted: currentIndex = Math.max(0, indexOfValue(Browser.theme))
                    onActivated: Browser.theme = currentValue
                }
                CheckRow {
                    text: "Enregistrées"
                    checked: Browser.savedOnly
                    onToggled: Browser.savedOnly = checked
                }
                CheckRow {
                    text: "Mes erreurs"
                    checked: Browser.wrongOnly
                    onToggled: Browser.wrongOnly = checked
                }
            }
        }
    }

    ListView {
        id: list
        anchors.fill: parent
        model: Browser
        spacing: 24
        clip: true
        topMargin: 28
        bottomMargin: 48
        cacheBuffer: 1600
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }

        delegate: Item {
            id: row
            required property int index
            required property int num
            required property string ref
            required property string statement
            required property url image
            required property var options
            required property int answer
            required property string themeName
            required property string comment
            required property string course
            required property bool saved
            width: list.width
            implicitHeight: card.implicitHeight
            Rectangle {
                id: card
                width: Math.min(Style.readable + 48, list.width - 64)
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: sheet.implicitHeight + 48
                radius: Style.r2
                color: Style.surface
                border.color: Style.line
                QuestionSheet {
                    id: sheet
                    x: 24
                    y: 24
                    width: parent.width - 48
                    mode: "browse"
                    position: row.index + 1
                    total: Browser.count
                    num: row.num
                    ref: row.ref
                    statement: row.statement
                    image: row.image
                    options: row.options
                    selection: 0
                    correct: row.answer
                    revealed: true
                    saved: row.saved
                    themeName: row.themeName
                    comment: row.comment
                    course: row.course
                    onSaveRequested: User.toggleSaved(row.num)
                }
            }
        }

        Column {
            anchors.centerIn: parent
            visible: list.count === 0
            spacing: 12
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Bank.ready ? "Aucune question ne correspond à ces critères." : "Aucune base de questions installée."
                font.family: Style.family
                font.pixelSize: Style.fL
                color: Style.muted
            }
            ActionButton {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: Bank.ready
                variant: "secondary"
                text: "Effacer les filtres"
                onClicked: {
                    searchField.text = ""
                    Browser.search = ""
                    Browser.theme = 0
                    themeBox.currentIndex = 0
                    Browser.savedOnly = false
                    Browser.wrongOnly = false
                }
            }
        }
    }
}
