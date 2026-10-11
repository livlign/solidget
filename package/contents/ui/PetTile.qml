import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// A pixel pet that lives in the tile.
// - Poodle: keeps busy with a little routine (sits, wags, sniffs, yawns,
//   play-bows, trots, naps) and gets livelier with the CPU: hops at medium
//   load; zooms, spins and chases its ball when busy; lies down panting
//   when hot. Frames come from images/poodle.png (made by tools/poodle.py).
// - Cat: naps, strolls or sprints with the CPU, in the theme's color.
// It animates at a few frames per second and stands still while asleep
// (every frame makes Plasma redraw the desktop).
GlassTile {
    id: tile
    required property var app

    readonly property bool isCat: app.petKind === "cat"

    // ---- Cat: k outline, b body, w eye, p nose/inner ear ----
    readonly property var catFrames: ({
        walk: [["................",
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
            ["................",
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
             "................"]],
        run: [["................",
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
            ["................",
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
             "................"]],
        sleep: [["................",
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
             "............kkk."]]
    })

    // ---- What the PC is doing ----
    readonly property real load: app.cpuUsage.value || 0
    readonly property real temp: app.cpuTempValue
    readonly property string mood: temp >= 85 ? "hot" : load < 15 ? "calm" : load < 45 ? "busy" : "zoom"

    // ---- What the pet is doing ----
    // Poodle activities: [sprite row, frame ms, speed across the tile, weight per mood]
    readonly property var acts: ({
        sit:   { row: "sit",   ms: 320, speed: 0,     calm: 3, busy: 1, zoom: 0 },
        wag:   { row: "wag",   ms: 200, speed: 0,     calm: 3, busy: 2, zoom: 0 },
        sniff: { row: "sniff", ms: 280, speed: 0.004, calm: 3, busy: 1, zoom: 0 },
        yawn:  { row: "yawn",  ms: 380, speed: 0,     calm: 1, busy: 0, zoom: 0 },
        bow:   { row: "bow",   ms: 240, speed: 0,     calm: 2, busy: 2, zoom: 1 },
        walk:  { row: "walk",  ms: 220, speed: 0.014, calm: 3, busy: 3, zoom: 0 },
        hop:   { row: "walk",  ms: 160, speed: 0.022, calm: 0, busy: 3, zoom: 1 },
        run:   { row: "run",   ms: 140, speed: 0.045, calm: 0, busy: 1, zoom: 3 },
        spin:  { row: "run",   ms: 140, speed: 0,     calm: 0, busy: 0, zoom: 2 },
        ball:  { row: "run",   ms: 140, speed: 0.04,  calm: 1, busy: 2, zoom: 2 },
        sleep: { row: "sleep", ms: 0,   speed: 0,     calm: 1, busy: 0, zoom: 0 },
        hot:   { row: "hot",   ms: 450, speed: 0 }
    })
    readonly property var sheetRows: ["walk", "run", "sit", "wag", "sniff", "bow", "yawn", "sleep", "hot"]
    readonly property var sheetFrames: ({ walk: 4, run: 4, sit: 4, wag: 4, sniff: 4, bow: 4, yawn: 4, sleep: 2, hot: 2 })

    property string activity: "sit"
    property int remaining: 12           // frames (or seconds, asleep) until the next activity
    function pickActivity() {
        if (isCat) {   // the cat just follows the CPU
            activity = mood === "hot" ? "hot" : load < 8 ? "sleep" : mood === "zoom" ? "run" : "walk";
            remaining = 10;
            return;
        }
        if (mood === "hot") { activity = "hot"; remaining = 20; return; }
        var names = Object.keys(acts), total = 0;
        names.forEach(function (n) { total += acts[n][mood] || 0; });
        var r = Math.random() * total;
        for (var i = 0; i < names.length; i++) {
            r -= acts[names[i]][mood] || 0;
            if (r < 0) { activity = names[i]; break; }
        }
        // A short nap (8-15 s); everything else 3-6 s worth of frames.
        remaining = activity === "sleep" ? 8 + Math.floor(Math.random() * 8)
             : Math.round((3000 + Math.random() * 3000) / Math.max(120, acts[activity].ms));
        if (activity === "spin" || Math.random() < 0.3) facingLeft = !facingLeft;
    }
    // A big change in the PC wakes the pet and changes plans right away.
    onMoodChanged: pickActivity()
    onIsCatChanged: pickActivity()
    Component.onCompleted: pickActivity()

    readonly property bool asleep: activity === "sleep"
    readonly property string caption: {
        if (activity === "hot") return i18n("Too hot! · %1", app.tempText(temp));
        if (isCat) return asleep ? i18n("Napping · all quiet") : activity === "run" ? i18n("Zoomies! · CPU %1%", Math.round(load)) : i18n("Strolling · CPU %1%", Math.round(load));
        switch (activity) {
        case "sleep": return i18n("Napping");
        case "sit":   return i18n("Sitting pretty");
        case "wag":   return i18n("Happy wiggles");
        case "sniff": return i18n("Sniffing around");
        case "yawn":  return i18n("Yawn…");
        case "bow":   return i18n("Wants to play!");
        case "walk":  return i18n("Trotting about");
        case "hop":   return i18n("Bouncy · CPU %1%", Math.round(load));
        case "spin":  return i18n("Spinning around!");
        case "ball":  return i18n("Fetch!");
        }
        return i18n("Zoomies! · CPU %1%", Math.round(load));
    }

    property int step: 0
    property real pos: 0.3          // 0..1 across the tile
    property bool facingLeft: true
    property real ballPos: 0        // 0..1, the ball rolls ahead of the dog

    Timer {
        interval: tile.isCat ? (tile.activity === "run" ? 200 : tile.activity === "hot" ? 500 : 333)
                             : Math.max(120, (tile.acts[tile.activity] || tile.acts.sit).ms)
        running: tile.visible && !tile.asleep && !app.editing
        repeat: true
        onTriggered: {
            tile.step++;
            if (tile.activity === "spin" && tile.step % 2 === 0) tile.facingLeft = !tile.facingLeft;
            var speed = tile.isCat ? (tile.activity === "run" ? 0.05 : tile.activity === "hot" ? 0.008 : 0.016)
                                   : (tile.acts[tile.activity] || tile.acts.sit).speed;
            tile.pos += tile.facingLeft ? -speed : speed;
            if (tile.pos < 0) { tile.pos = 0; tile.facingLeft = false; }
            if (tile.pos > 1) { tile.pos = 1; tile.facingLeft = true; }
            if (--tile.remaining <= 0) tile.pickActivity();
        }
    }
    // Asleep: breathe and drift the Zzz on the shared tick; wake when rested.
    Connections {
        target: app
        function onTickChanged() {
            if (!tile.asleep || !tile.visible) return;
            tile.step++;
            if (--tile.remaining <= 0) tile.pickActivity();
        }
    }

    // ---- Cat frames (text) ----
    readonly property var catCycle: catFrames[activity === "hot" ? "walk" : activity] || catFrames.walk
    readonly property var frame: catCycle[step % catCycle.length]
    readonly property int cols: isCat ? frame[0].length : 32
    readonly property int rows: isCat ? frame.length : 25
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

    // ---- Poodle frame (a cell of the sprite sheet) ----
    readonly property string dogRow: (acts[activity] || acts.sit).row
    readonly property int dogCol: step % sheetFrames[dogRow]
    // Hop: a little arc every 4 frames.
    readonly property real lift: activity === "hop" ? [0, 2, 3, 2][step % 4] : 0

    title: i18n("Pet")
    subtitle: caption
    accent: app.accent("pet")
    accent2: app.accent2("pet")
    level: asleep ? 0.15 : mood === "calm" ? 0.35 : mood === "busy" ? 0.6 : 0.85

    Item {
        id: stage
        anchors.fill: parent

        readonly property real px: Math.max(2, Math.floor(Math.min(width / (tile.cols + 8), (height - tile.u * 0.5) / (tile.rows + 1))))
        readonly property real spriteW: px * tile.cols
        readonly property real spriteH: px * tile.rows

        // Ground line
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            y: stage.height - stage.px
            height: Math.max(1, stage.px / 2)
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
        }

        // The ball, for fetch: rolls and bounces ahead of the dog.
        Rectangle {
            visible: tile.activity === "ball" && !tile.isCat
            width: stage.px * 4; height: width
            radius: tile.radius > 0 ? width / 2 : 0
            color: "#ef4444"
            border.width: Math.max(1, stage.px / 2)
            border.color: "#7f1d1d"
            x: Math.max(0, Math.min(stage.width - width, pet.x + (tile.facingLeft ? -width * 1.5 : stage.spriteW + width * 0.5)))
            y: stage.height - stage.px - height - stage.px * [0, 3, 5, 3][tile.step % 4]
        }

        Item {
            id: pet
            width: stage.spriteW
            height: stage.spriteH
            x: (stage.width - width) * tile.pos
            y: stage.height - height - stage.px - tile.lift * stage.px
            // Sprites face left; mirror when heading right. Lying poses face you.
            transform: Scale { origin.x: pet.width / 2; xScale: tile.facingLeft || tile.asleep || tile.activity === "hot" ? 1 : -1 }

            // Poodle: show one cell of the sheet by sliding the sheet inside a
            // clipped box (no image reloads, no per-pixel items).
            Item {
                anchors.fill: parent
                visible: !tile.isCat
                clip: true
                Image {
                    source: "../images/poodle.png"
                    smooth: false
                    width: sourceSize.width * stage.px
                    height: sourceSize.height * stage.px
                    x: -tile.dogCol * 32 * stage.px
                    y: -tile.sheetRows.indexOf(tile.dogRow) * 25 * stage.px
                }
            }

            // Cat: drawn square by square from the text frames.
            Repeater {
                model: tile.isCat ? tile.cols * tile.rows : 0
                Rectangle {
                    required property int index
                    readonly property int cx: index % tile.cols
                    readonly property int cy: Math.floor(index / tile.cols)
                    x: cx * stage.px
                    y: cy * stage.px
                    width: stage.px
                    height: stage.px
                    color: tile.colorFor(tile.frame[cy].charAt(cx))
                    visible: color.a > 0          // empty pixels draw nothing
                }
            }
            // Cat's sweat drop when hot.
            Rectangle {
                visible: tile.activity === "hot" && tile.isCat
                x: stage.px * 7; y: stage.px * (tile.step % 2 ? 0 : 1)
                width: stage.px; height: stage.px * 2
                color: "#7dd3fc"
            }
        }

        // Zzz while napping, drifting up one step per second.
        PlasmaComponents.Label {
            textFormat: Text.PlainText
            visible: tile.asleep
            text: ["z", "zZ", "zZz"][tile.step % 3]
            x: pet.x + stage.spriteW * 0.6
            y: pet.y + stage.spriteH * (tile.isCat ? 0 : 0.3) - stage.px * (2 + tile.step % 3)
            color: tile.accent
            font.pixelSize: stage.px * 4
            font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
            font.weight: Font.Bold
        }
    }
}
