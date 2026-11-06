import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

// 270° ring with a gradient arc, rounded caps and a soft glow. Drawn with
// Shapes (GPU) rather than Canvas: the value animates every second, and
// repainting a Canvas per frame cost a noticeable share of a CPU core.
Item {
    id: gauge

    property real value: 0          // 0..max
    property real value2: 0         // a faint second reach behind it (Memory: + cache)
    property real max: 100
    property color accent: "#38bdf8"
    property color accent2: "#6366f1"
    property real thickness: Math.max(3, Math.min(width, height) * 0.075)
    property bool glow: true        // soft halo under the arc (Glass)
    property bool roundCaps: true   // false = square ends (Flat)
    property bool blocks: false     // Pixel: the dial is a ring of square blocks
    property bool ticks: false      // Instrument: the dial is a ring of fine tick marks
    default property alias content: center.data

    property real shown: value
    Behavior on shown { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }

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

    // Pixel: square blocks along the same 270° arc, lit up to the value.
    Repeater {
        model: gauge.blocks ? 18 : 0
        Rectangle {
            required property int index
            readonly property real t: index / 17
            readonly property real a: (gauge.startDeg + gauge.sweepDeg * t) * Math.PI / 180
            readonly property bool lit: t <= gauge.frac && gauge.frac > 0.002
            width: gauge.thickness * 1.25; height: width
            x: gauge.cx + gauge.r * Math.cos(a) - width / 2
            y: gauge.cy + gauge.r * Math.sin(a) - height / 2
            color: lit ? Qt.tint(gauge.accent, Qt.rgba(gauge.accent2.r, gauge.accent2.g, gauge.accent2.b, t))
                       : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
            // a little bevel on lit blocks
            Rectangle { visible: parent.lit; width: parent.width; height: Math.max(1, parent.height * 0.18); color: Qt.rgba(1, 1, 1, 0.35) }
            Rectangle { visible: parent.lit; y: parent.height - height; width: parent.width; height: Math.max(1, parent.height * 0.18); color: Qt.rgba(0, 0, 0, 0.3) }
        }
    }

    // Instrument: thin radial ticks along the arc, every tenth one longer,
    // lit up to the value like a meter's scale.
    Repeater {
        model: gauge.ticks ? 41 : 0
        Rectangle {
            required property int index
            readonly property real t: index / 40
            readonly property real a: (gauge.startDeg + gauge.sweepDeg * t) * Math.PI / 180
            readonly property bool lit: t <= gauge.frac && gauge.frac > 0.002
            width: Math.max(1.5, gauge.thickness * 0.3)
            height: gauge.thickness * (index % 10 === 0 ? 1.9 : 1.3)
            x: gauge.cx + gauge.r * Math.cos(a) - width / 2
            y: gauge.cy + gauge.r * Math.sin(a) - height / 2
            rotation: a * 180 / Math.PI + 90
            antialiasing: true
            color: lit ? Qt.tint(gauge.accent, Qt.rgba(gauge.accent2.r, gauge.accent2.g, gauge.accent2.b, t))
                       : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.16)
        }
    }

    Shape {
        visible: !gauge.blocks && !gauge.ticks
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
        // Second reach (e.g. memory used + cache), faint, behind the value
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(gauge.accent.r, gauge.accent.g, gauge.accent.b, gauge.value2 > gauge.value ? 0.28 : 0)
            strokeWidth: gauge.thickness
            capStyle: gauge.roundCaps ? ShapePath.RoundCap : ShapePath.FlatCap
            PathAngleArc {
                centerX: gauge.cx; centerY: gauge.cy
                radiusX: gauge.r; radiusY: gauge.r
                startAngle: gauge.startDeg
                sweepAngle: gauge.sweepDeg * Math.max(0, Math.min(1, gauge.value2 / gauge.max))
            }
        }
        // Glow under the value arc
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(gauge.accent2.r, gauge.accent2.g, gauge.accent2.b, gauge.glow && gauge.frac > 0.002 ? 0.10 : 0)
            strokeWidth: gauge.thickness * 1.8
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: gauge.cx; centerY: gauge.cy
                radiusX: gauge.r; radiusY: gauge.r
                startAngle: gauge.startDeg; sweepAngle: gauge.valueSweep
            }
        }
        // Value arc, one color: a plain stroke with its own caps, so a low
        // reading is a short, even arc, not a two-colored blob.
        ShapePath {
            fillColor: "transparent"
            strokeColor: gauge.glow && gauge.frac > 0.002 || gauge.frac <= 0.002 ? "transparent" : gauge.accent
            strokeWidth: gauge.thickness
            capStyle: gauge.roundCaps ? ShapePath.RoundCap : ShapePath.FlatCap
            PathAngleArc {
                centerX: gauge.cx; centerY: gauge.cy
                radiusX: gauge.r; radiusY: gauge.r
                startAngle: gauge.startDeg; sweepAngle: gauge.valueSweep
            }
        }
        // Glass: the value arc as a filled band, so it can carry a conical
        // gradient (stroke gradients need a newer Qt).
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: gauge.glow ? glassGradient : null
            fillColor: "transparent"
            property ConicalGradient glassGradient: ConicalGradient {
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

    // Glass: rounded caps for the gradient band, each the color of the
    // band where it ends (the gradient starts at accent2).
    Rectangle {
        visible: gauge.glow && !gauge.blocks && !gauge.ticks && gauge.roundCaps && gauge.frac > 0.002
        width: gauge.thickness; height: width; radius: width / 2
        x: gauge.cx + gauge.r * Math.cos(gauge.startDeg * Math.PI / 180) - width / 2
        y: gauge.cy + gauge.r * Math.sin(gauge.startDeg * Math.PI / 180) - height / 2
        color: gauge.accent2
    }
    Rectangle {
        visible: gauge.glow && !gauge.blocks && !gauge.ticks && gauge.roundCaps && gauge.frac > 0.002
        width: gauge.thickness; height: width; radius: width / 2
        x: gauge.cx + gauge.r * Math.cos(gauge.endRad) - width / 2
        y: gauge.cy + gauge.r * Math.sin(gauge.endRad) - height / 2
        color: gauge.accent2
        // Bright tip
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.3; height: width; radius: width / 2
            color: Qt.rgba(1, 1, 1, 0.55)
        }
    }

    Item {
        id: center
        anchors.centerIn: parent
        width: gauge.size * 0.7
        height: gauge.size * 0.7
    }
}
