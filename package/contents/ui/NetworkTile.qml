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

    // Wi-Fi signal strength, 0-100 (0 on Ethernet).
    readonly property real signal: app.onWifi ? app.netSignal.value || 0 : 0

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
                        plain: tile.nativeOn
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
            liveDot: !tile.nativeOn
            bars: tile.look ? tile.look.chart === "bars" : false
            color: tile.downColor
            colorEnd: tile.downColor
            color2: tile.upColor
        }
    }

    // Wi-Fi signal right under "Wi-Fi" in the header: the familiar rising
    // bars, lit on NetworkManager's own steps, colored from the download
    // color to the upload color.
    Row {
        id: signalBars
        visible: tile.signal > 0 && tile.width > tile.u * 9
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Math.max(2, tile.u * 0.16)

        readonly property int lit: tile.signal > 80 ? 4 : tile.signal > 55 ? 3 : tile.signal > 30 ? 2 : tile.signal > 5 ? 1 : 0
        readonly property bool blocks: tile.look ? tile.look.meter === "blocks" : false
        readonly property bool round: tile.look ? tile.look.roundCaps : true
        readonly property real barW: Math.max(3, tile.u * 0.3)
        readonly property real fullH: Math.max(10, tile.u * 1.1)
        readonly property color track: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.13)

        Repeater {
            model: 4
            Item {
                id: bar
                required property int index
                readonly property bool on: index < signalBars.lit
                readonly property color color: Qt.tint(tile.downColor, Qt.rgba(tile.upColor.r, tile.upColor.g, tile.upColor.b, index / 3))
                readonly property real h: signalBars.fullH * (index + 1) / 4
                width: signalBars.barW
                height: signalBars.fullH

                // Soft glow behind a lit bar.
                Rectangle {
                    visible: bar.on && tile.glowOn && !signalBars.blocks
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -width * 0.3
                    width: parent.width * 2.2
                    height: bar.h + width * 0.6
                    radius: width / 2
                    color: Qt.rgba(bar.color.r, bar.color.g, bar.color.b, 0.16)
                }
                Rectangle {
                    visible: !signalBars.blocks
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: bar.h
                    radius: signalBars.round ? width / 2 : 0
                    color: bar.on ? bar.color : signalBars.track
                }
                // Pixel: each bar is a stack of square blocks.
                Column {
                    visible: signalBars.blocks
                    anchors.bottom: parent.bottom
                    spacing: Math.max(1, signalBars.barW * 0.25)
                    Repeater {
                        model: signalBars.blocks ? bar.index + 1 : 0
                        Rectangle {
                            width: signalBars.barW
                            height: width
                            color: bar.on ? bar.color : signalBars.track
                        }
                    }
                }
            }
        }
    }
}
