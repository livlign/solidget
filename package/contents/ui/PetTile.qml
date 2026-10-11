import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// A pixel cat that reacts to the PC: naps when idle, strolls at light load,
// sprints when busy and pants when hot. Drawn from a 16x12 grid of squares.
// It animates only while awake, at a few frames per second (a continuous
// animation would make Plasma redraw the whole desktop nonstop).
GlassTile {
    id: tile
    required property var app

    // ---- Sprites: k outline, b body, w eye, p nose/inner ear, d sweat ----
    readonly property var frames: ({
        walk1: ["................",
                "..k..k..........",
                ".kbkkbk........k",
                ".kbbbbk.......kb",
                ".kwbwbk.......kb",
                ".kbpbbkkkkkkkkbk",
                ".kbbbbbbbbbbbbk.",
                "..kbbbbbbbbbbbk.",
                "..kbbbbbbbbbbk..",
                "..kbk.kbk.kbk...",
                "..kk..kk..kk....",
                "................"],
        walk2: ["................",
                "..k..k..........",
                ".kbkkbk.........",
                ".kbbbbk........k",
                ".kwbwbk.......kb",
                ".kbpbbkkkkkkkkbk",
                ".kbbbbbbbbbbbbk.",
                "..kbbbbbbbbbbbk.",
                "..kbbbbbbbbbbk..",
                "...kbk.kbk.kbk..",
                "...kk..kk..kk...",
                "................"],
        run1:  ["................",
                "..k..k..........",
                ".kbkkbk.........",
                ".kbbbbk.........",
                ".kwbwbkkkkkkkkkk",
                ".kbpbbbbbbbbbbbb",
                "..kbbbbbbbbbbbk.",
                "..kbbbbbbbbbbk..",
                ".kbk.......kbk..",
                "kbk.........kbk.",
                "kk...........kk.",
                "................"],
        run2:  ["................",
                "..k..k..........",
                ".kbkkbk.........",
                ".kbbbbk........k",
                ".kwbwbkkkkkkkkkb",
                ".kbpbbbbbbbbbbbk",
                "..kbbbbbbbbbbbk.",
                "..kbbbbbbbbbbk..",
                "....kbk..kbk....",
                "....kbk..kbk....",
                "....kk...kk.....",
                "................"],
        sleep: ["................",
                "................",
                "................",
                "................",
                "......kkkkk.....",
                "....kkbbbbbkk...",
                "...kbbbbbbbbbk..",
                "..kbkkbbbbbbbbk.",
                "..kbpbbbbbbbbbk.",
                "..kbbbbbbbbbbkkk",
                "...kkkkkkkkkkbbk",
                "............kkk."]
    })

    // ---- Mood from the system ----
    readonly property real load: app.cpuUsage.value || 0
    readonly property real temp: app.cpuTempValue
    readonly property string mood: temp >= 85 ? "hot" : load < 8 ? "sleep" : load < 45 ? "walk" : "run"
    readonly property string caption: mood === "sleep" ? i18n("Napping · all quiet")
        : mood === "walk" ? i18n("Strolling · CPU %1%", Math.round(load))
        : mood === "run" ? i18n("Zoomies! · CPU %1%", Math.round(load))
        : i18n("Too hot! · %1", app.tempText(temp))

    property int step: 0
    property real pos: 0.3          // 0..1 across the tile
    property bool facingLeft: true

    // Frame timer only while awake.
    Timer {
        interval: tile.mood === "run" ? 125 : tile.mood === "hot" ? 400 : 280
        running: tile.visible && tile.mood !== "sleep" && !app.editing
        repeat: true
        onTriggered: {
            tile.step++;
            var speed = tile.mood === "run" ? 0.035 : tile.mood === "hot" ? 0.006 : 0.014;
            tile.pos += tile.facingLeft ? -speed : speed;
            if (tile.pos < 0) { tile.pos = 0; tile.facingLeft = false; }
            if (tile.pos > 1) { tile.pos = 1; tile.facingLeft = true; }
        }
    }
    // Sleeping: just the Zzz, on the shared tick.
    Connections { target: app; function onTickChanged() { if (tile.mood === "sleep") tile.step++; } }

    readonly property var frame: mood === "sleep" ? frames.sleep
        : mood === "run" ? (step % 2 ? frames.run1 : frames.run2)
        : (step % 2 ? frames.walk1 : frames.walk2)

    readonly property color bodyColor: app.accent("pet")
    readonly property color outline: dark ? "#0b0b0f" : "#1f1f24"
    function colorFor(ch) {
        switch (ch) {
        case "k": return outline;
        case "b": return bodyColor;
        case "w": return "#ffffff";
        case "p": return "#f9a8d4";
        case "d": return "#7dd3fc";
        }
        return "transparent";
    }

    title: i18n("Pet")
    subtitle: caption
    accent: app.accent("pet")
    accent2: app.accent2("pet")
    level: mood === "sleep" ? 0.15 : mood === "walk" ? 0.4 : 0.8

    Item {
        id: stage
        anchors.fill: parent

        readonly property real px: Math.max(2, Math.floor(Math.min(width / 22, (height - tile.u) / 13)))
        readonly property real spriteW: px * 16
        readonly property real spriteH: px * 12

        // Ground line
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            y: cat.y + stage.spriteH
            height: Math.max(1, stage.px / 2)
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
        }

        Item {
            id: cat
            width: stage.spriteW
            height: stage.spriteH
            x: (stage.width - width) * tile.pos
            y: stage.height - height - stage.px
            // Sprites face left; mirror when walking right.
            transform: Scale { origin.x: cat.width / 2; xScale: tile.facingLeft || tile.mood === "sleep" ? 1 : -1 }

            Repeater {
                model: 16 * 12
                Rectangle {
                    required property int index
                    readonly property int cx: index % 16
                    readonly property int cy: Math.floor(index / 16)
                    x: cx * stage.px
                    y: cy * stage.px
                    width: stage.px
                    height: stage.px
                    color: tile.colorFor(tile.frame[cy].charAt(cx))
                }
            }
            // Sweat drop when hot (bobs with the step).
            Rectangle {
                visible: tile.mood === "hot"
                x: stage.px * 7; y: stage.px * (tile.step % 2 ? 0 : 1)
                width: stage.px; height: stage.px * 2
                color: "#7dd3fc"
            }
        }

        // Zzz while napping, drifting up one step per second.
        PlasmaComponents.Label {
            visible: tile.mood === "sleep"
            text: ["z", "zZ", "zZz"][tile.step % 3]
            x: cat.x + stage.spriteW * 0.6
            y: cat.y - stage.px * (2 + tile.step % 3)
            color: tile.accent
            font.pixelSize: stage.px * 4
            font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
            font.weight: Font.Bold
        }
    }
}
