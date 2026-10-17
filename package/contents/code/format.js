.pragma library

// Sizes. Binary (KiB, MiB…, base 1024) by default; `decimal` gives kB, MB…
// (base 1000). Tiles go through main.qml's bytesText/rateText, which pass
// the user's unit settings.
function bytes(b, decimals, decimal) {
    if (b === undefined || b === null || isNaN(b)) return "–";
    var base = decimal ? 1000 : 1024;
    var units = decimal ? ["B", "kB", "MB", "GB", "TB"] : ["B", "KiB", "MiB", "GiB", "TiB"];
    var i = 0;
    while (Math.abs(b) >= base && i < units.length - 1) { b /= base; i++; }
    var d = decimals !== undefined ? decimals : (i === 0 ? 0 : (b < 10 ? 1 : 0));
    return b.toFixed(d) + " " + units[i];
}

// Bytes per second; `bits` shows network-style bit rates (kbps, Mbps…).
function rate(b, decimal, bits) {
    if (!bits) return bytes(b, undefined, decimal) + "/s";
    if (b === undefined || b === null || isNaN(b)) return "–";
    var v = b * 8;
    var units = ["bps", "kbps", "Mbps", "Gbps"];
    var i = 0;
    while (v >= 1000 && i < units.length - 1) { v /= 1000; i++; }
    return v.toFixed(i === 0 ? 0 : (v < 10 ? 1 : 0)) + " " + units[i];
}

function toFahrenheit(c) { return c * 9 / 5 + 32; }

// Decimal sizes, matching what drive vendors print on the box ("512 GB").
function driveSize(b) {
    if (!b) return "";
    if (b >= 1e12) return (b / 1e12).toFixed(b >= 1e13 ? 0 : 1).replace(/\.0$/, "") + " TB";
    return Math.round(b / 1e9) + " GB";
}

function percent(v) {
    if (v === undefined || v === null || isNaN(v)) return "–";
    return (v < 10 ? v.toFixed(1) : Math.round(v)) + "%";
}

function temp(c, fahrenheit) {
    if (!c || isNaN(c)) return "–";
    return fahrenheit ? Math.round(toFahrenheit(c)) + "°F" : Math.round(c) + "°C";
}

function ghz(mhz) {
    if (!mhz || isNaN(mhz)) return "";
    return (mhz / 1000).toFixed(2) + " GHz";
}

function uptime(seconds) {
    if (!seconds) return "";
    var d = Math.floor(seconds / 86400);
    var h = Math.floor(seconds % 86400 / 3600);
    var m = Math.floor(seconds % 3600 / 60);
    if (d > 0) return d + "d " + h + "h";
    if (h > 0) return h + "h " + m + "m";
    return m + "m";
}

// 74:12:05 (hours can pass 24).
function uptimeClock(seconds) {
    seconds = Math.max(0, Math.floor(seconds || 0));
    var h = Math.floor(seconds / 3600), m = Math.floor(seconds % 3600 / 60), s = seconds % 60;
    return h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
}

// Whole days, d, h, m and s, for building longer text.
function uptimeParts(seconds) {
    seconds = Math.max(0, Math.floor(seconds || 0));
    return { d: Math.floor(seconds / 86400), h: Math.floor(seconds % 86400 / 3600),
             m: Math.floor(seconds % 3600 / 60), s: seconds % 60 };
}
