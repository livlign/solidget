import QtQuick
import QtQuick.Shapes

// The Bluetooth mark, drawn as a line so it takes any color and size
// (the icon theme's version is a fixed little picture).
Shape {
    id: rune
    property color color: "white"
    // Line width as a share of the height.
    property real weight: 0.09
    readonly property real w: height * 0.55
    readonly property real x0: (width - w) / 2
    readonly property real lw: Math.max(1.5, height * weight)
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: "transparent"
        strokeColor: rune.color
        strokeWidth: rune.lw
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathPolyline {
            path: [
                Qt.point(rune.x0, rune.height * 0.27),
                Qt.point(rune.x0 + rune.w, rune.height * 0.73),
                Qt.point(rune.x0 + rune.w * 0.5, rune.height * 0.97 - rune.lw / 2),
                Qt.point(rune.x0 + rune.w * 0.5, rune.lw / 2 + rune.height * 0.03),
                Qt.point(rune.x0 + rune.w, rune.height * 0.27),
                Qt.point(rune.x0, rune.height * 0.73)
            ]
        }
    }
}
