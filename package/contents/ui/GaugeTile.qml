import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Ring gauge + details + optional history, arranged by tile shape:
//   wide (≥ 1.5:1):  [ring] [details over a chart that fills the rest]
//   square / tall:   ring on top, details below, chart fills what's left
GlassTile {
    id: tile

    property real value: 0               // percent
    property string valueText: ""        // optional override inside the ring
    property string unit: "%"
    property var details: []             // [{ label, value, dot? }]
    property var history: null           // array of samples, 0..100
    property real historyMax: 100

    level: value / 100

    readonly property bool sideBySide: width >= height * 1.5
    readonly property real rowH: u * 1.45
    readonly property real ringSize: sideBySide
        ? Math.min(body.height, body.width * 0.42)
        : Math.min(body.width * 0.9, body.height - (details.length ? rowH * Math.min(2, details.length) : 0))

    // Space left for details + chart, in the column beside or below the ring.
    readonly property real restH: sideBySide ? body.height : body.height - ringSize - u * 0.5
    readonly property real restW: sideBySide ? body.width - ringSize - u * 1.2 : body.width
    readonly property bool showChart: history !== null && restH - rowH * Math.min(details.length, 2) > u * 2.5
    readonly property int detailRows: Math.max(0, Math.min(details.length,
        Math.floor((restH - (showChart ? u * 2.5 : 0)) / rowH)))

    Item {
        id: body
        anchors.fill: parent

        RingGauge {
            id: ring
            width: tile.ringSize
            height: tile.ringSize
            x: tile.sideBySide ? 0 : (body.width - width) / 2
            y: tile.sideBySide ? (body.height - height) / 2 : 0
            value: tile.value
            accent: tile.accent
            accent2: tile.accent2
            glow: tile.glowOn
            roundCaps: tile.look ? tile.look.roundCaps : true

            BigNumber {
                family: tile.numberFamily
                anchors.centerIn: parent
                value: tile.value
                text: tile.valueText
                unit: tile.unit
                decimals: tile.value < 10 && tile.valueText === "" ? 1 : 0
                size: ring.width * 0.26
            }
        }

        ColumnLayout {
            x: tile.sideBySide ? ring.width + tile.u * 1.2 : 0
            y: tile.sideBySide ? 0 : ring.height + tile.u * 0.5
            width: tile.restW
            height: tile.restH
            spacing: 0

            Repeater {
                model: tile.details.slice(0, tile.detailRows)
                DetailRow {
                    required property var modelData
                    Layout.preferredHeight: tile.rowH
                    u: tile.u
                    maxValueWidth: tile.restW * 0.65
                    label: modelData.label
                    value: modelData.value
                    dot: modelData.dot || "transparent"
                }
            }

            Sparkline {
                visible: tile.showChart
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: tile.u * 0.3
                glow: tile.glowOn
                values: tile.history || []
                maxValue: tile.historyMax
                color: tile.accent
                colorEnd: tile.accent2
            }

            Item { visible: !tile.showChart; Layout.fillHeight: true }
        }
    }
}
