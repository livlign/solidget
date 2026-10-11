.pragma library

// Aurora palette: each tile owns a two-stop gradient. Hues are fixed (not
// taken from the Plasma accent) so the dashboard reads as one designed piece.
var ACCENTS = {
    clock:     ["#c7d2fe", "#818cf8"],
    specs:     ["#818cf8", "#c084fc"],
    cpu:       ["#38bdf8", "#6366f1"],
    gpu:       ["#34d399", "#06b6d4"],
    memory:    ["#c084fc", "#818cf8"],
    temps:     ["#22d3ee", "#f59e0b"],
    network:   ["#38bdf8", "#f472b6"],
    disk:      ["#2dd4bf", "#3b82f6"],
    battery:   ["#4ade80", "#22c55e"],
    cores:     ["#38bdf8", "#f43f5e"],
    processes: ["#f472b6", "#a78bfa"],
    power:     ["#fbbf24", "#f97316"],
    pet:       ["#fb923c", "#f472b6"],
    photo:     ["#e0e7ff", "#a5b4fc"],
    media:     ["#f472b6", "#a78bfa"],
    calendar:  ["#34d399", "#38bdf8"],
    quote:     ["#c4b5fd", "#f0abfc"],
    note:      ["#fde047", "#fb923c"],
    worldclock:["#38bdf8", "#818cf8"],
    focus:     ["#f43f5e", "#fb923c"]
};

var VENDOR = { amd: "#ef4444", intel: "#3b82f6", nvidia: "#84cc16", apple: "#a3a3a3" };

function accent(id) { return (ACCENTS[id] || ACCENTS.cpu)[0]; }
function accent2(id) { return (ACCENTS[id] || ACCENTS.cpu)[1]; }

