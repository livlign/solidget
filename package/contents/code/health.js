.pragma library

// Health score for the Health tile: start at 100 and take points off for
// each problem found. Every check returns { id, ok, cost, n? } so the tile
// can word it (and translate it); `cost` is how many points it took.
//
// s: { cpuTemp, gpuTemp, ssdTemp (°C), memPct, swapPct (0..100),
//      helper: specs.py health output, or null before it has run }

function band(value, steps) {
    // steps: [[threshold, cost], ...] highest threshold first.
    for (var i = 0; i < steps.length; i++)
        if (value >= steps[i][0]) return steps[i][1];
    return 0;
}

function checks(s) {
    var out = [];
    var h = s.helper || {};

    // Drives: a failing self-check is the worst news there is.
    (h.drives || []).forEach(function (d) {
        if (!d.ok) out.push({ id: "driveFailing", ok: false, cost: 40, name: d.name });
        else if (d.wear >= 70) out.push({ id: "driveWorn", ok: false, cost: band(d.wear, [[90, 20], [70, 8]]), name: d.name, n: d.wear });
    });
    if ((h.drives || []).length && out.every(function (c) { return c.id.indexOf("drive") !== 0; }))
        out.push({ id: "drivesOk", ok: true, cost: 0, n: h.drives.length });

    // Free space.
    var spaceBad = false;
    (h.space || []).forEach(function (m) {
        var pct = m.total > 0 ? m.free / m.total * 100 : 100;
        var cost = pct < 5 ? 25 : pct < 10 ? 12 : pct < 15 ? 5 : 0;
        if (cost) { spaceBad = true; out.push({ id: "lowSpace", ok: false, cost: cost, name: m.mount, n: Math.round(pct) }); }
    });
    if ((h.space || []).length && !spaceBad) out.push({ id: "spaceOk", ok: true, cost: 0 });

    // Heat.
    var hot = [["cpuHot", s.cpuTemp, [[95, 20], [85, 8]]],
               ["gpuHot", s.gpuTemp, [[95, 15], [85, 6]]],
               ["ssdHot", s.ssdTemp, [[75, 10], [65, 4]]]];
    var anyTemp = false, anyHot = false;
    hot.forEach(function (t) {
        if (!(t[1] > 0)) return;
        anyTemp = true;
        var cost = band(t[1], t[2]);
        if (cost) { anyHot = true; out.push({ id: t[0], ok: false, cost: cost, n: Math.round(t[1]) }); }
    });
    if (anyTemp && !anyHot) out.push({ id: "coolOk", ok: true, cost: 0 });

    // Memory.
    var memCost = band(s.memPct || 0, [[95, 12], [90, 5]]);
    var swapCost = band(s.swapPct || 0, [[80, 6]]);
    if (memCost) out.push({ id: "memoryFull", ok: false, cost: memCost, n: Math.round(s.memPct) });
    if (swapCost) out.push({ id: "swapFull", ok: false, cost: swapCost, n: Math.round(s.swapPct) });
    if (s.memPct > 0 && !memCost && !swapCost) out.push({ id: "memoryOk", ok: true, cost: 0 });

    // Services that failed to start or crashed.
    var failed = h.failed || [];
    if (failed.length) out.push({ id: "failedServices", ok: false, cost: Math.min(24, failed.length * 8), n: failed.length, name: failed[0] });
    else if (s.helper) out.push({ id: "servicesOk", ok: true, cost: 0 });

    // Updates and a pending restart.
    var u = h.updates;
    if (u && u.security > 0) out.push({ id: "securityUpdates", ok: false, cost: 8, n: u.security, total: u.count });
    else if (u && u.count >= 20) out.push({ id: "updates", ok: false, cost: 4, n: u.count });
    else if (u) out.push({ id: "updatesOk", ok: true, cost: 0, n: u.count });
    if (h.restart) out.push({ id: "restart", ok: false, cost: 5 });

    // Problems first, biggest first; then what's fine.
    return out.sort(function (a, b) { return (a.ok - b.ok) || (b.cost - a.cost); });
}

function score(list) {
    var lost = list.reduce(function (sum, c) { return sum + c.cost; }, 0);
    return Math.max(0, Math.min(100, 100 - lost));
}

// "great" | "good" | "care" | "trouble"
function grade(n) {
    return n >= 90 ? "great" : n >= 75 ? "good" : n >= 50 ? "care" : "trouble";
}
