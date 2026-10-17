import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../code/format.js" as Fmt
import "../code/sky.js" as Sky

// How long the PC has been on, over a scene you pick: the sky outside
// (sunrise, day, sunset, stars), a heartbeat, a face that gets sleepy, a
// little solar system, drifting colors, your own picture, or nothing.
// Font, size, color, wording and position are all up to you (Settings →
// Personal). Click the tile to try the next scene.
GlassTile {
    id: tile
    required property var app

    readonly property var opt: app.uptimeOptions
    readonly property string scene: opt.scene

    // Boot time from the sensor, then counted locally so the clock format
    // can tick every second (the sensor itself updates every 30 s).
    property real bootAt: 0
    property date now: new Date()
    readonly property real seconds: bootAt > 0 ? Math.max(0, now.getTime() / 1000 - bootAt) : (app.uptime.value || 0)
    // The sensor's reading only changes every 30 s, but the app hands it
    // over every second: re-sync only on a fresh reading, or a stale one
    // would make the count jump back and forth.
    property real lastReading: -1
    function syncBoot() {
        var up = app.uptime.value || 0;
        if (up <= 0 || up === lastReading) return;
        lastReading = up;
        var boot = Date.now() / 1000 - up;
        if (bootAt <= 0 || Math.abs(boot - bootAt) > 5) bootAt = boot;
    }
    Connections {
        target: app
        function onUptimeChanged() { tile.syncBoot(); }
        function onTickChanged() { tile.now = new Date(); }
    }
    Component.onCompleted: syncBoot()

    readonly property var parts: Fmt.uptimeParts(seconds)
    readonly property string bigText: {
        switch (opt.format) {
        case "clock": return Fmt.uptimeClock(seconds);
        case "days":  return (seconds / 86400).toFixed(seconds < 864000 ? 1 : 0);
        case "long":
            if (parts.d > 0) return i18np("%1 day", "%1 days", parts.d) + (parts.h > 0 ? ", " + i18np("%1 hour", "%1 hours", parts.h) : "");
            if (parts.h > 0) return i18np("%1 hour", "%1 hours", parts.h) + (parts.m > 0 ? ", " + i18np("%1 minute", "%1 minutes", parts.m) : "");
            return i18np("%1 minute", "%1 minutes", parts.m);
        }
        return Fmt.uptime(seconds) || "0m";
    }
    readonly property string unitText: opt.format === "days" ? i18n("days") : ""
    readonly property string labelText: opt.label !== "" ? opt.label : i18n("Up for")
    readonly property string sinceText: bootAt > 0
        ? i18n("since %1", Qt.formatDateTime(new Date(bootAt * 1000), seconds > 86400 * 6 ? "d MMM, hh:mm" : "ddd hh:mm")) : ""
    readonly property string recordText: app.uptimeRecord > seconds + 60 ? i18n("Record %1", Fmt.uptime(app.uptimeRecord)) : app.uptimeRecord > 3600 ? i18n("New record!") : ""

    // Scenes that cover the card get light text with a shadow.
    readonly property bool fullBleed: scene === "sky" || scene === "aurora" || (scene === "image" && opt.image !== "")
    readonly property color textColor: opt.color === "light" ? "#ffffff"
        : opt.color === "dark" ? "#14161f"
        : opt.color === "accent" ? accent
        : fullBleed ? "#ffffff" : app.boardText
    readonly property string fontFamily: opt.font === "pixel" ? app.pixelFontName
        : opt.font !== "" ? opt.font : (numberFamily || Kirigami.Theme.defaultFont.family)
    readonly property int fontWeight: opt.weight === "light" ? Font.Light : opt.weight === "bold" ? Font.Bold
        : opt.weight === "regular" ? Font.Normal
        : (numberFamily || nativeOn ? Font.Normal : Font.ExtraLight)
    readonly property real sizeScale: ({ s: 0.7, m: 1, l: 1.3, xl: 1.6 })[opt.size] || 1

    title: labelText
    subtitle: scene === "mood" ? moodScene.caption : scene === "pulse" ? "♥ " + i18n("%1 bpm", pulseScene.bpm)
        : scene === "binary" ? "0x" + Math.floor(seconds).toString(16) : ""
    accent: app.accent("uptime")
    accent2: app.accent2("uptime")
    level: 0.4
    Kirigami.Theme.inherit: !fullBleed
    Kirigami.Theme.textColor: textColor

    backdrop: [
        // The terminal is the whole card, in place of the big number.
        Loader {
            anchors.fill: parent
            active: tile.scene === "terminal"
            sourceComponent: UptimeTerminal {
                tick: visible ? tile.app.tick : 0
                pretty: "up " + [tile.parts.d > 0 ? i18np("%1 day", "%1 days", tile.parts.d) : "",
                                 tile.parts.h > 0 ? i18np("%1 hour", "%1 hours", tile.parts.h) : "",
                                 i18np("%1 minute", "%1 minutes", tile.parts.m)].filter(Boolean).join(", ")
                since: tile.opt.showBoot && tile.bootAt > 0 ? Qt.formatDateTime(new Date(tile.bootAt * 1000), "yyyy-MM-dd hh:mm:ss") : ""
                title: tile.labelText.toLowerCase() + " — zsh"
                color: "#4ade80"
                text: "#e5e7eb"
                radius: 0
                fontFamily: tile.opt.font !== "" ? tile.fontFamily : "monospace"
            }
        },
        // Ticks around the card's own border, in the padding, out of the way of the numbers.
        Loader {
            anchors.fill: parent
            active: tile.scene === "ticks"
            sourceComponent: UptimeTicks {
                tick: tile.app.tick
                seconds: tile.seconds
                color: tile.textColor
                accent: tile.accent
                margin: tile.tickMargin
                length: tile.tickLen
                thickness: Math.max(2, tile.u * 0.17)
                cornerRadius: Math.max(tile.radius, length * 1.4)
            }
        },
        Loader {
            anchors.fill: parent
            active: tile.scene === "sky"
            sourceComponent: UptimeSky { app: tile.app; now: tile.now; tick: tile.app.tick }
        },
        Loader {
            anchors.fill: parent
            active: tile.scene === "aurora"
            sourceComponent: UptimeAurora {
                tick: tile.app.tick
                color: tile.accent
                color2: tile.accent2
                base: Sky.mix(tile.baseColor.toString().slice(0, 7), "#000000", tile.dark ? 0.45 : 0.75)
            }
        },
        Loader {
            anchors.fill: parent
            active: tile.scene === "image" && tile.opt.image !== ""
            sourceComponent: Item {
                Image {
                    anchors.fill: parent
                    source: tile.opt.image
                    fillMode: tile.opt.fit === "fit" ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                    asynchronous: true
                    // Never decode a huge photo at full size for a small tile.
                    sourceSize.width: Math.min(2048, tile.width * 2)
                    sourceSize.height: Math.min(2048, tile.height * 2)
                    smooth: true
                }
                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: tile.opt.dim / 100
                }
            }
        }
    ]

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.app.nextUptimeScene()
    }

    // ---- Where things go ----
    readonly property bool ticks: scene === "ticks"
    // The ticks frame the numbers like a watch face, so they sit in the middle there.
    readonly property string align: ticks ? "center" : opt.align
    // A picture that needs its own space next to the numbers.
    readonly property bool figureScene: scene === "pulse" || scene === "mood" || scene === "orbit" || scene === "binary"
    readonly property bool beside: wide && (scene === "orbit" || scene === "mood")
    // Ticks run round the edge: the title moves inside them, and everything
    // keeps clear of them.
    showHeader: !ticks && scene !== "terminal"
    readonly property real tickMargin: Math.max(3, pad * 0.3)
    readonly property real tickLen: Math.max(7, u * 0.8)
    readonly property real inset: ticks ? Math.max(0, tickMargin + tickLen * 1.5 + u * 0.5 - pad) : 0

    // The free band for the picture: above the numbers, below them, or (wide
    // tiles, middle position) the whole area.
    readonly property Item area: textBlock.parent
    readonly property real gap: u * 0.4
    readonly property real bandY: !area || beside || align === "center" ? 0
        : align === "top" ? textBlock.y + textBlock.height + gap : 0
    readonly property real bandH: !area ? 0 : beside || align === "center" ? area.height
        : align === "top" ? Math.max(0, area.height - bandY) : Math.max(0, textBlock.y - gap)
    readonly property real figure: !area ? 0 : beside ? area.height : Math.min(area.width, bandH)

    UptimePulse {
        id: pulseScene
        visible: tile.scene === "pulse"
        x: 0; y: tile.bandY
        width: parent.width; height: tile.bandH
        app: tile.app
        tick: visible ? tile.app.tick : 0
        color: tile.accent
        opacity: tile.align === "center" ? 0.35 : 1
    }
    UptimeBinary {
        visible: tile.scene === "binary"
        x: 0; y: tile.bandY
        width: parent.width; height: tile.bandH
        tick: visible ? tile.app.tick : 0
        seconds: visible ? tile.seconds : 0
        color: tile.accent
        text: tile.textColor
        opacity: tile.align === "center" ? 0.35 : 1
    }
    UptimeOrbit {
        visible: tile.scene === "orbit"
        x: tile.beside ? parent.width - width : (parent.width - width) / 2
        y: tile.bandY + (tile.bandH - height) / 2
        width: tile.figure; height: tile.figure
        seconds: visible ? tile.seconds : 0
        color: tile.accent
        color2: tile.accent2
        line: Qt.rgba(tile.textColor.r, tile.textColor.g, tile.textColor.b, 0.22)
        opacity: tile.beside || tile.align !== "center" ? 1 : 0.35
    }
    UptimeMood {
        id: moodScene
        visible: tile.scene === "mood"
        x: tile.beside ? parent.width - width : (parent.width - width) / 2
        y: tile.bandY + (tile.bandH - height) / 2
        width: tile.figure; height: tile.figure
        app: tile.app
        tick: visible ? tile.app.tick : 0
        seconds: visible ? tile.seconds : 0
        color: tile.accent
        glow: Sky.mix(tile.accent.toString().slice(0, 7), "#ffffff", 0.55)
        opacity: tile.beside || tile.align !== "center" ? 1 : 0.35
    }

    // ---- The numbers ----
    // Measured at 100 px, then scaled to fit the width exactly.
    TextMetrics {
        id: metrics
        font.family: tile.fontFamily
        font.weight: tile.fontWeight
        font.pixelSize: 100
        text: big.text
    }
    ColumnLayout {
        id: textBlock
        z: 1
        visible: tile.scene !== "terminal"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: tile.inset
        anchors.rightMargin: tile.beside ? parent.height + tile.u : tile.inset
        // Placed with y, not by switching anchors: anchors swapped while
        // running can leave it stretched to the full height.
        height: implicitHeight
        y: tile.align === "top" ? tile.inset
         : tile.align === "bottom" ? parent.height - height - tile.inset
         : (parent.height - height) / 2
        spacing: 0
        layer.enabled: tile.fullBleed
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.6)
            shadowBlur: 0.6
            shadowVerticalOffset: 1
        }

        // The title, inside the ring of ticks (there's no header then).
        PlasmaComponents.Label {
            visible: tile.ticks
            textFormat: Text.PlainText
            Layout.fillWidth: true
            horizontalAlignment: big.horizontalAlignment
            text: tile.labelText
            color: tile.textColor
            opacity: 0.7
            font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.75)
            font.weight: Font.DemiBold
            font.capitalization: tile.nativeOn ? Font.MixedCase : Font.AllUppercase
            font.letterSpacing: tile.nativeOn ? 0 : tile.u * 0.1
            elide: Text.ElideRight
        }
        PlasmaComponents.Label {
            id: big
            textFormat: Text.PlainText
            // As big as fits the width, up to a share of the height (less
            // when a picture needs the room); the size setting scales that.
            readonly property real cap: (tile.area ? tile.area.height : tile.height) * (tile.figureScene && !tile.beside ? 0.24 : 0.34)
            readonly property real px: Math.max(Kirigami.Theme.smallFont.pixelSize,
                Math.min(cap * tile.sizeScale, textBlock.width / Math.max(1, metrics.advanceWidth) * 100 * 0.97))
            Layout.fillWidth: true
            horizontalAlignment: tile.align === "center" && !tile.beside ? Text.AlignHCenter : Text.AlignLeft
            verticalAlignment: Text.AlignTop
            text: tile.bigText + (tile.unitText ? " " + tile.unitText : "")
            color: tile.textColor
            font.family: tile.fontFamily
            font.pixelSize: px
            font.weight: tile.fontWeight
            font.features: { "tnum": 1 }
            elide: Text.ElideRight
        }
        PlasmaComponents.Label {
            textFormat: Text.PlainText
            visible: text !== ""
            Layout.fillWidth: true
            horizontalAlignment: big.horizontalAlignment
            text: [tile.opt.showBoot ? tile.sinceText : "", tile.opt.showRecord ? tile.recordText : ""].filter(Boolean).join(" · ")
            color: tile.textColor
            opacity: 0.8
            font.family: tile.opt.font === "pixel" ? tile.fontFamily : Kirigami.Theme.defaultFont.family
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, Math.min(tile.u * 0.85, big.px * 0.28))
            elide: Text.ElideRight
        }
    }

    PlasmaComponents.Label {
        visible: tile.scene === "image" && tile.opt.image === ""
        anchors.centerIn: parent
        width: parent.width * 0.9
        textFormat: Text.PlainText
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        opacity: 0.6
        text: i18n("Pick a picture in Settings → Personal")
    }
}
