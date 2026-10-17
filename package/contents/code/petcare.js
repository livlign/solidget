.pragma library

// The desk pet's needs. All times are seconds since 1970.
//
// Each need is worked out from when it was last looked after, so nothing is
// counted or saved every second: food runs out over 8 hours, fun over 5,
// a bath lasts 3 days, and the pet needs to go out every 6 hours. Skip the
// walk and there's an accident: a puddle, or a poop a few hours after a
// meal. Time stops while the PC is off (someone else looked after it).

var HOUR = 3600;
var TIMES = ["fed", "washed", "played", "petted", "relieved", "seen"];
var MAX_MESS = 3;

function fresh(now) {
    return { fed: now, washed: now, played: now, petted: now, relieved: now, seen: now, poops: 0, puddles: 0 };
}

// From the config text; anything odd is replaced by a sensible value.
function parse(text, now) {
    var s = fresh(now), d = null;
    try { d = JSON.parse(text || "{}"); } catch (e) { d = null; }
    if (!d || typeof d !== "object") return s;
    TIMES.forEach(function (f) {
        var v = Number(d[f]);
        if (isFinite(v) && v > 0 && v <= now + 60) s[f] = v;
    });
    ["poops", "puddles"].forEach(function (f) {
        var v = Math.floor(Number(d[f]));
        if (isFinite(v)) s[f] = Math.max(0, Math.min(MAX_MESS, v));
    });
    return s;
}

function serialize(s) {
    var out = {};
    TIMES.forEach(function (f) { out[f] = Math.round(s[f]); });
    out.poops = s.poops;
    out.puddles = s.puddles;
    return JSON.stringify(out);
}

function copy(s) {
    var c = {};
    Object.keys(s).forEach(function (k) { c[k] = s[k]; });
    return c;
}

// The PC was off (or the widget away) for a while: move every clock forward
// by the gap so the pet comes back as it was left.
function resume(s, now) {
    s = copy(s);
    var gap = now - s.seen;
    if (gap > 15 * 60) {
        TIMES.forEach(function (f) { if (f !== "seen") s[f] = Math.min(now, s[f] + gap); });
    }
    s.seen = now;
    return s;
}

function clamp(v) { return Math.max(0, Math.min(100, Math.round(v))); }

// 0..100 each; potty is how badly it needs to go out (100 = can't hold it).
function levels(s, now) {
    var mess = s.poops + s.puddles;
    return {
        food: clamp(100 - (now - s.fed) / (8 * HOUR) * 100),
        fun: clamp(100 - (now - Math.max(s.played, s.petted)) / (5 * HOUR) * 100),
        clean: clamp(100 - (now - s.washed) / (72 * HOUR) * 100 - mess * 15),
        potty: clamp((now - s.relieved) / (6 * HOUR) * 100)
    };
}

// Accidents. Returns [new state, "puddle" | "poop" | ""].
function step(s, now) {
    s = copy(s);
    if (now - s.relieved >= 6 * HOUR) {
        s.puddles = Math.min(MAX_MESS, s.puddles + 1);
        s.relieved = now;
        return [s, "puddle"];
    }
    if (s.fed > s.relieved && now - s.fed >= 3 * HOUR) {
        s.poops = Math.min(MAX_MESS, s.poops + 1);
        s.relieved = now;
        return [s, "poop"];
    }
    return [s, ""];
}

var ACTIONS = ["pet", "feed", "bath", "clean", "walk", "play"];

function act(s, what, now) {
    s = copy(s);
    switch (what) {
    case "feed":  s.fed = now; break;
    case "pet":   s.petted = now; break;
    case "play":  s.played = now; break;
    case "bath":  s.washed = now; break;
    case "clean": s.poops = 0; s.puddles = 0; break;
    case "walk":  s.relieved = now; s.played = now; break;
    }
    s.seen = now;
    return s;
}

// What the pet wants most right now, as an action name, or "".
function wish(lv, s) {
    if (s.poops + s.puddles > 0) return "clean";
    if (lv.potty >= 80) return "walk";
    if (lv.food <= 25) return "feed";
    if (lv.clean <= 25) return "bath";
    if (lv.fun <= 25) return "play";
    return "";
}

function happiness(lv) {
    return clamp((lv.food + lv.fun + lv.clean + (100 - lv.potty)) / 4);
}
