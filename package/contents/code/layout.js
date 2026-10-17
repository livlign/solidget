.pragma library

// Bento layout engine.
//
// Tiles live on a grid of cells. Each tile offers a list of spans
// (smallest first). We start everything at its smallest span, then grow
// tiles round-robin in priority order while the result still fits on the
// screen, and finally stretch tiles into any leftover holes so the grid is
// filled edge to edge.

// Spans as [columns, rows], smallest first.
var SPANS = {
    clock:     [[2, 1], [3, 1], [2, 2], [4, 2]],
    specs:     [[2, 3]],
    cpu:       [[1, 1], [2, 1], [2, 2]],
    gpu:       [[1, 1], [2, 1], [2, 2]],
    memory:    [[1, 1], [2, 1]],
    temps:     [[1, 1], [2, 1]],
    network:   [[1, 1], [2, 1], [3, 1], [2, 2]],
    disk:      [[1, 1], [2, 1]],
    battery:   [[1, 1], [2, 1]],
    cores:     [[2, 1], [2, 2], [3, 2]],
    processes: [[2, 2], [2, 3], [3, 3]],
    power:     [[1, 1], [2, 1]],
    pet:       [[2, 1], [2, 2], [3, 2]],
    photo:     [[2, 2], [3, 2], [4, 2], [4, 3]],
    media:     [[2, 1], [2, 2], [3, 2]],
    calendar:  [[2, 2], [2, 3], [3, 3]],
    quote:     [[2, 1], [3, 1], [2, 2]],
    note:      [[1, 1], [2, 1], [2, 2]],
    worldclock:[[2, 1], [2, 2]],
    focus:     [[1, 1], [2, 1], [2, 2]],
    uptime:    [[2, 1], [2, 2], [3, 2]]
};

// Who gets extra space first.
var GROW_PRIORITY = ["clock", "photo", "cpu", "specs", "gpu", "network", "media", "calendar", "pet", "cores", "processes",
                     "worldclock", "focus", "uptime", "quote", "note",
                     "memory", "temps", "power", "disk", "battery"];

// Target cell edge in grid units for each density setting.
var DENSITY = { compact: 8, comfortable: 10, large: 13, huge: 17 };
var DENSITY_ORDER = ["huge", "large", "comfortable", "compact"];

// Portrait screens: tall, narrow grids read best with some tiles spanning
// the full width instead of growing into 3-wide blocks.
var SPANS_PORTRAIT = {
    clock:     [[2, 1], [4, 1], [4, 2]],
    network:   [[2, 1], [4, 1], [2, 2]],
    cores:     [[2, 1], [2, 2], [4, 1]],
    processes: [[2, 2], [2, 3]]
};

function spansFor(id, cols, portrait) {
    var list = (portrait && SPANS_PORTRAIT[id]) || SPANS[id] || [[1, 1]];
    var out = [];
    for (var i = 0; i < list.length; i++) {
        var w = Math.min(list[i][0], cols);
        var h = list[i][1];
        // Squeezed into fewer columns: give the rows back so content still fits.
        if (w < list[i][0]) h = Math.max(h, Math.ceil(list[i][0] * list[i][1] / w));
        var dup = out.some(function (s) { return s[0] === w && s[1] === h; });
        if (!dup) out.push([w, h]);
    }
    return out;
}

// First-fit, row-major. Returns { rects, rows } where rows is the number of
// rows used. `limitRows` (optional) aborts early with null when exceeded.
function pack(sizes, cols, limitRows) {
    var grid = [];
    function free(x, y, w, h) {
        if (x + w > cols) return false;
        for (var yy = y; yy < y + h; yy++)
            for (var xx = x; xx < x + w; xx++)
                if (grid[yy] && grid[yy][xx]) return false;
        return true;
    }
    function take(x, y, w, h, idx) {
        for (var yy = y; yy < y + h; yy++) {
            if (!grid[yy]) grid[yy] = [];
            for (var xx = x; xx < x + w; xx++) grid[yy][xx] = idx + 1;
        }
    }
    var rects = [];
    var rows = 0;
    for (var i = 0; i < sizes.length; i++) {
        var w = sizes[i][0], h = sizes[i][1];
        var placed = false;
        for (var y = 0; !placed; y++) {
            if (limitRows !== undefined && y + h > limitRows) return null;
            for (var x = 0; x + w <= cols; x++) {
                if (free(x, y, w, h)) {
                    take(x, y, w, h, i);
                    rects.push({ x: x, y: y, w: w, h: h });
                    rows = Math.max(rows, y + h);
                    placed = true;
                    break;
                }
            }
        }
    }
    return { rects: rects, rows: rows, grid: grid };
}

