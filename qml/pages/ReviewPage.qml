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
    readonly property var errors: rev >= 0 ? User.reviewSummary() : ({})
    readonly property var weak: rev >= 0
        ? Exam.themeStats("technique").concat(Exam.themeStats("reglementation")).filter(t => t.weak)
              .sort((a, b) => a.rate - b.rate)
        : []

    function percent(rate) { return Math.round(rate * 100) + " %" }
    function errorsNote() {
        var p = errors.pending || 0, d = errors.due || 0
        if (p === 0)
            return "Aucune erreur en attente."
        var later = p - d
        var s = d > 0 ? (d + " à revoir aujourd'hui") : "Rien à revoir aujourd'hui"
        if (later > 0)
            s += " · " + later + " à revoir plus tard"
                 + (errors.nextLabel ? " (prochaine révision " + errors.nextLabel + ")" : "")
        return s + "."
    }
    function weakNote() {
        if (weak.length === 0)
            return "Aucun thème faible pour l'instant."
        // The three weakest, then how many others.
        var shown = weak.slice(0, 3).map(t => t.name + " (" + percent(t.rate) + ")").join(" · ")
        var others = weak.length - 3
        return others > 0 ? shown + " et " + others + (others > 1 ? " autres thèmes." : " autre thème.") : shown + "."
    }

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
        property string note: ""
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
                Text {
                    visible: src.note.length > 0
                    text: src.note
                    Layout.topMargin: 4
                    Layout.fillWidth: true
                    font.family: Style.family
                    font.pixelSize: Style.fS
                    font.bold: true
                    color: Style.text
                    wrapMode: Text.WordWrap
                }
            }
            RowLayout {
                Layout.row: src.narrow ? 1 : 0
                Layout.column: src.narrow ? 0 : 2
                Layout.columnSpan: src.narrow ? 2 : 1
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
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
            x: Style.margin
            y: Style.compact ? 20 : 40
            width: Math.min(1000, parent.width - 2 * Style.margin)
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
                detail: "Une question manquée revient le jour même, puis 1, 3 et 7 jours après chaque bonne réponse, et quitte la liste à la quatrième. Une nouvelle erreur la fait repartir du début."
                note: page.errorsNote()
                available: page.rev >= 0 ? Exam.reviewAvailable("wrong") : 0
            }
            Source {
                key: "weak"
                iconName: "target"
                heading: "Mes thèmes faibles"
                detail: "Les thèmes où vous réussissez moins de 75 % des réponses (5 réponses au moins). Les questions manquées passent en premier, puis celles jamais posées."
                note: page.weakNote()
                available: page.rev >= 0 ? Exam.reviewAvailable("weak") : 0
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
                    width: Math.min(implicitWidth, parent.width)
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
                    width: Math.min(implicitWidth, parent.width)
                    variant: "secondary"
                    iconName: "chart"
                    text: "Réussite par thème"
                    onClicked: Nav.window.go("history")
                }
                ActionButton {
                    width: Math.min(implicitWidth, parent.width)
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
