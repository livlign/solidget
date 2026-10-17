import QtQuick
import "../code/sky.js" as Sky

// Out for a walk: the sky as it is now, over one of a few places. Each
// ground has three layouts (`variant`), and any can be shown mirrored, so a
// walk through three of them always looks different:
//   grass: the park (tree, hydrant, fence), a meadow by a pond, the woods
//   snow:  a snowy field with a snowman, a frozen pond, snowy pines
//   sand:  the beach, desert dunes with a cactus, a beach with a castle
Item {
    id: out
    clip: true
    property real px: 2
    property real horizon: height * 0.5
    property real standY: height
    property var sky: null
    property string ground: "grass"       // grass | snow | sand
    property int variant: 0
    property bool mirror: false
    property int tick: 0

    // Things in each place: [picture, x (0..1), "far" (on the horizon) or
    // "" (at the back of the ground), pixels raised].
    readonly property var layouts: ({
        grass: [
            [["fence", 0.8, "far", 0], ["fence", 0.92, "far", 0], ["tree", 0.16, "", 3], ["bush", 0.45, "", 4],
             ["hydrant", 0.72, "", 0], ["flower", 0.33, "", -1], ["flower2", 0.6, "", 2], ["tuft", 0.06, "", -2],
             ["tuft", 0.88, "", 0], ["rock", 0.97, "", 5]],
            [["bench", 0.18, "far", 0], ["reeds", 0.36, "far", 0], ["reeds", 0.64, "far", 0], ["tree", 0.85, "", 3],
             ["flower", 0.1, "", 0], ["flower2", 0.27, "", -1], ["flower", 0.72, "", 2], ["mushroom", 0.95, "", 0],
             ["tuft", 0.55, "", -2]],
            [["pine", 0.08, "far", 0], ["pine", 0.3, "far", 0], ["pine", 0.95, "far", 0], ["tree", 0.68, "", 3],
             ["mushroom", 0.42, "", 0], ["mushroom", 0.47, "", -2], ["bush", 0.9, "", 2], ["rock", 0.2, "", 1],
             ["tuft", 0.58, "", -1]]
        ],
        snow: [
            [["pine_snow", 0.16, "", 3], ["pine", 0.9, "far", 0], ["pine_snow", 0.78, "far", 0], ["snowman", 0.58, "", 4],
             ["rock", 0.38, "", 2]],
            [["snowman", 0.2, "", 3], ["pine_snow", 0.75, "", 3], ["pine_snow", 0.9, "far", 0], ["pine_snow", 0.06, "far", 0],
             ["rock", 0.62, "", 1]],
            [["pine_snow", 0.1, "", 4], ["pine_snow", 0.4, "", 2], ["pine_snow", 0.25, "far", 0], ["pine_snow", 0.6, "far", 0],
             ["pine", 0.82, "far", 0], ["bench", 0.68, "", 2]]
        ],
        sand: [
            [["palm", 0.16, "", 3], ["umbrella", 0.55, "", 5], ["sandcastle", 0.8, "", 2], ["shell", 0.35, "", -1],
             ["shell", 0.68, "", 3]],
            [["cactus", 0.22, "", 2], ["cactus", 0.62, "far", 0], ["palm", 0.85, "", 3], ["rock", 0.45, "", 1],
             ["rock", 0.08, "far", 0]],
            [["umbrella", 0.3, "", 5], ["sandcastle", 0.5, "", 1], ["palm", 0.9, "", 3], ["shell", 0.12, "", 0],
             ["shell", 0.72, "", -2]]
        ]
    })
    // The pond, the frozen pond and the sea.
    readonly property bool sea: ground === "sand" && variant !== 1
    readonly property bool pond: (ground === "grass" && variant === 1) || (ground === "snow" && variant === 1)
    readonly property bool dunes: ground === "sand" && variant === 1

    function itemsFor(g, v) { return (layouts[g] || layouts.grass)[Math.max(0, Math.min(2, v))]; }
    // Where to pee: the first tree, hydrant or palm in the place.
    function peeSpotFor(sc) {
        var list = itemsFor(sc.ground, sc.variant);
        for (var i = 0; i < list.length; i++)
            if (["hydrant", "tree", "pine_snow", "palm", "cactus"].indexOf(list[i][0]) >= 0 && list[i][2] === "")
                return sc.mirror ? 1 - list[i][1] : list[i][1];
        return 0.5;
    }

    readonly property var flakes: Sky.scatter(22, 9)

    Rectangle {
        width: out.width; height: out.horizon
        gradient: Gradient {
            GradientStop { position: 0; color: out.sky ? out.sky.top : "#3d8fe0" }
            GradientStop { position: 1; color: out.sky ? out.sky.bottom : "#b9defc" }
        }
    }
    // The sea behind the beach
    Rectangle {
        visible: out.sea
        y: out.horizon - out.px * 4
        width: out.width; height: out.px * 6
        gradient: Gradient {
            GradientStop { position: 0; color: "#2f80c9" }
            GradientStop { position: 1; color: "#6cc3e8" }
        }
        Repeater {   // little waves, a step per second
            model: Math.ceil(out.width / (out.px * 14))
            Rectangle {
                required property int index
                x: (index * out.px * 14 + (out.tick % 4) * out.px * 2) % out.width
                y: out.px * (1 + index % 3)
                width: out.px * 4; height: Math.max(1, out.px / 2)
                color: "#e8f6ff"
                opacity: 0.8
            }
        }
    }
    // Dunes on the horizon
    Repeater {
        model: out.dunes ? 3 : 0
        Rectangle {
            required property int index
            width: out.width * 0.6; height: out.px * 16
            radius: height / 2
            x: out.width * (index * 0.35 - 0.1)
            y: out.horizon - out.px * (5 + index % 2 * 2)
            color: index % 2 ? "#dcbf7c" : "#e6cd8f"
        }
    }
    Rectangle {
        y: out.horizon
        width: out.width; height: out.height - out.horizon
        gradient: Gradient {
            GradientStop { position: 0; color: out.ground === "snow" ? "#e7eef8" : out.ground === "sand" ? "#e9d39b" : "#6fbf5a" }
            GradientStop { position: 1; color: out.ground === "snow" ? "#c9d7ea" : out.ground === "sand" ? "#d6b878" : "#4f9a43" }
        }
    }
    // A pond (blue) or a frozen one (pale ice), with a duck on the water.
    Rectangle {
        visible: out.pond
        x: out.width * 0.5 - width / 2
        y: out.horizon + out.px
        width: out.width * 0.32; height: out.px * 7
        radius: height / 2
        color: out.ground === "snow" ? "#cfe6f5" : "#4a9fd8"
        border.width: Math.max(1, out.px / 2)
        border.color: out.ground === "snow" ? "#a9c8de" : "#2f7bb0"
        Prop {
            visible: out.ground === "grass"
            name: "duck"; px: out.px
            flip: out.tick % 20 < 10
            x: parent.width * (0.2 + 0.6 * Math.abs(((out.tick % 20) / 10) - 1)) - width / 2
            y: -height * 0.4
        }
    }

    // Everything standing in this place
    Repeater {
        model: out.itemsFor(out.ground, out.variant)
        Prop {
            required property var modelData
            readonly property bool far: modelData[2] === "far"
            name: modelData[0]
            // Far things are drawn at half size, so they look further away.
            px: far ? Math.max(1, Math.round(out.px / 2)) : out.px
            flip: out.mirror
            x: (out.mirror ? 1 - modelData[1] : modelData[1]) * out.width - width / 2
            y: (far ? out.horizon + out.px * 2 : out.standY) - height - modelData[3] * out.px
        }
    }

    // Falling snow
    Repeater {
        model: out.ground === "snow" ? out.flakes : []
        Rectangle {
            required property var modelData
            x: (modelData.x * out.width + Math.sin(out.tick * 0.8 + modelData.phase) * out.px * 2) % out.width
            y: (modelData.y * out.height + out.tick * out.px * 3) % out.height
            width: Math.max(2, out.px); height: width; radius: width / 2
            color: "#ffffff"
            opacity: 0.85
            z: 2
        }
    }

    // Darker at night, warmer at sunrise and sunset.
    Rectangle {
        anchors.fill: parent
        visible: !!out.sky && (out.sky.dark || out.sky.phase === "dawn" || out.sky.phase === "dusk")
        color: out.sky && out.sky.dark ? "#05071a" : "#ff8a4c"
        opacity: out.sky && out.sky.dark ? 0.4 : 0.12
        z: 3
    }
}
