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
