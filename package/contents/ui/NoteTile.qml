import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

// A note typed straight onto the dashboard, saved shortly after you stop typing.
GlassTile {
    id: tile
    required property var app

    // A sticky note, not a document: keeps the config file small.
    readonly property int maxLength: 4000

    title: i18n("Note")
    subtitle: edit.activeFocus ? i18n("Typing…") : ""
    accent: app.accent("note")
    accent2: app.accent2("note")
    level: 0.25

    Timer {
        id: saveTimer
        interval: 800
        onTriggered: Plasmoid.configuration.noteText = edit.text.slice(0, tile.maxLength)
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: edit.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !app.editing

        TextEdit {
            id: edit
            textFormat: TextEdit.PlainText
            width: flick.width
            text: Plasmoid.configuration.noteText
            wrapMode: TextEdit.Wrap
            color: Kirigami.Theme.textColor
            selectionColor: tile.accent
            font.pixelSize: Math.max(Kirigami.Theme.defaultFont.pixelSize, tile.u * 0.95)
            font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
            enabled: !app.editing
            onTextChanged: if (activeFocus) saveTimer.restart()
            onActiveFocusChanged: if (!activeFocus) Plasmoid.configuration.noteText = text.slice(0, tile.maxLength)

            PlasmaComponents.Label {
                textFormat: Text.PlainText
                visible: edit.text === "" && !edit.activeFocus
                text: i18n("Click to write a note…")
                opacity: 0.45
                font: edit.font
            }
        }
    }
}
