import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// A reading with its details and optional history, laid out the style's
// way (`look.gauge`):
//   "ring":  a dial with the number inside
//            wide (≥ 1.5:1):  [dial] [details over a chart that fills the rest]
//            square / tall:   dial on top, details below, chart in what's left
//   "bar" / "hp": a big number over a bar ("hp": in segments, like a game's
//            health bar), then details and the chart; side by side when wide
GlassTile {
    id: tile

    property real value: 0               // percent
    property real value2: 0              // a faint second reach, percent (Memory: + cache)
    property string valueText: ""        // optional override inside the ring
    property string unit: "%"
    property var details: []             // [{ label, value, dot? }]
    property var history: null           // array of samples, 0..100
    property real historyMax: 100        // 0 = scale to the data (rates)
    property var history2: []            // optional second line (e.g. writes)
    property bool historySqrt: false     // squash big spikes (rates)
    property real historyMinMax: 1       // auto scale never goes below this
    property int slots: 0                // Pixel: show the value as this many inventory slots

    level: value / 100

    // A style may keep the dial for some tiles (Bento: GPU and Disk).
    readonly property string gauge: !look || !look.gauge ? "ring"
        : (look.ringTiles || []).indexOf(tileId) >= 0 ? "ring" : look.gauge
    readonly property bool barMode: gauge === "bar" || gauge === "hp"
    readonly property bool chips: detailStyle === "chips"
    readonly property bool sideBySide: width >= height * 1.5
    readonly property real rowH: u * (chips ? 1.75 : 1.45)
    readonly property real gap: u * 0.3
    // Chips sit in one row (as many as fit), rows stack.
    readonly property int detailSlots: chips ? Math.min(1, details.length) : details.length
    // Square / tall: the ring leaves room for two details below it.
    readonly property real ringSize: sideBySide
        ? Math.min(body.height, body.width * 0.42)
        : Math.min(body.width * 0.9, body.height - (details.length ? rowH * Math.min(2, detailSlots) + gap : 0))
    // Bar mode: the number's size and the block it makes with its bar.
    readonly property real numberSize: Math.max(Kirigami.Units.gridUnit * 1.6,
        Math.min(u * 3.6, body.height * (sideBySide ? 0.42 : 0.3), (sideBySide ? body.width * 0.42 : body.width) * 0.42))
    // A number's line is up to 1.4 × its size (Manrope, Noto Sans).
    readonly property real headH: numberSize * 1.4 + u * 0.4 + (slotMode ? slotH : barH)
    // Pixel: the value as inventory slots (Memory: one per GiB).
    readonly property bool slotMode: gauge === "hp" && slots > 0
    readonly property int slotCols: slots <= 16 ? 8 : 16
    readonly property real slotGap: Math.max(2, u * 0.15)
    readonly property real slotSize: Math.max(4, Math.min(u * 1.2, (leadW - slotGap * (slotCols - 1)) / slotCols))
    readonly property int slotRowCount: Math.ceil(slots / slotCols)
    readonly property real slotH: slotRowCount * slotSize + (slotRowCount - 1) * slotGap
    readonly property real barH: Math.max(4, u * (gauge === "hp" ? 0.7 : 0.45))
    readonly property real leadW: barMode ? (sideBySide ? body.width * 0.42 : body.width) : ringSize
    readonly property real leadH: barMode ? (sideBySide ? body.height : headH) : ringSize

    // Space left for details + chart, in the column beside or below the lead.
    readonly property real restH: sideBySide ? body.height : body.height - leadH - gap
    readonly property real restW: sideBySide ? body.width - leadW - u * 1.2 : body.width
    readonly property bool showChart: history !== null && restH - rowH * Math.min(detailSlots, 2) > u * 2.5
    readonly property int detailRows: Math.max(0, Math.min(detailSlots,
        Math.floor((restH - (showChart ? u * 2.5 : 0)) / rowH + 0.01)))
    // The dial's stroke, by the style's meter.
    readonly property real ringThickness: meterStyle === "hairline" ? Math.max(1.5, ringSize * 0.018)
        : meterStyle === "thick" ? Math.max(5, ringSize * 0.12)
        : Math.max(3, ringSize * 0.075)

    Item {
        id: body
        anchors.fill: parent

        RingGauge {
            id: ring
            visible: !tile.barMode
            width: tile.ringSize
            height: tile.ringSize
            x: tile.sideBySide ? 0 : (body.width - width) / 2
            y: tile.sideBySide ? (body.height - height) / 2 : 0
            value: tile.value
            value2: tile.value2
            accent: tile.accent
            accent2: tile.accent2
            glow: tile.glowOn
            thickness: tile.ringThickness
            roundCaps: tile.look ? tile.look.roundCaps : true
            blocks: tile.meterStyle === "blocks"
            ticks: tile.meterStyle === "ticks"

            BigNumber {
                family: tile.numberFamily
                figures: tile.figureFamily
                weight: tile.figureWeight
                plain: tile.nativeOn
                anchors.centerIn: parent
                value: tile.value
                text: tile.valueText
                unit: tile.unit
                decimals: tile.value < 10 && tile.valueText === "" ? 1 : 0
                size: ring.width * 0.26
            }
        }

        // Bar mode: the number, big, over a bar.
        ColumnLayout {
            visible: tile.barMode
            width: tile.leadW
            height: tile.leadH
            spacing: tile.u * 0.4
            Item { visible: tile.sideBySide; Layout.fillHeight: true }
            BigNumber {
                family: tile.numberFamily
                figures: tile.figureFamily
                weight: tile.figureWeight
                plain: tile.nativeOn
                value: tile.value
                text: tile.valueText
                unit: tile.unit
                decimals: tile.value < 10 && tile.valueText === "" ? 1 : 0
                size: tile.numberSize
            }
            Grid {
                visible: tile.slotMode
                columns: tile.slotCols
                spacing: tile.slotGap
                Repeater {
                    model: tile.slotMode ? tile.slots : 0
                    Rectangle {
                        required property int index
                        readonly property bool used: index < Math.round(tile.value / 100 * tile.slots)
                        readonly property bool cached: !used && index < Math.round(tile.value2 / 100 * tile.slots)
                        width: tile.slotSize; height: width
                        color: used ? tile.accent
                             : cached ? Qt.rgba(tile.accent.r, tile.accent.g, tile.accent.b, 0.3)
                             : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
                        // A highlight on top, a shade below: a little item icon.
                        Rectangle { visible: parent.used; width: parent.width; height: Math.max(1, parent.height * 0.2); color: Qt.rgba(1, 1, 1, 0.35) }
                        Rectangle { visible: parent.used; y: parent.height - height; width: parent.width; height: Math.max(1, parent.height * 0.2); color: Qt.rgba(0, 0, 0, 0.3) }
                    }
                }
            }
            MeterBar {
                visible: !tile.slotMode
                Layout.fillWidth: true
                Layout.preferredHeight: tile.barH
                value: tile.value / 100
                value2: tile.value2 / 100
                accent: tile.accent
                accent2: tile.accent2
                segments: tile.gauge === "hp" ? 10 : 0
                rounded: tile.look ? tile.look.roundCaps : true
            }
        }

        ColumnLayout {
            x: tile.sideBySide ? tile.leadW + tile.u * 1.2 : 0
            y: tile.sideBySide ? 0 : tile.leadH + tile.gap
            width: tile.restW
            height: tile.restH
            spacing: 0

            Repeater {
                model: tile.chips ? [] : tile.details.slice(0, tile.detailRows)
                DetailRow {
                    required property var modelData
                    Layout.preferredHeight: tile.rowH
                    u: tile.u
                    maxValueWidth: tile.restW * 0.65
                    label: modelData.label
                    value: modelData.value
                    dot: modelData.dot || "transparent"
                    kind: tile.detailStyle
                    family: tile.figureFamily
                }
            }
            // Bento: the details as a row of chips, as many as fit.
            Flow {
                visible: tile.chips && tile.detailRows > 0
                Layout.fillWidth: true
                Layout.preferredHeight: tile.rowH
                spacing: tile.u * 0.3
                clip: true
                Repeater {
                    model: tile.chips ? tile.details : []
                    DetailChip {
                        required property var modelData
                        u: tile.u
                        label: modelData.label
                        value: modelData.value
                        dot: modelData.dot || "transparent"
                        full: tile.restW > tile.u * 16
                    }
                }
            }

            Sparkline {
                visible: tile.showChart
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: tile.u * 0.3
                glow: tile.glowOn
                liveDot: !tile.nativeOn
                kind: tile.chartStyle
                values: tile.history || []
                values2: tile.history2 || []
                maxValue: tile.historyMax
                minAutoMax: tile.historyMinMax
                sqrtScale: tile.historySqrt
                color: tile.accent
                colorEnd: (tile.history2 || []).length ? tile.accent : tile.accent2
                color2: tile.accent2
            }

            Item { visible: !tile.showChart; Layout.fillHeight: true }
        }
    }
}
