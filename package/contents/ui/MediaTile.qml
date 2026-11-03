import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.private.mpris as Mpris

// Whatever is playing (Spotify, a browser tab, VLC, …) via Plasma's MPRIS
// model, with cover art, progress and controls.
GlassTile {
    id: tile
    required property var app

    // The multiplexer exposes the "current" player as a single row.
    property var player: null
    Repeater {
        model: Mpris.MultiplexerModel { }
        delegate: Item {
            required property var model
            Component.onCompleted: tile.player = model
            Component.onDestruction: if (tile.player === model) tile.player = null
        }
    }

    readonly property bool hasPlayer: player !== null && (player.track || "") !== ""
    readonly property bool playing: hasPlayer && player.playbackStatus === Mpris.PlaybackStatus.Playing
    // Position: sampled on the shared tick (no continuous redraws).
    property real positionUs: 0
    Connections {
        target: app
        function onTickChanged() {
            // Paused or hidden: nothing moves, so skip the D-Bus round trip.
            if (!tile.playing || !tile.visible || !tile.player.container) return;
            tile.player.container.updatePosition();
            tile.positionUs = tile.player.container.position || 0;
        }
    }
    // The current audio output and its volume (needs Plasma's audio service).
    Loader {
        id: audio
        source: "AudioOutput.qml"
        onLoaded: item.masked = Qt.binding(function () { return tile.app.masked; })
    }
    readonly property var output: audio.status === Loader.Ready && audio.item.ready ? audio.item : null

    readonly property real lengthUs: hasPlayer ? (player.length || 0) : 0
    function mmss(us) { var s = Math.max(0, Math.floor(us / 1e6)); return Math.floor(s / 60) + ":" + ("0" + s % 60).slice(-2); }

    title: i18n("Now playing")
    subtitle: hasPlayer ? (player.identity || "") : ""
    readonly property string artist: hasPlayer ? (player.artist || "") : ""
    // Video sites title tracks "Artist - Song"; the artist is shown below, so drop it.
    readonly property string track: {
        var t = hasPlayer ? String(player.track || "") : "";
        if (artist && t.toLowerCase().indexOf(artist.toLowerCase() + " - ") === 0) t = t.slice(artist.length + 3);
        return t;
    }
    accent: app.accent("media")
    accent2: app.accent2("media")
    level: playing ? 0.6 : 0.2

    // ---- Sizes ----
    // Side by side when there's width to spare, otherwise the cover on top.
    readonly property bool sideBySide: body.width > body.height * 1.25
    readonly property real btn: Math.max(Kirigami.Units.gridUnit * 1.3, Math.min(tile.u * 1.9, Kirigami.Units.gridUnit * 2.2))
    FontMetrics { id: titleFm; font.pixelSize: Math.max(Kirigami.Theme.defaultFont.pixelSize, tile.u * 1.0); font.weight: Font.DemiBold }
    FontMetrics { id: smallFm; font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.75) }
    // Beside the cover, the text needs room for the buttons and the time
    // (the controls row can't shrink); the cover shrinks rather than push
    // them past the tile's edge.
    readonly property real infoMinW: controls.implicitWidth
    // Height of everything but the title: artist, output, controls, progress line.
    readonly property real restH: smallFm.height * (output ? 2 : 1) + btn * 1.15 + tile.u * 0.9
    readonly property int titleLines: (sideBySide ? body.height : body.height - tile.u * 4) - restH >= titleFm.height * 2 ? 2 : 1

    // Buttons, the style's way: "native" (Plasma), "round", "keys" (flat
    // keys; Pixel's bevelled), "squircle" (Bento) or "outline" (Clear).
    readonly property string controls: look && look.controls ? look.controls : "round"
    // Glass: frosted glass over the blurred album art. Pixel: the cover
    // redrawn in big pixels.
    readonly property bool artOn: spot === "art" && cover.status === Image.Ready
    readonly property bool pixelArt: spot === "pixelart"

    component CtlButton: QQC2.AbstractButton {
        id: cb
        property string iconName
        property string tip
        property bool main: false
        readonly property bool keys: tile.controls === "keys"
        readonly property bool squircle: tile.controls === "squircle"
        implicitWidth: tile.btn * (main ? (keys || squircle ? 1.4 : 1.15) : 1)
        implicitHeight: tile.btn * (main && !keys && !squircle ? 1.15 : 1)
        hoverEnabled: true
        opacity: enabled ? 1 : 0.3
        // Plasma style: flat like Plasma's tool buttons, with the
        // highlight-colored hover frame; no filled play button.
        readonly property bool filled: cb.main && !tile.nativeOn && tile.controls !== "outline"
        readonly property color ink: Kirigami.Theme.textColor
        // Flat fills play in the text color; everything else in the accent.
        readonly property color fillColor: tile.headerStyle === "bar" ? ink : tile.artOn ? "#ffffff" : tile.accent
        Accessible.name: cb.tip
        QQC2.ToolTip.text: cb.tip
        QQC2.ToolTip.visible: cb.tip !== "" && hovered
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        background: Rectangle {
            radius: tile.nativeOn ? Kirigami.Units.cornerRadius
                  : cb.keys ? (tile.radius > 0 ? Kirigami.Units.cornerRadius * 0.6 : 0)
                  : cb.squircle ? height * 0.32
                  : tile.radius > 0 ? Math.min(width, height) / 2 : 0
            color: cb.filled ? cb.fillColor
                 : tile.nativeOn ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, cb.hovered ? 0.2 : 0)
                 : Qt.rgba(cb.ink.r, cb.ink.g, cb.ink.b, cb.hovered ? 0.16 : cb.squircle || tile.artOn ? 0.1 : cb.keys ? 0.04 : 0)
            border.width: tile.nativeOn && cb.hovered ? 1
                        : (cb.keys || tile.controls === "outline") && !cb.filled ? 1 : 0
            border.color: tile.nativeOn ? Kirigami.Theme.highlightColor
                        : Qt.rgba(cb.ink.r, cb.ink.g, cb.ink.b, tile.controls === "outline" && cb.main ? 0.8 : 0.22)
            opacity: cb.filled && !cb.hovered ? 0.92 : 1
            // Pixel: bevelled keys with a hard shadow.
            Rectangle {
                visible: tile.bevelOn
                z: -1
                x: 3; y: 3; width: parent.width; height: parent.height
                color: Qt.rgba(0, 0, 0, 0.5)
            }
            Rectangle {
                visible: tile.bevelOn
                width: parent.width; height: Math.max(2, parent.height * 0.12)
                color: Qt.rgba(1, 1, 1, 0.25)
            }
        }
        contentItem: Item {
            Kirigami.Icon {
                anchors.centerIn: parent
                width: Math.round(cb.width * 0.5); height: width
                source: cb.iconName
                isMask: true
                color: cb.filled ? (cb.fillColor.hslLightness > 0.6 ? "#111111" : "#ffffff") : Kirigami.Theme.textColor
            }
        }
    }

    // Glass: the album art, blurred and dimmed, fills the card behind the glass.
    backdrop: Image {
        anchors.fill: parent
        visible: tile.artOn
        source: tile.artOn ? cover.source : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        layer.enabled: visible
        layer.effect: MultiEffect {
            blurEnabled: true; blur: 1.0; blurMax: 64
            brightness: -0.3
            saturation: 0.15
        }
    }

    PlasmaComponents.Label {
        textFormat: Text.PlainText
        anchors.centerIn: parent
        visible: !tile.hasPlayer
        text: i18n("Nothing playing")
        opacity: 0.55
        font.pixelSize: Math.max(Kirigami.Theme.defaultFont.pixelSize, tile.u)
    }

    Item {
        id: body
        anchors.fill: parent
        visible: tile.hasPlayer
        // Over the album art, text in white.
        Kirigami.Theme.inherit: !tile.artOn
        Kirigami.Theme.textColor: "#ffffff"

        // ---- Cover ----
        Item {
            id: art
            // Whole pixels, so the cover isn't resampled half a pixel off.
            readonly property real side: Math.floor(tile.sideBySide ? Math.min(body.height, body.width - tile.u * 0.9 - tile.infoMinW)
                : Math.min(body.width, body.height - info.implicitHeight - tile.u * 0.6))
            visible: side >= tile.u * 3
            width: visible ? side : 0
            height: width
            x: tile.sideBySide ? 0 : Math.round((body.width - width) / 2)
            y: 0
            Rectangle {
                id: artMask
                anchors.fill: parent
                radius: tile.radius > 0 ? Kirigami.Units.cornerRadius * 1.5 : 0
                visible: false
                layer.enabled: true
            }
            Rectangle {
                anchors.fill: parent
                radius: artMask.radius
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: parent.width * 0.4; height: width
                    source: tile.hasPlayer ? (tile.player.iconName || "media-default-album") : "media-default-album"
                    visible: cover.status !== Image.Ready
                }
            }
            Item {
                anchors.fill: parent
                visible: cover.status === Image.Ready
                clip: true
                layer.enabled: artMask.radius > 0
                layer.effect: MultiEffect { maskEnabled: true; maskSource: artMask }
                // Browsers hand over tiny wide thumbnails (Chrome: 150×83).
                // Cropping one to a square stretches it to twice its size, so
                // show it whole instead, over a blurred copy that fills the box.
                // Measured on the backdrop: the cover's own size follows its
                // fill mode, which would loop.
                readonly property real aspect: backdrop.implicitWidth / Math.max(1, backdrop.implicitHeight)
                readonly property bool small: aspect > 1.4
                    && art.side > backdrop.implicitHeight * 1.5
                Image {
                    id: backdrop
                    anchors.fill: parent
                    opacity: parent.small ? 1 : 0
                    source: cover.source
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    layer.enabled: parent.small
                    layer.effect: MultiEffect {
                        blurEnabled: true; blur: 1.0; blurMax: 32
                        brightness: -0.15
                    }
                }
                // Pixel: the cover scaled down to 24 × 24 and blown back up.
                Image {
                    anchors.fill: parent
                    visible: tile.pixelArt
                    source: tile.pixelArt ? cover.source : ""
                    sourceSize: Qt.size(24, 24)
                    smooth: false
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Image {
                    id: cover
                    anchors.fill: parent
                    opacity: tile.pixelArt ? 0 : 1
                    // Players hand us any URL; only load local files and web images.
                    source: tile.hasPlayer && /^(file|https?):\/\//.test(String(tile.player.artUrl || "")) ? tile.player.artUrl : ""
                    fillMode: parent.small ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                    asynchronous: true
                    // 4:3 video thumbnails carry black bars around a 16:9
                    // picture; zooming by 4/3 pushes them out of the box.
                    scale: Math.abs(parent.aspect - 4 / 3) < 0.02 ? 4 / 3 : 1
                }
            }
        }

        // ---- Title, artist, controls, progress ----
        ColumnLayout {
            id: info
            x: tile.sideBySide ? art.width + (art.visible ? tile.u * 0.9 : 0) : 0
            width: body.width - x
            anchors.bottom: parent.bottom
            height: tile.sideBySide ? body.height : implicitHeight
            spacing: tile.u * 0.15

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: tile.track
                textFormat: Text.PlainText   // text from outside; never render it as HTML
                font.pixelSize: titleFm.font.pixelSize
                font.weight: Font.DemiBold
                font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
                horizontalAlignment: tile.sideBySide ? Text.AlignLeft : Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: tile.titleLines
                elide: Text.ElideRight
                lineHeight: 0.95
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: tile.artist || (tile.hasPlayer ? tile.player.identity || "" : "")
                textFormat: Text.PlainText
                opacity: 0.65
                font.pixelSize: smallFm.font.pixelSize
                horizontalAlignment: tile.sideBySide ? Text.AlignLeft : Text.AlignHCenter
                elide: Text.ElideRight
            }
            // Output and volume: scroll to change it, click the icon to mute.
            RowLayout {
                visible: tile.output !== null
                Layout.fillWidth: true
                spacing: tile.u * 0.3
                opacity: 0.65
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: (event) => tile.output.setPercent(tile.output.percent + (event.angleDelta.y > 0 ? 5 : -5))
                }
                Item { visible: !tile.sideBySide; Layout.fillWidth: true }
                Kirigami.Icon {
                    Layout.preferredWidth: smallFm.height
                    Layout.preferredHeight: smallFm.height
                    source: !tile.output ? "" : tile.output.muted || tile.output.percent === 0 ? "audio-volume-muted"
                        : tile.output.percent < 34 ? "audio-volume-low"
                        : tile.output.percent < 67 ? "audio-volume-medium" : "audio-volume-high"
                    isMask: true
                    color: Kirigami.Theme.textColor
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -tile.u * 0.2
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tile.output.toggleMute()
                    }
                }
                PlasmaComponents.Label {
                    Layout.fillWidth: tile.sideBySide
                    Layout.maximumWidth: tile.sideBySide ? -1 : body.width * 0.6
                    textFormat: Text.PlainText
                    text: tile.output ? tile.output.name : ""
                    font.pixelSize: smallFm.font.pixelSize
                    elide: Text.ElideRight
                }
                PlasmaComponents.Label {
                    textFormat: Text.PlainText
                    text: !tile.output ? "" : tile.output.muted ? i18n("Muted") : tile.output.percent + "%"
                    font.pixelSize: smallFm.font.pixelSize
                    font.features: { "tnum": 1 }
                }
                Item { visible: !tile.sideBySide; Layout.fillWidth: true }
            }
            Item { Layout.fillHeight: true; Layout.minimumHeight: tile.u * 0.3 }

            RowLayout {
                id: controls
                Layout.fillWidth: true
                spacing: tile.u * 0.2
                Item { visible: !tile.sideBySide; Layout.fillWidth: true }
                CtlButton {
                    iconName: "media-skip-backward"
                    tip: i18n("Previous")
                    enabled: tile.hasPlayer && tile.player.canGoPrevious
                    onClicked: tile.player.container.Previous()
                }
                CtlButton {
                    main: true
                    iconName: tile.playing ? "media-playback-pause" : "media-playback-start"
                    tip: tile.playing ? i18n("Pause") : i18n("Play")
                    onClicked: tile.player.container.PlayPause()
                }
                CtlButton {
                    iconName: "media-skip-forward"
                    tip: i18n("Next")
                    enabled: tile.hasPlayer && tile.player.canGoNext
                    onClicked: tile.player.container.Next()
                }
                Item { Layout.fillWidth: true }
                PlasmaComponents.Label {
                    visible: tile.lengthUs > 0 && tile.sideBySide
                    textFormat: Text.PlainText
                    text: tile.mmss(tile.positionUs) + " / " + tile.mmss(tile.lengthUs)
                    opacity: 0.55
                    font.pixelSize: smallFm.font.pixelSize * 0.9
                    font.features: { "tnum": 1 }
                }
            }

            // Thin progress line
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: tile.u * 0.2
                Layout.preferredHeight: Math.max(2, Math.round(tile.u * 0.16))
                visible: tile.lengthUs > 0
                radius: tile.radius > 0 ? height / 2 : 0
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                // Plasma: a round handle at the play position, like Breeze's sliders.
                Rectangle {
                    visible: tile.controls === "native"
                    z: 1
                    width: Math.max(Kirigami.Units.gridUnit * 0.8, parent.height * 4); height: width
                    radius: width / 2
                    x: parent.width * Math.min(1, tile.positionUs / Math.max(1, tile.lengthUs)) - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Kirigami.Theme.backgroundColor
                    border.width: 1
                    border.color: Kirigami.Theme.highlightColor
                }
                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * Math.min(1, tile.positionUs / Math.max(1, tile.lengthUs))
                    Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration } }
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: tile.accent }
                        GradientStop { position: 1; color: tile.accent2 }
                    }
                }
            }
            RowLayout {
                visible: tile.lengthUs > 0 && !tile.sideBySide
                Layout.fillWidth: true
                PlasmaComponents.Label { textFormat: Text.PlainText; text: tile.mmss(tile.positionUs); opacity: 0.55; font.pixelSize: smallFm.font.pixelSize * 0.9; font.features: { "tnum": 1 } }
                Item { Layout.fillWidth: true }
                PlasmaComponents.Label { textFormat: Text.PlainText; text: tile.mmss(tile.lengthUs); opacity: 0.55; font.pixelSize: smallFm.font.pixelSize * 0.9; font.features: { "tnum": 1 } }
            }
        }
    }
}
