import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../code/sky.js" as Sky

// A pixel pet that lives in the tile, in its own little room.
// - Poodle: keeps busy with a little routine (sits, wags, sniffs, yawns,
//   play-bows, trots, naps in its bed, drinks) and gets livelier with the
//   CPU: hops at medium load; zooms, spins and chases its ball when busy;
//   lies down panting when hot. Frames come from images/poodle.png (made by
//   tools/poodle.py); the room and everything in it from images/props.png
//   (tools/props.py).
// - Cat: the same, drawn square by square in the theme's color.
// It has needs (food, fun, a bath now and then, and walks: skip those and
// there's a mess to clean up). The buttons pet, feed, wash, clean up after,
// walk or play with it. Walks go outside: a park, the snow or the beach,
// with a tree to pee on and an animal friend to chase.
// It animates at a few frames per second and stands still while asleep
// (every frame makes Plasma redraw the desktop).
GlassTile {
    id: tile
    required property var app

    readonly property var po: app.petOptions
    readonly property bool isCat: po.kind === "cat"
    readonly property var lv: app.petLevels
    readonly property string wish: app.petWish

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
        sit: [["................",
             "..k..k..........",
             ".kbkkbk.........",
             ".kbbbbk.........",
             ".kwbwbk.........",
             ".kbpbbk.....k...",
             "..kbbbbkk..kbk..",
             "..kbbbbbbk.kbk..",
             "..kbbbbbbbkbk...",
             "..kbbbbbbbbk....",
             "..kbkbkkbbk.....",
             "..kkkkk.kkk....."],
            ["................",
             "..k..k..........",
             ".kbkkbk.........",
             ".kbbbbk.........",
             ".kwbwbk.........",
             ".kbpbbk.........",
             "..kbbbbkk...kk..",
             "..kbbbbbbk.kbbk.",
             "..kbbbbbbbkbk...",
             "..kbbbbbbbbk....",
             "..kbkbkkbbk.....",
             "..kkkkk.kkk....."]],
        eat: [["................",
             "................",
             "...............k",
             "..............kb",
             "..k..k........kb",
             ".kbkkbkkkkkkkkbk",
             ".kbbbbbbbbbbbbk.",
             ".kwbwbbbbbbbbbk.",
             ".kbpbbbbbbbbbk..",
             "..kkkbk.kbk.kbk.",
             ".....kk.kk..kk..",
             "................"],
            ["................",
             "................",
             "................",
             "...............k",
             "..k..k........kb",
             ".kbkkbkkkkkkkkbk",
             ".kbbbbbbbbbbbbk.",
             ".kkbkbbbbbbbbbk.",
             ".kbpbbbbbbbbbk..",
             "..kkkbk.kbk.kbk.",
             ".....kk.kk..kk..",
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
    // What the cat shows for each activity.
    readonly property var catPose: ({ walk: "walk", sniff: "walk", hop: "walk", run: "run", ball: "run", spin: "run",
        shake: "run", hot: "walk", sit: "sit", wag: "sit", bow: "sit", yawn: "sit", beg: "sit", pee: "sit",
        eat: "eat", sleep: "sleep" })

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
        hot:   { row: "hot",   ms: 450, speed: 0 },
        eat:   { row: "eat",   ms: 260, speed: 0 },
        pee:   { row: "pee",   ms: 400, speed: 0 },
        shake: { row: "shake", ms: 110, speed: 0 },
        beg:   { row: "beg",   ms: 380, speed: 0 }
    })
    readonly property var sheetRows: ["walk", "run", "sit", "wag", "sniff", "bow", "yawn", "sleep", "hot", "eat", "pee", "shake", "beg"]
    readonly property var sheetFrames: ({ walk: 4, run: 4, sit: 4, wag: 4, sniff: 4, bow: 4, yawn: 4, sleep: 2, hot: 2, eat: 4, pee: 2, shake: 4, beg: 2 })

    property string activity: "sit"
    property int remaining: 12           // frames (or seconds, asleep) until the next activity
    property string place: "home"        // home | out
    property string fx: ""               // hearts | bubbles | drops | sparkles | pee
    property string toy: "ball"
    property bool inTub: false
    property bool bowlFull: false

    // Where the pet is: pos across the tile (0..1) and depth across the
    // floor (0 = back, by the wall and furniture; 1 = the front edge).
    property real pos: 0.45
    property real depth: 0.6
    property bool facingLeft: true
    property var wander: null            // { x, d }: strolling there for no reason

    // A plan is a list of steps run in order:
    //   { go: x, d: depth, run }   walk (or run) somewhere
    //   { act, frames, fx, face }   do something there ("face": "left" or "right")
    //   { place: "out" | "home" } or { call: "functionName" }
    property var plan: []
    property var job: null

    function startPlan(steps) {
        // Whatever was going on stops: no half-filled bowl or empty tub left behind.
        bowlFull = false;
        inTub = false;
        fx = "";
        wander = null;
        plan = steps;
        job = null;
        runNext();
    }
    function runNext() {
        while (plan.length) {
            var s = plan[0];
            plan = plan.slice(1);
            if (s.place) { place = s.place; continue; }
            if (s.call) { tile[s.call](); continue; }
            job = s;
            fx = s.fx || "";
            if (s.go !== undefined) {
                activity = s.run ? "run" : "walk";
                remaining = 400;        // a long way at most; arriving ends the step
            } else {
                activity = s.act;
                remaining = s.frames || 10;
                if (s.face) facingLeft = s.face === "left";
            }
            return;
        }
        job = null;
        fx = "";
        inTub = false;
        pickActivity();
    }

    // Spots in the tile, as pos values for the pet's left edge.
    function posFor(leftPx) {
        var w = stage.width - stage.petW;
        return w > 0 ? Math.max(0, Math.min(1, leftPx / w)) : 0.5;
    }
    // Standing centered on something at fraction f of the width.
    function posAt(f) { return posFor(f * stage.width - stage.petW * 0.5); }
    // Facing left with the mouth right over something at fraction f.
    function mouthAt(f) { return posFor(f * stage.width - stage.petW * (isCat ? 0.2 : 0.07)); }
    // A spot on the floor at depth d: x (0..1) squeezed between the walls.
    function onFloor(x, d) {
        if (place !== "home" || !po.room || stage.width <= 0) return x;
        var y = stage.footY(d), w = stage.width - stage.petW;
        if (w <= 0) return x;
        var lo = room.floorLeft(y) / w, hi = (room.floorRight(y) - stage.petW) / w;
        return Math.max(lo, Math.min(hi, x));
    }
    // Walk up to a thing at the back from its right, then face it.
    function approach(f, run) {
        var x = mouthAt(f);
        return [{ go: Math.min(1, x + 0.08), d: 0.35, run: !!run }, { go: x, d: 0 }];
    }

    function pickActivity() {
        wander = null;
        if (isCat) {   // the cat follows the CPU, with naps in its bed
            activity = mood === "hot" ? "hot" : load < 8 ? "sleep" : mood === "zoom" ? "run" : Math.random() < 0.3 ? "sit" : "walk";
            remaining = activity === "sleep" ? 10 + Math.floor(Math.random() * 10) : 10;
        } else if (mood === "hot") {
            activity = "hot"; remaining = 20;
            return;
        } else {
            // Now and then, something in the room (calm moments only).
            // (Not before the tile has a size: the spots wouldn't be known yet.)
            if (place === "home" && mood === "calm" && po.room && stage.width > 0 && Math.random() < 0.25) {
                var r = Math.random();
                if (r < 0.4 || (stage.sky && stage.sky.dark && r < 0.7))
                    return startPlan([{ go: posAt(room.spots.bed), d: Math.min(1, room.bedDepth + 0.25) }, { go: posAt(room.spots.bed), d: room.bedDepth },
                                      { act: "sleep", frames: 15 + Math.floor(Math.random() * 15) }]);
                if (r < 0.75)
                    return startPlan(approach(room.spots.water).concat([{ act: "eat", frames: 10, face: "left" }]));
                if (room.roomy)
                    return startPlan(approach(room.spots.basket).concat([{ act: "sniff", frames: 6, face: "left" }, { act: "bow", frames: 6 }]));
            }
            var names = Object.keys(acts), total = 0;
            names.forEach(function (n) { total += acts[n][mood] || 0; });
            var x = Math.random() * total;
            for (var i = 0; i < names.length; i++) {
                x -= acts[names[i]][mood] || 0;
                if (x < 0) { activity = names[i]; break; }
            }
            // A short nap (8-15 s); everything else 3-6 s worth of frames.
            remaining = activity === "sleep" ? 8 + Math.floor(Math.random() * 8)
                 : Math.round((3000 + Math.random() * 3000) / Math.max(120, acts[activity].ms));
            if (activity === "spin" || Math.random() < 0.3) facingLeft = !facingLeft;
        }
        // Moving about: off to a random spot on the floor, not just sideways.
        if (["walk", "hop", "run", "ball"].indexOf(activity) >= 0) {
            var d = 0.15 + Math.random() * 0.85;
            wander = { x: onFloor(Math.random(), d), d: d };
        }
    }
    // A big change in the PC wakes the pet and changes plans right away
    // (unless it's busy with something you asked).
    onMoodChanged: if (!job) pickActivity()
    onIsCatChanged: if (!job) pickActivity()
    Component.onCompleted: pickActivity()

    // One step toward (x, d). Returns true on arrival. Speed is in pixels,
    // so going back and forth across the floor isn't faster than sideways.
    function stepTo(x, d, run) {
        var w = Math.max(1, stage.width - stage.petW), h = Math.max(1, stage.footFront - stage.footBack);
        var dx = (x - pos) * w, dy = (d - depth) * h;
        var dist = Math.sqrt(dx * dx + dy * dy);
        var sp = (run ? 0.05 : 0.026) * Math.max(stage.width, 200);
        if (Math.abs(dx) > 1) facingLeft = dx < 0;
        if (dist <= sp) { pos = x; depth = d; return true; }
        pos += dx / dist * sp / w;
        depth += dy / dist * sp / h;
        return false;
    }

    // ---- The buttons ----
    function care(what) {
        if (what === "walk" && place === "out") return startPlan(goHome(true));
        app.petAct(what);
        var home = place === "out" ? goHome(false) : [];
        switch (what) {
        case "pet":
            return startPlan(home.concat([{ act: isCat ? "sit" : "wag", frames: 16, fx: "hearts" }]));
        case "feed":
            return startPlan(home.concat([{ call: "fillBowl" }, { act: isCat ? "sit" : "beg", frames: 4 }],
                                         approach(room.spots.bowl, true),
                                         [{ act: "eat", frames: 24, face: "left" }, { call: "emptyBowl" },
                                          { go: Math.min(1, mouthAt(room.spots.bowl) + 0.06), d: 0.5 },
                                          { act: isCat ? "sit" : "wag", frames: 8, fx: "hearts" }]));
        case "bath":
            return startPlan(home.concat([{ go: posAt(room.spots.tub), d: 0.35 }, { go: posAt(room.spots.tub), d: 0 }, { call: "intoTub" },
                                          { act: "sit", frames: 22, fx: "bubbles" }, { call: "outOfTub" },
                                          { go: posAt(room.spots.tub), d: 0.55 },
                                          { act: "shake", frames: 14, fx: "drops" },
                                          { act: isCat ? "sit" : "wag", frames: 8, fx: "sparkles" }]));
        case "clean":
            return startPlan(home.concat([{ act: isCat ? "sit" : "wag", frames: 10, fx: "sparkles" }]));
        case "play":
            toy = ["ball", "bone", "duck"][Math.floor(Math.random() * 3)];
            return startPlan(home.concat([{ act: isCat ? "sit" : "bow", frames: 6 },
                                          { go: Math.random() < 0.5 ? 0.1 : 0.9, d: 0.8, run: true },
                                          { act: "ball", frames: 12 },
                                          { go: 0.5, d: 0.3, run: true },
                                          { act: isCat ? "sit" : "wag", frames: 8 }]));
        case "walk":
            return goForWalk();
        }
    }

    // ---- Walks: three places in a row, out one side and into the next ----
    readonly property var places: ({ grass: 3, snow: 3, sand: 3 })   // layouts per ground
    property var scenes: [{ ground: "grass", variant: 0, mirror: false }]
    property int sceneIndex: 0
    readonly property var scene: scenes[Math.min(sceneIndex, scenes.length - 1)]

    function pickScenes() {
        var g = po.ground;
        if (g === "auto") g = app.weather && app.weather.ready && ((app.weather.code >= 71 && app.weather.code <= 77) || app.weather.code === 85 || app.weather.code === 86) ? "snow" : "grass";
        var all = [];
        Object.keys(places).forEach(function (k) {
            if (g === "mix" || g === k)
                for (var v = 0; v < places[k]; v++) all.push({ ground: k, variant: v, mirror: Math.random() < 0.4 });
        });
        // Shuffle and take three.
        for (var i = all.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1)), t = all[i];
            all[i] = all[j]; all[j] = t;
        }
        return all.slice(0, 3);
    }

    function goForWalk() {
        scenes = pickScenes();
        sceneIndex = 0;
        // Over to the door in the right-hand wall, and out.
        var steps = [{ go: 0.75, d: Math.min(1, room.doorDepth + 0.25) }, { go: posAt(room.spots.door), d: room.doorDepth },
                     { place: "out" }, { call: "enterScene" }];
        for (var i = 0; i < scenes.length; i++) {
            if (i > 0) steps.push({ call: "nextScene" });
            var peeAt = posAt(outside.peeSpotFor(scenes[i]));
            if (i === 0)        // sniff around and find the perfect spot
                steps = steps.concat([{ go: 0.3, d: 0.6 }, { act: "sniff", frames: 10 },
                                      { go: peeAt + (peeAt < 0.5 ? 0.07 : -0.07), d: 0.1 },
                                      { act: isCat ? "sit" : "pee", frames: 10, fx: "pee" }]);
            else if (i === 1)   // meet a friend, play
                steps = steps.concat([{ go: 0.25, d: 0.5 }, { call: "chaseFriend" }, { act: isCat ? "sit" : "bow", frames: 8, fx: "hearts" },
                                      { go: 0.85, d: 0.85, run: true }, { go: 0.4, d: 0.2, run: true },
                                      { act: isCat ? "sit" : "wag", frames: 8 }]);
            else                // a sniff and a rest
                steps = steps.concat([{ go: 0.45, d: 0.7 }, { act: "sniff", frames: 8 }, { act: "sit", frames: 8 }]);
            steps.push({ go: 1, d: 0.5 });
        }
        startPlan(steps.concat(goHomeTail()));
    }
    function goHome(run) { return [{ go: 1, d: 0.5, run: run }].concat(goHomeTail()); }
    function goHomeTail() {
        return [{ place: "home" }, { call: "enterHome" }, { go: 0.7, d: 0.6 }, { act: "sit", frames: 6 }];
    }

    function newFriend() {
        var kinds = ({ grass: ["bird", "butterfly", "squirrel", "rabbit", "pal"],
                       snow: ["bird", "rabbit", "pal"],
                       sand: ["crab", "bird", "crab"] })[scene.ground];
        friendKind = kinds[Math.floor(Math.random() * kinds.length)];
        friendPos = 0.5 + Math.random() * 0.4;
        friendDepth = 0.3 + Math.random() * 0.6;
    }
    function enterScene() { pos = 0; depth = 0.5; facingLeft = false; newFriend(); }
    function nextScene() { sceneIndex++; enterScene(); }
    function chaseFriend() { plan = [{ go: friendPos, d: friendDepth, run: true }].concat(plan); }
    function enterHome() { pos = posAt(room.spots.door); depth = room.doorDepth; facingLeft = true; }
    function fillBowl() { bowlFull = true; }
    function emptyBowl() { bowlFull = false; }
    function intoTub() { inTub = true; }
    function outOfTub() { inTub = false; }

    readonly property bool asleep: activity === "sleep"

    property int step: 0

    // ---- Animal friend, outside ----
    property string friendKind: "bird"
    property real friendPos: 0.7
    property real friendDepth: 0.5
    property bool friendLeft: true
    readonly property bool flies: friendKind === "bird" || friendKind === "butterfly"

    Timer {
        interval: tile.isCat ? (tile.activity === "run" || tile.activity === "ball" ? 200 : tile.activity === "hot" ? 500 : 333)
                             : Math.max(110, (tile.acts[tile.activity] || tile.acts.sit).ms)
        running: tile.visible && !tile.asleep && !app.editing
        repeat: true
        onTriggered: {
            tile.step++;
            if (tile.activity === "spin" && tile.step % 2 === 0) tile.facingLeft = !tile.facingLeft;
            // The friend wanders, and keeps a step ahead of the pet.
            if (tile.place === "out") {
                var near = Math.abs(tile.friendPos - tile.pos) < 0.12;
                var fs = near ? 0.03 : 0.008;
                if (near) tile.friendLeft = tile.friendPos < tile.pos;
                else if (Math.random() < 0.08) tile.friendLeft = !tile.friendLeft;
                tile.friendPos += tile.friendLeft ? -fs : fs;
                if (tile.friendPos < 0.05) { tile.friendPos = 0.05; tile.friendLeft = false; }
                if (tile.friendPos > 0.95) { tile.friendPos = 0.95; tile.friendLeft = true; }
            }
            var j = tile.job;
            if (j && j.go !== undefined) {           // walking somewhere
                if (tile.stepTo(j.go, j.d === undefined ? tile.depth : j.d, j.run)) tile.runNext();
                return;
            }
            if (tile.wander) {                       // strolling about
                if (tile.stepTo(tile.wander.x, tile.wander.d, tile.activity !== "walk")) {
                    // Fetch: the ball bounces back off the wall, the pet runs after it.
                    if (tile.activity === "ball" && tile.remaining-- > 0)
                        tile.wander = { x: tile.onFloor(tile.pos < 0.5 ? 0.9 : 0.1, tile.depth), d: tile.depth };
                    else tile.pickActivity();
                }
                return;
            }
            if (tile.isCat && tile.activity === "hot") tile.pos = Math.max(0, Math.min(1, tile.pos + (tile.facingLeft ? -0.008 : 0.008)));
            if (--tile.remaining <= 0) {
                if (j) tile.runNext(); else tile.pickActivity();
            }
        }
    }
    // Asleep: breathe and drift the Zzz on the shared tick; wake when rested.
    Connections {
        target: app
        function onTickChanged() {
            if (!tile.asleep || !tile.visible) return;
            tile.step++;
            if (--tile.remaining <= 0) {
                if (tile.job) tile.runNext(); else tile.pickActivity();
            }
        }
    }

    // ---- Cat frames (text) ----
    readonly property var catCycle: catFrames[catPose[activity] || "walk"] || catFrames.walk
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

    // No header: the room gets the whole card. The name, if set, sits in a corner.
    showHeader: false
    bleed: true
    accent: app.accent("pet")
    accent2: app.accent2("pet")
    level: asleep ? 0.15 : mood === "calm" ? 0.35 : mood === "busy" ? 0.6 : 0.85

    HoverHandler { id: hover }

    Item {
        id: stage
        anchors.fill: parent
        clip: po.room

        // Pixel size. The room and the pet share one scale (rpx), so things
        // keep real-life sizes; Medium and Large make just the pet bigger.
        readonly property int rpx: Math.max(height >= 80 && width >= 160 ? 2 : 1, Math.round(Math.min(height * 0.32 / 25, width < 330 ? width / 80 : width / 140)))
        // A small dog next to real furniture: Small draws it at two thirds of
        // the room's scale; Medium at the room's; Large a step bigger.
        readonly property int px: tile.po.size === "l" ? rpx + 1 : tile.po.size === "m" ? rpx : Math.max(1, Math.round(rpx * 0.67))
        // The cat's frames are half the size: draw them at twice the scale.
        readonly property int cpx: tile.isCat ? px * 2 : px
        readonly property real petW: cpx * tile.cols
        readonly property real petH: cpx * tile.rows
        // Floor: furniture stands along the back of it; the pet walks anywhere
        // between the back (depth 0, feet at footBack) and the front edge.
        readonly property bool deep: tile.po.room || tile.place === "out"
        readonly property real floorY: deep ? height - Math.max(rpx * 18, height * 0.36) : height - rpx
        readonly property real backY: deep ? floorY + rpx * 3 : height - rpx
        readonly property real footBack: deep ? backY : height - rpx
        readonly property real footFront: deep ? height - rpx * 2 : height - rpx
        function footY(d) { return footBack + (footFront - footBack) * d; }
        // The sky outside (and the nerd room's clock), worked out again once a minute.
        property int minute: 0
        readonly property date clock: { stage.minute; return new Date(); }
        Connections { target: tile.app; function onTickChanged() { if (tile.app.tick % 60 === 0) stage.minute++; } }
        readonly property var sky: {
            stage.minute;   // re-run every minute
            var w = tile.app.weather, d = w && w.ready && w.daily.length ? w.daily[0] : null;
            var now = new Date();
            return Sky.at(now.getHours() * 60 + now.getMinutes(),
                          Sky.minutesOf(d ? d.sunrise : "", 390), Sky.minutesOf(d ? d.sunset : "", 1110));
        }

        PetRoom {
            id: room
            anchors.fill: parent
            visible: tile.po.room && tile.place === "home"
            px: stage.rpx
            floorY: stage.floorY
            standY: stage.backY
            sky: stage.sky
            bowlFull: tile.bowlFull
            showTub: tile.inTub || tile.fx === "bubbles"
            style: tile.po.roomStyle
            tick: visible ? tile.app.tick : 0
            accent: tile.accent
            now: stage.clock
            app: tile.app
            footBack: stage.footBack
            footFront: stage.footFront
            pixelFont: tile.app.pixelFontName || ""
        }
        PetOutside {
            id: outside
            anchors.fill: parent
            visible: tile.place === "out"
            px: stage.rpx
            horizon: stage.floorY - stage.rpx * 4
            standY: stage.backY
            sky: stage.sky
            ground: tile.scene.ground
            variant: tile.scene.variant
            mirror: tile.scene.mirror
            tick: visible ? tile.app.tick : 0
        }

        // Ground line (simple look)
        Rectangle {
            visible: !tile.po.room && tile.place === "home"
            anchors.left: parent.left
            anchors.right: parent.right
            y: stage.height - stage.rpx
            height: Math.max(1, stage.rpx / 2)
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
        }

        // Without the room, the bowl and tub still turn up when needed.
        Prop {
            visible: !tile.po.room && tile.place === "home" && (tile.bowlFull || tile.activity === "eat")
            name: tile.bowlFull ? "bowl_full" : "bowl"
            px: stage.rpx
            x: stage.width * room.spots.bowl - width / 2
            y: stage.backY - height
        }
        Prop {
            visible: !tile.po.room && (tile.inTub || tile.fx === "bubbles")
            name: "tub"
            px: stage.rpx
            x: stage.width * room.spots.tub - width / 2
            y: stage.backY - height + stage.rpx * 2
        }

        // Eating or drinking: the bowl in front of the muzzle, so the head
        // dips into it rather than covering it.
        Prop {
            readonly property real mouthX: tile.facingLeft ? pet.x + stage.petW * (tile.isCat ? 0.2 : 0.07) : pet.x + stage.petW * (tile.isCat ? 0.8 : 0.93)
            readonly property bool water: Math.abs(mouthX - room.spots.water * stage.width) < Math.abs(mouthX - room.spots.bowl * stage.width)
            visible: tile.po.room && tile.place === "home" && tile.activity === "eat" && tile.depth < 0.05
            name: water ? "water" : tile.bowlFull ? "bowl_full" : "bowl"
            px: stage.rpx
            x: (water ? room.spots.water : room.spots.bowl) * stage.width - width / 2
            y: stage.backY - height
            z: pet.z + 0.1
        }

        // The mess: poops and puddles on the floor, until cleaned up.
        Repeater {
            // (No mess at all when needs are switched off.)
            model: tile.place === "home" && tile.po.needs ? tile.app.petState.puddles : 0
            Rectangle {
                required property int index
                x: stage.width * [0.33, 0.74, 0.12][index] - width / 2
                y: stage.footY(0.45) - height / 2
                width: stage.rpx * 10; height: stage.rpx * 2.5; radius: height / 2
                color: "#f2d64b"
                opacity: 0.75
            }
        }
        Repeater {
            model: tile.place === "home" && tile.po.needs ? tile.app.petState.poops : 0
            Prop {
                required property int index
                name: "poop"; px: stage.rpx
                x: stage.width * [0.62, 0.28, 0.85][index] - width / 2
                y: stage.footY(0.55) - height
            }
        }

        // The toy, for fetch: rolls and bounces ahead of the pet.
        Prop {
            visible: tile.activity === "ball"
            name: tile.toy
            px: stage.px
            // Rolls ahead of the pet but stays on the floor, never into a wall.
            readonly property real floorY: stage.footY(tile.depth)
            readonly property real lo: tile.place === "home" && tile.po.room ? room.floorLeft(floorY) : 0
            readonly property real hi: tile.place === "home" && tile.po.room ? room.floorRight(floorY) : stage.width
            x: Math.max(lo, Math.min(hi - width, pet.x + (tile.facingLeft ? -width * 1.5 : stage.petW + width * 0.5)))
            y: floorY - height - stage.px * [0, 3, 5, 3][tile.step % 4]
            z: pet.z + 0.01
        }

        // Friend, outside
        Prop {
            visible: tile.place === "out"
            name: tile.friendKind + (tile.step % 2 ? "1" : "2")
            px: stage.rpx
            flip: !tile.friendLeft
            x: (stage.width - width) * tile.friendPos
            y: tile.flies ? stage.footY(tile.friendDepth) - stage.petH * 1.3 - stage.rpx * [0, 2, 3, 1][tile.step % 4]
                          : stage.footY(tile.friendDepth) - height - stage.rpx * (tile.friendKind === "rabbit" || tile.friendKind === "squirrel" ? [0, 2][tile.step % 2] : 0)
            z: 1 + tile.friendDepth
        }

        Item {
            id: pet
            readonly property bool onBed: tile.asleep && tile.place === "home" && tile.po.room
                && Math.abs(tile.depth - room.bedDepth) < 0.05 && Math.abs(tile.pos - tile.posAt(room.spots.bed)) < 0.03
            width: stage.petW
            height: stage.petH
            // Kept on the floor: in the den it narrows toward the back.
            readonly property real footAt: stage.footY(tile.depth)
            x: tile.place === "home" && tile.po.room
               ? Math.max(room.floorLeft(footAt), Math.min(room.floorRight(footAt) - width, (stage.width - width) * tile.pos))
               : (stage.width - width) * tile.pos
            // In the tub it sits back at the tub, with the water over its legs.
            y: tile.inTub ? stage.backY - stage.px * 3 - height
             : stage.footY(tile.depth) - height - tile.lift * stage.px - (onBed ? room.bedRaise : 0)
            // Nearer the front draws over what's behind (the friend, the toy).
            z: 1 + tile.depth
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
                    x: cx * stage.cpx
                    y: cy * stage.cpx
                    width: stage.cpx
                    height: stage.cpx
                    color: tile.colorFor(tile.frame[cy].charAt(cx))
                    visible: color.a > 0          // empty pixels draw nothing
                }
            }
            // Cat's sweat drop when hot.
            Rectangle {
                visible: tile.activity === "hot" && tile.isCat
                x: stage.cpx * 7; y: stage.cpx * (tile.step % 2 ? 0 : 1)
                width: stage.cpx; height: stage.cpx * 2
                color: "#7dd3fc"
            }

            // Clicking the pet pets it.
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: tile.care("pet")
            }
        }

        // Bath water in front of the pet
        Rectangle {
            visible: tile.inTub
            x: stage.width * room.spots.tub - width / 2
            y: stage.backY - stage.rpx * 10
            width: stage.rpx * 30; height: stage.rpx * 6
            color: "#cbe9ff"
            z: 2
        }

        // ---- Effects, a step per frame ----
        Repeater {      // hearts float up
            model: tile.fx === "hearts" ? 3 : 0
            Prop {
                required property int index
                name: "heart"; px: stage.px
                x: pet.x + stage.petW * (0.2 + index * 0.3)
                y: pet.y - height - stage.px * ((tile.step + index * 3) % 8) * 1.5
                opacity: 1 - ((tile.step + index * 3) % 8) / 9
                z: 4
            }
        }
        Repeater {      // soap bubbles
            model: tile.fx === "bubbles" ? 6 : 0
            Rectangle {
                required property int index
                readonly property int k: (tile.step + index * 2) % 7
                width: stage.px * (2 + index % 3); height: width; radius: width / 2
                x: stage.width * room.spots.tub - stage.px * 10 + index * stage.px * 4
                y: stage.backY - stage.px * 9 - k * stage.px * 2
                color: Qt.rgba(1, 1, 1, 0.5)
                border.width: 1
                border.color: Qt.rgba(0.6, 0.85, 1, 0.9)
                opacity: 1 - k / 8
                z: 4
            }
        }
        Repeater {      // water flying off
            model: tile.fx === "drops" ? 6 : 0
            Prop {
                required property int index
                name: "drop"; px: stage.px
                readonly property int k: (tile.step + index) % 4
                x: pet.x + stage.petW / 2 + (index % 2 ? 1 : -1) * stage.px * (6 + k * 4 + index)
                y: pet.y + stage.petH * 0.3 - k * stage.px * 2 + (index % 3) * stage.px * 3
                z: 4
            }
        }
        Repeater {      // sparkles
            model: tile.fx === "sparkles" ? 4 : 0
            Prop {
                required property int index
                name: "sparkle"; px: stage.px
                visible: (tile.step + index) % 3 !== 0
                x: (index % 2 ? pet.x + stage.petW : pet.x) + (index < 2 ? -stage.px * 4 : stage.px * 2)
                y: pet.y + (index < 2 ? 0 : stage.petH * 0.5)
                z: 4
            }
        }
        Rectangle {     // a little yellow puddle while peeing
            visible: tile.fx === "pee" && tile.activity === "pee"
            x: pet.x + (tile.facingLeft ? stage.petW * 0.65 : stage.petW * 0.05)
            y: stage.footY(tile.depth) - height / 2
            width: stage.px * (2 + Math.min(6, tile.step % 10)); height: stage.px * 1.5; radius: height / 2
            color: "#f2d64b"
            opacity: 0.8
        }

        // Thought bubble: what it wants, on and off.
        Rectangle {
            visible: tile.po.needs && tile.wish !== "" && !tile.job && !tile.asleep && tile.app.tick % 8 < 5
            readonly property real s: stage.px * 13
            x: Math.max(0, Math.min(stage.width - s, pet.x + stage.petW * 0.6))
            y: Math.max(0, pet.y - s * 0.9)
            width: s; height: s * 0.85; radius: tile.radius > 0 ? s * 0.3 : 0
            color: "#ffffff"
            border.width: Math.max(1, stage.px / 2)
            border.color: "#2b2118"
            z: 5
            Prop {
                anchors.centerIn: parent
                name: "i_" + tile.wish
                px: stage.px
            }
        }

        // Zzz while napping, drifting up one step per second.
        PlasmaComponents.Label {
            textFormat: Text.PlainText
            visible: tile.asleep
            text: ["z", "zZ", "zZz"][tile.step % 3]
            x: pet.x + stage.petW * 0.6
            y: pet.y + stage.petH * (tile.isCat ? 0 : 0.3) - stage.px * (2 + tile.step % 3)
            color: tile.accent
            font.pixelSize: stage.px * 4
            font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
            font.weight: Font.Bold
            z: 5
        }

        // The pet's name, if it has one, as a little tag top left.
        Rectangle {
            id: nameTag
            // Only where it doesn't run into the buttons.
            visible: tile.po.name !== "" && x + width + stage.rpx * 4 < (buttons.visible ? buttons.x : stage.width)
            x: stage.rpx * 2; y: stage.rpx * 2
            width: nameLabel.implicitWidth + stage.rpx * 6
            height: nameLabel.implicitHeight + stage.rpx * 2
            radius: tile.radius > 0 ? height / 2 : 0
            color: Qt.rgba(tile.baseColor.r, tile.baseColor.g, tile.baseColor.b, 0.75)
            z: 6
            PlasmaComponents.Label {
                id: nameLabel
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: tile.po.name
                font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
                font.weight: Font.DemiBold
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.75)
            }
        }

        // ---- Care buttons, top right ----
        Row {
            id: buttons
            visible: tile.po.buttons === "always" || (tile.po.buttons === "hover" && hover.hovered)
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: stage.px
            spacing: Math.max(2, stage.px)
            z: 6
            readonly property real size: Math.max(Kirigami.Units.iconSizes.small + 6, Math.min(tile.u * 1.5, stage.height / 6, (stage.width - stage.px * 4) / 6.6))
            Repeater {
                model: [
                    { id: "pet",   tip: i18n("Pet") },
                    { id: "feed",  tip: i18n("Feed") },
                    { id: "bath",  tip: i18n("Bath") },
                    { id: "clean", tip: i18n("Clean up") },
                    { id: "walk",  tip: tile.place === "out" ? i18n("Go home") : i18n("Walk") },
                    { id: "play",  tip: i18n("Play") }
                ]
                QQC2.AbstractButton {
                    id: careButton
                    required property var modelData
                    readonly property bool wanted: tile.po.needs && tile.wish === modelData.id
                    width: buttons.size; height: buttons.size
                    hoverEnabled: true
                    onClicked: tile.care(modelData.id)
                    QQC2.ToolTip.text: modelData.tip
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    Accessible.name: modelData.tip
                    background: Rectangle {
                        radius: tile.radius > 0 ? width * 0.3 : 0
                        color: careButton.wanted ? Qt.rgba(tile.accent.r, tile.accent.g, tile.accent.b, careButton.hovered ? 0.9 : 0.7)
                             : Qt.rgba(tile.baseColor.r, tile.baseColor.g, tile.baseColor.b, careButton.hovered ? 0.95 : 0.75)
                        border.width: 1
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, careButton.hovered ? 0.4 : 0.15)
                    }
                    contentItem: Item {
                        Prop {
                            anchors.centerIn: parent
                            name: modelData.id === "walk" && tile.place === "out" ? "i_home" : "i_" + modelData.id
                            px: Math.max(1, Math.floor(careButton.height * 0.7 / 9))
                        }
                    }
                }
            }
        }
    }
}
