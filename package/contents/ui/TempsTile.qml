import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/palette.js" as Palette

GlassTile {
    id: tile
    required property var app

    readonly property var raw: [
        { label: i18n("CPU"), value: app.cpuTempValue },
        { label: i18n("GPU"), value: app.gpuTemp.value || 0 },
        { label: i18n("SSD"), value: app.nvmeTemp.value || 0 }
    ].filter(function (s) { return s.value > 0; })

    // CPU sensors jitter by a few degrees every second. A running average
    // keeps the numbers and colors calm while still following real changes
    // within a few seconds.
    property var smoothed: ({})
    onRawChanged: {
        var next = {};
        raw.forEach(function (s) {
            var old = smoothed[s.label];
            next[s.label] = old === undefined || Math.abs(s.value - old) > 15 ? s.value : old + (s.value - old) * 0.3;
        });
        smoothed = next;
    }
    // Whole degrees, so the bars only move (and the desktop only redraws)
    // when the shown number changes.
    readonly property var sources: raw.map(function (s) {
        return { label: s.label, value: Math.round(smoothed[s.label] !== undefined ? smoothed[s.label] : s.value) };
    })
    readonly property real hottest: sources.reduce(function (m, s) { return Math.max(m, s.value); }, 0)
    property color hotColor: app.tempColor(hottest)
    Behavior on hotColor { ColorAnimation { duration: Kirigami.Units.longDuration } }

    title: i18n("Temperatures")
    subtitle: hottest >= 85 ? i18n("Running hot") : hottest >= 70 ? i18n("Warm") : i18n("Cool")
    accent: hotColor
    accent2: app.heat(Math.max(0, Palette.tempLevel(hottest) - 0.3))
    level: Palette.tempLevel(hottest)

    // Bar unit: tile.u, shrunk so every row fits the height. A row is about
    // 2 units tall (a label line of 1.25, a 0.25 gap, a bar up to 0.5) with
    // 0.5 between rows.
    // Stacked, the number comes first: the bars take what it leaves (down
    // to a readable floor), so it's the same size as the other tiles'.
    readonly property real barRows: Math.max(1, sources.length * 2.5 - 0.5)
    readonly property real barU: Math.min(u, grid.height / barRows,
        wide ? u : Math.max(u * 0.7, (grid.height - figureSize * 1.4 - grid.rowSpacing) / barRows))

    // Pixel: a row of little thermometers instead of bars.
    readonly property bool thermometers: look && look.heatBar === "segments"

    Row {
        visible: tile.thermometers
        anchors.fill: parent
        readonly property int count: Math.max(1, tile.sources.length)
        readonly property real colW: width / count
        Repeater {
            model: tile.thermometers ? tile.sources.length : 0
            Item {
                id: thermo
                required property int index
                readonly property var source: tile.sources[index] || { label: "", value: 0 }
                readonly property real frac: Math.max(0, Math.min(1, source.value / 100))
                readonly property color hot: app.tempColor(source.value)
                readonly property real cell: Math.max(3, Math.min(tile.u * 0.55, (height - tile.u * 4.2) / 13))
                width: parent.colW
                height: parent.height
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    spacing: Math.max(2, tile.u * 0.2)
                    PlasmaComponents.Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        textFormat: Text.PlainText
                        text: app.tempText(thermo.source.value)
                        color: thermo.hot
                        font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
                        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.75)
                    }
                    // The tube: ten cells, lit from the bottom.
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: thermo.cell + 6
                        height: thermo.cell * 10 + 2 * 9 + 6
                        color: Qt.rgba(0, 0, 0, 0.35)
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Repeater {
                                model: 10
                                Rectangle {
                                    required property int index
                                    readonly property int level: 9 - index
                                    width: thermo.cell; height: thermo.cell
                                    color: level < Math.round(thermo.frac * 10)
                                        ? Qt.tint(app.heat(0), Qt.rgba(thermo.hot.r, thermo.hot.g, thermo.hot.b, level / 9))
                                        : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
                                }
                            }
                        }
                    }
                    // The bulb.
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: thermo.cell * 2.2; height: width
                        color: thermo.hot
                        border.width: 3
                        border.color: Qt.rgba(0, 0, 0, 0.35)
                    }
                    PlasmaComponents.Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(implicitWidth, thermo.width)
                        textFormat: Text.PlainText
                        text: thermo.source.label
                        opacity: 0.6
                        elide: Text.ElideRight
                        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.7)
                    }
                }
            }
        }
    }

    GridLayout {
        id: grid
        visible: !tile.thermometers
        anchors.fill: parent
        columns: tile.wide ? 2 : 1
        columnSpacing: tile.u
        rowSpacing: tile.u * 0.5

        BigNumber {
                family: tile.numberFamily
                figures: tile.figureFamily
                weight: tile.figureWeight
                plain: tile.nativeOn
            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
            value: app.tempValue(tile.hottest)
            unit: app.tempUnit
            // In the board's ink like every other tile's number, so a cool
            // reading stays calm; it takes the heat color once it's warm.
            color: tile.hottest >= 70 ? tile.hotColor : Kirigami.Theme.textColor
            // Stacked: the number gets the height the bars leave (its line is
            // up to 1.4x the font size, e.g. Noto Sans), and steps aside if
            // that's too little.
            readonly property real fit: tile.wide ? parent.height : (parent.height - bars.implicitHeight - parent.rowSpacing) / 1.4
            size: Math.min(tile.figureSize, fit)   // the same size as the other tiles' numbers
            visible: size >= tile.u * 1.4
        }
        ColumnLayout {
            id: bars
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom
            spacing: tile.barU * 0.5
            // A count, not the array: `sources` is rebuilt every sensor tick,
            // and an array model would recreate the bars each time, so they'd
            // jump instead of easing to the new reading.
            Repeater {
                model: tile.sources.length
                HeatBar {
                    required property int index
                    readonly property var source: tile.sources[index] || { label: "", value: 0 }
                    u: tile.barU
                    label: source.label
                    celsius: source.value
                    valueText: app.tempText(source.value)
                    hotColor: app.tempColor(source.value)
                    coolColor: app.heat(0)
                    square: tile.radius === 0
                    kind: tile.look && tile.look.heatBar ? tile.look.heatBar : "thin"
                    detailKind: tile.detailStyle
                    family: tile.figureFamily
                }
            }
        }
    }
}
