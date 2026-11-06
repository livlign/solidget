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
    focus:     ["#f43f5e", "#fb923c"],
    uptime:    ["#38bdf8", "#a78bfa"],
    bluetooth: ["#60a5fa", "#818cf8"],
    health:    ["#4ade80", "#2dd4bf"]
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
// tint: how much of the tile's own color tints its card (0..1).
// font: "" = system, "pixel" = bundled Silkscreen (numbers and titles).
// figures: a bundled font for numbers and titles: "mono" (JetBrains Mono)
// or "round" (Manrope).
// figureWeight: big numbers "hairline", "thin", "light", "regular", "semi",
// "bold" or "heavy".
//
// Each style is also a recipe for how tiles lay themselves out:
//   header:  "native" (Plasma), "caps" (spaced capitals), "rule" (capitals over
//            a dashed line), "plain" (bold beside a color chip), "bar" (a thick
//            ink rule on top of the card), "quiet" (small, no mark)
//   gauge:   CPU/GPU/Memory/Disk: "ring" (a dial) or "bar" / "hp" (a big
//            number over a bar; "hp" = segmented like a game's health bar)
//   meter:   the dial: "ring", "thick", "hairline", "ticks" or "blocks"
//   chart:   "line", "area", "grid", "columns", "rounded" or "bars" (Pixel)
//   details: label/value rows: "rows", "ruled", "readout" (dotted leader),
//            "chips" (rounded tags) or "caps"
//   heatBar: temperature bars: "thin", "glow", "square", "hairline",
//            "needle", "pill" or "segments"
//   controls: media buttons: "native", "round", "keys", "squircle", "outline"
//   today:   the calendar's today: "frame", "circle", "block", "rounded", "outline"
//   spotlight: tiles drawn apart from the rest, by tile id: "ink" (inverted),
//            "fill" (solid tile color), "bare" (no card), "inset" (an
//            ordinary card; the clock's weather gets a card of its own color),
//            "art" (over the blurred album art), "pixelart" (cover redrawn
//            in big pixels)
var STYLES = {
    // native: draw the card with the Plasma Style's own SVG and take every
    // color from the system (accent for meters, semantic colors for heat).
    plasma: { name: "Plasma", hint: "Matches your Plasma Style and colors, like KDE's own widgets", plasmaFrame: true,
              radius: 0.3, bodyAlpha: 1.0, tint: 0, glow: false, shadow: false, hardShadow: false, bevel: false,
              border: 0, highlight: false, roundCaps: true, font: "", figureWeight: "light",
              header: "native", gauge: "bar", meter: "ring", chart: "area", details: "rows", heatBar: "thin",
              controls: "native", today: "frame", spotlight: {} },
    glass: { name: "Glass", hint: "Frosted cards with soft glows",
             radius: 1.2, bodyAlpha: null, tint: 0, glow: true, shadow: true, hardShadow: false, bevel: false,
             border: 1, highlight: true, roundCaps: true, font: "", figureWeight: "thin",
             header: "caps", gauge: "ring", meter: "ring", chart: "area", details: "rows", heatBar: "glow",
             controls: "round", today: "circle", spotlight: { media: "art" } },
    flat:  { name: "Flat", hint: "A printed poster: solid tiles, huge bold numbers, square bars",
             radius: 0, bodyAlpha: 0.97, tint: 0.2, glow: false, shadow: false, hardShadow: false, bevel: false,
             border: 0, highlight: false, roundCaps: false, font: "", figureWeight: "bold",
             header: "bar", gauge: "bar", meter: "ring", chart: "columns", details: "ruled", heatBar: "square",
             controls: "keys", today: "block", spotlight: { media: "ink" } },
    clear: { name: "Clear", hint: "Barely-there panes; the clock sits right on your wallpaper",
             // Light themes put dark text on the card, so it must stay mostly
             // opaque: thinner, a dark wallpaper turns it a muddy grey.
             radius: 1.5, bodyAlpha: { dark: 0.32, light: 0.9 }, tint: 0, glow: false, shadow: false, hardShadow: false, bevel: false,
             border: 1, highlight: true, roundCaps: true, font: "", figureWeight: "hairline",
             header: "quiet", gauge: "ring", meter: "hairline", chart: "line", details: "rows", heatBar: "hairline",
             controls: "outline", today: "outline", spotlight: { clock: "bare" } },
    pixel: { name: "Pixel", hint: "A game HUD: chunky blocks, health bars and a pixel font",
             radius: 0, bodyAlpha: 1.0, tint: 0.12, glow: false, shadow: false, hardShadow: true, bevel: true,
             border: 0, highlight: false, roundCaps: false, font: "pixel", figureWeight: "light",
             header: "caps", gauge: "hp", meter: "blocks", chart: "bars", details: "caps", heatBar: "segments",
             controls: "keys", today: "block", spotlight: { media: "pixelart" } },
    instrument: { name: "Instrument", hint: "Hairline panels, monospaced readouts and tick-mark dials, like test gear",
             radius: 0.3, bodyAlpha: 1.0, tint: 0, glow: false, shadow: false, hardShadow: false, bevel: false,
             border: 1, highlight: false, roundCaps: false, font: "", figures: "mono", figureWeight: "light",
             header: "rule", gauge: "ring", meter: "ticks", chart: "grid", details: "readout", heatBar: "needle",
             controls: "keys", today: "block", spotlight: {} },
    bento: { name: "Bento", hint: "Soft, rounded pastel cards with big bold numbers",
             radius: 1.9, bodyAlpha: 1.0, tint: 0.16, glow: false, shadow: true, hardShadow: false, bevel: false,
             border: 0, highlight: false, roundCaps: true, font: "", figures: "round", figureWeight: "semi",
             header: "plain", gauge: "bar", ringTiles: ["gpu", "disk"], meter: "thick", chart: "rounded", details: "chips", heatBar: "pill",
             controls: "squircle", today: "rounded", spotlight: { clock: "inset", power: "fill" } },
    // edge: "neon" = a glowing outline in the tile's own color.
    neon:  { name: "Neon", hint: "Dark panes outlined in glowing light, like signs at night",
             radius: 0.8, bodyAlpha: { dark: 0.5, light: 0.75 }, tint: 0, glow: false, shadow: false, hardShadow: false, bevel: false,
             border: 0, highlight: false, roundCaps: true, font: "", figureWeight: "thin", edge: "neon",
             header: "caps", gauge: "ring", meter: "ring", chart: "area", details: "rows", heatBar: "glow",
             controls: "outline", today: "outline", spotlight: {} },
    // raised: lit from the top left, a light edge above and a shade below,
    // as if pressed up out of the board.
    soft:  { name: "Soft", hint: "Raised cards lit from the top left, like soft clay",
             radius: 1.4, bodyAlpha: 1.0, tint: 0.05, glow: false, shadow: false, hardShadow: false, bevel: false,
             border: 0, highlight: false, roundCaps: true, font: "", figureWeight: "light", raised: true,
             header: "quiet", gauge: "ring", meter: "thick", chart: "area", details: "rows", heatBar: "pill",
             controls: "squircle", today: "rounded", spotlight: {} },
    // inkBorder: a thick border in the text color.
    brutal: { name: "Brutal", hint: "Thick ink borders, hard shadows and loud color blocks",
             radius: 0, bodyAlpha: 1.0, tint: 0.4, glow: false, shadow: false, hardShadow: true, bevel: false,
             border: 3, inkBorder: true, highlight: false, roundCaps: false, font: "", figureWeight: "bold",
             header: "plain", gauge: "bar", meter: "ring", chart: "columns", details: "ruled", heatBar: "square",
             controls: "keys", today: "block", spotlight: { clock: "fill" } }
};
var STYLE_ORDER = ["plasma", "glass", "flat", "clear", "pixel", "instrument", "bento", "neon", "soft", "brutal"];

