import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

// Area chart with a soft glow, drawn with Shapes (GPU). `values2` draws a
// second series (e.g. upload) without fill. `maxValue: 0` auto-scales;
// `sqrtScale` keeps one spike from flattening everything else.
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
    property real lineWidth: Math.max(1.5, Math.min(2.5, height / 70))
    property bool glow: true

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

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Fill under the main series
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: 0; y2: chart.height
                GradientStop { position: 0; color: Qt.rgba(chart.colorEnd.r, chart.colorEnd.g, chart.colorEnd.b, 0.30) }
                GradientStop { position: 1; color: Qt.rgba(chart.colorEnd.r, chart.colorEnd.g, chart.colorEnd.b, 0.0) }
            }
            PathSvg { path: chart.area1 }
        }
        // Glow + line, main series
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(chart.colorEnd.r, chart.colorEnd.g, chart.colorEnd.b, chart.glow ? 0.12 : 0)
            strokeWidth: chart.lineWidth * 3
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathSvg { path: chart.path1 }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: chart.colorEnd
            strokeWidth: chart.lineWidth
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathSvg { path: chart.path1 }
        }
        // Second series: plain line, so it doesn't compete with the main one
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(chart.color2.r, chart.color2.g, chart.color2.b, 0.9)
            strokeWidth: chart.lineWidth
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathSvg { path: chart.path2 }
        }
    }

    // Live dot at the newest sample
    Rectangle {
        visible: chart.line1.length > 0
        readonly property point p: chart.line1.length ? chart.line1[chart.line1.length - 1] : Qt.point(0, 0)
        width: chart.lineWidth * 2.6; height: width; radius: width / 2
        x: p.x - width; y: p.y - height / 2
        color: chart.colorEnd
    }
}
