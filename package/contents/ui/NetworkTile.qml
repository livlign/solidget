import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../code/format.js" as Fmt
import "../code/palette.js" as Palette

GlassTile {
    id: tile
    required property var app

    readonly property color downColor: app.accent("network")
    readonly property color upColor: app.accent2("network")

    title: i18n("Network")
    subtitle: app.shownNetwork
    accent: downColor
    accent2: upColor
    // Glow follows how busy the link is, on a log scale up to ~100 MB/s.
    level: Math.min(1, Math.log(1 + (app.netDown.value + app.netUp.value) / 1024) / Math.log(1 + 100 * 1024))

    function split(rate) {
        var s = app.netRateText(rate);
        var i = s.indexOf(" ");
        return { n: s.slice(0, i), unit: s.slice(i + 1) };
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: tile.u * 0.3

        GridLayout {
            Layout.fillWidth: true
            columns: tile.width > tile.u * 13 ? 2 : 1
            columnSpacing: tile.u * 1.5
            rowSpacing: 0

            Repeater {
                model: [
                    { arrow: "↓", label: i18n("Download"), rate: app.netDown.value, color: tile.downColor },
                    { arrow: "↑", label: i18n("Upload"), rate: app.netUp.value, color: tile.upColor }
                ]
                ColumnLayout {
                    required property var modelData
                    readonly property var parts: tile.split(modelData.rate)
                    spacing: 0
                    PlasmaComponents.Label {
                        textFormat: Text.PlainText
                        text: modelData.arrow + " " + modelData.label
                        color: modelData.color
                        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.75)
                        font.weight: Font.DemiBold
                    }
                    BigNumber {
                        family: tile.numberFamily
                        text: parts.n
                        unit: parts.unit
                        size: Math.min(tile.u * 2.6, tile.height * 0.16)
                    }
                }
            }
        }

        Sparkline {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: tile.u * 2
            values: app.downHistory.values
            values2: app.upHistory.values
            maxValue: 0
            minAutoMax: 64 * 1024
            sqrtScale: true
            glow: tile.glowOn
            bars: tile.look ? tile.look.chart === "bars" : false
            color: tile.downColor
            colorEnd: tile.downColor
            color2: tile.upColor
        }
    }
}
