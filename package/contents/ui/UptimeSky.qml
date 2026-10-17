import QtQuick
import QtQuick.Shapes
import "../code/sky.js" as Sky

// Uptime scene: the sky outside right now. Sunrise, a blue day, sunset and a
// starry night with the real moon phase, over hills with a little house.
// Clouds, rain or snow follow the weather when the weather is on.
// Moves on the shared tick only.
Item {
    id: sky
    required property var app
    property date now: new Date()
    property int tick: 0
    // false: no hills or house (the pet's window puts a city there instead).
    property bool landscape: true
    // Drawn over the sky and clouds, under the rain or snow.
    default property alias scenery: sceneryItem.data

    readonly property var w: app.weather
    readonly property var today: w && w.ready && w.daily && w.daily.length ? w.daily[0] : null
    readonly property real minutes: now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60
    readonly property var k: Sky.at(minutes, Sky.minutesOf(today ? today.sunrise : "", 390), Sky.minutesOf(today ? today.sunset : "", 1110))
    readonly property real moonPhase: Sky.moonPhase(now)
    readonly property int code: w && w.ready ? w.code : -1
    // Open-Meteo weather codes: 0 clear, 1-3 clouds, 45/48 fog, 51-67 rain,
    // 71-77 snow, 80-82 showers, 85/86 snow showers, 95+ thunder.
    readonly property int clouds: code < 0 ? 2 : code === 0 ? 0 : code <= 2 ? 2 : 4
    readonly property string fall: (code >= 71 && code <= 77) || code === 85 || code === 86 ? "snow"
        : (code >= 51 && code <= 67) || (code >= 80 && code <= 82) || code >= 95 ? "rain" : ""
    readonly property real horizon: landscape ? height * 0.74 : height
    readonly property var stars: Sky.scatter(46, 11)
    readonly property var drops: Sky.scatter(36, 5)

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: sky.k.top }
            GradientStop { position: 0.85; color: sky.k.bottom }
        }
    }

    // Stars, twinkling a little on the tick.
    Repeater {
        model: sky.k.stars > 0 ? sky.stars : []
        Rectangle {
            required property var modelData
            required property int index
            readonly property real s: 1 + Math.round(modelData.size * 1.6)
            x: modelData.x * sky.width
            y: modelData.y * sky.horizon * 0.9
            width: s; height: s
            radius: s / 2
            color: "#ffffff"
            opacity: sky.k.stars * ((sky.tick + modelData.phase) % 5 === 0 ? 0.35 : 0.55 + modelData.size * 0.45)
        }
    }

    // Sun, with a soft glow; low and orange near the horizon.
    Item {
        id: sun
        visible: sky.k.sun.up
        readonly property real d: Math.max(10, Math.min(sky.width, sky.height) * 0.16)
        x: sky.width * (0.08 + 0.84 * Math.max(0, Math.min(1, sky.k.sun.t))) - d / 2
        y: sky.horizon - d / 2 - (sky.horizon - d * 1.2) * sky.k.sun.height
        width: d; height: d
        Rectangle {
            anchors.centerIn: parent
            width: parent.d * 2.6; height: width; radius: width / 2
            color: Sky.mix("#fff3b0", "#ff9a4d", 1 - sky.k.sun.height)
            opacity: 0.18
        }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Sky.mix("#fff6c8", "#ffb067", 1 - sky.k.sun.height)
        }
    }

    // Moon, in today's phase: a sky-colored disc slides over it.
    Item {
        id: moon
        visible: sky.k.moon.up && sky.k.stars > 0.2
        readonly property real d: Math.max(9, Math.min(sky.width, sky.height) * 0.13)
        readonly property real p: sky.moonPhase
        x: sky.width * (0.1 + 0.8 * Math.max(0, Math.min(1, sky.k.moon.t))) - d / 2
        y: sky.horizon - d / 2 - (sky.horizon - d * 1.4) * Math.max(0.25, sky.k.moon.height)
        width: d; height: d
        Rectangle {
            anchors.centerIn: parent
            width: parent.d * 2.2; height: width; radius: width / 2
            color: "#dfe7ff"
            opacity: 0.08
        }
        Rectangle { anchors.fill: parent; radius: width / 2; color: "#f4f1de" }
        Rectangle {
            width: parent.d; height: parent.d; radius: width / 2
            y: 0
            // New moon: covered; full: slid all the way off.
            x: moon.p <= 0.5 ? -parent.d * 2 * moon.p * 1.05 : parent.d * 2 * (1 - moon.p) * 1.05
            // The sky's color at the moon's height, so the disc blends in.
            color: Sky.mix(sky.k.top, sky.k.bottom, (moon.y + moon.d / 2) / (sky.height * 0.85))
            opacity: Math.abs(moon.p - 0.5) < 0.03 ? 0 : 1
        }
    }

    // Clouds drifting right, a few pixels per second.
    Repeater {
        model: sky.clouds
        Item {
            id: cloud
            required property int index
            readonly property real cw: sky.width * (0.22 + 0.05 * (index % 3))
            readonly property real speed: 0.6 + index * 0.35
            width: cw; height: cw * 0.36
            x: ((index * 0.31 * sky.width + sky.tick * speed) % (sky.width + cw)) - cw
            y: sky.height * (0.1 + 0.11 * index)
            opacity: sky.k.dark ? 0.35 : 0.88
            readonly property color tone: sky.code >= 3 || sky.fall ? Sky.mix("#ffffff", "#7d8597", 0.45)
                                        : sky.k.dark ? "#8892b0" : "#ffffff"
            Rectangle { x: 0; y: cloud.height * 0.4; width: cloud.width; height: cloud.height * 0.6; radius: height / 2; color: cloud.tone }
            Rectangle { x: cloud.width * 0.18; y: cloud.height * 0.1; width: cloud.width * 0.38; height: width * 0.8; radius: height / 2; color: cloud.tone }
            Rectangle { x: cloud.width * 0.45; y: 0; width: cloud.width * 0.34; height: width * 0.9; radius: height / 2; color: cloud.tone }
        }
    }

    Item { id: sceneryItem; anchors.fill: parent }

    // Rain or snow, a step per second.
    Repeater {
        model: sky.fall ? sky.drops : []
        Rectangle {
            required property var modelData
            readonly property bool snow: sky.fall === "snow"
            // Wrapped both ways (JS % keeps the sign, so rain drifting left would leave for good).
            readonly property real rawX: modelData.x * sky.width + (snow ? Math.sin((sky.tick + modelData.phase) * 0.9) * 4 : -sky.tick * 3)
            x: ((rawX % sky.width) + sky.width) % sky.width
            y: (modelData.y * sky.height + sky.tick * (snow ? 9 : 26)) % sky.horizon
            width: snow ? 3 : 1.5
            height: snow ? 3 : 8
            radius: snow ? 1.5 : 0
            rotation: snow ? 0 : 12
            color: snow ? "#ffffff" : "#c6dcff"
            opacity: 0.75
        }
    }

    // Hills, darker at night.
    Shape {
        visible: sky.landscape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: Sky.mix(sky.k.bottom, sky.k.dark ? "#000000" : "#2f6b4f", sky.k.dark ? 0.55 : 0.55)
            startX: 0; startY: sky.horizon
            PathQuad { x: sky.width * 0.55; y: sky.horizon - sky.height * 0.02; controlX: sky.width * 0.25; controlY: sky.horizon - sky.height * 0.16 }
            PathQuad { x: sky.width; y: sky.horizon - sky.height * 0.06; controlX: sky.width * 0.8; controlY: sky.horizon - sky.height * 0.14 }
            PathLine { x: sky.width; y: sky.height }
            PathLine { x: 0; y: sky.height }
        }
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: Sky.mix(sky.k.bottom, sky.k.dark ? "#000000" : "#1f5138", sky.k.dark ? 0.75 : 0.7)
            startX: 0; startY: sky.horizon + sky.height * 0.1
            PathQuad { x: sky.width; y: sky.horizon + sky.height * 0.04; controlX: sky.width * 0.6; controlY: sky.horizon - sky.height * 0.04 }
            PathLine { x: sky.width; y: sky.height }
            PathLine { x: 0; y: sky.height }
        }
    }

    // A little house on the hill; its window glows after dark.
    Item {
        id: house
        visible: sky.landscape
        readonly property real s: Math.max(8, Math.min(sky.width, sky.height) * 0.09)
        x: sky.width * 0.78
        y: sky.horizon - sky.height * 0.1 - s * 0.55
        width: s; height: s
        readonly property color wall: Sky.mix(sky.k.bottom, "#000000", sky.k.dark ? 0.8 : 0.6)
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 0; strokeColor: "transparent"
                fillColor: house.wall
                startX: -house.width * 0.1; startY: house.height * 0.45
                PathLine { x: house.width * 0.5; y: 0 }
                PathLine { x: house.width * 1.1; y: house.height * 0.45 }
                PathLine { x: house.width * 0.95; y: house.height * 0.45 }
                PathLine { x: house.width * 0.95; y: house.height }
                PathLine { x: house.width * 0.05; y: house.height }
                PathLine { x: house.width * 0.05; y: house.height * 0.45 }
            }
        }
        Rectangle {
            x: parent.width * 0.38; y: parent.height * 0.55
            width: parent.width * 0.26; height: width
            color: sky.k.dark ? "#ffd27a" : Sky.mix(sky.k.bottom, "#000000", 0.3)
        }
    }
}
