import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

// Area chart with a soft glow, drawn with Shapes (GPU). `values2` draws a
// second series (e.g. upload) without fill. `maxValue: 0` auto-scales;
// `sqrtScale` keeps one spike from flattening everything else.
// `kind` is the style's chart: "line", "area" (deeper fill), "grid" (a line
// over faint gridlines, no fill), "columns" (square bars, the newest in
// full color), "rounded" (fewer, rounded bars), "pen" (a soft line with a
// dot on the newest reading, no fill: Bento) or "bars" (Pixel blocks).
Item {
    id: chart

    property var values: []
    property var values2: []
    property real maxValue: 100
    property real minAutoMax: 1
    property bool sqrtScale: false
    property int capacity: 60
    property color color: "#38bdf8"
    property color colorEnd: color
    property color color2: "#f472b6"
    property real lineWidth: Math.max(1.5, Math.min(2.5, height / 70)) * (kind === "pen" ? 1.4 : 1)
    property bool glow: true
    property bool bars: false       // Pixel: blocky columns snapped to a grid
    property string kind: bars ? "bars" : "line"
    readonly property bool columns: kind === "columns" || kind === "rounded"
    property bool liveDot: true     // dot on the newest sample (Plasma's charts have none)

    implicitHeight: Kirigami.Units.gridUnit * 2.5

    readonly property real scaleMax: {
        if (maxValue > 0) return maxValue;
        var m = minAutoMax;
        for (var i = 0; i < values.length; i++) m = Math.max(m, values[i]);
        for (var j = 0; j < values2.length; j++) m = Math.max(m, values2[j]);
        return m;
    }

    function points(data) {
        if (!data || data.length < 2 || width <= 0 || height <= 0) return [];
        var step = width / (capacity - 1);
        var x0 = width - (data.length - 1) * step;
        var pad = lineWidth * 2;
        var h = height - pad * 2;
        var pts = [];
        for (var i = 0; i < data.length; i++) {
            var r = scaleMax > 0 ? Math.min(data[i] / scaleMax, 1) : 0;
            if (sqrtScale) r = Math.sqrt(r);
            pts.push(Qt.point(x0 + i * step, pad + h - r * h));
        }
        return pts;
    }
    readonly property var line1: points(values)
    // Columns and rounded bars: the series averaged into a few wide bars.
    readonly property int colCount: kind === "rounded" ? 16 : 24
    readonly property var colHeights: colsOf(values)
    // Bento: the second series as capsules too, not a line across them.
    readonly property bool capsules: kind === "rounded"
    readonly property var colHeights2: capsules && values2 && values2.length ? colsOf(values2) : []
    function colsOf(values) {
        if (!columns || !values || values.length < 2 || height <= 0) return [];
        var per = Math.max(1, Math.floor(capacity / colCount));
        var out = [];
        for (var c = colCount - 1; c >= 0; c--) {
            var end = values.length - c * per, start = end - per, sum = 0, n = 0;
            for (var i = Math.max(0, start); i < end; i++) { sum += values[i]; n++; }
            var r = n && scaleMax > 0 ? Math.min(sum / n / scaleMax, 1) : 0;
            out.push(n ? (sqrtScale ? Math.sqrt(r) : r) : -1);
        }
        return out;
    }
    readonly property var line2: points(values2)

    // Smooth SVG path through the points: each segment is a cubic whose
    // control points sit at the horizontal midpoint, so the curve never
    // overshoots (no fake dips below zero) the way Catmull-Rom would.
    function svg(pts) {
        if (pts.length < 2) return "";
        var d = "M " + pts[0].x.toFixed(1) + " " + pts[0].y.toFixed(1);
        for (var i = 1; i < pts.length; i++) {
            var mx = ((pts[i - 1].x + pts[i].x) / 2).toFixed(1);
            d += " C " + mx + " " + pts[i - 1].y.toFixed(1) + " " + mx + " " + pts[i].y.toFixed(1)
               + " " + pts[i].x.toFixed(1) + " " + pts[i].y.toFixed(1);
        }
        return d;
    }
    readonly property string path1: svg(line1)
    readonly property string path2: svg(line2)
    readonly property string area1: line1.length
        ? path1 + " L " + line1[line1.length - 1].x.toFixed(1) + " " + height.toFixed(1)
                + " L " + line1[0].x.toFixed(1) + " " + height.toFixed(1) + " Z" : ""

    // Pixel: one column per sample, heights snapped to whole blocks.
    readonly property real block: Math.max(3, Math.round(lineWidth * 2))
    Repeater {
        model: chart.bars ? chart.line1.length : 0
        Rectangle {
            required property int index
            readonly property point p: chart.line1[index]
            readonly property real colW: chart.width / (chart.capacity - 1)
            readonly property real h: Math.round((chart.height - p.y) / chart.block) * chart.block
            x: p.x - colW / 2; width: Math.max(1, colW - 1)
            y: chart.height - h; height: h
            color: Qt.rgba(chart.colorEnd.r, chart.colorEnd.g, chart.colorEnd.b, 0.35 + 0.65 * index / Math.max(1, chart.line1.length - 1))
        }
    }
    Repeater {   // second series: a block on top of each column
        model: chart.bars ? chart.line2.length : 0
        Rectangle {
            required property int index
            readonly property point p: chart.line2[index]
            width: chart.block; height: chart.block
            x: p.x - width / 2
            y: Math.round(p.y / chart.block) * chart.block - height / 2
            color: chart.color2
        }
    }

    // Columns / rounded bars.
    Row {
        visible: chart.columns
        anchors.bottom: parent.bottom
        width: parent.width
        height: parent.height
        spacing: Math.max(1, chart.width / chart.colCount * (chart.kind === "rounded" ? 0.3 : 0.12))
        Repeater {
            model: chart.columns ? chart.colHeights.length : 0
            Item {
                id: col
                required property int index
                readonly property real r: chart.colHeights[index]
                readonly property real r2: chart.colHeights2.length > index ? chart.colHeights2[index] : -1
                readonly property bool newest: index === chart.colHeights.length - 1
                anchors.bottom: parent.bottom
                width: (chart.width - parent.spacing * (chart.colCount - 1)) / chart.colCount
                height: chart.height
                // Bento: every column is a capsule with a faint track, so a
                // quiet minute reads as empty capsules, not stray dashes.
                Rectangle {
                    visible: chart.capsules && col.r >= 0
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.rgba(chart.colorEnd.r, chart.colorEnd.g, chart.colorEnd.b, 0.07)
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: col.r < 0 ? 0 : chart.capsules ? Math.max(width, col.r * chart.height) : Math.max(2, col.r * chart.height)
                    radius: chart.capsules ? width / 2 : 0
                    color: col.newest ? chart.colorEnd : Qt.rgba(chart.colorEnd.r, chart.colorEnd.g, chart.colorEnd.b, chart.capsules ? 0.55 : 0.35)
                    Behavior on height { NumberAnimation { duration: Kirigami.Units.longDuration } }
                }
                // The second series, a slimmer capsule inside.
                Rectangle {
                    visible: col.r2 >= 0
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.42
                    height: Math.max(width, col.r2 * chart.height)
                    radius: width / 2
                    color: chart.color2
                    Behavior on height { NumberAnimation { duration: Kirigami.Units.longDuration } }
                }
            }
        }
    }

    // Instrument: faint gridlines behind the trace.
    Repeater {
        model: chart.kind === "grid" ? 3 : 0
        Rectangle {
            required property int index
            width: chart.width; height: 1
            y: Math.round(chart.height * (index + 1) / 4)
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.07)
        }
    }
    Repeater {
        model: chart.kind === "grid" ? 3 : 0
        Rectangle {
            required property int index
            width: 1; height: chart.height
            x: Math.round(chart.width * (index + 1) / 4)
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.07)
        }
    }

    // Lines; with columns only the second series is drawn here, as a line.
    Shape {
        visible: !chart.bars
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Fill under the main series
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: 0; y2: chart.height
                GradientStop { position: 0; color: Qt.rgba(chart.colorEnd.r, chart.colorEnd.g, chart.colorEnd.b,
                    chart.kind === "grid" || chart.kind === "pen" ? 0 : chart.kind === "area" ? 0.45 : 0.30) }
                GradientStop { position: 1; color: Qt.rgba(chart.colorEnd.r, chart.colorEnd.g, chart.colorEnd.b, 0.0) }
            }
            PathSvg { path: chart.columns ? "" : chart.area1 }
        }
        // Glow + line, main series
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(chart.colorEnd.r, chart.colorEnd.g, chart.colorEnd.b, chart.glow ? 0.12 : 0)
            strokeWidth: chart.lineWidth * 3
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathSvg { path: chart.columns ? "" : chart.path1 }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: chart.colorEnd
            strokeWidth: chart.lineWidth
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathSvg { path: chart.columns ? "" : chart.path1 }
        }
        // Second series: plain line, so it doesn't compete with the main one
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(chart.color2.r, chart.color2.g, chart.color2.b, 0.9)
            strokeWidth: chart.lineWidth
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathSvg { path: chart.capsules ? "" : chart.path2 }
        }
    }

    // Live dot at the newest sample
    Rectangle {
        visible: chart.liveDot && !chart.bars && !chart.columns && chart.line1.length > 0
        readonly property point p: chart.line1.length ? chart.line1[chart.line1.length - 1] : Qt.point(0, 0)
        width: chart.lineWidth * 2.6; height: width; radius: width / 2
        x: p.x - width; y: p.y - height / 2
        color: chart.colorEnd
    }
}
