.pragma library

// The sky for a time of day: colors, where the sun is, how many stars show.
// Times are minutes after midnight. Sunrise and sunset come from the weather
// (the tile's own location); without it, 6:30 and 18:30.

var KEYS = {
    night: ["#070b1f", "#1b2450"],
    dawn:  ["#33306e", "#f39a6b"],
    day:   ["#3d8fe0", "#b9defc"],
    dusk:  ["#3b2a6b", "#ff8a5c"]
};

function hexToRgb(hex) {
    var n = parseInt(hex.slice(1), 16);
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

function mix(a, b, t) {
    t = Math.max(0, Math.min(1, t));
    var x = hexToRgb(a), y = hexToRgb(b);
    var out = [0, 1, 2].map(function (i) { return Math.round(x[i] + (y[i] - x[i]) * t); });
    return "#" + ((1 << 24) | (out[0] << 16) | (out[1] << 8) | out[2]).toString(16).slice(1);
}

function mixPair(a, b, t) { return [mix(a[0], b[0], t), mix(a[1], b[1], t)]; }

// "2026-10-15T06:10" -> 370; anything else -> fallback.
function minutesOf(iso, fallback) {
    var m = /T(\d\d):(\d\d)/.exec(iso || "");
    return m ? parseInt(m[1], 10) * 60 + parseInt(m[2], 10) : fallback;
}

function at(now, rise, set) {
    if (!(rise > 0 && set > rise)) { rise = 390; set = 1110; }
    var colors, phase;
    var dawnStart = rise - 45, dawnEnd = rise + 40, duskStart = set - 40, duskEnd = set + 45;
    if (now < dawnStart || now >= duskEnd) {
        colors = KEYS.night; phase = "night";
    } else if (now < rise) {
        colors = mixPair(KEYS.night, KEYS.dawn, (now - dawnStart) / 45); phase = "dawn";
    } else if (now < dawnEnd) {
        colors = mixPair(KEYS.dawn, KEYS.day, (now - rise) / 40); phase = "dawn";
    } else if (now < duskStart) {
        colors = KEYS.day; phase = "day";
    } else if (now < set) {
        colors = mixPair(KEYS.day, KEYS.dusk, (now - duskStart) / 40); phase = "dusk";
    } else {
        colors = mixPair(KEYS.dusk, KEYS.night, (now - set) / 45); phase = "dusk";
    }
    // Sun: 0..1 across the sky between sunrise and sunset, on an arc.
    var sunT = (now - rise) / (set - rise);
    // Moon: across the night, sunset to the next sunrise.
    var nightLen = 1440 - (set - rise);
    var moonT = ((now - set + 1440) % 1440) / nightLen;
    var stars = phase === "night" ? 1 : phase === "day" ? 0
              : now < rise ? Math.max(0, (rise - now) / 45) : Math.max(0, (now - set) / 45);
    return {
        top: colors[0], bottom: colors[1], phase: phase,
        sun: { t: sunT, up: sunT > -0.03 && sunT < 1.03, height: Math.sin(Math.max(0, Math.min(1, sunT)) * Math.PI) },
        moon: { t: moonT, up: moonT >= 0 && moonT <= 1, height: Math.sin(Math.max(0, Math.min(1, moonT)) * Math.PI) },
        stars: Math.min(1, stars),
        dark: phase === "night" || (phase !== "day" && stars > 0.5)
    };
}

// Moon phase, 0 = new, 0.5 = full, from a known new moon (6 Jan 2000).
function moonPhase(date) {
    var days = (date.getTime() - Date.UTC(2000, 0, 6, 18, 14)) / 86400000;
    var p = (days / 29.530588853) % 1;
    return p < 0 ? p + 1 : p;
}

// Same "random" spots every time, so stars don't jump between redraws.
function scatter(n, seed) {
    var out = [], s = seed || 7;
    function rnd() { s = (s * 16807) % 2147483647; return (s - 1) / 2147483646; }
    for (var i = 0; i < n; i++) out.push({ x: rnd(), y: rnd(), size: rnd(), phase: Math.floor(rnd() * 5) });
    return out;
}
