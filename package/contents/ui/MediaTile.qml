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
    readonly property real lengthUs: hasPlayer ? (player.length || 0) : 0
    function mmss(us) { var s = Math.max(0, Math.floor(us / 1e6)); return Math.floor(s / 60) + ":" + ("0" + s % 60).slice(-2); }

    title: hasPlayer ? (player.identity || i18n("Now playing")) : i18n("Now playing")
    accent: app.accent("media")
    accent2: app.accent2("media")
    level: playing ? 0.6 : 0.2

    // Fit the text and controls to the tile height: drop to one title line,
    // then hide the artist, then shrink the buttons.
    FontMetrics { id: titleFm; font.pixelSize: Math.max(Kirigami.Theme.defaultFont.pixelSize, tile.u * 1.15); font.weight: Font.DemiBold }
    FontMetrics { id: artistFm; font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.85) }
    readonly property real btnBase: Math.max(Kirigami.Units.gridUnit * 0.8, tile.u)
    readonly property real barH: Math.max(3, tile.u * 0.22) + 4
    readonly property real gap: tile.u * 0.2
    readonly property real fitH: content.height - (content.columns === 1 ? tile.u * 3 + content.rowSpacing : 0)
    function needH(lines, artist, btn) { return lines * titleFm.height + (artist ? artistFm.height + gap : 0) + barH + btn + gap * 2; }
    readonly property int titleLines: needH(2, true, btnBase * 2.6) <= fitH ? 2 : 1
    readonly property bool showArtist: needH(titleLines, true, btnBase * 2.6) <= fitH
    readonly property real bigSide: Math.max(btnBase * 1.5, Math.min(btnBase * 2.6, fitH - needH(titleLines, showArtist, 0)))

    component CtlButton: QQC2.AbstractButton {
        id: cb
        property string iconName
        property bool big: false
        implicitWidth: big ? tile.bigSide : tile.bigSide * 0.77
        implicitHeight: implicitWidth
        hoverEnabled: true
        opacity: enabled ? 1 : 0.35
        background: Rectangle {
            radius: tile.radius > 0 ? width / 2 : 0
            color: cb.big ? tile.accent : (cb.hovered ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14) : "transparent")
        }
        contentItem: Kirigami.Icon {
            source: cb.iconName
            isMask: true
            color: cb.big ? (tile.accent.hslLightness > 0.6 ? "#111111" : "#ffffff") : Kirigami.Theme.textColor
            implicitWidth: Math.min(cb.big ? Kirigami.Units.iconSizes.medium : Kirigami.Units.iconSizes.small, cb.width * 0.6)
            implicitHeight: implicitWidth
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

    GridLayout {
        id: content
        anchors.fill: parent
        visible: tile.hasPlayer
        columns: tile.width > tile.height * 1.2 ? 2 : 1
        columnSpacing: tile.u
        rowSpacing: tile.u * 0.5

        // Cover art
        Item {
            id: art
            // Stacked: the cover gets whatever height the text and buttons
            // leave, so the controls never spill out of the tile.
            readonly property real side: parent.columns === 2 ? Math.min(parent.height, parent.width * 0.42)
                : Math.max(0, Math.min(parent.width, parent.height - info.implicitHeight - parent.rowSpacing))
            visible: side >= tile.u * 3
            Layout.preferredWidth: side
            Layout.preferredHeight: side
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
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
            Image {
                id: cover
                anchors.fill: parent
                // Players hand us any URL; only load local files and web images.
                source: tile.hasPlayer && /^(file|https?):\/\//.test(String(tile.player.artUrl || "")) ? tile.player.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
                layer.enabled: artMask.radius > 0
                layer.effect: MultiEffect { maskEnabled: true; maskSource: artMask }
            }
        }

        ColumnLayout {
            id: info
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: tile.u * 0.2

            Item { Layout.fillHeight: true }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: tile.hasPlayer ? tile.player.track : ""
                textFormat: Text.PlainText   // text from outside; never render it as HTML
                font.pixelSize: Math.max(Kirigami.Theme.defaultFont.pixelSize, tile.u * 1.15)
                font.weight: Font.DemiBold
                font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
                elide: Text.ElideRight
                maximumLineCount: tile.titleLines
                wrapMode: Text.Wrap
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: tile.hasPlayer ? (tile.player.artist || tile.player.identity || "") : ""
                textFormat: Text.PlainText
                visible: tile.showArtist
                opacity: 0.7
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.85)
                elide: Text.ElideRight
            }

            // Progress bar, then elapsed · controls · length on one row.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(3, tile.u * 0.22)
                visible: tile.lengthUs > 0
                radius: tile.radius > 0 ? height / 2 : 0
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
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
                Layout.fillWidth: true
                spacing: tile.u * 0.3
                PlasmaComponents.Label {
                    textFormat: Text.PlainText
                    Layout.preferredWidth: tile.lengthUs > 0 ? implicitWidth : 0
                    text: tile.lengthUs > 0 ? tile.mmss(tile.positionUs) : ""
                    opacity: 0.55; font.pixelSize: Kirigami.Theme.smallFont.pixelSize; font.features: { "tnum": 1 }
                }
                Item { Layout.fillWidth: true }
                CtlButton {
                    iconName: "media-skip-backward"
                    enabled: tile.hasPlayer && tile.player.canGoPrevious
                    onClicked: tile.player.container.Previous()
                }
                CtlButton {
                    big: true
                    iconName: tile.playing ? "media-playback-pause" : "media-playback-start"
                    onClicked: tile.player.container.PlayPause()
                }
                CtlButton {
                    iconName: "media-skip-forward"
                    enabled: tile.hasPlayer && tile.player.canGoNext
                    onClicked: tile.player.container.Next()
                }
                Item { Layout.fillWidth: true }
                PlasmaComponents.Label {
                    textFormat: Text.PlainText
                    Layout.preferredWidth: tile.lengthUs > 0 ? implicitWidth : 0
                    text: tile.lengthUs > 0 ? tile.mmss(tile.lengthUs) : ""
                    opacity: 0.55; font.pixelSize: Kirigami.Theme.smallFont.pixelSize; font.features: { "tnum": 1 }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
