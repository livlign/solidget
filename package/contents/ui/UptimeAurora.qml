import QtQuick
import QtQuick.Shapes
import "../code/sky.js" as Sky

// Uptime scene: soft color clouds drifting slowly on a dark field, in the
// tile's colors. Moves a little on each shared tick, never on its own.
Item {
    id: aurora
    property int tick: 0
    property color color: "#38bdf8"
    property color color2: "#a78bfa"
    property color base: "#0b1020"

    readonly property real t: tick * 0.045
    readonly property var sparks: Sky.scatter(18, 23)

    Rectangle { anchors.fill: parent; color: aurora.base }

    component Blob: ShapePath {
        property int index
        readonly property color c: index % 2 ? aurora.color2 : aurora.color
        readonly property real cx: aurora.width * (0.5 + 0.38 * Math.sin(aurora.t * (0.7 + index * 0.23) + index * 1.7))
        readonly property real cy: aurora.height * (0.5 + 0.34 * Math.cos(aurora.t * (0.5 + index * 0.19) + index * 2.3))
        readonly property real rad: Math.max(aurora.width, aurora.height) * (0.42 + 0.08 * index)
        strokeWidth: 0
        strokeColor: "transparent"
        fillGradient: RadialGradient {
            centerX: cx; centerY: cy; centerRadius: rad
            focalX: cx; focalY: cy
            GradientStop { position: 0; color: Qt.rgba(c.r, c.g, c.b, 0.55) }
            GradientStop { position: 1; color: Qt.rgba(c.r, c.g, c.b, 0) }
        }
        PathRectangle { width: aurora.width; height: aurora.height }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        Blob { index: 0 }
        Blob { index: 1 }
        Blob { index: 2 }
        Blob { index: 3 }
    }

    // Tiny sparkles that fade in and out.
    Repeater {
        model: aurora.sparks
        Rectangle {
            required property var modelData
            x: modelData.x * aurora.width
            y: modelData.y * aurora.height
            width: 2; height: 2; radius: 1
            color: "#ffffff"
            opacity: ((aurora.tick + modelData.phase) % 5) / 6
        }
    }
}
