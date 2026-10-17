import QtQuick
import QtQuick.Shapes

// Uptime scene: your PC as a little character, its face on the screen. It's
// fresh after a restart, content for a day, sleepy after a few, and worn
// out (asking for a reboot) after a week. Stressed when the CPU is maxed.
// Blinks now and then.
Item {
    id: face
    required property var app
    property int tick: 0
    property real seconds: 0
    property color color: "#38bdf8"      // the case
    property color glow: "#7dd3fc"       // the face on the screen

    readonly property real hours: seconds / 3600
    readonly property bool stressed: ((app.cpuUsage && app.cpuUsage.value) || 0) > 85
    readonly property string mood: stressed ? "stressed" : hours < 1 ? "fresh" : hours < 24 ? "happy"
        : hours < 72 ? "calm" : hours < 168 ? "tired" : "exhausted"
    readonly property string caption: ({
        stressed: i18n("Working hard!"),
        fresh: i18n("Fresh start!"),
        happy: i18n("Feeling good"),
        calm: i18n("Steady going"),
        tired: i18n("Getting sleepy…"),
        exhausted: i18n("Reboot me, please?")
    })[mood]
    readonly property bool blink: tick % 7 === 0 && (mood === "happy" || mood === "calm" || mood === "fresh")

    // The monitor fills the item: case, screen, then a neck and foot below.
    readonly property real s: Math.min(width, height / 1.05)
    readonly property real mw: s
    readonly property real mh: s * 0.74
    readonly property real mx: (width - mw) / 2
    readonly property real my: (height - s * 1.0) / 2
    readonly property real r: s * 0.12

    // Case
    Rectangle {
        x: face.mx; y: face.my
        width: face.mw; height: face.mh
        radius: face.r
        color: face.color
        Rectangle {     // a light catching the top edge
            x: face.r; y: Math.max(1, face.s * 0.012)
            width: parent.width - face.r * 2; height: Math.max(1, face.s * 0.012)
            color: "#ffffff"
            opacity: 0.35
        }
    }
    // Screen
    Rectangle {
        id: screen
        x: face.mx + face.s * 0.07; y: face.my + face.s * 0.07
        width: face.mw - face.s * 0.14; height: face.mh - face.s * 0.17
        radius: face.r * 0.6
        color: "#141826"
        // A little power light under the screen
        Rectangle {
            x: parent.width - width; y: parent.height + face.s * 0.02
            width: face.s * 0.035; height: width; radius: width / 2
            color: face.stressed ? "#f97316" : "#4ade80"
        }
    }
    // Neck and foot
    Rectangle {
        x: face.mx + face.mw / 2 - width / 2; y: face.my + face.mh
        width: face.s * 0.14; height: face.s * 0.12
        color: Qt.darker(face.color, 1.25)
    }
    Rectangle {
        x: face.mx + face.mw / 2 - width / 2; y: face.my + face.mh + face.s * 0.11
        width: face.s * 0.42; height: face.s * 0.07
        radius: height / 2
        color: face.color
    }

    // ---- The face, glowing on the screen ----
    readonly property real ex: screen.width * 0.27        // eye offset from the middle
    readonly property real ey: screen.y + screen.height * 0.42
    readonly property real cx: screen.x + screen.width / 2
    readonly property real ew: screen.width * 0.11
    readonly property real stroke: Math.max(2, face.s * 0.035)

    // Eyes: tall ovals; arcs when happy; lines when tired, blinking or worn out;
    // wide circles when stressed.
    Repeater {
        model: [-1, 1]
        Item {
            id: eye
            required property int modelData
            readonly property real x0: face.cx + modelData * face.ex
            Rectangle {     // open
                visible: !face.blink && (face.mood === "calm" || face.mood === "stressed")
                readonly property real w: face.mood === "stressed" ? face.ew * 1.3 : face.ew
                x: eye.x0 - w / 2
                y: face.ey - (face.mood === "stressed" ? w : w * 1.4) / 2
                width: w; height: face.mood === "stressed" ? w : w * 1.4
                radius: width / 2
                color: face.glow
            }
            Shape {         // happy arcs (^ ^)
                visible: !face.blink && (face.mood === "fresh" || face.mood === "happy")
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: face.glow
                    strokeWidth: face.stroke
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    startX: eye.x0 - face.ew * 0.7; startY: face.ey + face.ew * 0.3
                    PathQuad { x: eye.x0 + face.ew * 0.7; y: face.ey + face.ew * 0.3; controlX: eye.x0; controlY: face.ey - face.ew * 0.9 }
                }
            }
            Rectangle {     // closed or sleepy: a line, drooping when worn out
                visible: face.blink || face.mood === "tired" || face.mood === "exhausted"
                x: eye.x0 - face.ew * 0.7
                y: face.ey - height / 2 + (face.mood === "exhausted" ? face.ew * 0.3 : 0)
                width: face.ew * 1.4; height: face.stroke
                radius: height / 2
                rotation: face.mood === "exhausted" ? eye.modelData * -12 : 0
                color: face.glow
            }
        }
    }
    // Blush when happy
    Repeater {
        model: face.mood === "fresh" || face.mood === "happy" ? [-1, 1] : []
        Rectangle {
            required property int modelData
            width: face.ew * 1.2; height: face.ew * 0.55; radius: height / 2
            x: face.cx + modelData * face.ex * 1.25 - width / 2
            y: face.ey + face.ew * 1.0
            color: "#f472b6"
            opacity: 0.55
        }
    }
    // Mouth: a smile, a small smile, flat, a wobble, or an "o".
    Shape {
        anchors.fill: parent
        visible: face.mood !== "stressed"
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            id: mouth
            readonly property real mw: face.ew * ({ fresh: 2.6, happy: 2.2, calm: 1.6, tired: 1.3, exhausted: 1.6 })[face.mood]
            readonly property real bend: face.ew * ({ fresh: 1.4, happy: 1.0, calm: 0.35, tired: 0, exhausted: -0.6 })[face.mood]
            readonly property real my: face.ey + face.ew * 1.5
            strokeColor: face.glow
            strokeWidth: face.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: face.cx - mw / 2; startY: my
            PathQuad { x: face.cx + mouth.mw / 2; y: mouth.my; controlX: face.cx; controlY: mouth.my + mouth.bend }
        }
    }
    Rectangle {
        visible: face.mood === "stressed"
        width: face.ew * 0.9; height: face.ew * 1.1; radius: width / 2
        x: face.cx - width / 2; y: face.ey + face.ew * 1.0
        color: "transparent"
        border.width: face.stroke
        border.color: face.glow
    }

    // Sweat drop (stressed or worn out), Zzz (sleepy or worn out).
    Rectangle {
        visible: face.mood === "stressed" || face.mood === "exhausted"
        width: face.s * 0.06; height: width * 1.5; radius: width / 2
        x: face.mx + face.mw - width * 0.6; y: face.my + face.s * 0.08 + (face.tick % 2) * face.s * 0.02
        color: "#7dd3fc"
    }
    Text {
        visible: face.mood === "exhausted" || face.mood === "tired"
        textFormat: Text.PlainText
        text: ["z", "zZ", "zZz"][face.tick % 3]
        x: face.mx + face.mw - face.s * 0.05; y: face.my - face.s * 0.16
        color: face.glow
        font.pixelSize: face.s * 0.15
        font.bold: true
    }
}
