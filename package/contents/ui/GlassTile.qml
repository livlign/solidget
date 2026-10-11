import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// The card every tile is built on. `look` (from main.qml) picks the style:
// Glass = translucent body, drop shadow and color glows that follow `level`
// (0..1, e.g. current load); Flat, Clear and Pixel drop or change those.
Item {
    id: tile

    property var look: null
    // Defaults reproduce Glass on the Plasma colors when no look is given.
    readonly property bool glowOn: look ? look.glow : true
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
    property color accent: "#38bdf8"
    property color accent2: "#6366f1"
    property real level: 0.3
    property real bodyOpacity: look ? look.bodyAlpha : (dark ? 0.66 : 0.72)
    property bool showHeader: true
    default property alias content: body.data

    // Size helpers for children: `u` is a font/spacing unit that scales with
    // the tile, so a tile on a 4K wall dashboard reads from across the room.
    readonly property real u: Math.max(Kirigami.Units.gridUnit * 0.75, Math.min(width, height * 1.4) / 14)
    readonly property real pad: Math.max(Kirigami.Units.largeSpacing, u * 0.9)
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

    RectangularShadow {
        visible: tile.shadowOn
        anchors.fill: card
        offset.y: Kirigami.Units.smallSpacing * 1.5
        radius: tile.radius
        blur: Kirigami.Units.gridUnit * 1.6
        spread: -Kirigami.Units.smallSpacing
        color: Qt.rgba(0, 0, 0, tile.dark ? 0.45 : 0.18)
    }

    Shape {
        id: card
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
        // Border: a hairline for Glass/Clear, a solid frame for Pixel.
        ShapePath {
            fillColor: "transparent"
            strokeWidth: tile.borderWidth
            strokeColor: tile.borderWidth === 0 ? "transparent"
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
        anchors.margins: tile.pad
        spacing: tile.u * 0.4

        RowLayout {
            visible: tile.showHeader
            Layout.fillWidth: true
            spacing: tile.u * 0.45

            Rectangle {
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
                font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.78)
                font.weight: Font.DemiBold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: tile.u * 0.12
                opacity: 0.75
                Layout.fillWidth: true
                Layout.minimumWidth: Math.min(implicitWidth, tile.width * 0.45)
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                text: tile.subtitle
                // Drop the subtitle rather than truncate the title.
                visible: text !== "" && titleLabel.implicitWidth + Math.min(implicitWidth, tile.u * 4) + tile.u * 2 < tile.width - tile.pad * 2
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.72)
                opacity: 0.55
                elide: Text.ElideRight
                Layout.maximumWidth: tile.width * 0.5
            }
        }

        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
