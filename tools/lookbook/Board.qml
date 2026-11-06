import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import "../../package/contents/ui"
import "../../package/contents/code/palette.js" as Palette
import "../../package/contents/code/format.js" as Fmt

// One board in one look, with made-up readings, for tools/lookbook/lookbook.py.
// The look object mirrors `look` in main.qml; keep the two in step.
Rectangle {
    id: root
    readonly property var args: Qt.application.arguments
    readonly property string styleKey: args[args.length - 3]
    readonly property string themeKey: args[args.length - 2]
    readonly property real power: +args[args.length - 1]
    width: 1072; height: 1630
    // A dim wallpaper, light at one end, so see-through cards show it.
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: "#1b2a3a" }
        GradientStop { position: 0.6; color: "#0a0d12" }
        GradientStop { position: 1; color: "#6d7f8c" }
    }

    FontLoader { id: monoFont; source: "../../package/contents/fonts/JetBrainsMono-Light.ttf" }
    FontLoader { source: "../../package/contents/fonts/JetBrainsMono-Regular.ttf" }
    FontLoader { source: "../../package/contents/fonts/JetBrainsMono-Medium.ttf" }
    FontLoader { id: roundFont; source: "../../package/contents/fonts/Manrope-ExtraBold.ttf" }
    FontLoader { source: "../../package/contents/fonts/Manrope-Bold.ttf" }
    FontLoader { source: "../../package/contents/fonts/Manrope-SemiBold.ttf" }
    FontLoader { id: pixelFont; source: "../../package/contents/fonts/Silkscreen-Regular.ttf" }

    readonly property real unit: Math.min(245, 252 * 1.4) / 14
    readonly property var look: {
        var st = Palette.STYLES[styleKey], th = Palette.THEMES[themeKey];
        var native = st.plasmaFrame === true;
        var dark = th.dark === null ? true : th.dark;
        var surface = st.bodyAlpha;
        return {
            style: styleKey, theme: themeKey, dark: dark, plasmaFrame: native,
            body: th.body || "#20232a", text: th.text || "",
            bodyAlpha: th.opaque && !native ? 1 : surface === null ? (dark ? 0.66 : 0.72)
                     : typeof surface === "object" ? (dark ? surface.dark : surface.light) : surface,
            radius: st.radius, glow: Palette.glowFor(styleKey, themeKey), shadow: st.shadow, border: st.border,
            highlight: st.highlight, roundCaps: st.roundCaps, tint: th.opaque ? 0 : st.tint, bevel: st.bevel,
            hardShadow: st.hardShadow,
            fontFamily: st.font === "pixel" ? pixelFont.name : "",
            meter: st.meter, chart: st.chart,
            figureFamily: st.figures === "mono" ? monoFont.name : st.figures === "round" ? roundFont.name : "",
            figureWeight: ({ hairline: Font.Thin, thin: Font.ExtraLight, light: Font.Light, regular: Font.Normal,
                             semi: Font.DemiBold, bold: Font.Bold, heavy: Font.ExtraBold })[st.figureWeight] || Font.Light,
            figures: st.figures || "", neonEdge: st.edge === "neon", raised: st.raised === true,
            inkBorder: st.inkBorder === true, header: st.header || "caps", gauge: st.gauge || "ring",
            details: st.details || "rows", heatBar: st.heatBar || "thin", controls: st.controls || "round",
            today: st.today || "circle", spotlight: st.spotlight || ({}),
            rgb: th.rgb === true && !native, rgbClock: rgbClock, edge: !native && th.edge ? th.edge : "",
            tintBy: st.tintBy || "",
            groupTints: st.tintBy === "group" ? ({ life: Palette.groupTint(themeKey, "life", plasmaPalette),
                                                   personal: Palette.groupTint(themeKey, "personal", plasmaPalette) }) : ({}),
            unit: unit
        };
    }
    readonly property var plasmaPalette: Palette.plasmaPalette("#3daee9", true)
    QtObject { id: rgbClock; property real phase: 0.3 }

    Kirigami.Theme.inherit: false
    Kirigami.Theme.textColor: look.text || "#eff0f1"
    Kirigami.Theme.backgroundColor: look.body

    Weather { id: wx; ready: true; temp: 24; feelsLike: 30; code: 95; humidity: 98; isDay: false }
    function hist(base, amp, seed) {
        var a = [];
        for (var i = 0; i < 60; i++)
            a.push(Math.max(0, base + amp * Math.sin(i * 0.7 + seed) * Math.sin(i * 0.23 + seed * 2) + (i % 13 === 5 ? amp * 3 : 0)));
        return a;
    }
    property var player: ({ track: "I bought every SATISFYING fidget toy on the internet", artist: "EXCESSORIZE ME.",
        identity: "Chrome", playbackStatus: Mpris.PlaybackStatus.Playing, length: 1001e6, artUrl: "",
        canGoPrevious: false, canGoNext: false, container: { updatePosition: function () {}, position: 254e6 } })

    QtObject {
        id: fake
        property var look: root.look
        property string themeId: root.themeKey
        property bool nativeStyle: root.look.plasmaFrame
        property bool twelveHour: true; property bool masked: false; property string shownPlace: ""
        property bool editing: false; property int tick: 0
        property var uptime: ({ value: 3600 }); property var weather: wx
        property var specs: ({ cpu: { name: "AMD Ryzen 5 5600X", threads: 12 }, gpus: [{ name: "AMD Radeon RX 6600" }],
                               sensors: { fans: [{ label: "GPU fan", id: "none" }], gpuPowerFile: "x" } })
        property var batteryState: ({ present: false }); property real gpuWatts: root.power
        property real cpuTempValue: 59; property var gpuTemp: ({ value: 54 }); property var nvmeTemp: ({ value: 51 })
        readonly property string tempUnit: "°C"
        property var cpuUsage: ({ value: 4 }); property var cpuFreq: ({ value: 3450 }); property var cpuHistory: ({ values: root.hist(4, 4, 1) })
        property var gpuUsage: ({ value: 6 }); property var gpuHistory: ({ values: root.hist(6, 5, 2) })
        property var gpuVramUsed: ({ value: 785 * 1048576 }); property var gpuVramTotal: ({ value: 8 * 1073741824 })
        property var memTotal: ({ value: 31 * 1073741824 }); property var memUsed: ({ value: 5.2 * 1073741824 }); property var memCache: ({ value: 7.8 * 1073741824 })
        property var diskTotal: ({ value: 477e9 }); property var diskUsed: ({ value: 76e9 })
        property var diskRead: ({ value: 0 }); property var diskWrite: ({ value: 0 })
        property var readHistory: ({ values: root.hist(0, 2e5, 3) }); property var writeHistory: ({ values: root.hist(0, 1e5, 4) })
        property var netDown: ({ value: 344 }); property var netUp: ({ value: 424 }); property bool onWifi: true
        property int netSignal: 70; property string shownNetwork: "Wi-Fi"
        property var downHistory: ({ values: root.hist(400, 900, 5) }); property var upHistory: ({ values: root.hist(200, 500, 6) })
        function bytesText(b, d) { return Fmt.bytes(b, d, false); }
        function rateText(b) { return Fmt.rate(b, false, false); }
        function netRateText(b) { return Fmt.rate(b, false, false); }
        function accent(id) { return root.look.plasmaFrame ? Palette.nativePair(id, "#3daee9", "#27ae60")[0] : Palette.accentPair(root.themeKey, id, root.plasmaPalette)[0]; }
        function accent2(id) { return root.look.plasmaFrame ? Palette.nativePair(id, "#3daee9", "#27ae60")[1] : Palette.accentPair(root.themeKey, id, root.plasmaPalette)[1]; }
        function hoursMinutes(d) { return "6:44"; }
        function timeText(d) { return Qt.formatTime(d, "h:mm AP"); }
        function tempText(c) { return Fmt.temp(c, false); }
        function tempValue(c) { return c; }
        function heat(t) { return root.look.plasmaFrame ? Palette.nativeHeat(t, "#27ae60", "#f67400", "#da4453") : Palette.heatFor(root.themeKey, t, root.look.dark); }
        function tempColor(c) { return heat(Palette.tempLevel(c)); }
    }

    // [tile file, x, y, w, h, tile id, media player: "play" / "none"]
    readonly property real g: 15
    readonly property real one: 245
    readonly property real two: 505
    readonly property real row: 252
    readonly property var cells: [
        ["ClockTile", 0, 0, two, row, "clock"], ["TempsTile", 520, 0, one, row, "temps"], ["PowerTile", 780, 0, one, row, "power"],
        ["MediaTile", 0, 1, two, row, "media", "play"], ["NetworkTile", 520, 1, two, row, "network"],
        ["CpuTile", 0, 2, two, row, "cpu"], ["GpuTile", 520, 2, two, row, "gpu"],
        ["ProcessesTile", 0, 3, two, row, "processes"], ["CoresTile", 520, 3, two, row, "cores"],
        ["MemoryTile", 0, 4, one, row, "memory"], ["DiskTile", 260, 4, one, row, "disk"],
        ["QuoteTile", 520, 4, one, row, "quote"], ["NoteTile", 780, 4, one, row, "note"],
        ["MediaTile", 0, 5, two, row, "media", "none"], ["MediaTile", 520, 5, one, row, "media", "play"],
        ["ClockTile", 780, 5, one, row, "clock"]
    ]
    Repeater {
        model: root.cells
        Loader {
            id: cell
            required property var modelData
            readonly property string media: modelData[6] || ""
            x: 16 + modelData[1]; y: 16 + modelData[2] * (root.row + root.g)
            width: modelData[3]; height: modelData[4]
            Component.onCompleted: setSource("../../package/contents/ui/" + modelData[0] + ".qml",
                { app: fake, look: root.look, tileId: modelData[5] })
            // Now playing reads the desktop's real players; pin it to ours.
            Timer {
                interval: 600; running: cell.media !== ""; repeat: true
                onTriggered: {
                    cell.item.player = cell.media === "play" ? root.player : null;
                    if (cell.media === "play") cell.item.positionUs = 254e6;
                }
            }
        }
    }
}