// Stretch tiles into empty cells: first rightwards, then downwards.
// Tiles in `fixed` (indices) keep the exact size the user gave them.
function fillHoles(result, cols, rows, fixed) {
    fixed = fixed || {};
    var grid = result.grid;
    var rects = result.rects;
    function cellFree(x, y) { return y < rows && x < cols && !(grid[y] && grid[y][x]); }
    function claim(x, y, idx) { if (!grid[y]) grid[y] = []; grid[y][x] = idx + 1; }

    var changed = true;
    while (changed) {
        changed = false;
        for (var i = 0; i < rects.length; i++) {
            if (fixed[i]) continue;
            var r = rects[i];
            var canRight = r.x + r.w < cols;
            for (var yy = r.y; canRight && yy < r.y + r.h; yy++)
                if (!cellFree(r.x + r.w, yy)) canRight = false;
            if (canRight) {
                for (yy = r.y; yy < r.y + r.h; yy++) claim(r.x + r.w, yy, i);
                r.w++;
                changed = true;
            }
        }
    }
    changed = true;
    while (changed) {
        changed = false;
        for (i = 0; i < rects.length; i++) {
            if (fixed[i]) continue;
            r = rects[i];
            var canDown = r.y + r.h < rows;
            for (var xx = r.x; canDown && xx < r.x + r.w; xx++)
                if (!cellFree(xx, r.y + r.h)) canDown = false;
            if (canDown) {
                for (xx = r.x; xx < r.x + r.w; xx++) claim(xx, r.y + r.h, i);
                r.h++;
                changed = true;
            }
        }
    }
}

// A user size is either a span index into SPANS (older configs) or an
// exact { w, h } from dragging the resize handle.
// Saved sizes and positions come from a config file anyone can edit, so
// every number is forced into a sane range before use. Without this, a
// value like y=10000000 makes a board millions of rows tall and freezes Plasma.
var MAX_ROW = 64;     // furthest row a tile may start on
var MAX_H = 12;       // tallest a tile may be, in rows
function cell(v, lo, hi) {
    v = Math.floor(Number(v));
    return isFinite(v) ? Math.max(lo, Math.min(hi, v)) : lo;
}

function isExact(f) { return f !== undefined && f !== null && typeof f === "object"; }
function isForced(f) { return isExact(f) || (f !== undefined && f !== null && f >= 0); }

// ids:     visible tile ids, in the user's order
// cols:    grid columns
// rows:    rows that fit on screen (0 = unlimited / scrolling)
// forced:  { id: spanIndex | {w, h} } for tiles the user sized by hand
// Returns { rects: [{id,x,y,w,h,manual}], rows }
function arrange(ids, cols, rows, forced, portrait) {
    forced = forced || {};
    var fixed = {};
    var options = ids.map(function (id, i) {
        var f = forced[id];
        if (isExact(f)) {
            fixed[i] = true;
            return [[cell(f.w, 1, cols), cell(f.h, 1, MAX_H)]];
        }
        return spansFor(id, cols, portrait);
    });
    var level = ids.map(function (id, i) {
        var f = forced[id];
        return !isExact(f) && isForced(f) ? cell(f, 0, options[i].length - 1) : 0;
    });
    function sizes() { return level.map(function (l, i) { return options[i][l]; }); }

    var best = pack(sizes(), cols);
    if (rows > 0 && best.rows <= rows) {
        // Grow round-robin by priority while everything still fits.
        var order = ids.map(function (id, i) { return i; }).sort(function (a, b) {
            var pa = GROW_PRIORITY.indexOf(ids[a]), pb = GROW_PRIORITY.indexOf(ids[b]);
            return (pa < 0 ? 99 : pa) - (pb < 0 ? 99 : pb);
        });
        var grew = true;
        while (grew) {
            grew = false;
            for (var k = 0; k < order.length; k++) {
                var i = order[k];
                if (isForced(forced[ids[i]])) continue;
                if (level[i] + 1 >= options[i].length) continue;
                level[i]++;
                var attempt = pack(sizes(), cols, rows);
                if (attempt) { best = attempt; grew = true; }
                else level[i]--;
            }
        }
        fillHoles(best, cols, rows, fixed);
    } else {
        // Scrolling: still close the gaps the packer left behind.
        fillHoles(best, cols, best.rows, fixed);
    }
    var usedRows = rows > 0 ? Math.max(rows, best.rows) : best.rows;
    return {
        rects: best.rects.map(function (r, i) {
            return { id: ids[i], x: r.x, y: r.y, w: r.w, h: r.h, manual: !!fixed[i] };
        }),
        rows: usedRows
    };
}

// ---- Fixed positions (hand-edited layouts) ----------------------------------
// Once the user moves or resizes a tile, every tile keeps an exact cell
// position {x, y, w, h}. Nothing is re-packed: shrinking leaves a gap, and
// growing or dropping a tile only pushes the tiles it overlaps straight down.

function overlaps(a, b) {
    return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
}

