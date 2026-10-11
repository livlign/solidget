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
    property real lineWidth: Math.max(1.5, height / 40)
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
    readonly property var area1: line1.length
        ? line1.concat([Qt.point(line1[line1.length - 1].x, height), Qt.point(line1[0].x, height)]) : []

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
            PathPolyline { path: chart.area1 }
        }
        // Glow + line, main series
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(chart.colorEnd.r, chart.colorEnd.g, chart.colorEnd.b, chart.glow ? 0.16 : 0)
            strokeWidth: chart.lineWidth * 4
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathPolyline { path: chart.line1 }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: chart.colorEnd
            strokeWidth: chart.lineWidth
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathPolyline { path: chart.line1 }
        }
        // Second series
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(chart.color2.r, chart.color2.g, chart.color2.b, chart.glow ? 0.16 : 0)
            strokeWidth: chart.lineWidth * 4
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathPolyline { path: chart.line2 }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: chart.color2
            strokeWidth: chart.lineWidth
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathPolyline { path: chart.line2 }
        }
    }

    // Live dot at the newest sample
    Rectangle {
        visible: chart.line1.length > 0
        readonly property point p: chart.line1.length ? chart.line1[chart.line1.length - 1] : Qt.point(0, 0)
        width: chart.lineWidth * 3.2; height: width; radius: width / 2
        x: p.x - width; y: p.y - height / 2
        color: chart.colorEnd
    }
}
