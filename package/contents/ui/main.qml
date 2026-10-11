import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import "../code/layout.js" as Bento
import "../code/format.js" as Fmt

PlasmoidItem {
    id: root

    // ---- Tile catalogue -------------------------------------------------

    readonly property var allTiles: ["clock", "specs", "cpu", "gpu", "memory", "temps", "network",
                                     "cores", "processes", "power", "disk", "battery"]
    readonly property var tileInfo: ({
        clock:     { name: i18n("Clock & date"),  icon: "clock" },
        specs:     { name: i18n("PC specs"),      icon: "computer" },
        cpu:       { name: i18n("CPU"),           icon: "cpu" },
        gpu:       { name: i18n("GPU"),           icon: "show-gpu-effects" },
        memory:    { name: i18n("Memory"),        icon: "memory" },
        temps:     { name: i18n("Temperatures"),  icon: "temperature-normal" },
        network:   { name: i18n("Network"),       icon: "network-wired" },
        cores:     { name: i18n("Core heatmap"),  icon: "view-grid" },
        processes: { name: i18n("Top apps"),      icon: "view-process-system" },
        power:     { name: i18n("Power & fans"),  icon: "flash" },
        disk:      { name: i18n("Storage"),       icon: "drive-harddisk" },
        battery:   { name: i18n("Battery"),       icon: "battery-080" }
    })

    readonly property var presetIds: ["essentials", "everything", "showcase", "performance", "everyday", "minimal"]
    readonly property var presets: ({
        essentials:  { name: i18n("Essentials"),  hint: i18n("Clock, your build and the vitals"),
                       tiles: ["clock", "specs", "cpu", "gpu", "memory", "temps", "network"],
                       portrait: ["clock", "specs", "cpu", "gpu", "temps", "memory", "network"] },
        everything:  { name: i18n("Everything"),  hint: i18n("Every tile your PC supports — great full screen"),
                       tiles: ["clock", "specs", "cpu", "gpu", "cores", "processes", "memory", "temps", "network", "power", "disk", "battery"],
                       portrait: ["clock", "specs", "cpu", "gpu", "temps", "memory", "cores", "network", "processes", "power", "disk", "battery"] },
        showcase:    { name: i18n("Showcase"),    hint: i18n("Your build front and center"),
                       tiles: ["specs", "cpu", "gpu", "temps", "power"] },
        performance: { name: i18n("Performance"), hint: i18n("For gaming and heavy work"),
                       tiles: ["cpu", "gpu", "cores", "temps", "power", "processes"],
                       portrait: ["cpu", "gpu", "temps", "power", "cores", "processes"] },
        everyday:    { name: i18n("Everyday"),    hint: i18n("Calm essentials for daily use"),
                       tiles: ["clock", "cpu", "memory", "network", "disk", "battery"] },
        minimal:     { name: i18n("Minimal"),     hint: i18n("Just the vitals"),
                       tiles: ["cpu", "memory", "battery"] }
    })

    readonly property var densities: ["auto", "compact", "comfortable", "large", "huge"]

    // ---- Persisted layout ----------------------------------------------

    function splitList(s) {
        return (s || "").split(",").map(function (x) { return x.trim(); }).filter(function (x) { return x !== ""; });
    }

    readonly property var savedOrder: splitList(Plasmoid.configuration.tileOrder).filter(function (id) { return allTiles.indexOf(id) >= 0; })
    // Tiles added in newer versions go to the end and start hidden.
    readonly property var order: savedOrder.concat(allTiles.filter(function (id) { return savedOrder.indexOf(id) < 0; }))
    readonly property var hidden: splitList(Plasmoid.configuration.hiddenTiles)
        .concat(allTiles.filter(function (id) { return savedOrder.indexOf(id) < 0; }))
    // The preset last picked; `customized` means the user has changed it
    // since (Reset layout goes back to it).
    readonly property string currentPreset: presets[Plasmoid.configuration.preset] ? Plasmoid.configuration.preset : "essentials"
    readonly property bool customized: Plasmoid.configuration.customized
    readonly property string density: Plasmoid.configuration.density || "auto"
    // "id:WxH" = exact size from the resize handle; "id:N" = span index (older configs).
    readonly property var spans: {
        var m = {};
        splitList(Plasmoid.configuration.tileSpans).forEach(function (pair) {
            var kv = pair.split(":");
            if (kv.length !== 2) return;
            var wh = /^(\d+)x(\d+)$/.exec(kv[1]);
            m[kv[0]] = wh ? { w: parseInt(wh[1]), h: parseInt(wh[2]) } : parseInt(kv[1]);
        });
        return m;
    }

    // Hand-edited layout: exact cell positions, "id:x,y,w,h;..." in config.
    // Empty means the automatic (packed) layout.
    readonly property var manualRects: {
        var raw = Plasmoid.configuration.tileRects || "";
        if (!raw) return null;
        var m = {};
        raw.split(";").forEach(function (pair) {
            var kv = pair.split(":");
            if (kv.length !== 2) return;
            var n = kv[1].split(",").map(function (v) { return parseInt(v); });
            if (n.length === 4 && n.every(function (v) { return !isNaN(v); }))
                m[kv[0]] = { x: n[0], y: n[1], w: n[2], h: n[3] };
        });
        return Object.keys(m).length ? m : null;
    }
    // Live preview while dragging/resizing in edit mode; null otherwise.
    property var dragRects: null
    readonly property var layoutRects: dragRects || manualRects
    readonly property var layoutOrder: order
    readonly property var layoutSpans: spans
    readonly property var visibleTiles: layoutOrder.filter(function (id) { return hidden.indexOf(id) < 0 && isAvailable(id); })

    function isAvailable(id) {
        switch (id) {
        case "gpu":     return !!(specs.gpus && specs.gpus.length > 0) || gpuVramTotal.value > 0;
        case "battery": return !!batteryState.present;
        case "temps":   return cpuTempValue > 0 || gpuTemp.value > 0;
        case "power":   return gpuWatts > 0 || !!(specs.sensors && (specs.sensors.fans.length > 0 || specs.sensors.gpuPowerFile));
        default:        return true;
        }
    }

    // ---- Orientation ---------------------------------------------------------
    // "auto" decides from the widget's shape; presets have a tile order per
    // orientation and some tiles get portrait-friendly shapes (layout.js).
    readonly property string orientationSetting: Plasmoid.configuration.orientation || "auto"
    property real boardAspect: 1    // width / height, reported by the board
    readonly property bool isPortrait: orientationSetting === "portrait"
        || (orientationSetting === "auto" && boardAspect < 1)
    onIsPortraitChanged: if (!customized) Qt.callLater(applyPreset, currentPreset)

    function spanChoices(id) {
        return Bento.spansFor(id, boardRef ? boardRef.plan.cols : 4, isPortrait);
    }

    function applyPreset(id) {
        var tiles = (isPortrait && presets[id].portrait) || presets[id].tiles;
        var rest = allTiles.filter(function (t) { return tiles.indexOf(t) < 0; });
        Plasmoid.configuration.tileOrder = tiles.concat(rest).join(",");
        Plasmoid.configuration.hiddenTiles = rest.join(",");
        Plasmoid.configuration.tileSpans = "";
        Plasmoid.configuration.tileRects = "";
        Plasmoid.configuration.preset = id;
        Plasmoid.configuration.customized = false;
    }

    function persistOrder(o) {
        Plasmoid.configuration.tileOrder = o.join(",");
        // Freeze the effective hidden set too, so "new tile" defaults don't linger.
        Plasmoid.configuration.hiddenTiles = hidden.filter(function (t, i, a) { return a.indexOf(t) === i; }).join(",");
        Plasmoid.configuration.customized = true;
    }

    function setTileShown(id, shown) {
        var h = hidden.filter(function (t) { return t !== id; });
        if (!shown) h.push(id);
        Plasmoid.configuration.tileOrder = order.join(",");
        Plasmoid.configuration.hiddenTiles = h.filter(function (t, i, a) { return a.indexOf(t) === i; }).join(",");
        Plasmoid.configuration.customized = true;
    }

    function moveTile(id, delta) {
        var o = order.slice();
        var i = o.indexOf(id);
        var j = i + delta;
        if (i < 0 || j < 0 || j >= o.length) return;
        o.splice(i, 1);
        o.splice(j, 0, id);
        persistOrder(o);
    }

    function setRects(m) {
        Plasmoid.configuration.tileRects = Object.keys(m).map(function (k) {
            var r = m[k];
            return k + ":" + [r.x, r.y, r.w, r.h].join(",");
        }).join(";");
        Plasmoid.configuration.customized = true;
    }

    // Size from the Settings list or a tile's "default size" button.
    // value: null for the tile's default size, a span index, or { w, h }.
    // Goes through the board so the layout switches to fixed positions and
    // only this tile changes.
    property var boardRef: null
    function setTileSpan(id, value) {
        if (boardRef) boardRef.setTileSize(id, value);
    }

    // Back to the last preset: its tiles, its order, automatic sizes.
    function resetLayout() {
        applyPreset(currentPreset);
    }

    function setDensity(d) {
        Plasmoid.configuration.density = d;
    }

    // ---- Placement -------------------------------------------------------
    // On the desktop, each widget sits in an ItemContainer managed by the
    // containment's AppletsLayout (the thing the resize handles talk to).
    // Resizing that container is how "fill the screen" works.

    readonly property var placements: [
        { id: "full",   name: i18n("Full screen"),  r: [0, 0, 1, 1] },
        { id: "left",   name: i18n("Left half"),    r: [0, 0, 0.5, 1] },
        { id: "right",  name: i18n("Right half"),   r: [0.5, 0, 0.5, 1] },
        { id: "top",    name: i18n("Top half"),     r: [0, 0, 1, 0.5] },
        { id: "bottom", name: i18n("Bottom half"),  r: [0, 0.5, 1, 0.5] },
        { id: "tl",     name: i18n("Top left"),     r: [0, 0, 0.5, 0.5] },
        { id: "tr",     name: i18n("Top right"),    r: [0.5, 0, 0.5, 0.5] },
        { id: "bl",     name: i18n("Bottom left"),  r: [0, 0.5, 0.5, 0.5] },
        { id: "br",     name: i18n("Bottom right"), r: [0.5, 0.5, 0.5, 0.5] },
        { id: "lthird", name: i18n("Left sidebar"), r: [0, 0, 1 / 3, 1] },
        { id: "rthird", name: i18n("Right sidebar"), r: [2 / 3, 0, 1 / 3, 1] },
        { id: "corner", name: i18n("Corner card"),  r: [0.72, 0, 0.28, 0.62] }
    ]

    function appletContainer() {
        for (var p = root.parent; p; p = p.parent) {
            if (p.layout && typeof p.layout.positionItem === "function")
                return p;
        }
        return null;
    }
    function canPlace() { return appletContainer() !== null; }

    function place(r) {
        var c = appletContainer();
        if (!c) {
            console.warn("Solidget: not on a desktop, can't place");
            return;
        }
        var L = c.layout;
        var m = Kirigami.Units.gridUnit;
        var W = L.width - 2 * m, H = L.height - 2 * m;
        var x = m + r[0] * W + (r[0] > 0 ? m / 2 : 0);
        var y = m + r[1] * H + (r[1] > 0 ? m / 2 : 0);
        var w = r[2] * W - (r[0] > 0 ? m / 2 : 0) - (r[0] + r[2] < 0.999 ? m / 2 : 0);
        var h = r[3] * H - (r[1] > 0 ? m / 2 : 0) - (r[1] + r[3] < 0.999 ? m / 2 : 0);
        c.x = Math.round(x);
        c.y = Math.round(y);
        c.width = Math.round(w);
        c.height = Math.round(h);
        L.positionItem(c);
        if (typeof L.save === "function")
            L.save();
    }

    function handlePlaceRequest() {
        var req = Plasmoid.configuration.placeRequest;
        if (!req) return;
        var match = placements.filter(function (p) { return p.id === req; })[0];
        Plasmoid.configuration.placeRequest = "";
        if (match) Qt.callLater(place, match.r);
        else console.warn("Solidget: unknown placement", req);
    }
    Connections {
        target: Plasmoid.configuration
        function onPlaceRequestChanged() { root.handlePlaceRequest(); }
    }
    Component.onCompleted: Qt.callLater(handlePlaceRequest)

    // ---- Live sensors (ksystemstats) -------------------------------------

    Sensors.Sensor { id: cpuUsage;     sensorId: "cpu/all/usage";               updateRateLimit: 1000 }
    Sensors.Sensor { id: cpuFreq;      sensorId: "cpu/all/averageFrequency";    updateRateLimit: 2000 }
    Sensors.Sensor { id: cpuTempAvg;   sensorId: "cpu/all/averageTemperature";  updateRateLimit: 2000 }
    Sensors.Sensor { id: cpuTempMax;   sensorId: "cpu/all/maximumTemperature";  updateRateLimit: 2000 }
    Sensors.Sensor { id: gpuUsage;     sensorId: "gpu/all/usage";               updateRateLimit: 1000 }
    Sensors.Sensor { id: gpuVramUsed;  sensorId: "gpu/all/usedVram";            updateRateLimit: 2000 }
    Sensors.Sensor { id: gpuVramTotal; sensorId: "gpu/all/totalVram";           updateRateLimit: 10000 }
    Sensors.Sensor { id: gpuTemp;      sensorId: "gpu/gpu0/temperature";        updateRateLimit: 2000 }
    Sensors.Sensor { id: gpuPower;     sensorId: "gpu/gpu0/power";              updateRateLimit: 1000 }
    Sensors.Sensor { id: memUsed;      sensorId: "memory/physical/used";        updateRateLimit: 2000 }
    Sensors.Sensor { id: memTotal;     sensorId: "memory/physical/total";       updateRateLimit: 10000 }
    Sensors.Sensor { id: memCache;     sensorId: "memory/physical/cache";       updateRateLimit: 5000 }
    Sensors.Sensor { id: netDown;      sensorId: "network/all/download";        updateRateLimit: 1000 }
    Sensors.Sensor { id: netUp;        sensorId: "network/all/upload";          updateRateLimit: 1000 }
    Sensors.Sensor { id: netName;      sensorId: specs.sensors && specs.sensors.netIface ? "network/" + specs.sensors.netIface + "/network" : "";     updateRateLimit: 30000 }
    Sensors.Sensor { id: netIp;        sensorId: specs.sensors && specs.sensors.netIface ? "network/" + specs.sensors.netIface + "/ipv4address" : ""; updateRateLimit: 30000 }
    Sensors.Sensor { id: diskUsed;     sensorId: "disk/all/used";               updateRateLimit: 10000 }
    Sensors.Sensor { id: diskTotal;    sensorId: "disk/all/total";              updateRateLimit: 10000 }
    Sensors.Sensor { id: diskRead;     sensorId: "disk/all/read";               updateRateLimit: 1000 }
    Sensors.Sensor { id: diskWrite;    sensorId: "disk/all/write";              updateRateLimit: 1000 }
    Sensors.Sensor { id: nvmeTemp;     sensorId: specs.sensors ? specs.sensors.nvmeTemp : ""; updateRateLimit: 5000 }
    Sensors.Sensor { id: uptimeSensor; sensorId: "os/system/uptime";            updateRateLimit: 30000 }

    // Exposed to tiles through `app: root`.
    readonly property alias cpuUsage: cpuUsage
    readonly property alias cpuFreq: cpuFreq
    readonly property alias gpuUsage: gpuUsage
    readonly property alias gpuVramUsed: gpuVramUsed
    readonly property alias gpuVramTotal: gpuVramTotal
    readonly property alias gpuTemp: gpuTemp
    readonly property alias gpuPower: gpuPower
    readonly property alias memUsed: memUsed
    readonly property alias memTotal: memTotal
    readonly property alias memCache: memCache
    readonly property alias netDown: netDown
    readonly property alias netUp: netUp
    readonly property alias netName: netName
    readonly property alias netIp: netIp
    readonly property alias diskUsed: diskUsed
    readonly property alias diskTotal: diskTotal
    readonly property alias diskRead: diskRead
    readonly property alias diskWrite: diskWrite
    readonly property alias nvmeTemp: nvmeTemp
    readonly property alias uptime: uptimeSensor
    readonly property real cpuTempValue: cpuTempAvg.value > 0 ? cpuTempAvg.value : (cpuTempMax.value || 0)

    History { id: cpuHistory }
    History { id: gpuHistory }
    History { id: downHistory }
    History { id: upHistory }
    readonly property alias cpuHistory: cpuHistory
    readonly property alias gpuHistory: gpuHistory
    readonly property alias downHistory: downHistory
    readonly property alias upHistory: upHistory

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            cpuHistory.push(cpuUsage.value);
            gpuHistory.push(gpuUsage.value);
            downHistory.push(netDown.value);
            upHistory.push(netUp.value);
        }
    }

    // ---- Static specs + battery (helper script) --------------------------

    property var specs: ({})
    property var batteryState: ({ present: false })

    readonly property string helper: "python3 '" + Qt.resolvedUrl("../code/specs.py").toString().replace(/^file:\/\//, "") + "'"

    P5Support.DataSource {
        engine: "executable"
        connectedSources: [root.helper]
        onNewData: (source, data) => {
            disconnectSource(source);
            try {
                root.specs = JSON.parse(data["stdout"]);
                root.batteryState = root.specs.battery || { present: false };
            } catch (e) {
                console.warn("Solidget: could not read specs:", e, data["stderr"]);
            }
        }
    }

    P5Support.DataSource {
        engine: "executable"
        interval: 60000
        connectedSources: root.batteryState.present ? [root.helper + " battery"] : []
        onNewData: (source, data) => {
            try { root.batteryState = JSON.parse(data["stdout"]); } catch (e) {}
        }
    }

    // GPU board power straight from sysfs (µW) when the driver exposes it.
    property real gpuPowerSysfs: 0
    P5Support.DataSource {
        engine: "executable"
        interval: 2000
        connectedSources: root.specs.sensors && root.specs.sensors.gpuPowerFile
            ? ["cat '" + root.specs.sensors.gpuPowerFile + "'"] : []
        onNewData: (source, data) => { root.gpuPowerSysfs = (parseInt(data["stdout"]) || 0) / 1e6; }
    }
    readonly property real gpuWatts: gpuPowerSysfs > 0 ? gpuPowerSysfs : (gpuPower.value || 0)

    // ---- Units & privacy --------------------------------------------------
    // Every tile formats through these, so one setting changes the whole board.

    readonly property bool useFahrenheit: Plasmoid.configuration.weatherUnit === "f"
        || (Plasmoid.configuration.weatherUnit === "auto" && Qt.locale().measurementSystem === Locale.ImperialUSSystem)
    readonly property bool decimalUnits: Plasmoid.configuration.dataUnits === "decimal"
    readonly property bool networkBits: Plasmoid.configuration.networkBits
    readonly property string tempUnit: useFahrenheit ? "°F" : "°C"
    function tempText(c) { return Fmt.temp(c, useFahrenheit); }
    function tempValue(c) { return useFahrenheit && c ? Fmt.toFahrenheit(c) : c; }
    function bytesText(b, decimals) { return Fmt.bytes(b, decimals, decimalUnits); }
    function rateText(b) { return Fmt.rate(b, decimalUnits, false); }
    function netRateText(b) { return Fmt.rate(b, decimalUnits, networkBits); }

    // Hide what identifies you or your network (on by default), so the
    // dashboard is safe to screenshot and share.
    readonly property bool masked: Plasmoid.configuration.maskSensitive
    readonly property string hostname: specs.system ? specs.system.hostname : ""
    readonly property string shownHostname: masked || !hostname ? i18n("This PC") : hostname
    readonly property string shownNetwork: {
        var iface = specs.sensors ? specs.sensors.netIface || "" : "";
        var kind = iface.indexOf("wl") === 0 ? i18n("Wi-Fi") : iface ? i18n("Ethernet") : "";
        if (masked) return kind;
        return [netName.value || kind, netIp.value || ""].filter(Boolean).join(" · ");
    }
    readonly property string shownPlace: masked ? "" : weatherModel.place

    // ---- Weather -----------------------------------------------------------

    Weather {
        id: weatherModel
        enabled: Plasmoid.configuration.weatherEnabled && root.visibleTiles.indexOf("clock") >= 0
        city: Plasmoid.configuration.weatherCity
        fahrenheit: root.useFahrenheit
    }
    readonly property alias weather: weatherModel

    // ---- Clipboard -------------------------------------------------------

    TextEdit { id: clipboardHelper; visible: false }
    function copyToClipboard(text) {
        clipboardHelper.text = text;
        clipboardHelper.selectAll();
        clipboardHelper.copy();
    }
    function copySpecs() {
        var c = Qt.createComponent("SpecsTile.qml");
        var t = c.createObject(null, { app: root });
        if (t) { copyToClipboard(t.asText()); t.destroy(); }
    }

    // ---- UI --------------------------------------------------------------

    property bool editing: false
    property bool showSettings: false
    onEditingChanged: if (!editing) { showSettings = false; dragRects = null; }

    // The glass tiles are the design; no Plasma frame behind them.
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Solidget Settings…")
            icon.name: "document-edit"
            onTriggered: root.showSettings = true
        },
        PlasmaCore.Action {
            text: i18n("Edit Layout")
            icon.name: "transform-move"
            onTriggered: { root.showSettings = false; root.editing = true; }
        },
        PlasmaCore.Action {
            text: i18n("Copy PC Specs")
            icon.name: "edit-copy"
            onTriggered: root.copySpecs()
        }
    ]

    preferredRepresentation: fullRepresentation
    compactRepresentation: Kirigami.Icon { source: "computer" }

    fullRepresentation: Item {
        id: full

        Layout.minimumWidth: Kirigami.Units.gridUnit * 10
        Layout.minimumHeight: Kirigami.Units.gridUnit * 8
        Layout.preferredWidth: Kirigami.Units.gridUnit * 30
        Layout.preferredHeight: Kirigami.Units.gridUnit * 44

        HoverHandler { id: hover }

        // Plain Flickable rather than ScrollView: ScrollView resizes its
        // content, which fights the layout engine and causes binding loops.
        Flickable {
            id: scroll
            anchors.fill: parent
            contentWidth: width
            contentHeight: board.height
            clip: contentHeight > height
            interactive: !root.editing
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: PlasmaComponents.ScrollBar { visible: scroll.contentHeight > scroll.height }

            Item {
                id: board
                width: scroll.width
                height: Math.max(scroll.height, plan.rows * (plan.cellH + gap) - gap)

                readonly property real gap: Math.max(Kirigami.Units.largeSpacing, Math.min(scroll.width, scroll.height) / 70)
                readonly property var plan: Bento.plan(root.visibleTiles, scroll.width, scroll.height,
                                                        Kirigami.Units.gridUnit, gap, root.density, true, root.layoutSpans,
                                                        root.layoutRects, root.isPortrait)
                readonly property var rectsById: {
                    var m = {};
                    plan.rects.forEach(function (r) { m[r.id] = r; });
                    return m;
                }

                // ---- Hand editing: fixed positions ----
                // The first move/resize snapshots every tile's current spot;
                // from then on tiles stay put. Only the tile being edited
                // changes, and tiles it overlaps are pushed straight down.
                function cellAt(p) {
                    return { x: Math.floor(p.x / (plan.cellW + gap)), y: Math.floor(p.y / (plan.cellH + gap)) };
                }
                Component.onCompleted: root.boardRef = board
                onWidthChanged: if (scroll.height > 0) root.boardAspect = scroll.width / scroll.height
                Connections {
                    target: scroll
                    function onHeightChanged() { if (scroll.height > 0) root.boardAspect = scroll.width / scroll.height; }
                }

                // Every tile's spot as shown now (hidden tiles keep their saved spot).
                function currentRects() {
                    var m = {};
                    var saved = root.manualRects || {};
                    Object.keys(saved).forEach(function (k) { m[k] = Object.assign({}, saved[k]); });
                    plan.rects.forEach(function (r) { m[r.id] = { x: r.x, y: r.y, w: r.w, h: r.h }; });
                    return m;
                }
                function copyRects(m) {
                    var out = {};
                    Object.keys(m).forEach(function (k) { out[k] = Object.assign({}, m[k]); });
                    return out;
                }

                property var editBase: null     // layout when the gesture began
                property var grab: null         // pointer offset inside the tile, in cells
                property string draggingId: ""
                property string lastCell: ""

                function beginDrag(id, p) {
                    editBase = currentRects();
                    var c = cellAt(p);
                    grab = { x: c.x - editBase[id].x, y: c.y - editBase[id].y };
                    draggingId = id;
                    lastCell = "";
                }
                function dragMove(id, p) {
                    if (!editBase) return;
                    var c = cellAt(p);
                    var r = editBase[id];
                    var nx = Math.max(0, Math.min(plan.cols - r.w, c.x - grab.x));
                    var ny = Math.max(0, c.y - grab.y);
                    var key = nx + "," + ny;
                    if (key === lastCell) return;
                    lastCell = key;
                    // Always start from the layout at drag start, so tiles that
                    // were pushed aside come back when you move on.
                    var m = copyRects(editBase);
                    m[id].x = nx;
                    m[id].y = ny;
                    root.dragRects = Bento.resolve(m, plan.cols, id);
                }
                function endDrag() {
                    if (root.dragRects) root.setRects(root.dragRects);
                    root.dragRects = null;
                    editBase = null;
                    draggingId = "";
                }

                function resizeTo(id, w, h) {
                    if (!editBase) editBase = currentRects();
                    var m = copyRects(editBase);
                    m[id].w = Math.max(1, Math.min(plan.cols - m[id].x, w));
                    m[id].h = Math.max(1, Math.min(8, h));
                    root.dragRects = Bento.resolve(m, plan.cols, id);
                }
                function endResize(id) {
                    if (root.dragRects) root.setRects(root.dragRects);
                    root.dragRects = null;
                    editBase = null;
                }

                // From Settings / the tile's "default size" button.
                function setTileSize(id, value) {
                    var m = currentRects();
                    if (!m[id]) return;
                    var choices = Bento.spansFor(id, plan.cols, root.isPortrait);
                    var size = value === null || value === undefined || value === -1 ? choices[0]
                             : typeof value === "number" ? choices[Math.min(value, choices.length - 1)]
                             : [value.w, value.h];
                    m[id].w = Math.max(1, Math.min(plan.cols - m[id].x, size[0]));
                    m[id].h = Math.max(1, size[1]);
                    root.setRects(Bento.resolve(m, plan.cols, id));
                }

                // Where the dragged tile will land.
                Rectangle {
                    readonly property var r: board.draggingId ? board.rectsById[board.draggingId] : null
                    visible: !!r
                    z: 1
                    x: r ? r.x * (board.plan.cellW + board.gap) : 0
                    y: r ? r.y * (board.plan.cellH + board.gap) : 0
                    width: r ? r.w * board.plan.cellW + (r.w - 1) * board.gap : 0
                    height: r ? r.h * board.plan.cellH + (r.h - 1) * board.gap : 0
                    radius: Kirigami.Units.gridUnit
                    color: Qt.rgba(0.5, 0.55, 1, 0.12)
                    border.width: 2
                    border.color: "#818cf8"
                    Behavior on x { NumberAnimation { duration: Kirigami.Units.shortDuration } }
                    Behavior on y { NumberAnimation { duration: Kirigami.Units.shortDuration } }
                }

                // One delegate per known tile, kept alive across reorders, so
                // a tile keeps its state (and the one being dragged survives).
                Repeater {
                    id: tileRepeater
                    model: root.allTiles

                    Loader {
                        id: slot
                        required property string modelData
                        readonly property bool shown: root.visibleTiles.indexOf(modelData) >= 0
                        readonly property var r: board.rectsById[modelData] || { x: 0, y: 0, w: 1, h: 1, manual: false }
                        readonly property real cellX: r.x * (board.plan.cellW + board.gap)
                        readonly property real cellY: r.y * (board.plan.cellH + board.gap)

                        property bool dragging: false
                        property real dragX: 0
                        property real dragY: 0

                        active: shown
                        visible: shown
                        z: dragging ? 10 : 0
                        x: dragging ? dragX : cellX
                        y: dragging ? dragY : cellY
                        width: r.w * board.plan.cellW + (r.w - 1) * board.gap
                        height: r.h * board.plan.cellH + (r.h - 1) * board.gap

                        Behavior on x { enabled: !slot.dragging; NumberAnimation { duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic } }
                        Behavior on y { enabled: !slot.dragging; NumberAnimation { duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic } }
                        Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }

                        // Staggered entrance whenever a tile appears.
                        opacity: 0
                        scale: 0.96
                        onLoaded: { opacity = 0; scale = 0.96; entrance.restart(); }
                        SequentialAnimation {
                            id: entrance
                            PauseAnimation { duration: Math.max(0, root.visibleTiles.indexOf(slot.modelData)) * 60 }
                            ParallelAnimation {
                                NumberAnimation { target: slot; property: "opacity"; to: 1; duration: 500; easing.type: Easing.OutCubic }
                                NumberAnimation { target: slot; property: "scale"; to: 1; duration: 600; easing.type: Easing.OutBack }
                            }
                        }

                        sourceComponent: {
                            switch (modelData) {
                            case "clock":     return clockTile;
                            case "specs":     return specsTile;
                            case "cpu":       return cpuTile;
                            case "gpu":       return gpuTile;
                            case "memory":    return memoryTile;
                            case "temps":     return tempsTile;
                            case "network":   return networkTile;
                            case "cores":     return coresTile;
                            case "processes": return processesTile;
                            case "power":     return powerTile;
                            case "disk":      return diskTile;
                            case "battery":   return batteryTile;
                            }
                            return null;
                        }

                        TileEditOverlay {
                            anchors.fill: parent
                            visible: root.editing && slot.shown
                            z: 5
                            app: root
                            boardItem: board
                            tileSlot: slot
                        }
                    }
                }

                PlasmaComponents.Label {
                    visible: root.visibleTiles.length === 0
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: i18n("All tiles are hidden. Click the pencil, then Settings, to bring some back.")
                    opacity: 0.6
                }
            }
        }

        // ---- Edit-mode toolbar ----
        Rectangle {
            id: toolbar
            visible: root.editing && !root.showSettings
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Kirigami.Units.largeSpacing
            z: 20
            width: toolRow.implicitWidth + Kirigami.Units.largeSpacing * 2
            height: toolRow.implicitHeight + Kirigami.Units.smallSpacing * 2
            radius: height / 2
            color: Qt.rgba(0.07, 0.08, 0.12, 0.92)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)

            RowLayout {
                id: toolRow
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing
                PlasmaComponents.Label {
                    text: i18n("Drag to move · drag the corner to resize")
                    opacity: 0.6
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    visible: full.width > Kirigami.Units.gridUnit * 30
                    Layout.rightMargin: Kirigami.Units.smallSpacing
                }
                PlasmaComponents.ToolButton {
                    icon.name: "configure"
                    text: i18n("Settings")
                    display: QQC2.AbstractButton.TextBesideIcon
                    onClicked: root.showSettings = true
                }
                PlasmaComponents.ToolButton {
                    icon.name: "edit-undo"
                    text: i18n("Reset layout")
                    display: QQC2.AbstractButton.TextBesideIcon
                    onClicked: root.resetLayout()
                    QQC2.ToolTip.text: i18n("Back to the %1 preset: its tiles, order and automatic sizes", root.presets[root.currentPreset].name)
                    QQC2.ToolTip.visible: hovered
                }
                PlasmaComponents.Button {
                    icon.name: "dialog-ok-apply"
                    text: i18n("Done")
                    onClicked: root.editing = false
                }
            }
        }

        // ---- Settings sheet floats over the live board ----
        Rectangle {
            anchors.fill: parent
            visible: root.showSettings
            z: 25
            color: Qt.rgba(0, 0, 0, 0.25)
            MouseArea { anchors.fill: parent; onClicked: root.showSettings = false }
        }

        EditPanel {
            id: editor
            app: root
            z: 30
            width: Math.min(full.width, Kirigami.Units.gridUnit * 24)
            height: full.height
            x: root.showSettings ? full.width - width : full.width + Kirigami.Units.gridUnit
            visible: x < full.width
            Behavior on x { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }
        }

        // Pencil appears on hover, so the dashboard stays clean otherwise.
        PlasmaComponents.ToolButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Kirigami.Units.smallSpacing
            z: 20
            visible: !root.editing && !root.showSettings
            opacity: hover.hovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
            icon.name: "document-edit"
            onClicked: root.showSettings = true
            QQC2.ToolTip.text: i18n("Settings")
            QQC2.ToolTip.visible: hovered
        }
    }

    Component { id: clockTile;     ClockTile     { app: root } }
    Component { id: specsTile;     SpecsTile     { app: root } }
    Component { id: cpuTile;       CpuTile       { app: root } }
    Component { id: gpuTile;       GpuTile       { app: root } }
    Component { id: memoryTile;    MemoryTile    { app: root } }
    Component { id: tempsTile;     TempsTile     { app: root } }
    Component { id: networkTile;   NetworkTile   { app: root } }
    Component { id: coresTile;     CoresTile     { app: root } }
    Component { id: processesTile; ProcessesTile { app: root } }
    Component { id: powerTile;     PowerTile     { app: root } }
    Component { id: diskTile;      DiskTile      { app: root } }
    Component { id: batteryTile;   BatteryTile   { app: root } }
}
