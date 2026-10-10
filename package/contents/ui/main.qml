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
                       tiles: ["clock", "specs", "cpu", "gpu", "memory", "temps", "network"] },
        everything:  { name: i18n("Everything"),  hint: i18n("Every tile your PC supports — great full screen"),
                       tiles: ["clock", "specs", "cpu", "gpu", "cores", "processes", "memory", "temps", "network", "power", "disk", "battery"] },
        showcase:    { name: i18n("Showcase"),    hint: i18n("Your build front and center"),
                       tiles: ["specs", "cpu", "gpu", "temps", "power"] },
        performance: { name: i18n("Performance"), hint: i18n("For gaming and heavy work"),
                       tiles: ["cpu", "gpu", "cores", "temps", "power", "processes"] },
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

    // Live previews while dragging/resizing in edit mode; null otherwise.
    property var dragOrder: null
    property var dragSpans: null
    readonly property var layoutOrder: dragOrder || order
    readonly property var layoutSpans: dragSpans || spans
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

    function applyPreset(id) {
        var tiles = presets[id].tiles;
        var rest = allTiles.filter(function (t) { return tiles.indexOf(t) < 0; });
        Plasmoid.configuration.tileOrder = tiles.concat(rest).join(",");
        Plasmoid.configuration.hiddenTiles = rest.join(",");
        Plasmoid.configuration.tileSpans = "";
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

    function setAllSpans(m) {
        Plasmoid.configuration.tileSpans = Object.keys(m).map(function (k) {
            var v = m[k];
            return k + ":" + (typeof v === "object" ? v.w + "x" + v.h : v);
        }).join(",");
        Plasmoid.configuration.customized = true;
    }

    // value: null to go back to auto, a span index, or { w, h }. Other
    // tiles keep the size they have on screen (see Board.frozenSpans).
    property var boardRef: null
    function setTileSpan(id, value) {
        var m = boardRef ? boardRef.frozenSpans() : Object.assign({}, spans);
        if (value === null || value === undefined || value === -1) delete m[id];
        else m[id] = value;
        setAllSpans(m);
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

    // ---- Weather -----------------------------------------------------------

    Weather {
        id: weatherModel
        enabled: Plasmoid.configuration.weatherEnabled && root.visibleTiles.indexOf("clock") >= 0
        city: Plasmoid.configuration.weatherCity
        fahrenheit: Plasmoid.configuration.weatherUnit === "f"
            || (Plasmoid.configuration.weatherUnit === "auto" && Qt.locale().measurementSystem === Locale.ImperialUSSystem)
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
    onEditingChanged: if (!editing) { showSettings = false; dragOrder = null; dragSpans = null; }

    // The glass tiles are the design; no Plasma frame behind them.
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Customize Solidget…")
            icon.name: "document-edit"
            onTriggered: root.editing = true
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
                                                        Kirigami.Units.gridUnit, gap, root.density, true, root.layoutSpans)
                readonly property var rectsById: {
                    var m = {};
                    plan.rects.forEach(function (r) { m[r.id] = r; });
                    return m;
                }

                // ---- Drag to reorder ----
                property string lastTarget: ""
                function cellAt(p) {
                    return { x: Math.floor(p.x / (plan.cellW + gap)), y: Math.floor(p.y / (plan.cellH + gap)) };
                }
                Component.onCompleted: root.boardRef = board

                // Every visible tile's size as currently shown, as exact sizes.
                // Taken at the start of a hand edit so only the tile being
                // edited changes size; the others keep theirs and just move.
                function frozenSpans() {
                    var m = Object.assign({}, root.spans);
                    plan.rects.forEach(function (r) {
                        var v = m[r.id];
                        if (!(v && typeof v === "object")) m[r.id] = { w: r.w, h: r.h };
                    });
                    return m;
                }

                // Pointer over another tile: take its place; the rest reflow.
                function dragOver(id, p) {
                    if (!root.dragSpans) root.dragSpans = frozenSpans();
                    var c = cellAt(p);
                    var target = "";
                    plan.rects.forEach(function (r) {
                        if (r.id !== id && c.x >= r.x && c.x < r.x + r.w && c.y >= r.y && c.y < r.y + r.h)
                            target = r.id;
                    });
                    if (target === lastTarget) return;
                    lastTarget = target;
                    if (!target) return;
                    var o = root.layoutOrder.slice();
                    var from = o.indexOf(id), to = o.indexOf(target);
                    o.splice(from, 1);
                    o.splice(to, 0, id);
                    root.dragOrder = o;
                }
                function endDrag() {
                    lastTarget = "";
                    if (root.dragOrder) {
                        root.setAllSpans(root.dragSpans || frozenSpans());
                        root.persistOrder(root.dragOrder);
                    }
                    root.dragOrder = null;
                    root.dragSpans = null;
                }

                // ---- Drag the corner to resize ----
                function resizeTo(id, w, h) {
                    var m = root.dragSpans ? Object.assign({}, root.dragSpans) : frozenSpans();
                    m[id] = { w: Math.max(1, Math.min(plan.cols, w)), h: Math.max(1, Math.min(8, h)) };
                    root.dragSpans = m;
                }
                function endResize(id) {
                    if (root.dragSpans) root.setAllSpans(root.dragSpans);
                    root.dragSpans = null;
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
            visible: !root.editing
            opacity: hover.hovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
            icon.name: "document-edit"
            onClicked: root.editing = true
            QQC2.ToolTip.text: i18n("Edit layout")
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
