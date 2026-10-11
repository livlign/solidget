// Run: node tests/code.test.js
// Checks the plain-JS helpers and that the QML, settings and colors agree
// with each other (every tile has colors, every setting is declared, ...).
const fs = require("fs");
const path = require("path");
const assert = require("assert");

const root = path.join(__dirname, "..", "package", "contents");
const read = (p) => fs.readFileSync(path.join(root, p), "utf8");
function load(file, names) {
    const src = read("code/" + file).replace(".pragma library", "");
    return new Function(src + "; return { " + names.join(", ") + " };")();
}

let passed = 0;
function test(name, fn) {
    try { fn(); passed++; }
    catch (e) { console.error("FAIL " + name + "\n  " + e.message); process.exitCode = 1; }
}

// ---- format.js -------------------------------------------------------------
const F = load("format.js", ["bytes", "rate", "temp", "toFahrenheit", "driveSize", "percent", "ghz", "uptime"]);

test("bytes: binary and decimal units", () => {
    assert.strictEqual(F.bytes(0), "0 B");
    assert.strictEqual(F.bytes(1536), "1.5 KiB");
    assert.strictEqual(F.bytes(8 * 1024 ** 3), "8.0 GiB");
    assert.strictEqual(F.bytes(32 * 1024 ** 3), "32 GiB");
    assert.strictEqual(F.bytes(1500, undefined, true), "1.5 kB");
    assert.strictEqual(F.bytes(NaN), "–");
    assert.strictEqual(F.bytes(undefined), "–");
});
test("rate: bytes per second or bits", () => {
    assert.strictEqual(F.rate(2048), "2.0 KiB/s");
    assert.strictEqual(F.rate(125000, true, true), "1.0 Mbps");
    assert.strictEqual(F.rate(100, false, true), "800 bps");
});
test("temp: Celsius and Fahrenheit, empty when unknown", () => {
    assert.strictEqual(F.temp(63.4), "63°C");
    assert.strictEqual(F.temp(100, true), "212°F");
    assert.strictEqual(F.temp(0), "–");
    assert.strictEqual(F.temp(NaN), "–");
});
test("driveSize: the number printed on the box", () => {
    assert.strictEqual(F.driveSize(512110190592), "512 GB");
    assert.strictEqual(F.driveSize(2e12), "2 TB");
    assert.strictEqual(F.driveSize(1.5e12), "1.5 TB");
    assert.strictEqual(F.driveSize(0), "");
});
test("small helpers", () => {
    assert.strictEqual(F.percent(5.25), "5.3%");
    assert.strictEqual(F.percent(42.4), "42%");
    assert.strictEqual(F.ghz(3110), "3.11 GHz");
    assert.strictEqual(F.uptime(97 * 60), "1h 37m");
    assert.strictEqual(F.uptime(3 * 86400 + 7200), "3d 2h");
});