function clampRect(r, cols) {
    var w = cell(r.w, 1, cols);
    return { x: cell(r.x, 0, cols - w), y: cell(r.y, 0, MAX_ROW), w: w, h: cell(r.h, 1, MAX_H) };
}

// Make `rects` ({ id: {x,y,w,h} }) overlap-free. `priority` keeps its spot;
// the rest are settled top to bottom, each pushed down just past whatever it
// hits. Tiles that don't collide with anything stay exactly where they are.
function resolve(rects, cols, priority) {
    var out = {};
    var placed = [];
    if (priority && rects[priority]) {
        out[priority] = clampRect(rects[priority], cols);
        placed.push(out[priority]);
    }
    Object.keys(rects).filter(function (id) { return id !== priority; })
        .sort(function (a, b) { return rects[a].y - rects[b].y || rects[a].x - rects[b].x; })
        .forEach(function (id) {
            var r = clampRect(rects[id], cols);
            for (;;) {
                var hit = placed.filter(function (q) { return overlaps(r, q); });
                if (!hit.length) break;
                r.y = Math.max.apply(null, hit.map(function (q) { return q.y + q.h; }));
            }
            out[id] = r;
            placed.push(r);
        });
    return out;
}

// Tiles with a saved spot go there; tiles without one (newly shown) take the
// first free spot that fits their smallest size.
function arrangeManual(ids, manual, cols, portrait) {
    var known = {};
    ids.forEach(function (id) { if (manual[id]) known[id] = manual[id]; });
    var settled = resolve(known, cols, null);
    var rects = [];
    ids.forEach(function (id) {
        if (settled[id]) rects.push({ id: id, x: settled[id].x, y: settled[id].y, w: settled[id].w, h: settled[id].h, manual: true });
    });
    ids.forEach(function (id) {
        if (settled[id]) return;
        var s = spansFor(id, cols, portrait)[0];
        for (var y = 0; y < 10000; y++) {
            for (var x = 0; x + s[0] <= cols; x++) {
                var r = { x: x, y: y, w: s[0], h: s[1] };
                if (!rects.some(function (q) { return overlaps(r, q); })) {
                    rects.push({ id: id, x: x, y: y, w: s[0], h: s[1], manual: true });
                    return;
                }
            }
        }
    });
    var rows = rects.reduce(function (m, r) { return Math.max(m, r.y + r.h); }, 0);
    return { rects: rects, rows: rows };
}

// Pick grid dimensions for a pixel area.
// density: "auto" or a DENSITY key. fill: true to fit the height (no scroll).
// manual: { id: {x,y,w,h} } for a hand-edited layout, or null for automatic.
// portrait: undefined = decide from the area's shape.
function plan(ids, width, height, gridUnit, gap, density, fill, forced, manual, portrait) {
    if (portrait === undefined || portrait === null) portrait = height > width;
    function dims(key) {
        var target = DENSITY[key] * gridUnit;
        var cols = Math.max(1, Math.floor((width + gap) / (target + gap)));
        var rows = fill ? Math.max(1, Math.floor((height + gap) / (target + gap))) : 0;
        return { cols: cols, rows: rows, key: key };
    }
    var chosen = null;
    if (density === "auto" || !DENSITY[density]) {
        // Biggest density whose smallest layout still fits on screen.
        for (var d = 0; d < DENSITY_ORDER.length; d++) {
            var c = dims(DENSITY_ORDER[d]);
            if (!fill) { if (c.cols >= 2 || d === DENSITY_ORDER.length - 1) { chosen = c; break; } continue; }
            var test = pack(ids.map(function (id) { return spansFor(id, c.cols, portrait)[0]; }), c.cols, c.rows);
            if (test) { chosen = c; break; }
        }
        if (!chosen) chosen = dims("compact");
    } else {
        chosen = dims(density);
    }
    var result;
    if (manual) {
        result = arrangeManual(ids, manual, chosen.cols, portrait);
        // Keep the grid at least screen-sized so cells never change size
        // when tiles shrink (that's what made the layout "jump").
        result.rows = Math.max(result.rows, chosen.rows);
    } else {
        result = arrange(ids, chosen.cols, chosen.rows, forced, portrait);
    }
    var cellW = (width - gap * (chosen.cols - 1)) / chosen.cols;
    var cellH;
    var fitted = (height - gap * (result.rows - 1)) / result.rows;
    if (fill && result.rows <= chosen.rows) cellH = fitted;
    // A hand-arranged layout with more rows than fit: squeeze the rows to the
    // height (down to a readable minimum) rather than run off the screen.
    else if (fill && manual) cellH = Math.max(gridUnit * 5, fitted);
    else cellH = Math.min(cellW, DENSITY[chosen.key] * gridUnit * 1.1);
    return { cols: chosen.cols, rows: result.rows, cellW: cellW, cellH: cellH, density: chosen.key, rects: result.rects, portrait: portrait };
}