function hexToRgb(hex) {
    var n = parseInt(hex.slice(1), 16);
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

function mix(a, b, t) {
    var x = hexToRgb(a), y = hexToRgb(b);
    function ch(i) { return Math.round(x[i] + (y[i] - x[i]) * t); }
    return "#" + ((1 << 24) | (ch(0) << 16) | (ch(1) << 8) | ch(2)).toString(16).slice(1);
}

// Cool -> warm -> hot ramp for temperatures and core load (t in 0..1).
var HEAT = ["#22d3ee", "#38bdf8", "#a3e635", "#facc15", "#f97316", "#ef4444"];
function heat(t) {
    t = Math.max(0, Math.min(1, t || 0));
    var pos = t * (HEAT.length - 1);
    var i = Math.min(Math.floor(pos), HEAT.length - 2);
    return mix(HEAT[i], HEAT[i + 1], pos - i);
}

// Temperature in °C to 0..1 for the heat ramp (35 cool, 90 hot).
function tempLevel(c) {
    return Math.max(0, Math.min(1, ((c || 0) - 35) / 55));
}

// ---- Styles: shape and material (no colors) --------------------------------
// radius is in grid units; bodyAlpha null = the theme's default opacity.
var STYLES = {
    // native: draw the card with the Plasma Style's own SVG and take every
    // color from the system (accent for meters, semantic colors for heat).
    plasma: { name: "Plasma", hint: "Matches your Plasma Style and colors", plasmaFrame: true,
              radius: 0.3, bodyAlpha: 1.0, tint: 0, glow: false, shadow: false, hardShadow: false, bevel: false,
              border: 0, highlight: false, roundCaps: false, font: "", meter: "ring", chart: "line" },
    // tint: how much of the tile's own color tints its card (0..1).
    // font: "" = system, "pixel" = bundled Silkscreen (numbers and titles).
    // meter: "ring" or "blocks"; chart: "line" or "bars".
    glass: { name: "Glass", hint: "Frosted cards with soft glows",
             radius: 1.2, bodyAlpha: null, tint: 0, glow: true, shadow: true, hardShadow: false, bevel: false,
             border: 1, highlight: true, roundCaps: true, font: "", meter: "ring", chart: "line" },
    flat:  { name: "Flat", hint: "Sharp, solid tiles in their own colors, no effects",
             radius: 0, bodyAlpha: 0.97, tint: 0.2, glow: false, shadow: false, hardShadow: false, bevel: false,
             border: 0, highlight: false, roundCaps: false, font: "", meter: "ring", chart: "line" },
    clear: { name: "Clear", hint: "Barely-there cards that let the wallpaper through",
             // Light themes put dark text on the card, so it must stay fairly
             // opaque to stay readable over dark wallpapers.
             radius: 1.5, bodyAlpha: { dark: 0.32, light: 0.62 }, tint: 0, glow: false, shadow: false, hardShadow: false, bevel: false,
             border: 1, highlight: true, roundCaps: true, font: "", meter: "ring", chart: "line" },
    pixel: { name: "Pixel", hint: "Chunky blocks, bevels and a pixel font, like a voxel game",
             radius: 0, bodyAlpha: 1.0, tint: 0.12, glow: false, shadow: false, hardShadow: true, bevel: true,
             border: 0, highlight: false, roundCaps: false, font: "pixel", meter: "blocks", chart: "bars" }
};
var STYLE_ORDER = ["plasma", "glass", "flat", "clear", "pixel"];

// ---- Themes: colors only ------------------------------------------------------
// body/text null = follow Plasma. palette = six hues the tiles draw from;
// null = the hand-tuned Aurora pairs above ("plasma" builds one from the
// system accent instead, see plasmaPalette). heat = [cool, hot] override.
var THEMES = {
    plasma:    { name: "Follow Plasma", dark: null,  body: null,      text: null,      palette: null },
    aurora:    { name: "Aurora",        dark: true,  body: "#11141f", text: "#e8ecf8", palette: null },
    glacier:   { name: "Glacier Mint",  dark: false, body: "#eef8f7", text: "#12302e",
                 palette: ["#0d9488", "#16a34a", "#0284c7", "#0891b2", "#65a30d", "#0e7490"] },
    sandstone: { name: "Sandstone",     dark: false, body: "#faf3e8", text: "#3a2c1e",
                 palette: ["#c2410c", "#b45309", "#a16207", "#be123c", "#4d7c0f", "#9a3412"] },
    ember:     { name: "Ember Dusk",    dark: true,  body: "#1b1311", text: "#f6e7dd",
                 palette: ["#fb923c", "#f43f5e", "#fbbf24", "#f97316", "#e11d48", "#fde68a"] },
    lagoon:    { name: "Deep Lagoon",   dark: true,  body: "#06191d", text: "#d6f2ef",
                 palette: ["#22d3ee", "#2dd4bf", "#38bdf8", "#5eead4", "#0ea5e9", "#a7f3d0"] },
    plum:      { name: "Plum Velvet",   dark: true,  body: "#190f22", text: "#f2e7f8",
                 palette: ["#e879f9", "#c084fc", "#f472b6", "#a78bfa", "#fb7185", "#f5d0fe"] },
    moss:      { name: "Moss Lantern",  dark: true,  body: "#0d140d", text: "#dfeccb",
                 palette: ["#a3e635", "#facc15", "#84cc16", "#fbbf24", "#4ade80", "#d9f99d"] },
    ink:       { name: "Ink & Paper",   dark: false, body: "#f7f7f2", text: "#141414",
                 palette: ["#141414", "#5c5c5c", "#2e2e2e", "#7a7a7a", "#404040", "#9a9a9a"], heat: ["#c8c8c8", "#141414"], mono: true },
    lotus:     { name: "Lotus Pond",    dark: false, body: "#fcf1f4", text: "#3b1d2a",
                 palette: ["#db2777", "#16a34a", "#be185d", "#15803d", "#e11d48", "#22c55e"] }
};
var THEME_ORDER = ["plasma", "aurora", "glacier", "sandstone", "ember", "lagoon", "plum", "moss", "ink", "lotus"];

// Which palette hue each tile uses (its second color is two steps along).
var TILE_HUE = { cpu: 0, gpu: 1, memory: 2, network: 0, disk: 3, battery: 1, clock: 5,
                 specs: 2, processes: 3, power: 4, cores: 0, temps: 4,
                 pet: 4, photo: 5, media: 3, calendar: 1, quote: 2, note: 5, worldclock: 0, focus: 4 };

// Follow Plasma: six hues spread around the system accent color, made
// lighter on dark backgrounds and deeper on light ones so they stay readable.
var PLASMA_SPREAD = [0, 130, 45, -45, 180, 90];
function plasmaPalette(accentHex, dark) {
    var c = hexToRgb(/^#[0-9a-f]{6}$/i.test(accentHex || "") ? accentHex : "#3daee9");
    var r = c[0] / 255, g = c[1] / 255, b = c[2] / 255;
    var max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min, h = 0;
    if (d > 0) {
        h = max === r ? ((g - b) / d) % 6 : max === g ? (b - r) / d + 2 : (r - g) / d + 4;
        h *= 60;
    }
    var l = (max + min) / 2;
    var s = d === 0 ? 0 : d / (1 - Math.abs(2 * l - 1));
    s = Math.max(0.55, Math.min(0.85, s));     // a grey accent still gives colors
    l = dark ? 0.64 : 0.42;
    return PLASMA_SPREAD.map(function (off) { return hsl((h + off + 360) % 360, s, l); });
}
function hsl(h, s, l) {
    var k = function (n) { return (n + h / 30) % 12; };
    var a = s * Math.min(l, 1 - l);
    var f = function (n) { return Math.round(255 * (l - a * Math.max(-1, Math.min(k(n) - 3, 9 - k(n), 1)))); };
    return "#" + ((1 << 24) | (f(0) << 16) | (f(8) << 8) | f(4)).toString(16).slice(1);
}

// plasma = the palette from plasmaPalette(), used by the "plasma" theme.
function accentPair(themeId, id, plasma) {
    var t = THEMES[themeId];
    var p = t && (t.palette || (themeId === "plasma" ? plasma : null));
    if (!p) return ACCENTS[id] || ACCENTS.cpu;
    if (id === "network") return [p[0], p[3]];   // download / upload must differ
    var i = TILE_HUE[id] || 0;
    return [p[i % p.length], p[(i + 2) % p.length]];
}

// dark: whether the board is dark, for themes that follow Plasma.
function heatFor(themeId, t, dark) {
    var th = THEMES[themeId];
    if (th && th.heat) return mix(th.heat[0], th.heat[1], Math.max(0, Math.min(1, t || 0)));
    // Yellows and cyans wash out on light cards; deepen them there.
    if (th && (th.dark === false || (th.dark === null && dark === false))) return mix(heat(t), "#000000", 0.28);
    return heat(t);
}

// Brand colors on the specs card, except in monochrome themes.
function vendorColor(themeId, vendor) {
    var th = THEMES[themeId];
    if (th && th.mono) return "";
    return VENDOR[vendor] || "";
}

// ---- Looks: one click sets a style and a theme --------------------------------
var LOOKS = [
    { name: "Plasma",         style: "plasma", theme: "plasma" },
    { name: "Aurora Glass",   style: "glass", theme: "aurora" },
    { name: "Retro Terminal", style: "pixel", theme: "moss" },
    { name: "Paper",          style: "flat",  theme: "ink" },
    { name: "Frost",          style: "clear", theme: "glacier" },
    { name: "Campfire",       style: "glass", theme: "ember" },
    { name: "Reef",           style: "flat",  theme: "lagoon" }
];

// ---- Native (Plasma style) colors ---------------------------------------------
// Every tile wears the system accent; network (down/up) and disk
// (read/write) chart two series, so they get a second color.
function nativePair(id, accentHex, secondHex) {
    return id === "network" || id === "disk" ? [accentHex, secondHex] : [accentHex, accentHex];
}
// Heat follows Plasma's semantic colors: positive -> neutral -> negative.
// It stays positive while things are fine (below 70 °C, the Temperatures
// tile's "Warm"), so a "Cool" reading is never painted as a warning.
function nativeHeat(t, positive, neutral, negative) {
    t = Math.max(0, Math.min(1, t || 0));
    if (t < 0.6) return positive;
    if (t < 0.8) return mix(positive, neutral, (t - 0.6) / 0.2);
    return mix(neutral, negative, (t - 0.8) / 0.2);
}
