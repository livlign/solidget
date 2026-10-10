.pragma library

// Binary sizes (what the OS actually reports for RAM and data rates).
function bytes(b, decimals) {
    if (b === undefined || b === null || isNaN(b)) return "–";
    var units = ["B", "KiB", "MiB", "GiB", "TiB"];
    var i = 0;
    while (Math.abs(b) >= 1024 && i < units.length - 1) { b /= 1024; i++; }
    var d = decimals !== undefined ? decimals : (i === 0 ? 0 : (b < 10 ? 1 : 0));
    return b.toFixed(d) + " " + units[i];
}

function rate(b) {
    return bytes(b) + "/s";
}

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

function temp(c) {
    if (!c || isNaN(c)) return "–";
    return Math.round(c) + "°C";
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
