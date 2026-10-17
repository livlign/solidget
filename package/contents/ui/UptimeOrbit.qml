import QtQuick

// Uptime scene: a little solar system that keeps time. Inner to outer, the
// planets go round once a minute, once an hour, once a day and once a week
// since the PC started; a moon marks every full week. Drawn big, so it can
// run off the tile's edge as a backdrop.
Item {
    id: orbit
    property real seconds: 0
    property color color: "#38bdf8"
    property color color2: "#818cf8"
    property color line: Qt.rgba(1, 1, 1, 0.2)
    // Where the sun sits, and how far the outer ring reaches.
    property real cx: width / 2
    property real cy: height / 2
    property real r: Math.min(width, height) * 0.47

    readonly property var rings: [
        { f: (seconds % 60) / 60,         size: 0.07, at: 0.3 },
        { f: (seconds % 3600) / 3600,     size: 0.085, at: 0.5 },
        { f: (seconds % 86400) / 86400,   size: 0.1,  at: 0.72 },
        { f: (seconds % 604800) / 604800, size: 0.12, at: 0.96 }
    ]
    readonly property int weeks: Math.floor(seconds / 604800)

    // The sun, with a soft glow
    Rectangle {
        readonly property real d: orbit.r * 0.42
        x: orbit.cx - d / 2; y: orbit.cy - d / 2
        width: d; height: d; radius: d / 2
        color: orbit.color2
        opacity: 0.18
    }
    Rectangle {
        readonly property real d: orbit.r * 0.24
        x: orbit.cx - d / 2; y: orbit.cy - d / 2
        width: d; height: d; radius: d / 2
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(orbit.color2, 1.35) }
            GradientStop { position: 1; color: orbit.color2 }
        }
    }

    // A fixed count, with each ring's numbers looked up: a new array as the
    // model would rebuild every ring every second.
    Repeater {
        model: 4
        Item {
            id: ring
            required property int index
            readonly property var modelData: orbit.rings[index]
            readonly property real rr: orbit.r * modelData.at
            readonly property real a: modelData.f * Math.PI * 2 - Math.PI / 2
            readonly property real pd: Math.max(7, orbit.r * modelData.size)
            anchors.fill: parent

            Rectangle {
                x: orbit.cx - ring.rr; y: orbit.cy - ring.rr
                width: ring.rr * 2; height: width; radius: width / 2
                color: "transparent"
                border.width: Math.max(1, orbit.r / 140)
                border.color: orbit.line
            }
            // A faint trail behind each planet
            Rectangle {
                readonly property real ta: ring.a - 0.25
                x: orbit.cx + Math.cos(ta) * ring.rr - width / 2
                y: orbit.cy + Math.sin(ta) * ring.rr - height / 2
                width: ring.pd * 0.6; height: width; radius: width / 2
                color: planet.color
                opacity: 0.25
            }
            Rectangle {
                id: planet
                x: orbit.cx + Math.cos(ring.a) * ring.rr - ring.pd / 2
                y: orbit.cy + Math.sin(ring.a) * ring.rr - ring.pd / 2
                width: ring.pd; height: width; radius: width / 2
                color: ring.index % 2 ? orbit.color2 : orbit.color
                Rectangle {     // lit side
                    x: parent.width * 0.18; y: parent.height * 0.15
                    width: parent.width * 0.35; height: width; radius: width / 2
                    color: "#ffffff"
                    opacity: 0.45
                }
            }
            // Moons on the outer planet, one per full week.
            Repeater {
                model: ring.index === 3 ? Math.min(4, orbit.weeks) : 0
                Rectangle {
                    required property int index
                    readonly property real ma: index * Math.PI / 2 + orbit.seconds / 600
                    x: planet.x + planet.width / 2 + Math.cos(ma) * ring.pd * 0.95 - width / 2
                    y: planet.y + planet.height / 2 + Math.sin(ma) * ring.pd * 0.95 - height / 2
                    width: Math.max(3, ring.pd * 0.3); height: width; radius: width / 2
                    color: "#e5e7eb"
                }
            }
        }
    }
}