// ---- Themes: colors only ------------------------------------------------------
// body/text null = follow Plasma. palette = six hues the tiles draw from;
// null = the hand-tuned Aurora pairs above ("plasma" builds one from the
// system accent instead, see plasmaPalette). heat = [cool, hot] override.
// opaque = solid tiles in every style (crisp, nothing shows through);
// rgb = a rainbow rim that sweeps across the board; edge = a hairline
// around each tile, so solid tiles stay apart on any wallpaper.
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
                 palette: ["#db2777", "#16a34a", "#be185d", "#15803d", "#e11d48", "#22c55e"] },
    snow:      { name: "Snow",          dark: false, body: "#ffffff", text: "#0b1220", opaque: true, edge: "#dfe4ec",
                 palette: ["#2563eb", "#16a34a", "#db2777", "#ea580c", "#7c3aed", "#0891b2"] },
    midnight:  { name: "Midnight",      dark: true,  body: "#0d1117", text: "#e6edf3", opaque: true, edge: "#262d38",
                 palette: ["#60a5fa", "#34d399", "#f472b6", "#fbbf24", "#a78bfa", "#22d3ee"] },
    rgb:       { name: "RGB",           dark: true,  body: "#07070b", text: "#f5f7fa", opaque: true, rgb: true,
                 palette: ["#00e5ff", "#22ff88", "#ff2d95", "#ffcc00", "#a855f7", "#ff7a00"] },
    // Amber readouts on graphite, like a lab meter; cool blue only for a
    // second trace (upload, a tile's second color).
    peach:     { name: "Peach Sorbet",  dark: false, body: "#fff3eb", text: "#3d2418",
                 palette: ["#ea580c", "#db2777", "#d97706", "#e11d48", "#65a30d", "#c2410c"] },
    sky:       { name: "Sky Paper",     dark: false, body: "#f1f6ff", text: "#13233d",
                 palette: ["#2563eb", "#0891b2", "#4f46e5", "#0284c7", "#059669", "#7c3aed"] },
    matcha:    { name: "Matcha",        dark: false, body: "#f1f5e9", text: "#1f2d16",
                 palette: ["#4d7c0f", "#0f766e", "#65a30d", "#a16207", "#15803d", "#3f6212"] },
    lavender:  { name: "Lavender Mist", dark: false, body: "#f5f1fc", text: "#2a1f45",
                 palette: ["#7c3aed", "#c026d3", "#6366f1", "#db2777", "#0891b2", "#9333ea"] },
    nightfall: { name: "Nightfall",     dark: true,  body: "#111a2e", text: "#e3ebfa",
                 palette: ["#7dd3fc", "#a5b4fc", "#60a5fa", "#93c5fd", "#c4b5fd", "#67e8f9"] },
    espresso:  { name: "Espresso",      dark: true,  body: "#1c1512", text: "#f3e6da",
                 palette: ["#d6a77a", "#f0c48b", "#c08457", "#e9b384", "#a3b18a", "#f5d6b4"] },
    sakura:    { name: "Sakura Night",  dark: true,  body: "#1e1219", text: "#fbe7ef",
                 palette: ["#f9a8d4", "#fda4af", "#f472b6", "#c4b5fd", "#fbcfe8", "#f0abfc"] },
    arcade:    { name: "Neon Arcade",   dark: true,  body: "#0b0820", text: "#eef0ff",
                 palette: ["#22e5ff", "#ff3df2", "#7cff6b", "#ffe14d", "#a06bff", "#ff8a3d"] },
    graphite:  { name: "Graphite Amber", dark: true, body: "#111418", text: "#e6e9ed", opaque: true, edge: "#262b33",
                 palette: ["#ffb547", "#e9c891", "#ffa05c", "#7dd3fc", "#f2d39b", "#c9d1db"] },
    // Clear inks on white; the Bento style tints each card to a pastel.
    oat:       { name: "Oat Milk",      dark: false, body: "#fffdf9", text: "#2b2622",
                 palette: ["#3b5bdb", "#0c8599", "#7048e8", "#d6336c", "#e8590c", "#b08900"] }
};
// Themes and looks go from the lightest card to the darkest. Follow Plasma
// has no color of its own: it sorts by the system's (see byLightness), and
// comes first where that isn't known.
// Text for a card of this color: near-black or white, whichever stands
// out more (WCAG contrast; by eye, yellow takes black and teal takes black).
function inkOn(hex) {
    var l = luminance(/^#[0-9a-f]{6}$/i.test(hex || "") ? hex : "#808080");
    return (l + 0.05) / (luminance("#1d1a17") + 0.05) > 1.05 / (l + 0.05) ? "#1d1a17" : "#ffffff";
}
function luminance(hex) {
    var c = hexToRgb(hex).map(function (v) {
        v /= 255;
        return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    });
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
}
var THEME_ORDER = ["plasma"].concat(Object.keys(THEMES).filter(function (k) { return k !== "plasma"; })
    .sort(function (a, b) { return luminance(THEMES[b].body) - luminance(THEMES[a].body); }));

// Which palette hue each tile uses (its second color is two steps along).
var TILE_HUE = { cpu: 0, gpu: 1, memory: 2, network: 0, disk: 3, battery: 1, clock: 5,
                 specs: 2, processes: 3, power: 4, cores: 0, temps: 4,
                 pet: 4, photo: 5, media: 3, calendar: 1, quote: 2, note: 5, worldclock: 0, focus: 4, uptime: 5,
                 bluetooth: 2, health: 1 };

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

// Solid themes (Snow, Midnight) keep their card color clean: no color glows,
// in any style. RGB keeps them under its rainbow rim.
function glowFor(styleId, themeId) {
    var st = STYLES[styleId], th = THEMES[themeId];
    return !!(st && st.glow) && !(th && th.opaque && !th.rgb);
}

// ---- Looks: one click sets a style and a theme --------------------------------
var LOOKS = [
    { name: "Plasma",         style: "plasma", theme: "plasma" },
    { name: "Aurora Glass",   style: "glass", theme: "aurora" },
    { name: "Retro Terminal", style: "pixel", theme: "moss" },
    { name: "Paper",          style: "flat",  theme: "ink" },
    { name: "Frost",          style: "clear", theme: "glacier" },
    { name: "Campfire",       style: "glass", theme: "ember" },
    { name: "Reef",           style: "flat",  theme: "lagoon" },
    { name: "Daylight",       style: "flat",  theme: "snow" },
    { name: "Midnight",       style: "flat",  theme: "midnight" },
    { name: "RGB Rig",        style: "glass", theme: "rgb" },
    { name: "Instrument Panel", style: "instrument", theme: "graphite" },
    { name: "Soft Bento",     style: "bento", theme: "oat" },
    { name: "Neon Nights",    style: "neon",  theme: "arcade" },
    { name: "Clay",           style: "soft",  theme: "peach" },
    { name: "Poster Pop",     style: "brutal", theme: "sky" },
    { name: "Night Owl",      style: "glass", theme: "nightfall" },
    { name: "Café",           style: "bento", theme: "espresso" },
    { name: "Hanami",         style: "clear", theme: "sakura" }
];
// Like the colors: Plasma first, then from the lightest to the darkest.
LOOKS.sort(function (a, b) {
    if (a.theme === "plasma" || b.theme === "plasma") return a.theme === "plasma" ? -1 : 1;
    return luminance(THEMES[b.theme].body) - luminance(THEMES[a.theme].body);
});

// `items` (theme ids, or looks with a .theme) from light to dark, with
// Follow Plasma placed by the system's own background color.
function byLightness(items, plasmaBody) {
    var key = function (it) { return typeof it === "string" ? it : it.theme; };
    var lum = function (it) {
        var k = key(it);
        return luminance(k === "plasma" ? (/^#[0-9a-f]{6}$/i.test(plasmaBody || "") ? plasmaBody : "#ffffff") : THEMES[k].body);
    };
    return items.slice().sort(function (a, b) { return lum(b) - lum(a); });
}

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
