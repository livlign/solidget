import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.components as PlasmaComponents

// The card every tile is built on. `look` (from main.qml) picks the style:
// Glass = translucent body, drop shadow and color glows that follow `level`
// (0..1, e.g. current load); Flat, Clear and Pixel drop or change those.
// Plasma draws the Plasma Style's own widget background instead.
Item {
    id: tile

    property var look: null
    readonly property bool nativeOn: look ? look.plasmaFrame === true : false
    // Defaults reproduce Glass on the Plasma colors when no look is given.
    readonly property bool glowOn: !solid && (look ? look.glow : true)
    readonly property bool shadowOn: look ? look.shadow : true
    readonly property bool highlightOn: look ? look.highlight : true
    readonly property int borderWidth: look ? look.border : 1
    readonly property string numberFamily: look ? look.fontFamily : ""
    readonly property bool bevelOn: look ? look.bevel : false
    readonly property bool hardShadowOn: look ? look.hardShadow : false
    readonly property real tintAmount: look ? look.tint : 0
    readonly property color baseColor: look ? look.body : (dark ? "#12141f" : "#ffffff")
    // Flat and Pixel tint each card with its tile's own color.
    readonly property color bodyColor: tintAmount > 0
        ? Qt.tint(baseColor, Qt.rgba(accent.r, accent.g, accent.b, tintAmount)) : baseColor
    readonly property real bevelW: Math.max(3, Kirigami.Units.gridUnit * 0.22)

    property string title
    property string subtitle
    // A tile can make its subtitle a switch (Top apps: by CPU / by memory).
    property bool subtitleClickable: false
    signal subtitleClicked()
    property color accent: "#38bdf8"
    property color accent2: "#6366f1"
    property real level: 0.3
    property bool solid: false      // e.g. the Settings panel: never see-through
    property real bodyOpacity: solid ? 1.0 : look ? look.bodyAlpha : (dark ? 0.66 : 0.72)
    property bool showHeader: true
    default property alias content: body.data
    // A picture filling the whole card behind the content (the Uptime
    // tile's scenes), cut to the card's rounded corners.
    property alias backdrop: backdropItem.data
    // Content reaches the card's edges (no padding), cut to its corners.
    property bool bleed: false

    // Size helpers for children: `u` is a font/spacing unit that scales with
    // the tile, so a tile on a 4K wall dashboard reads from across the room.
    readonly property real u: Math.max(Kirigami.Units.gridUnit * 0.75, Math.min(width, height * 1.4) / 14)
    // Plasma: the same padding on every tile, as in Plasma's own widgets.
    // (Plasma's frame margins count from the outside of its shadow band, which
    // sits outside the tile: measure from the card's visible edge instead.)
    readonly property real pad: nativeOn
        ? Math.max(Kirigami.Units.largeSpacing * 1.5, u * 0.85,
                   frame.margins.left - frame.inset.left, frame.margins.top - frame.inset.top)
        : Math.max(Kirigami.Units.largeSpacing, u * 0.9)
    readonly property bool wide: width > height * 1.6
    readonly property bool tall: height > width * 1.4
    readonly property bool roomy: height > Kirigami.Units.gridUnit * 11
    readonly property bool dark: look ? look.dark : Kirigami.Theme.backgroundColor.hslLightness < 0.5
    readonly property real radius: Math.min(Kirigami.Units.gridUnit * (look ? look.radius : 1.2), Math.min(width, height) * 0.12)

    property real shownLevel: level
    Behavior on shownLevel { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }

    // Extra glow when the tile is working hard. (This used to "breathe",
    // but any endless animation keeps the whole desktop redrawing.)
    readonly property real breath: glowOn && level > 0.85 ? 1 : 0

    // Pixel: a hard, offset block shadow.
    Rectangle {
        visible: tile.hardShadowOn
        x: tile.bevelW * 1.5; y: tile.bevelW * 1.5
        width: parent.width; height: parent.height
        color: Qt.rgba(0, 0, 0, tile.dark ? 0.55 : 0.28)
    }

    // Plasma: the Plasma Style's own background, so tiles match the
    // built-in widgets (Breeze or any other Plasma Style).
    // Settings sheet: Plasma's dialog frame expects the compositor to blur
    // what's behind it, which never happens inside a widget, so back it
    // with the solid window color or the board shows through.
    Rectangle {
        visible: tile.nativeOn && tile.solid
        anchors.fill: parent
        anchors.margins: 1
        radius: Kirigami.Units.cornerRadius
        color: Kirigami.Theme.backgroundColor
    }
    // Plasma style: the frame image has a see-through band around the card
    // (room for its shadow). Let that band spill outside the tile so the
    // visible card fills the tile, the same size as in the other styles.
    KSvg.FrameSvgItem {
        id: frame
        visible: tile.nativeOn
        anchors.fill: parent
        anchors.leftMargin: -inset.left
        anchors.topMargin: -inset.top
        anchors.rightMargin: -inset.right
        anchors.bottomMargin: -inset.bottom
        imagePath: tile.solid ? "dialogs/background" : "widgets/background"
    }

    // RGB theme: a rainbow rim with a soft halo. The hues turn with the shared
    // clock and are offset by where the tile sits, so the colors sweep
    // across the board like an RGB keyboard.
    readonly property bool rgbOn: look ? look.rgb === true : false
    readonly property string edgeColor: look && look.edge ? look.edge : ""
    readonly property real rgbPhase: rgbOn && look.rgbClock ? look.rgbClock.phase : 0
    // A thin rim cut from one rainbow gradient laid over the whole board.
    // It runs top to bottom, tilted a little to the right, and drifts down
    // a tiny step each second, so the colors flow down across the tiles.
    readonly property real rgbHue: ((rgbPhase % 1) + 1) % 1
    readonly property Item rgbBoard: rgbOn && parent && parent.parent ? parent.parent : null
    // This tile's spot on the board (the slot it sits in).
    readonly property real rgbX: rgbBoard ? parent.x : 0
    readonly property real rgbY: rgbBoard ? parent.y : 0
    // How far one full rainbow stretches, along the flow.
    readonly property real rgbSpan: rgbBoard ? Math.max(200, rgbBoard.height * 0.7) : 400
    function rgbStop(k) { return Qt.hsla((((k - rgbHue) % 1) + 1) % 1, 1, 0.58, 0.9); }
    Shape {
        id: rgbRim
        visible: tile.rgbOn
        anchors.fill: parent
        z: 1                // over the card (it's only an outline)
        preferredRendererType: Shape.CurveRenderer
        readonly property real sw: 2
        readonly property real r: tile.radius
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillRule: ShapePath.OddEvenFill
            // Direction of the flow: down, 15 degrees toward the right.
            fillGradient: LinearGradient {
                spread: ShapeGradient.RepeatSpread
                x1: -tile.rgbX; y1: -tile.rgbY
                x2: -tile.rgbX + tile.rgbSpan * 0.259; y2: -tile.rgbY + tile.rgbSpan * 0.966
                GradientStop { position: 0;    color: tile.rgbStop(0) }
                GradientStop { position: 0.17; color: tile.rgbStop(0.17) }
                GradientStop { position: 0.33; color: tile.rgbStop(0.33) }
                GradientStop { position: 0.5;  color: tile.rgbStop(0.5) }
                GradientStop { position: 0.67; color: tile.rgbStop(0.67) }
                GradientStop { position: 0.83; color: tile.rgbStop(0.83) }
                GradientStop { position: 1;    color: tile.rgbStop(1) }
            }
            // A ring: the card's outline minus a slightly smaller one.
            PathRectangle { width: rgbRim.width; height: rgbRim.height; radius: rgbRim.r }
            PathRectangle {
                x: rgbRim.sw; y: rgbRim.sw
                width: rgbRim.width - rgbRim.sw * 2; height: rgbRim.height - rgbRim.sw * 2
                radius: Math.max(0, rgbRim.r - rgbRim.sw)
            }
        }
    }

    RectangularShadow {
        visible: tile.shadowOn && !tile.rgbOn
        anchors.fill: card
        offset.y: Kirigami.Units.smallSpacing * 1.5
        radius: tile.radius
        blur: Kirigami.Units.gridUnit * 1.6
        spread: -Kirigami.Units.smallSpacing
        color: Qt.rgba(0, 0, 0, tile.dark ? 0.45 : 0.18)
    }

    Shape {
        id: card
        visible: !tile.nativeOn
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        readonly property real glowA: !tile.glowOn ? 0
            : (tile.dark ? 0.10 : 0.07) + tile.shownLevel * (tile.dark ? 0.38 : 0.22) + tile.breath * 0.08

        // Body
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: Qt.rgba(tile.bodyColor.r, tile.bodyColor.g, tile.bodyColor.b, tile.bodyOpacity)
            PathRectangle { width: card.width; height: card.height; radius: tile.radius }
        }
        // Primary glow, top-left
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: card.width * 0.12; centerY: -card.height * 0.05
                centerRadius: Math.max(card.width, card.height) * 0.95
                focalX: centerX; focalY: centerY
                GradientStop { position: 0; color: Qt.rgba(tile.accent.r, tile.accent.g, tile.accent.b, card.glowA) }
                GradientStop { position: 1; color: Qt.rgba(tile.accent.r, tile.accent.g, tile.accent.b, 0) }
            }
            PathRectangle { width: card.width; height: card.height; radius: tile.radius }
        }
        // Secondary glow, bottom-right
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: card.width * 0.95; centerY: card.height * 1.05
                centerRadius: Math.max(card.width, card.height) * 0.7
                focalX: centerX; focalY: centerY
                GradientStop { position: 0; color: Qt.rgba(tile.accent2.r, tile.accent2.g, tile.accent2.b, card.glowA * 0.7) }
                GradientStop { position: 1; color: Qt.rgba(tile.accent2.r, tile.accent2.g, tile.accent2.b, 0) }
            }
            PathRectangle { width: card.width; height: card.height; radius: tile.radius }
        }
        // Border: a hairline for Glass/Clear, a solid frame for Pixel, or the
        // theme's own hairline (Snow, Midnight) when the style has none.
        ShapePath {
            fillColor: "transparent"
            strokeWidth: tile.borderWidth === 0 && tile.edgeColor !== "" ? 1 : tile.borderWidth
            strokeColor: tile.borderWidth === 0 && tile.edgeColor !== "" ? tile.edgeColor
                : tile.borderWidth === 0 ? "transparent"
                : tile.borderWidth > 1 ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.45)
                : tile.dark ? Qt.rgba(1, 1, 1, 0.07 + tile.shownLevel * 0.05)
                : Qt.rgba(0, 0, 0, 0.08)
            joinStyle: ShapePath.MiterJoin
            PathRectangle {
                x: tile.borderWidth / 2; y: tile.borderWidth / 2
                width: card.width - tile.borderWidth; height: card.height - tile.borderWidth
                radius: tile.radius
            }
        }
    }

    Item {
        id: backdropItem
        anchors.fill: parent
        visible: children.length > 0
        layer.enabled: visible && tile.radius > 0
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: backdropMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }
    Rectangle {
        id: backdropMask
        anchors.fill: parent
        radius: tile.nativeOn ? Kirigami.Units.cornerRadius : tile.radius
        visible: false
        layer.enabled: backdropItem.layer.enabled || body.layer.enabled
    }

    // Light catching the top edge of the glass.
    Rectangle {
        visible: tile.highlightOn
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - tile.radius * 2
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, tile.dark ? 0.28 : 0.9) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    // Pixel: a block bevel, light on the top/left edges, dark on bottom/right.
    Item {
        visible: tile.bevelOn
        anchors.fill: parent
        Rectangle { x: 0; y: 0; width: parent.width; height: tile.bevelW; color: Qt.rgba(1, 1, 1, tile.dark ? 0.16 : 0.55) }
        Rectangle { x: 0; y: 0; width: tile.bevelW; height: parent.height; color: Qt.rgba(1, 1, 1, tile.dark ? 0.16 : 0.55) }
        Rectangle { x: 0; y: parent.height - tile.bevelW; width: parent.width; height: tile.bevelW; color: Qt.rgba(0, 0, 0, tile.dark ? 0.45 : 0.22) }
        Rectangle { x: parent.width - tile.bevelW; y: 0; width: tile.bevelW; height: parent.height; color: Qt.rgba(0, 0, 0, tile.dark ? 0.45 : 0.22) }
    }

    ColumnLayout {
        anchors.fill: parent
        // Edge-to-edge content (bleed) fills the card; everything else is padded.
        anchors.margins: tile.bleed ? 0 : tile.pad
        spacing: tile.u * 0.4

        RowLayout {
            visible: tile.showHeader
            Layout.fillWidth: true
            spacing: tile.u * 0.45

            Rectangle {
                visible: !tile.nativeOn
                Layout.preferredWidth: tile.u * 0.45
                Layout.preferredHeight: Layout.preferredWidth
                radius: tile.radius > 0 ? width / 2 : 0
                gradient: Gradient {
                    GradientStop { position: 0; color: tile.accent }
                    GradientStop { position: 1; color: tile.accent2 }
                }
            }
            PlasmaComponents.Label {
                id: titleLabel
                text: tile.title
                textFormat: Text.PlainText   // text from outside; never render it as HTML
                font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
                // Plasma: a plain heading, one size on every tile, the way
                // Plasma's own widgets title things.
                font.pixelSize: tile.nativeOn ? Kirigami.Units.gridUnit * 0.85
                              : Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.78)
                font.weight: Font.DemiBold
                font.capitalization: tile.nativeOn ? Font.MixedCase : Font.AllUppercase
                font.letterSpacing: tile.nativeOn ? 0 : tile.u * 0.12
                opacity: tile.nativeOn ? 0.9 : 0.75
                Layout.fillWidth: true
                Layout.minimumWidth: Math.min(implicitWidth, tile.width * 0.45)
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                text: tile.subtitle
                textFormat: Text.PlainText
                // Drop the subtitle rather than truncate the title.
                visible: text !== "" && titleLabel.implicitWidth + Math.min(implicitWidth, tile.u * 4) + tile.u * 2 < tile.width - tile.pad * 2
                font.pixelSize: tile.nativeOn ? Kirigami.Units.gridUnit * 0.75
                              : Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.72)
                opacity: subtitleMouse.containsMouse ? 0.9 : 0.55
                font.underline: subtitleMouse.containsMouse
                elide: Text.ElideRight
                Layout.maximumWidth: tile.width * 0.5
                MouseArea {
                    id: subtitleMouse
                    anchors.fill: parent
                    anchors.margins: -tile.u * 0.3
                    enabled: tile.subtitleClickable
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tile.subtitleClicked()
                }
            }
        }

        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            layer.enabled: tile.bleed && tile.radius > 0
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: backdropMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }
        }
    }
}
