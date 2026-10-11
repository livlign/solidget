import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../code/quotes.js" as Quotes

GlassTile {
    id: tile
    required property var app

    property date today: new Date()
    // Re-check after midnight, on the shared tick.
    Connections { target: app; function onTickChanged() { if (app.tick % 60 === 0) tile.today = new Date(); } }
    readonly property var q: Quotes.forDate(today)

    title: i18n("Quote of the day")
    accent: app.accent("quote")
    accent2: app.accent2("quote")
    level: 0.3

    ColumnLayout {
        anchors.fill: parent
        spacing: tile.u * 0.4
        PlasmaComponents.Label {
            text: "“"
            color: tile.accent
            font.pixelSize: tile.u * 3
            font.family: tile.numberFamily || "serif"
            Layout.preferredHeight: tile.u * 1.4
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: tile.q[0]
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            fontSizeMode: Text.Fit
            minimumPixelSize: Kirigami.Theme.smallFont.pixelSize
            font.pixelSize: tile.u * 1.5
            font.family: tile.numberFamily || "serif"
            font.italic: !tile.numberFamily
            verticalAlignment: Text.AlignTop
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: "— " + tile.q[1]
            opacity: 0.65
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.8)
            elide: Text.ElideRight
        }
    }
}
