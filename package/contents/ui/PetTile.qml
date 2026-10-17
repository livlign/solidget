import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../code/sky.js" as Sky

// A pixel pet that lives in the tile, in its own little room.
// - Poodle: keeps busy with little routines (sniffs around the room, barks
//   out the window, scratches an itch, rolls on the rug, lies about, comes
//   over to say hi, has the zoomies, drinks) and naps in its bed once it's
//   tired (sooner at night). It comes over when the mouse does, and gets
//   livelier with the
//   CPU: hops at medium load; zooms, spins and plays with its toys when
//   busy; lies down panting when hot. Frames come from images/poodle.png (made by
//   tools/poodle.py); the room and everything in it from images/props.png
//   (tools/props.py).
// - Cat: the same, drawn square by square in the theme's color.
// It has needs (food, fun, a bath now and then, and walks: skip those and
// there's a mess to clean up). Its bowls are always full, so it has a
// drink or a snack when it likes. The buttons pet it, give it a treat
// (caught in the air, sometimes for a trick first), wash, clean up after,
// walk or play with it. It naps on its own bed or cushion. Walks go outside: a park, the snow or the beach,
// with a tree to pee on and an animal friend to chase. Play is a game of
// fetch: the toy flies, bounces and rolls on its own, and the pet chases it
// down, brings it back (or doesn't), and is too wound up to nap for a while.
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
        scratch: "sit", bark: "sit", eat: "eat", sleep: "sleep", rest: "sleep", roll: "sleep" })

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
        scratch: { row: "scratch", ms: 150, speed: 0, calm: 1, busy: 1, zoom: 0 },
        bow:   { row: "bow",   ms: 240, speed: 0,     calm: 2, busy: 2, zoom: 1 },
        walk:  { row: "walk",  ms: 220, speed: 0.014, calm: 3, busy: 3, zoom: 0 },
        hop:   { row: "walk",  ms: 160, speed: 0.022, calm: 0, busy: 3, zoom: 1 },
        run:   { row: "run",   ms: 140, speed: 0.045, calm: 0, busy: 1, zoom: 3 },
        spin:  { row: "run",   ms: 140, speed: 0,     calm: 0, busy: 0, zoom: 2 },
        ball:  { row: "run",   ms: 140, speed: 0.04,  calm: 1, busy: 2, zoom: 2 },
        sleep: { row: "sleep", ms: 0,   speed: 0 },
        rest:  { row: "rest",  ms: 420, speed: 0 },
        roll:  { row: "roll",  ms: 200, speed: 0 },
        bark:  { row: "bark",  ms: 260, speed: 0 },
        hot:   { row: "hot",   ms: 450, speed: 0 },
        eat:   { row: "eat",   ms: 260, speed: 0 },
        pee:   { row: "pee",   ms: 400, speed: 0 },
        shake: { row: "shake", ms: 110, speed: 0 },
        beg:   { row: "beg",   ms: 380, speed: 0 }
    })
    readonly property var sheetRows: ["walk", "run", "sit", "wag", "sniff", "bow", "yawn", "sleep", "hot", "eat", "pee", "shake", "beg",
                                      "rest", "scratch", "roll", "bark"]
    readonly property var sheetFrames: ({ walk: 4, run: 4, sit: 4, wag: 4, sniff: 4, bow: 4, yawn: 4, sleep: 2, hot: 2, eat: 4, pee: 2, shake: 4, beg: 2,
                                          rest: 4, scratch: 4, roll: 4, bark: 4 })

    property string activity: "sit"
    property int remaining: 12           // frames (or seconds, asleep) until the next activity
    property string place: "home"        // home | out
    property string fx: ""               // hearts | bubbles | drops | sparkles | pee
    property string toy: "ball"
    property int playedAt: -1000         // app.tick when the last game ended
    readonly property bool excited: app.tick - playedAt < 120
    // Runs down while awake (faster when running about, and at night) and
    // fills up again asleep. Naps only come once it's low.
    property real energy: 0.8
    readonly property bool tired: energy < 0.45
    property int noticedAt: -1000        // app.tick when it last came over to the mouse
    property bool inTub: false
    property string treat: ""            // a treat on its way to the mouth, or being eaten
    property real treatFall: 1           // 0 = up out of sight, 1 = at the mouth
    NumberAnimation { id: treatDrop; target: tile; property: "treatFall"; from: 0; to: 1; duration: 450; easing.type: Easing.InQuad }

    // Where the pet is: pos across the tile (0..1) and depth across the
    // floor (0 = back, by the wall and furniture; 1 = the front edge).
    property real pos: 0.45
    property real depth: 0.6
    property bool facingLeft: true
    property var wander: null            // { x, d }: strolling there for no reason

    // A plan is a list of steps run in order:
    //   { go: x, d: depth, run }   walk (or run) somewhere
    //   { act, frames, fx, face }   do something there ("face": "left" or "right")
    //   { fetch: true }             run the toy down and pick it up
    //   { place: "out" | "home" } or { call: "functionName" }
    property var plan: []
    property var job: null

    function startPlan(steps) {
        // Whatever was going on stops: no half-filled bowl or empty tub left
        // behind, and the toy is dropped where the pet stands.
        dropToy();
        treat = "";
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
            if (s.fetch) {
                activity = "run";
                remaining = 200;        // gives up on the toy after a while
            } else if (s.go !== undefined) {
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
        var canPlay = place === "home" && stage.width > 0 && mood !== "hot";
        if (mood !== "hot") {
            var r = routine();
            if (r) return startPlan(r);
        }
        if (isCat) {   // the cat follows the CPU, and naps when it's quiet and the cat is tired
            var sleepy = load < 8 && !excited && (energy < 0.6 || (stage.sky && stage.sky.dark));
            activity = mood === "hot" ? "hot" : sleepy ? "sleep" : mood === "zoom" ? "run" : Math.random() < 0.3 ? "sit" : "walk";
            remaining = activity === "sleep" ? 10 + Math.floor(Math.random() * 10) : 10;
        } else if (mood === "hot") {
            activity = "hot"; remaining = 20;
            return;
        } else {
            // Still wound up after a game: as lively as on a busy CPU.
            var m = mood === "calm" && excited ? "busy" : mood;
            var names = Object.keys(acts), total = 0;
            names.forEach(function (n) { total += acts[n][m] || 0; });
            var x = Math.random() * total;
            for (var i = 0; i < names.length; i++) {
                x -= acts[names[i]][m] || 0;
                if (x < 0) { activity = names[i]; break; }
            }
            if (activity === "ball") {
                if (canPlay) return startPlan(soloPlay());
                activity = "run";
            }
            // 3-6 s worth of frames.
            remaining = Math.round((3000 + Math.random() * 3000) / Math.max(120, acts[activity].ms));
            if (activity === "spin" || Math.random() < 0.3) facingLeft = !facingLeft;
        }
        // Moving about: off to a random spot on the floor, not just sideways.
        if (["walk", "hop", "run"].indexOf(activity) >= 0) {
            var d = 0.15 + Math.random() * 0.85;
            wander = { x: onFloor(Math.random(), d), d: d };
        }
    }
    // Something with a bit more to it than a single act, about half the
    // time: a plan picked by weight from what fits the moment. Null: none.
    function routine() {
        if (place !== "home" || stage.width <= 0 || Math.random() < 0.45) return null;
        var night = stage.sky && stage.sky.dark, calm = mood === "calm" && !excited;
        var rnd = function (a, b) { return a + Math.floor(Math.random() * (b - a + 1)); };
        var spot = function (d0, d1) { var d = d0 + Math.random() * (d1 - d0); return { go: onFloor(0.1 + Math.random() * 0.8, d), d: d }; };
        var list = [];
        function add(w, make) { if (w > 0) list.push({ w: w, make: make }); }

        // A nap: off to bed (or wherever it is), with a yawn first. Up after
        // with a stretch and a shake.
        add(tired && calm ? (night ? 10 : 5) : 0, function () {
            var bed = po.room ? [{ go: posAt(room.petBedX), d: Math.min(1, room.bedDepth + 0.25) }, { go: posAt(room.petBedX), d: room.bedDepth }]
                              : [{ act: "rest", frames: 6 }];
            return [{ act: "yawn", frames: 4 }].concat(bed, [{ act: "sleep", frames: rnd(20, 45) },
                    { act: "yawn", frames: 4 }, { act: "bow", frames: 4 }, { act: "shake", frames: 6 }]);
        });
        // Lying about, awake: looking around, the odd yawn.
        add(tired ? 4 : calm ? 2 : 0, function () {
            return [spot(0.4, 1), { act: "rest", frames: rnd(14, 26) }].concat(Math.random() < 0.5 ? [{ act: "yawn", frames: 4 }] : [],
                   [{ act: "bow", frames: 4 }]);
        });
        // A drink.
        add(po.room ? 2 : 0, function () { return approach(room.spots.water).concat([{ act: "eat", frames: 10, face: "left" }]); });
        // A snack from the bowl (always full), more often when hungry.
        add(po.needs && lv.food < 50 ? 5 : 1.5, function () {
            return approach(room.spots.bowl).concat([{ act: "eat", frames: rnd(12, 20), face: "left" }, { call: "snack" }]);
        });
        // A rummage in the toy basket.
        add(po.room && room.roomy ? 1 : 0, function () {
            return [{ go: posAt(room.basketX), d: 0.55 }, { act: "sniff", frames: 6 }, { act: "bow", frames: 4 }];
        });
        // Looking out of the window, and barking at whatever is out there.
        add(po.room ? (night ? 1 : 3) : 0, function () {
            var at = posAt(room.spots.window);
            return [{ go: at, d: 0.3 }, { go: at, d: 0 }, { act: "sit", frames: rnd(6, 10) }]
                .concat(night || Math.random() < 0.3 ? [] : [{ act: "bark", frames: rnd(6, 10), fx: "woof" }, { act: "wag", frames: 4 }]);
        });
        // A sniff around the room, nose to the floor.
        add(3, function () {
            var steps = [];
            for (var i = rnd(2, 3); i > 0; i--) steps.push(spot(0.1, 1), { act: "sniff", frames: rnd(4, 8) });
            return steps;
        });
        // An itch, then a shake.
        add(2, function () { return [{ act: "scratch", frames: rnd(10, 16) }, { act: "shake", frames: 4 }]; });
        // A good roll on the rug.
        add(calm ? 2 : 1, function () {
            return [spot(0.55, 0.85), { act: "roll", frames: rnd(10, 16) }, { act: "shake", frames: 4 }, { act: "wag", frames: 4 }];
        });
        // Over to say hi to you.
        add(2, function () {
            var d = 0.85 + Math.random() * 0.15;
            return [{ go: onFloor(posAt(0.3 + Math.random() * 0.4), d), d: d }, { act: Math.random() < 0.5 ? "beg" : "wag", frames: rnd(8, 12),
                      fx: Math.random() < 0.4 ? "hearts" : "" }];
        });
        // The zoomies: laps of the room and a spin.
        add(calm ? (tired ? 0 : 0.7) : 3, function () {
            var steps = [{ act: "bow", frames: 3 }];
            for (var i = rnd(3, 5); i > 0; i--) { var s = spot(0.05, 1); s.run = true; steps.push(s); }
            return steps.concat([{ act: "spin", frames: rnd(6, 10) }, { act: "wag", frames: 4 }]);
        });
        // Chasing its own tail.
        add(tired ? 0 : 1, function () { return [{ act: "spin", frames: rnd(8, 14) }, { act: "sit", frames: 4 }]; });
        // Playing on its own (more if a toy is lying about, or after a game).
        add(tired ? 0.5 : toyOut || excited ? 4 : 1.5, soloPlay);

        var total = 0;
        list.forEach(function (o) { total += o.w; });
        var x = Math.random() * total;
        for (var i = 0; i < list.length; i++) {
            x -= list[i].w;
            if (x < 0) return list[i].make();
        }
        return null;
    }

    // The mouse comes over: the pet comes to see you (now and then, and not
    // when it's busy with something, or fast asleep).
    function noticeYou(px) {
        if (job || place !== "home" || stage.width <= 0 || mood === "hot" || app.tick - noticedAt < 20) return;
        if (asleep && Math.random() < 0.7) return;
        noticedAt = app.tick;
        var d = 0.85 + Math.random() * 0.15;
        startPlan([{ go: onFloor(posAt(Math.max(0, Math.min(1, px / stage.width))), d), d: d, run: excited || mood !== "calm" },
                   { act: Math.random() < 0.6 ? "wag" : "beg", frames: 10 }]);
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
        case "feed":   // a treat: over to you, maybe a trick, sit pretty, catch it
            var d = 0.85 + Math.random() * 0.1, r = Math.random();
            var trick = r < 0.2 ? [{ act: "roll", frames: 8 }] : r < 0.4 ? [{ act: "spin", frames: 8 }]
                      : r < 0.55 ? [{ act: "bow", frames: 5 }] : [];
            return startPlan(home.concat([{ go: onFloor(posAt(0.35 + Math.random() * 0.3), d), d: d, run: true }], trick,
                                         [{ act: "beg", frames: 4 }, { call: "giveTreat" }, { act: "beg", frames: 2 },
                                          { act: "eat", frames: 12 }, { call: "treatGone" },
                                          { act: "wag", frames: 10, fx: "hearts" }]));
        case "bath":
            return startPlan(home.concat([{ go: posAt(room.spots.tub), d: 0.35 }, { go: posAt(room.spots.tub), d: 0 }, { call: "intoTub" },
                                          { act: "sit", frames: 22, fx: "bubbles" }, { call: "outOfTub" },
                                          { go: posAt(room.spots.tub), d: 0.55 },
                                          { act: "shake", frames: 14, fx: "drops" },
                                          { act: isCat ? "sit" : "wag", frames: 8, fx: "sparkles" }]));
        case "clean":
            return startPlan(home.concat([{ act: isCat ? "sit" : "wag", frames: 10, fx: "sparkles" }]));
        case "play":   // fetch: you throw, it brings it back, a few times over
            toy = ["ball", "bone", "duck"][Math.floor(Math.random() * 3)];
            roundsLeft = 3 + Math.floor(Math.random() * 3);
            return startPlan(home.concat([{ act: "bow", frames: 6 }, { call: "throwToy" },
                                          { act: "bow", frames: 2 }, { fetch: true }, { call: "fetchRound" }]));
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
        toyOut = false;      // the toy stays home
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
    // Treats: a dog biscuit, jerky, cheese or a fish (the cat's favorite).
    function giveTreat() {
        var kinds = isCat ? ["fish", "fish", "cheese", "jerky"] : ["biscuit", "biscuit", "jerky", "cheese", "fish"];
        treat = kinds[Math.floor(Math.random() * kinds.length)];
        treatDrop.restart();
    }
    function treatGone() { treat = ""; }
    // A snack from the bowl counts as a meal (written down only when it was
    // getting hungry, not every nibble).
    function snack() { if (po.needs && lv.food < 70) app.petAct("feed"); }
    function intoTub() { inTub = true; }
    function outOfTub() { inTub = false; }

    // ---- The toy: flies, bounces and rolls on its own, or rides in the mouth ----
    property bool toyOut: false
    property bool toyHeld: false
    property real toyX: 0.5              // its middle, as a fraction of the width
    property real toyD: 0.5              // depth, like the pet's
    property real toyZ: 0                // height off the floor, in pet pixels
    property real toyVX: 0
    property real toyVD: 0
    property real toyVZ: 0
    property int toyIdle: 0              // seconds lying about; it's put away after a while
    property int roundsLeft: 0
    property int soloLeft: 0
    readonly property bool toyMoving: toyOut && !toyHeld && (toyZ > 0 || toyVZ > 0 || toyVX !== 0 || toyVD !== 0)

    // Where the mouth is in the frame, facing left, as fractions [x, y].
    readonly property var mouth: isCat ? [0.2, 0.5]
        : ["walk", "run", "sniff", "eat", "pee"].indexOf(dogRow) >= 0 ? [0.19, dogRow === "sniff" || dogRow === "eat" ? 0.8 : 0.6]
        : [0.3, dogRow === "bow" ? 0.7 : 0.6]
    function mouthX() { return pet.x + stage.petW * (facingLeft ? mouth[0] : 1 - mouth[0]); }
    function mouthY() { return pet.y + stage.petH * mouth[1]; }

    // You throw it in from the front.
    function throwToy() {
        toyOut = true; toyHeld = false; toyIdle = 0;
        toyX = 0.3 + Math.random() * 0.4; toyD = 1; toyZ = 16;
        toyVX = (Math.random() - 0.5) * 0.07;
        toyVD = -(0.04 + Math.random() * 0.06);
        toyVZ = 3 + Math.random() * 4;
    }
    // Let go of it, right where the mouth is.
    function dropToy() {
        if (!toyHeld) return;
        toyHeld = false; toyIdle = 0;
        toyX = mouthX() / Math.max(1, stage.width);
        toyD = depth;
        toyZ = Math.max(0, (stage.footY(depth) - mouthY()) / stage.px - toyItem.height / stage.px / 2);
        toyVX = 0; toyVD = 0; toyVZ = 0;
    }
    // Flung up with a toss of the head: mostly the way it's facing.
    function tossToy() {
        dropToy();
        var dir = (facingLeft ? -1 : 1) * (Math.random() < 0.8 ? 1 : -1);
        toyVX = dir * (0.012 + Math.random() * 0.03);
        toyVD = (Math.random() - 0.5) * 0.09;
        toyVZ = 5 + Math.random() * 4;
    }
    // Pushed along the floor with the nose.
    function nudgeToy() {
        dropToy();
        toyVX = (facingLeft ? -1 : 1) * (0.02 + Math.random() * 0.025);
        toyVD = (Math.random() - 0.5) * 0.06;
    }
    function toyFromBasket() {
        toyOut = true; toyHeld = true; toyIdle = 0;
        toyVX = 0; toyVD = 0; toyVZ = 0; toyZ = 0;
    }
    function toyTick() {
        toyX += toyVX;
        toyD += toyVD;
        if (toyZ > 0 || toyVZ > 0) {         // in the air: falls, bounces lower each time
            toyZ += toyVZ;
            toyVZ -= 1.4;
            if (toyZ <= 0) {
                toyZ = 0;
                toyVZ = toyVZ < -3 ? -toyVZ * 0.45 : 0;
                toyVX *= 0.75; toyVD *= 0.75;
            }
        } else {                             // rolling: slows down
            toyVX *= 0.85; toyVD *= 0.85;
            if (Math.abs(toyVX) + Math.abs(toyVD) < 0.002) { toyVX = 0; toyVD = 0; }
        }
        // Off the walls (and the front edge).
        if (toyD < 0) { toyD = 0; toyVD = -toyVD * 0.6; }
        if (toyD > 1) { toyD = 1; toyVD = -toyVD * 0.6; }
        var y = stage.footY(toyD), half = toyItem.width / 2;
        var lo = (place === "home" && po.room ? room.floorLeft(y) : 0) + half;
        var hi = (place === "home" && po.room ? room.floorRight(y) : stage.width) - half;
        var w = Math.max(1, stage.width);
        if (toyX < lo / w) { toyX = lo / w; toyVX = Math.abs(toyVX) * 0.6; }
        if (toyX > hi / w) { toyX = hi / w; toyVX = -Math.abs(toyVX) * 0.6; }
    }
    // One step after the toy, wherever it is now; snaps it up once it's
    // low enough. Returns true when done (caught, or given up).
    function fetchStep() {
        if (!toyOut || toyHeld || --remaining <= 0) return true;
        var tp = toyX * stage.width, left = pet.x + stage.petW / 2 > tp;
        var x = posFor(tp - stage.petW * (left ? mouth[0] : 1 - mouth[0]));
        if (stepTo(x, toyD, true) && toyZ < 4) {
            facingLeft = left;
            toyHeld = true; toyIdle = 0;
            toyVX = 0; toyVD = 0; toyVZ = 0; toyZ = 0;
            return true;
        }
        return false;
    }

    // A round of fetch with you: back with the toy (mostly), then again.
    function fetchRound() {
        if (!toyHeld) return;                // lost it: game over
        var steps = [], r = Math.random();
        if (r < 0.2) {                       // keep-away: a lap of the room with it first
            for (var i = 0; i < 2; i++) {
                var d = 0.2 + Math.random() * 0.8;
                steps.push({ go: onFloor(Math.random(), d), d: d, run: true });
            }
        } else if (r < 0.35) {               // gives it a good shake
            steps.push({ act: "shake", frames: 8 });
        } else if (r < 0.5) {                // a little game of its own on the way
            steps.push({ call: "tossToy" }, { act: "bow", frames: 3 }, { fetch: true });
        }
        steps.push({ go: onFloor(posAt(0.3 + Math.random() * 0.4), 0.9), d: 0.9, run: Math.random() < 0.5 },
                   { call: "dropToy" });
        if (--roundsLeft > 0)
            steps.push({ act: Math.random() < 0.5 ? "beg" : "bow", frames: 6 }, { call: "throwToy" },
                       { act: "bow", frames: 2 }, { fetch: true }, { call: "fetchRound" });
        else
            steps.push({ act: "wag", frames: 14, fx: "hearts" }, { call: "donePlaying" });
        plan = steps.concat(plan);
    }
    function donePlaying() { playedAt = app.tick; }

    // Playing on its own: a toy from the basket (or the one lying about),
    // tossed, nudged and chased a few times, then left where it lands.
    function soloPlay() {
        soloLeft = 1 + Math.floor(Math.random() * 3);
        if (toyOut) return [{ fetch: true }, { call: "soloRound" }];
        toy = ["ball", "bone", "duck"][Math.floor(Math.random() * 3)];
        var b = po.room && room.roomy ? room.basketX : 0.15 + Math.random() * 0.7;
        return [{ go: posAt(b), d: 0.55 }, { act: "sniff", frames: 4 }, { call: "toyFromBasket" }, { call: "soloRound" }];
    }
    function soloRound() {
        var steps;
        if (!toyHeld || soloLeft-- <= 0) {
            dropToy();
            steps = [{ act: Math.random() < 0.5 ? "wag" : "sit", frames: 6 }];
        } else {
            var r = Math.random();
            steps = r < 0.45 ? [{ call: "tossToy" }, { act: "bow", frames: 3 }, { fetch: true }]
                  : r < 0.75 ? [{ act: "sniff", frames: 2 }, { call: "nudgeToy" }, { fetch: true }]
                  : [{ act: "shake", frames: 8 }, { call: "tossToy" }, { fetch: true }];
            steps.push({ call: "soloRound" });
        }
        plan = steps.concat(plan);
    }

    readonly property bool asleep: activity === "sleep"

    property int step: 0

    // ---- Animal friend, outside ----
    property string friendKind: "bird"
    property real friendPos: 0.7
    property real friendDepth: 0.5
    property bool friendLeft: true
    readonly property bool flies: friendKind === "bird" || friendKind === "butterfly"

    Timer {
        interval: tile.isCat ? (tile.activity === "run" ? 200 : tile.activity === "hot" ? 500 : 333)
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
            if (j && j.fetch) {                      // chasing the toy
                if (tile.fetchStep()) tile.runNext();
                return;
            }
            if (j && j.go !== undefined) {           // walking somewhere
                if (tile.stepTo(j.go, j.d === undefined ? tile.depth : j.d, j.run)) tile.runNext();
                return;
            }
            if (tile.wander) {                       // strolling about
                if (tile.stepTo(tile.wander.x, tile.wander.d, tile.activity !== "walk")) tile.pickActivity();
                return;
            }
            if (tile.isCat && tile.activity === "hot") tile.pos = Math.max(0, Math.min(1, tile.pos + (tile.facingLeft ? -0.008 : 0.008)));
            if (--tile.remaining <= 0) {
                if (j) tile.runNext(); else tile.pickActivity();
            }
        }
    }
    // The toy in flight: a smoother step than the pet's, only while it moves.
    Timer {
        interval: 80
        running: tile.toyMoving && tile.visible && !app.editing
        repeat: true
        onTriggered: tile.toyTick()
    }
    // Asleep: breathe and drift the Zzz on the shared tick; wake when rested.
    // A toy left lying about for a few minutes is put away.
    Connections {
        target: app
        function onTickChanged() {
            if (tile.toyOut && !tile.toyHeld && !tile.job && ++tile.toyIdle > 180) tile.toyOut = false;
            var a = tile.activity;
            var e = tile.energy + (a === "sleep" ? 0.012 : a === "rest" ? 0.003
                                   : a === "run" || a === "spin" || a === "ball" ? -0.004 : -0.0012)
                                - (stage.sky && stage.sky.dark ? 0.0008 : 0);
            tile.energy = Math.max(0, Math.min(1, e));
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

    HoverHandler {
        id: hover
        onHoveredChanged: if (hovered) tile.noticeYou(point.position.x)
    }

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
            visible: !tile.po.room && tile.place === "home" && tile.activity === "eat" && tile.treat === ""
            name: "bowl_full"
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
            name: water ? "water" : "bowl_full"
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

        // The toy: in the mouth, or loose on the floor with a shadow under it.
        Rectangle {
            visible: toyItem.visible && !tile.toyHeld
            readonly property real k: Math.max(0.3, 1 - tile.toyZ / 30)
            width: toyItem.width * k; height: stage.px * 1.5; radius: height / 2
            x: tile.toyX * stage.width - width / 2
            y: stage.footY(tile.toyD) - height * 0.6
            color: Qt.rgba(0, 0, 0, 0.25 * k)
            z: 1 + tile.toyD - 0.001
        }
        Prop {
            id: toyItem
            visible: tile.toyOut && tile.place === "home"
            name: tile.toy
            px: stage.px
            x: (tile.toyHeld ? tile.mouthX() : tile.toyX * stage.width) - width / 2
            y: tile.toyHeld ? tile.mouthY() - height / 2 : stage.footY(tile.toyD) - height - tile.toyZ * stage.px
            z: tile.toyHeld ? pet.z + 0.01 : 1 + tile.toyD
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
                && Math.abs(tile.depth - room.bedDepth) < 0.05 && Math.abs(tile.pos - tile.posAt(room.petBedX)) < 0.03
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

        // A treat: dropped from above (your hand), caught, then chewed.
        Prop {
            visible: tile.treat !== "" && tile.place === "home"
            name: tile.treat || "biscuit"
            px: stage.px
            x: tile.mouthX() - width / 2
            y: -height + (tile.mouthY() - height / 2 + height) * tile.treatFall
            z: pet.z + 0.02
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

        // Woof! at the window.
        PlasmaComponents.Label {
            textFormat: Text.PlainText
            visible: tile.fx === "woof" && tile.activity === "bark" && tile.step % 4 >= 1
            text: i18n("woof!")
            x: pet.x + stage.petW * (tile.step % 8 < 4 ? 0.0 : 0.4)
            y: pet.y - height * 0.6
            color: tile.accent
            font.pixelSize: stage.px * 4
            font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
            font.weight: Font.Bold
            z: 5
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
