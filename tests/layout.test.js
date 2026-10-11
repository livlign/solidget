// Run: node tests/layout.test.js
const fs = require("fs");
const path = require("path");
const assert = require("assert");
const src = fs.readFileSync(path.join(__dirname, "../package/contents/code/layout.js"), "utf8").replace(".pragma library", "");
const L = new Function(src + "; return { pack, arrange, plan, spansFor };")();

function render(res, cols) {
    const g = [];
    for (let y = 0; y < res.rows; y++) g.push(Array(cols).fill("."));
    res.rects.forEach((r, i) => {
        const ch = r.id[0].toUpperCase() === r.id[0] ? r.id[0] : r.id.slice(0, 1).toUpperCase();
        for (let y = r.y; y < r.y + r.h; y++) for (let x = r.x; x < r.x + r.w; x++) {
            assert.strictEqual(g[y][x], ".", `overlap at ${x},${y} by ${r.id}`);
            g[y][x] = "abcdefghijklmnop"[i];
        }
    });
    return g.map(r => r.join("")).join("\n");
}

const all = ["specs", "clock", "cpu", "gpu", "memory", "temps", "network", "disk", "cores", "processes", "power"];
const gu = 18, gap = 12;

for (const [name, w, h, fill, density] of [
    ["1080p full screen", 1920, 1040, true, "auto"],
    ["portrait full screen", 1080, 1920, true, "auto"],
    ["right half 1440p", 1100, 1350, true, "auto"],
    ["corner widget", 560, 800, true, "auto"],
    ["narrow sidebar", 300, 1000, true, "auto"],
    ["1080p huge", 1920, 1040, true, "huge"],
]) {
    const p = L.plan(all, w, h, gu, gap, density, fill, {});
    const txt = render(p, p.cols);
    const holes = (txt.match(/\./g) || []).length;
    console.log(`\n${name}: ${p.cols}x${p.rows} density=${p.density} cell=${p.cellW.toFixed(0)}x${p.cellH.toFixed(0)} holes=${holes}`);
    console.log(p.rects.map((r, i) => "abcdefghijklmnop"[i] + "=" + r.id + " " + r.w + "x" + r.h).join("  "));
    console.log(txt);
    assert.strictEqual(p.rects.length, all.length);
    if (p.rows * (p.cellH + gap) - gap <= h + 1) assert.strictEqual(holes, 0, "fits on screen but has holes");
}

// Forced size is respected
const f = L.arrange(["cpu", "memory"], 4, 4, { cpu: 0 });
assert.deepStrictEqual([f.rects[0].w, f.rects[0].h].join("x") !== "", true);
console.log("\nall layout tests passed");

// Exact user sizes are kept as-is (no growth, no hole filling)
{
    const res = L.arrange(["clock", "cpu", "memory", "gpu"], 4, 4, { cpu: { w: 3, h: 2 } });
    const cpu = res.rects.find(r => r.id === "cpu");
    assert.strictEqual(cpu.w + "x" + cpu.h, "3x2");
    assert.strictEqual(cpu.manual, true);
    console.log("\nexact size:\n" + render(res, 4));
    // Oversized requests clamp to the grid
    const big = L.arrange(["cpu"], 2, 0, { cpu: { w: 9, h: 1 } });
    assert.strictEqual(big.rects[0].w, 2);
    console.log("exact-size tests passed");
}

// Fixed positions: shrinking leaves a gap, nothing else moves
{
    const L2 = new Function(src + "; return { resolve, arrangeManual, plan };")();
    const start = { a: { x: 0, y: 0, w: 2, h: 2 }, b: { x: 2, y: 0, w: 2, h: 1 }, c: { x: 0, y: 2, w: 1, h: 1 } };
    const shrunk = L2.resolve(Object.assign({}, start, { a: { x: 0, y: 0, w: 1, h: 1 } }), 4, "a");
    assert.deepStrictEqual(shrunk.b, start.b);
    assert.deepStrictEqual(shrunk.c, start.c);
    // Growing pushes only the overlapped tile down
    const grown = L2.resolve(Object.assign({}, start, { a: { x: 0, y: 0, w: 2, h: 3 } }), 4, "a");
    assert.deepStrictEqual(grown.b, start.b, "b doesn't overlap, stays");
    assert.deepStrictEqual(grown.c, { x: 0, y: 3, w: 1, h: 1 }, "c pushed just below a");
    // Dropping onto another tile pushes it down, others untouched
    const moved = L2.resolve(Object.assign({}, start, { c: { x: 2, y: 0, w: 1, h: 1 } }), 4, "c");
    assert.deepStrictEqual(moved.c, { x: 2, y: 0, w: 1, h: 1 });
    assert.deepStrictEqual(moved.b, { x: 2, y: 1, w: 2, h: 1 });
    assert.deepStrictEqual(moved.a, start.a);
    // A tile without a saved spot takes the first free one
    const m = L2.arrangeManual(["a", "b", "cpu"], { a: start.a, b: start.b }, 4);
    const cpu = m.rects.find(r => r.id === "cpu");
    assert.deepStrictEqual([cpu.x, cpu.y], [2, 1]);
    // Cell size doesn't change when the bottom tile shrinks
    const p1 = L2.plan(["a", "b"], 1000, 800, 18, 12, "large", true, {}, { a: { x: 0, y: 0, w: 2, h: 3 }, b: { x: 2, y: 0, w: 1, h: 1 } });
    const p2 = L2.plan(["a", "b"], 1000, 800, 18, 12, "large", true, {}, { a: { x: 0, y: 0, w: 2, h: 1 }, b: { x: 2, y: 0, w: 1, h: 1 } });
    assert.strictEqual(p1.cellH, p2.cellH);
    assert.strictEqual(p1.cellW, p2.cellW);
    console.log("fixed-position tests passed");
}

// ---- Broken or hostile config values ----------------------------------------
// tileRects/tileSpans live in a plain config file. Junk there must never
// throw, overlap tiles, or make the board absurdly big (that froze Plasma).
{
    const junk = [1e7, -1e7, NaN, Infinity, -Infinity, "12abc", null, undefined, 2.7, -0.5];
    const ids = ["clock", "cpu", "gpu", "memory", "network"];
    let n = 0;
    for (const a of junk) for (const b of junk) {
        const manual = { cpu: { x: a, y: b, w: a, h: b }, clock: { x: b, y: a, w: 3, h: 1 }, gpu: { x: 0, y: 0, w: b, h: a } };
        const r = L.plan(ids, 1080, 1920, gu, gap, "auto", true, null, manual, true);
        assert.ok(r.rows <= 64 + 12 * ids.length, `too many rows (${r.rows}) for ${a}, ${b}`);
        render(r, r.cols);   // throws on overlaps
        const forced = { cpu: { w: a, h: b }, gpu: a };
        const f = L.plan(ids, 1080, 1920, gu, gap, "auto", true, forced, null, true);
        assert.ok(f.rows < 200, `forced sizes made ${f.rows} rows`);
        f.rects.forEach((q) => assert.ok([q.x, q.y, q.w, q.h].every(Number.isFinite), "non-number in " + JSON.stringify(q)));
        n++;
    }
    console.log(`hostile config tests passed (${n} cases)`);
}
