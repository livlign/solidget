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
    power:     ["#fbbf24", "#f97316"]
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
