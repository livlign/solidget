import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

// 270° ring with a gradient arc, rounded caps and a soft glow. Drawn with
// Shapes (GPU) rather than Canvas: the value animates every second, and
// repainting a Canvas per frame cost a noticeable share of a CPU core.
Item {
    id: gauge

    property real value: 0          // 0..max
    property real max: 100
    property color accent: "#38bdf8"
    property color accent2: "#6366f1"
    property real thickness: Math.max(3, Math.min(width, height) * 0.075)
    property bool glow: true        // soft halo under the arc (Glass)
    property bool roundCaps: true   // false = square ends (Pixel)
    default property alias content: center.data

    property real shown: value
    Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

    readonly property real size: Math.min(width, height)
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real r: Math.max(1, (size - thickness) / 2 - thickness * 0.6)
    readonly property real startDeg: 135
    readonly property real sweepDeg: 270
    readonly property real frac: Math.max(0, Math.min(1, shown / max))
    readonly property real valueSweep: Math.max(0.01, sweepDeg * frac)
    readonly property real endRad: (startDeg + valueSweep) * Math.PI / 180

    implicitWidth: Kirigami.Units.gridUnit * 6
    implicitHeight: implicitWidth

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Track
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.09)
            strokeWidth: gauge.thickness
            capStyle: gauge.roundCaps ? ShapePath.RoundCap : ShapePath.FlatCap
            PathAngleArc {
                centerX: gauge.cx; centerY: gauge.cy
                radiusX: gauge.r; radiusY: gauge.r
                startAngle: gauge.startDeg; sweepAngle: gauge.sweepDeg
            }
        }
        // Glow under the value arc
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(gauge.accent2.r, gauge.accent2.g, gauge.accent2.b, gauge.glow && gauge.frac > 0.002 ? 0.18 : 0)
            strokeWidth: gauge.thickness * 2.6
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: gauge.cx; centerY: gauge.cy
                radiusX: gauge.r; radiusY: gauge.r
                startAngle: gauge.startDeg; sweepAngle: gauge.valueSweep
            }
        }
        // Value arc as a filled band, so it can carry a conical gradient
        // (stroke gradients need a newer Qt).
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: ConicalGradient {
                centerX: gauge.cx; centerY: gauge.cy
                angle: 225
                GradientStop { position: 0.0; color: gauge.accent2 }
                GradientStop { position: 0.75; color: gauge.accent }
                GradientStop { position: 1.0; color: gauge.accent2 }
            }
            startX: gauge.cx + (gauge.r + gauge.thickness / 2) * Math.cos(gauge.startDeg * Math.PI / 180)
            startY: gauge.cy + (gauge.r + gauge.thickness / 2) * Math.sin(gauge.startDeg * Math.PI / 180)
            PathAngleArc {
                moveToStart: false
                centerX: gauge.cx; centerY: gauge.cy
                radiusX: gauge.r + gauge.thickness / 2; radiusY: radiusX
                startAngle: gauge.startDeg; sweepAngle: gauge.valueSweep
            }
            PathAngleArc {
                moveToStart: false
                centerX: gauge.cx; centerY: gauge.cy
                radiusX: gauge.r - gauge.thickness / 2; radiusY: radiusX
                startAngle: gauge.startDeg + gauge.valueSweep
                sweepAngle: -gauge.valueSweep
            }
        }
    }

    // Rounded caps for the value band
    Rectangle {
        visible: gauge.roundCaps && gauge.frac > 0.002
        width: gauge.thickness; height: width; radius: width / 2
        x: gauge.cx + gauge.r * Math.cos(gauge.startDeg * Math.PI / 180) - width / 2
        y: gauge.cy + gauge.r * Math.sin(gauge.startDeg * Math.PI / 180) - height / 2
        color: gauge.accent
    }
    Rectangle {
        visible: gauge.roundCaps && gauge.frac > 0.002
        width: gauge.thickness; height: width; radius: width / 2
        x: gauge.cx + gauge.r * Math.cos(gauge.endRad) - width / 2
        y: gauge.cy + gauge.r * Math.sin(gauge.endRad) - height / 2
        color: gauge.accent2
        // Bright tip
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.45; height: width; radius: width / 2
            color: Qt.rgba(1, 1, 1, 0.85)
        }
    }

    Item {
        id: center
        anchors.centerIn: parent
        width: gauge.size * 0.7
        height: gauge.size * 0.7
    }
}
