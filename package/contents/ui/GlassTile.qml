import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Aurora glass card: translucent body, soft drop shadow, and two blurred
// color glows whose strength follows `level` (0..1), e.g. current load.
Item {
    id: tile

    property string title
    property string subtitle
    property color accent: "#38bdf8"
    property color accent2: "#6366f1"
    property real level: 0.3
    property real bodyOpacity: dark ? 0.66 : 0.72
    property bool showHeader: true
    default property alias content: body.data

    // Size helpers for children: `u` is a font/spacing unit that scales with
    // the tile, so a tile on a 4K wall dashboard reads from across the room.
    readonly property real u: Math.max(Kirigami.Units.gridUnit * 0.75, Math.min(width, height * 1.4) / 14)
    readonly property real pad: Math.max(Kirigami.Units.largeSpacing, u * 0.9)
    readonly property bool wide: width > height * 1.6
    readonly property bool tall: height > width * 1.4
    readonly property bool roomy: height > Kirigami.Units.gridUnit * 11
    readonly property bool dark: Kirigami.Theme.backgroundColor.hslLightness < 0.5
    readonly property real radius: Math.min(Kirigami.Units.gridUnit * 1.2, Math.min(width, height) * 0.12)

    property real shownLevel: level
    Behavior on shownLevel { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }

    // Slow breathing when the tile is working hard.
    property real breath: 0
    SequentialAnimation on breath {
        running: tile.level > 0.85 && tile.visible
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 1600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 1600; easing.type: Easing.InOutSine }
        onRunningChanged: if (!running) tile.breath = 0
    }

    RectangularShadow {
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

        readonly property real glowA: (tile.dark ? 0.10 : 0.07) + tile.shownLevel * (tile.dark ? 0.38 : 0.22) + tile.breath * 0.08

        // Body
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: tile.dark ? Qt.rgba(0.07, 0.08, 0.12, tile.bodyOpacity) : Qt.rgba(1, 1, 1, tile.bodyOpacity)
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
        // Hairline border, tinted by the accent as load rises.
        ShapePath {
            fillColor: "transparent"
            strokeWidth: 1
            strokeColor: tile.dark
                ? Qt.rgba(1, 1, 1, 0.07 + tile.shownLevel * 0.05)
                : Qt.rgba(0, 0, 0, 0.08)
            PathRectangle { x: 0.5; y: 0.5; width: card.width - 1; height: card.height - 1; radius: tile.radius }
        }
    }

    // Light catching the top edge of the glass.
    Rectangle {
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
                radius: width / 2
                gradient: Gradient {
                    GradientStop { position: 0; color: tile.accent }
                    GradientStop { position: 1; color: tile.accent2 }
                }
            }
            PlasmaComponents.Label {
                id: titleLabel
                text: tile.title
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
