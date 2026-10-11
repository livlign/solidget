import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// A pixel pet that reacts to the PC: naps when idle, strolls at light load,
// bounces when busy and pants when hot. An apricot teddy-cut poodle sitting
// face-on (24x23 squares) or a cat in the theme's color (16x12).
// It animates only while awake, at a few frames per second (a continuous
// animation would make Plasma redraw the whole desktop nonstop).
GlassTile {
    id: tile
    required property var app

    readonly property bool isCat: app.petKind === "cat"

    // ---- Dog: k outline, b coat, q curls, s ears/paws, c cream chest,
    //      m muzzle, e eye, w eye shine, n nose, g nose shine, t tongue,
    //      v collar, y bell ----
    readonly property var dogFrames: ({
        walk1: ["........................",
                "...kkk...kkkkkk...kkk...",
                "..kssskkkkkkkkkkkksssk..",
                ".kssssskkbbbbqbkksssssk.",
                ".ksssskbbqbbbbqbbkssssk.",
                "kssssskbbbqbbbbqbksssssk",
                ".kssskqbbbbqbbbbqbksssk.",
                ".kssskbbbbbbbbbbbqksssk.",
                "..ksskbewbbbbbbewbkssk..",
                "...kkkbeebbmmbbeebkkk...",
                "....kkbbbmngnnmbbbkk....",
                "....kkqbbmmnnmmbbbkk....",
                ".....kkbbmmkkmmbbkk.....",
                "......kkkbmmmmbkkk......",
                "......kbbkkkkkkbbk......",
                "......kbbvvvvvvqbk......",
                ".....kqbbbcyycbbqbk.....",
                "....kbbqbbbccbbbbqbk....",
                "....kbbbqbkbbkbbbbqk....",
                ".....kbbbqkbbkqbbbk.....",
                ".....kbbsskbbkbqbbk.....",
                "......kkbbbqbksskk......",
                "........kkkbqkkk........"],
        walk2: ["........................",
                "...kkk...kkkkkk...kkk...",
                "..kssskkkkkkkkkkkksssk..",
                ".kssssskkbbbbqbkksssssk.",
                ".ksssskbbqbbbbqbbkssssk.",
                "kssssskbbbqbbbbqbksssssk",
                ".kssskqbbbbqbbbbqbksssk.",
                ".kssskbbbbbbbbbbbqksssk.",
                "..ksskbewbbbbbbewbkssk..",
                "...kkkbeebbmmbbeebkkk...",
                "....kkbbbmngnnmbbbkk....",
                "....kkqbbmmnnmmbbbkk....",
                ".....kkbbmmkkmmbbkk.....",
                "......kkkbmmmmbkkk......",
                "......kbbkkkkkkbbk......",
                "......kbbvvvvvvqbk......",
                ".....kqbbbcyycbbqbk.....",
                "....kbbqbbbccbbbbqbk....",
                "....kbbbqbkbbkbbbbqk....",
                ".....kbbbqkbbkqbbbk.....",
                ".....kbbbbkbbkssbbk.....",
                "......kksskqbbbbkk......",
                "........kkkbqkkk........"],
        run1:  ["..ksssk..kkkkkk..ksssk..",
                ".kssssskkkkkkkkkksssssk.",
                ".kssssskkbbbbqbkksssssk.",
                "kssssskbbqbbbbqbbksssssk",
                ".ksssskbbbqbbbbqbkssssk.",
                ".kssskqbbbbqbbbbqbksssk.",
                "..ksskbbbbbbbbbbbqkssk..",
                "...kkkbewbbbbbbewbkkk...",
                "....kkbeebbmmbbeebkk....",
                "....kkbbbmngnnmbbbkk....",
                "....kkqbbmmnnmmbbbkk....",
                ".....kkbbmmkkmmbbkk.....",
                "......kkkbmttmbkkk......",
                "......kbbkkkkkkbbk......",
                "......kbbvvvvvvqbk......",
                ".....kqbbbcyycbbqbk.....",
                "....kbbqbbbccbbbbqbk....",
                "....kbbbqbkbbkbbbbqk....",
                ".....kbbbqkbbkqbbbk.....",
                ".....kbbbbkbbkbqbbk.....",
                "......kksskqbksskk......",
                "........kkkbqkkk........",
                "........................"],
        run2:  ["........................",
                "...kkk...kkkkkk...kkk...",
                "..kssskkkkkkkkkkkksssk..",
                ".kssssskkbbbbqbkksssssk.",
                ".ksssskbbqbbbbqbbkssssk.",
                "kssssskbbbqbbbbqbksssssk",
                ".kssskqbbbbqbbbbqbksssk.",
                ".kssskbbbbbbbbbbbqksssk.",
                "..ksskbewbbbbbbewbkssk..",
                "...kkkbeebbmmbbeebkkk...",
                "....kkbbbmngnnmbbbkk....",
                "....kkqbbmmnnmmbbbkk....",
                ".....kkbbmmkkmmbbkk.....",
                "......kkkbmttmbkkk......",
                "......kbbkkkkkkbbk......",
                "......kbbvvvvvvqbk......",
                ".....kqbbbcyycbbqbk.....",
                "....kbbqbbbccbbbbqbk....",
                "....kbbbqbkbbkbbbbqk....",
                ".....kbbbqkbbkqbbbk.....",
                ".....kbbsskbbkbqbbk.....",
                "......kkbbbqbksskk......",
                "........kkkbqkkk........"],
        hot1:  ["........................",
                "...kkk...kkkkkk...kkk...",
                "..kssskkkkkkkkkkkksssk..",
                ".kssssskkbbbbqbkksssssk.",
                ".ksssskbbqbbbbqbbkssssk.",
                "kssssskbbbqbbbbqbksssssk",
                ".kssskqbbbbqbbbbqbksssk.",
                ".kssskbbbbbbbbbbbqksssk.",
                "..ksskbewbbbbbbewbkssk..",
                "...kkkbeebbmmbbeebkkk...",
                "....kkbbbmngnnmbbbkk....",
                "....kkqbbmmnnmmbbbkk....",
                ".....kkbbmmkkmmbbkk.....",
                "......kkkbmttmbkkk......",
                "......kbbkkttkkbbk......",
                "......kbbvvvvvvqbk......",
                ".....kqbbbcyycbbqbk.....",
                "....kbbqbbbccbbbbqbk....",
                "....kbbbqbkbbkbbbbqk....",
                ".....kbbbqkbbkqbbbk.....",
                ".....kbbbbkbbkbqbbk.....",
                "......kksskqbksskk......",
                "........kkkbqkkk........"],
        hot2:  ["........................",
                "...kkk...kkkkkk...kkk...",
                "..kssskkkkkkkkkkkksssk..",
                ".kssssskkbbbbqbkksssssk.",
                ".ksssskbbqbbbbqbbkssssk.",
                "kssssskbbbqbbbbqbksssssk",
                ".kssskqbbbbqbbbbqbksssk.",
                ".kssskbbbbbbbbbbbqksssk.",
                "..ksskbbbbbbbbbbbbkssk..",
                "...kkkbeebbmmbbeebkkk...",
                "....kkbbbmngnnmbbbkk....",
                "....kkqbbmmnnmmbbbkk....",
                ".....kkbbmmkkmmbbkk.....",
                "......kkkbmttmbkkk......",
                "......kbbkkkkkkbbk......",
                "......kbbvvvvvvqbk......",
                ".....kqbbbcyycbbqbk.....",
                "....kbbqbbbccbbbbqbk....",
                "....kbbbqbkbbkbbbbqk....",
                ".....kbbbqkbbkqbbbk.....",
                ".....kbbbbkbbkbqbbk.....",
                "......kksskqbksskk......",
                "........kkkbqkkk........"],
        sleep: ["........................",
                "........................",
                "........................",
                "........................",
                "........................",
                "........................",
                "........................",
                "........................",
                "........................",
                "...k...kkkkkk...k.......",
                "..kskkkkkkkkkkkksk......",
                ".kssskqbbbbqbbksssk.....",
                "kssskbbqbbbbqbbksssk....",
                "ksssbbbbbbbbbbbbsssk....",
                "ksskqbbbbbbbbbbbksskkk..",
                ".kskbbeebbbbeebbksbbqbk.",
                "..kkbbbbmnnmbbbbqbbbbqbk",
                "...kkbbmmnnmmbbkbqbbbbqk",
                "....kkbbmmmmbbkbbbqbbbbk",
                "....kkkkkkkkkbbbbbbqbbk.",
                "...kkbbbkbbbkbbbkbbbqk..",
                "...kkbqbkkkkkbbbkkkkk...",
                "....kkkkk...kkkkk......."]
    })

    // ---- Cat: k outline, b body, w eye, p nose/inner ear ----
    readonly property var catFrames: ({
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
        // Every frame redraws the whole desktop window, so keep these low.
        interval: tile.mood === "run" ? 200 : tile.mood === "hot" ? 500 : 333
        running: tile.visible && tile.mood !== "sleep" && !app.editing
        repeat: true
        onTriggered: {
            tile.step++;
            var speed = tile.mood === "run" ? 0.05 : tile.mood === "hot" ? 0.008 : 0.016;
            tile.pos += tile.facingLeft ? -speed : speed;
            if (tile.pos < 0) { tile.pos = 0; tile.facingLeft = false; }
            if (tile.pos > 1) { tile.pos = 1; tile.facingLeft = true; }
        }
    }
    // Sleeping: just the Zzz, on the shared tick.
    Connections { target: app; function onTickChanged() { if (tile.mood === "sleep") tile.step++; } }

    readonly property var frames: isCat ? catFrames : dogFrames
    readonly property var frame: mood === "sleep" ? frames.sleep
        : mood === "run" ? (step % 2 ? frames.run1 : frames.run2)
        : mood === "hot" && frames.hot1 ? (step % 2 ? frames.hot1 : frames.hot2)
        : (step % 2 ? frames.walk1 : frames.walk2)
    readonly property int cols: frame[0].length
    readonly property int rows: frame.length

    // The dog keeps its own coat in every theme; the cat wears the theme.
    readonly property var dogColors: ({ k: "#4a2c17", b: "#e0a46a", q: "#d5965c", s: "#c27f45", c: "#f8e6cc",
                                        m: "#f0c590", e: "#1a1110", w: "#ffffff", n: "#1a1110", g: "#6b5a50",
                                        t: "#f28ba8", v: "#9b7fe0", y: "#f5c518" })
    readonly property color bodyColor: app.accent("pet")
    readonly property color outline: dark ? "#0b0b0f" : "#1f1f24"
    function colorFor(ch) {
        if (!isCat) return dogColors[ch] || "transparent";
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

        readonly property real px: Math.max(2, Math.floor(Math.min(width / (tile.cols + 6), (height - tile.u) / (tile.rows + 1))))
        readonly property real spriteW: px * tile.cols
        readonly property real spriteH: px * tile.rows

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
                model: tile.cols * tile.rows
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
            // Sweat drop when hot (bobs with the step). The dog pants instead.
            Rectangle {
                visible: tile.mood === "hot" && tile.isCat
                x: stage.px * 7; y: stage.px * (tile.step % 2 ? 0 : 1)
                width: stage.px; height: stage.px * 2
                color: "#7dd3fc"
            }
        }

        // Zzz while napping, drifting up one step per second.
        PlasmaComponents.Label {
            textFormat: Text.PlainText
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
