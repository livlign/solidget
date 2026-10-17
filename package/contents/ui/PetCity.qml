import QtQuick
import "../code/sky.js" as Sky

// The city outside the nerd room's window: two layers of towers in the
// colors of the time of day. After dark their windows light up, neon signs
// glow and blink, and now and then a flying car crosses. Moves on the
// shared tick only.
Item {
    id: city
    property var sky: null          // Sky.at(...)
    property int tick: 0
    property real px: 2
    property string pixelFont: ""

    readonly property string phase: sky ? sky.phase : "day"
    readonly property bool lit: phase === "night" || phase === "dusk" || (sky && sky.dark)
    // Far and near tower colors for each time of day.
    readonly property var tones: ({
        day:   ["#9fb6d4", "#5f7898"],
        dawn:  ["#9a7fa8", "#5d4a73"],
        dusk:  ["#6c4f86", "#38294f"],
        night: ["#1d2747", "#0f1529"]
    })
    readonly property var tone: tones[phase] || tones.day
    readonly property var far: Sky.scatter(9, 41)
    readonly property var near: Sky.scatter(7, 17)

    // ---- Towers ----
    Repeater {
        model: city.far
        Rectangle {
            required property var modelData
            required property int index
            x: city.width * (index / city.far.length) - city.px * 2
            width: city.width / city.far.length + city.px * (2 + modelData.size * 3)
            height: city.height * (0.45 + modelData.y * 0.4)
            y: city.height - height
            color: city.tone[0]
        }
    }
    Repeater {
        model: city.near
        Item {
            id: tower
            required property var modelData
            required property int index
            x: city.width * (index / city.near.length) + city.px * modelData.phase * 2
            width: city.width / city.near.length * (0.6 + modelData.size * 0.35)
            height: city.height * (0.3 + modelData.y * 0.45)
            y: city.height - height
            Rectangle { anchors.fill: parent; color: city.tone[1] }
            Rectangle {     // a roof antenna on some
                visible: tower.modelData.x > 0.5
                x: parent.width * 0.5; y: -city.px * 4
                width: Math.max(1, city.px / 2); height: city.px * 4
                color: city.tone[1]
                Rectangle {
                    visible: city.lit && city.tick % 2 === 0
                    x: -city.px / 2; y: -city.px / 2
                    width: city.px; height: city.px
                    color: "#ff4d4d"
                }
            }
            // Lit windows after dark: a grid, some on, a few changing each second.
            Grid {
                visible: city.lit
                x: city.px; y: city.px * 2
                columns: Math.max(1, Math.floor((tower.width - city.px) / (city.px * 2.5)))
                rowSpacing: city.px * 1.5
                columnSpacing: city.px * 1.5
                Repeater {
                    model: Math.max(0, Math.floor((tower.width - city.px) / (city.px * 2.5)) * Math.floor((tower.height - city.px * 2) / (city.px * 2.5)))
                    Rectangle {
                        required property int index
                        readonly property int h: (index * 37 + tower.index * 101) % 23
                        width: city.px; height: city.px
                        color: ["#7ff3ff", "#ffd27a", "#ff8ad8", "#ffd27a"][h % 4]
                        visible: h < 9 || (h === 11 && (city.tick + index) % 6 < 3)
                        opacity: 0.85
                    }
                }
            }
        }
    }

    // ---- Neon signs, after dark ----
    Repeater {
        model: city.lit ? [["BYTE", 0.18, 0.32, "#ff4fd8"], ["24/7", 0.62, 0.45, "#4ff3ff"], ["RAMEN", 0.8, 0.2, "#ff5a5a"]] : []
        Rectangle {
            required property var modelData
            required property int index
            x: city.width * modelData[1]
            y: city.height * modelData[2]
            width: label.implicitWidth + city.px * 2
            height: label.implicitHeight + city.px
            color: "#0b0f1d"
            border.width: Math.max(1, city.px / 2)
            border.color: modelData[3]
            // One of them flickers.
            opacity: index === 2 && city.tick % 7 === 0 ? 0.35 : 1
            Text {
                id: label
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: modelData[0]
                color: modelData[3]
                font.family: city.pixelFont || "monospace"
                font.pixelSize: Math.max(6, city.px * 3)
            }
        }
    }

    // ---- A flying car crossing every so often ----
    Item {
        readonly property int period: 26
        readonly property real t: (city.tick % period) / 10
        visible: t <= 1
        x: -width + (city.width + width * 2) * t
        y: city.height * 0.18
        width: city.px * 9; height: city.px * 3
        Rectangle { y: city.px; width: parent.width; height: city.px * 2; radius: city.px; color: "#2b3047" }
        Rectangle { x: city.px * 3; width: city.px * 3; height: city.px * 1.5; radius: city.px / 2; color: "#7ff3ff"; opacity: 0.8 }
        Rectangle { x: parent.width - city.px; y: city.px * 1.5; width: city.px; height: city.px; color: city.tick % 2 ? "#ff4d4d" : "#ffd27a" }
    }
}
