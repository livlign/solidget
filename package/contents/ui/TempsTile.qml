import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/palette.js" as Palette

GlassTile {
    id: tile
    required property var app

    readonly property var sources: [
        { label: i18n("CPU"), value: app.cpuTempValue },
        { label: i18n("GPU"), value: app.gpuTemp.value || 0 },
        { label: i18n("SSD"), value: app.nvmeTemp.value || 0 }
    ].filter(function (s) { return s.value > 0; })
    readonly property real hottest: sources.reduce(function (m, s) { return Math.max(m, s.value); }, 0)
    readonly property color hotColor: app.tempColor(hottest)

    title: i18n("Temperatures")
    subtitle: hottest >= 85 ? i18n("Running hot") : hottest >= 70 ? i18n("Warm") : i18n("Cool")
    accent: hotColor
    accent2: app.heat(Math.max(0, Palette.tempLevel(hottest) - 0.3))
    level: Palette.tempLevel(hottest)

    // Bar unit: tile.u, shrunk so every row fits the height. A row is about
    // 1.7 units tall (label, gap, bar) with 0.5 between rows.
    readonly property real barU: Math.min(u, (grid.height + 1) / Math.max(1, sources.length * 2.2 - 0.5))

    GridLayout {
        id: grid
        anchors.fill: parent
        columns: tile.wide ? 2 : 1
        columnSpacing: tile.u
        rowSpacing: tile.u * 0.5

        BigNumber {
                family: tile.numberFamily
                plain: tile.nativeOn
            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
            value: app.tempValue(tile.hottest)
            unit: app.tempUnit
            color: tile.hotColor
            // Stacked: the number gets the height the bars leave (its line is
            // up to 1.4x the font size, e.g. Noto Sans), and steps aside if
            // that's too little.
            readonly property real fit: tile.wide ? parent.height : (parent.height - bars.implicitHeight - parent.rowSpacing) / 1.4
            size: Math.min(tile.u * (tile.wide ? 4.2 : 3.4), fit)
            visible: size >= tile.u * 1.4
        }
        ColumnLayout {
            id: bars
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom
            spacing: tile.barU * 0.5
            Repeater {
                model: tile.sources
                HeatBar {
                    required property var modelData
                    u: tile.barU
                    label: modelData.label
                    celsius: modelData.value
                    valueText: app.tempText(modelData.value)
                    hotColor: app.tempColor(modelData.value)
                    coolColor: app.heat(0)
                    square: tile.radius === 0
                }
            }
        }
    }
}