// ---- shell.js --------------------------------------------------------------
// Every command the widget runs is built with Shell.command(). Feed it
// hostile strings and run the result through a real shell: each one must
// come back as exactly one, unchanged argument, and nothing may execute.
const Sh = load("shell.js", ["quote", "command"]);
test("shell quoting survives hostile input", () => {
    const { execFileSync } = require("child_process");
    const evil = [
        "plain", "", " ", "it's", "'", "''", "a'b'c", "$(touch /tmp/solidget-pwned)", "`id`",
        "; rm -rf ~", "&& echo hi", "| cat", "> /tmp/x", "\\", "\\'", "\n", "line1\nline2",
        "--help", "-rf", "*", "~", "$HOME", "${IFS}", "\t", "émoji 🎉", "\"double\""
    ];
    const cmd = Sh.command(["printf", "%s\\0"].concat(evil));
    const out = execFileSync("/bin/sh", ["-c", cmd], { encoding: "utf8" }).split("\0").slice(0, -1);
    assert.deepStrictEqual(out, evil);
    assert.ok(!fs.existsSync("/tmp/solidget-pwned"), "a command ran!");
});
test("main.qml builds commands only with Shell.command", () => {
    const main = read("ui/main.qml");
    assert.ok(!/connectSource\(\s*"/.test(main), "connectSource with a raw string");
    assert.ok(!/connectedSources:\s*(?:[^\n]*\?\s*)?\[\s*"/.test(main), "connectedSources with a raw string");
});

// ---- quotes.js -------------------------------------------------------------
const Q = load("quotes.js", ["QUOTES", "forDate"]);
test("quotes: one per day, always text + author", () => {
    Q.QUOTES.forEach((q) => assert.ok(q.length === 2 && q[0] && q[1], "bad quote " + q));
    for (let d = 0; d < 400; d++) {
        const q = Q.forDate(new Date(2026, 0, 1 + d));
        assert.ok(q && q[0], "no quote for day " + d);
    }
});

// ---- palette.js ------------------------------------------------------------
const P = load("palette.js", ["ACCENTS", "STYLES", "STYLE_ORDER", "THEMES", "THEME_ORDER", "TILE_HUE", "LOOKS", "accentPair", "heatFor", "vendorColor", "plasmaPalette"]);
const hex = /^#[0-9a-f]{6}$/i;

// Tile ids from main.qml, so a new tile can't be forgotten here.
const main = read("ui/main.qml");
const tiles = JSON.parse(main.match(/allTiles: (\[[^\]]+\])/)[1].replace(/\s+/g, " "));

test("every tile has colors in every theme", () => {
    tiles.forEach((id) => {
        assert.ok(P.ACCENTS[id], "ACCENTS missing " + id);
        assert.ok(id in P.TILE_HUE, "TILE_HUE missing " + id);
        P.THEME_ORDER.forEach((th) => {
            const pair = P.accentPair(th, id);
            assert.ok(hex.test(pair[0]) && hex.test(pair[1]), th + "/" + id + " gave " + pair);
        });
    });
});
test("themes, styles and looks are consistent", () => {
    assert.deepStrictEqual(Object.keys(P.THEMES).sort(), P.THEME_ORDER.slice().sort());
    assert.deepStrictEqual(Object.keys(P.STYLES).sort(), P.STYLE_ORDER.slice().sort());
    P.LOOKS.forEach((l) => assert.ok(P.STYLES[l.style] && P.THEMES[l.theme], "bad look " + l.name));
    P.THEME_ORDER.forEach((th) => [0, 0.5, 1].forEach((t) => assert.ok(/^#[0-9a-f]{6}$/i.test(P.heatFor(th, t)), th + " heat " + t)));
});
test("Follow Plasma builds its colors from the system accent", () => {
    ["#3daee9", "#e93d58", "#808080", "", "junk"].forEach((acc) => [true, false].forEach((dark) => {
        const p = P.plasmaPalette(acc, dark);
        assert.strictEqual(p.length, 6);
        p.forEach((c) => assert.ok(hex.test(c), acc + " gave " + c));
        assert.strictEqual(new Set(p).size, 6, "hues repeat for " + acc);
        tiles.forEach((id) => assert.ok(hex.test(P.accentPair("plasma", id, p)[0])));
    }));
    // It must not look like Aurora, the theme next to it.
    assert.notDeepStrictEqual(P.accentPair("plasma", "cpu", P.plasmaPalette("#3daee9", true)), P.accentPair("aurora", "cpu"));
    assert.ok(hex.test(P.heatFor("plasma", 0.5, false)));
});
test("network download and upload colors differ", () => {
    P.THEME_ORDER.forEach((th) => {
        const p = P.accentPair(th, "network");
        assert.notStrictEqual(p[0], p[1], th);
    });
});

// ---- QML <-> files <-> settings -------------------------------------------
test("pet sprites are well formed", () => {
    const pet = read("ui/PetTile.qml");
    // Every [ "row", "row", ... ] list of sprite rows (the Zzz label's short strings aside).
    const frames = [...pet.matchAll(/\[((?:\s*"[^"]*",?)+)\]/g)]
        .map((m) => [...m[1].matchAll(/"([^"]*)"/g)].map((r) => r[1]))
        .filter((rows) => rows[0].length > 5);
    assert.ok(frames.length >= 16, "found " + frames.length + " frames");
    frames.forEach((rows, i) => {
        assert.ok(rows.every((r) => r.length === rows[0].length), "frame " + i + " has uneven rows");
        assert.ok(rows.every((r) => /^[.kbqscmewngtvypd]+$/.test(r)), "frame " + i + " uses an unknown color");
    });
    for (const mood of ["walk", "run", "sleep"]) assert.ok(new RegExp("\\b" + mood + ": \\[").test(pet), "no " + mood + " frames");
});
test("every tile has a QML file and a name", () => {
    const files = fs.readdirSync(path.join(root, "ui"));
    tiles.forEach((id) => {
        assert.ok(new RegExp("\\b" + id + ":\\s*\\{ name:").test(main), "tileInfo missing " + id);
    });
    // The board's switch maps an id to a Component wrapping <Something>Tile.
    tiles.forEach((id) => {
        const m = main.match(new RegExp('case "' + id + '":\\s*return (\\w+);'));
        assert.ok(m, "no case for " + id + " in the board's sourceComponent switch");
        const comp = main.match(new RegExp("Component \\{ id: " + m[1] + ";\\s*(\\w+)"));
        assert.ok(comp && files.includes(comp[1] + ".qml"), id + ": missing component or file");
    });
});
test("presets only use known tiles", () => {
    const block = main.slice(main.indexOf("readonly property var presets"), main.indexOf("readonly property string currentPreset"));
    const used = [...block.matchAll(/(?:tiles|portrait):\s*(\[[^\]]*\])/g)].flatMap((m) => JSON.parse(m[1]));
    assert.ok(used.length > 0);
    used.forEach((id) => assert.ok(tiles.includes(id), "unknown tile in a preset: " + id));
});
test("every setting used in QML is declared in main.xml", () => {
    const xml = read("config/main.xml");
    const declared = new Set([...xml.matchAll(/<entry name="(\w+)"/g)].map((m) => m[1]));
    const ui = fs.readdirSync(path.join(root, "ui")).map((f) => read("ui/" + f)).join("\n");
    const used = new Set([...ui.matchAll(/Plasmoid\.configuration\.(\w+)/g)].map((m) => m[1]));
    used.forEach((k) => assert.ok(declared.has(k), "Plasmoid.configuration." + k + " is not in main.xml"));
    assert.ok(!/<!--(?:(?!-->)[\s\S])*--(?!>)/.test(xml), "main.xml has '--' inside a comment (breaks the XML)");
});

console.log(passed + " code checks passed");
