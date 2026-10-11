import QtQuick
import QtQuick.Shapes

// Three-blade fan that spins faster as RPM rises (scaled down to stay calm).
Item {
    id: fan
    property real rpm: 0
    property color color: "#fbbf24"

    Shape {
        id: blades
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        readonly property real c: width / 2

        ShapePath {
            fillColor: Qt.rgba(fan.color.r, fan.color.g, fan.color.b, 0.9)
            strokeColor: "transparent"
            startX: blades.c; startY: blades.c
            PathQuad { x: blades.c; y: 0; controlX: blades.c * 0.35; controlY: blades.c * 0.45 }
            PathQuad { x: blades.c; y: blades.c; controlX: blades.c * 1.35; controlY: blades.c * 0.3 }
        }
        ShapePath {
            fillColor: Qt.rgba(fan.color.r, fan.color.g, fan.color.b, 0.9)
            strokeColor: "transparent"
            startX: blades.c; startY: blades.c
            PathQuad { x: blades.c * 1.866; y: blades.c * 1.5; controlX: blades.c * 1.72; controlY: blades.c * 0.95 }
            PathQuad { x: blades.c; y: blades.c; controlX: blades.c * 1.42; controlY: blades.c * 1.75 }
        }
        ShapePath {
            fillColor: Qt.rgba(fan.color.r, fan.color.g, fan.color.b, 0.9)
            strokeColor: "transparent"
            startX: blades.c; startY: blades.c
            PathQuad { x: blades.c * 0.134; y: blades.c * 1.5; controlX: blades.c * 0.93; controlY: blades.c * 1.88 }
            PathQuad { x: blades.c; y: blades.c; controlX: blades.c * 0.25; controlY: blades.c * 0.95 }
        }
        ShapePath {
            fillColor: "#0b1020"
            strokeColor: Qt.rgba(fan.color.r, fan.color.g, fan.color.b, 0.9)
            strokeWidth: Math.max(1, blades.c * 0.06)
            PathAngleArc { centerX: blades.c; centerY: blades.c; radiusX: blades.c * 0.2; radiusY: blades.c * 0.2; startAngle: 0; sweepAngle: 360 }
        }
    }

    // Spins smoothly. A RotationAnimator runs on the render thread, so it
    // doesn't wake the rest of the widget. Speed comes in a few steps: a
    // change restarts the spin, so it shouldn't follow every RPM wobble.
    readonly property int band: rpm <= 0 ? 0 : rpm < 900 ? 1 : rpm < 1800 ? 2 : rpm < 3000 ? 3 : 4
    RotationAnimator {
        target: blades
        from: blades.rotation
        to: blades.rotation + 360
        loops: Animation.Infinite
        duration: [1000, 2400, 1500, 1000, 700][fan.band]
        running: fan.band > 0 && fan.visible
    }
}
