import QtQuick
import org.kde.kirigami as Kirigami
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

    // Turns in one short eased step per second (on the shared tick) instead
    // of spinning nonstop: a continuous animation makes Plasma redraw the
    // whole desktop every frame. Step size follows the RPM.
    property real angle: 0
    Behavior on angle { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }
    function advance() { if (rpm > 0) angle += Math.min(150, 30 + rpm / 20); }
    Binding { target: blades; property: "rotation"; value: fan.angle }
}
