import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../code/palette.js" as Palette
import "../code/format.js" as Fmt

// Labelled temperature bar whose fill runs along the cool→hot ramp.
ColumnLayout {
    id: bar

    property string label
    property real celsius: 0              // drives the color ramp
    property string valueText: Fmt.temp(celsius)   // shown text, in the user's unit
    property color hotColor: Palette.heat(Palette.tempLevel(celsius))
    Behavior on hotColor { ColorAnimation { duration: Kirigami.Units.longDuration } }
    property color coolColor: Palette.heat(0)
    property bool square: false
    property string kind: "thin"
    property real u: Kirigami.Units.gridUnit
    // The tile's detail rows, so the label line matches the other tiles:
    // "readout" (Instrument) = a DetailRow, mono caps with a dotted leader
    // and the heat in its square; anything else = label and colored value.
    property string detailKind: ""
    property string family: ""

    readonly property real frac: Math.max(0, Math.min(1, celsius / 100))
    Layout.fillWidth: true
    spacing: u * 0.25

    DetailRow {
        visible: bar.detailKind === "readout"
        Layout.fillWidth: true
        u: bar.u
        label: bar.label
        value: bar.valueText
        dot: bar.hotColor
        kind: "readout"
        family: bar.family
    }
    RowLayout {
        visible: bar.detailKind !== "readout"
        Layout.fillWidth: true
        PlasmaComponents.Label {
            textFormat: Text.PlainText
            text: bar.label
            opacity: 0.6
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, bar.u * 0.8)
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
        PlasmaComponents.Label {
            textFormat: Text.PlainText
            text: bar.valueText
            color: bar.hotColor
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, bar.u * 0.9)
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }
    }
    // The bar, the style's way: "thin" (default), "glow" (thin with a soft
    // halo), "square" (thick, solid), "hairline", "pill" (thick, rounded,
    // solid), "needle" (a marker on a cool→hot scale) or "segments" (Pixel).
    Item {
        id: track
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(bar.kind === "hairline" ? 2 : 3, bar.u * ({ hairline: 0.1, square: 0.5, pill: 0.55, needle: 0.45, segments: 0.6 }[bar.kind] || 0.32))
        readonly property color wash: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

        // Continuous bars
        Rectangle {
            visible: bar.kind !== "needle" && bar.kind !== "segments"
            anchors.fill: parent
            radius: bar.square || bar.kind === "square" ? 0 : height / 2
            color: bar.kind === "pill" && Kirigami.Theme.backgroundColor.hslLightness > 0.5 && Kirigami.Theme.backgroundColor.hslLightness <= 0.93
                   ? Qt.rgba(1, 1, 1, 0.7) : track.wash
            Rectangle {   // glow
                visible: bar.kind === "glow"
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height * 3
                width: parent.width * bar.frac
                radius: height / 2
                color: Qt.rgba(bar.hotColor.r, bar.hotColor.g, bar.hotColor.b, 0.18)
            }
            Rectangle {
                height: parent.height
                radius: parent.radius
                width: parent.width * bar.frac
                Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }
                color: bar.hotColor
                // Solid in Flat, Bento and Clear; a cool→hot ramp elsewhere.
                gradient: bar.kind === "square" || bar.kind === "pill" || bar.kind === "hairline" ? null : ramp
                Gradient {
                    id: ramp
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: bar.coolColor }
                    GradientStop { position: 1; color: bar.hotColor }
                }
            }
        }

        // Instrument: a dim cool→hot scale with a needle at the reading.
        Rectangle {
            visible: bar.kind === "needle"
            anchors.fill: parent
            opacity: 0.35
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: bar.coolColor }
                GradientStop { position: 1; color: Palette.heat(1) }
            }
        }
        Repeater {   // scale marks every 10°
            model: bar.kind === "needle" ? 9 : 0
            Rectangle {
                required property int index
                x: Math.round(track.width * (index + 1) / 10); width: 1
                height: track.height
                color: Kirigami.Theme.backgroundColor
                opacity: 0.6
            }
        }
        Rectangle {
            visible: bar.kind === "needle"
            x: Math.round(track.width * bar.frac) - 1
            Behavior on x { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }
            y: -track.height * 0.4
            width: 2; height: track.height * 1.8
            color: bar.hotColor
        }

        // Pixel: ten blocks, lit up to the reading.
        Row {
            visible: bar.kind === "segments"
            anchors.fill: parent
            spacing: Math.max(1, bar.u * 0.1)
            Repeater {
                model: bar.kind === "segments" ? 10 : 0
                Rectangle {
                    required property int index
                    width: (track.width - parent.spacing * 9) / 10
                    height: track.height
                    color: index < Math.round(bar.frac * 10) ? Qt.tint(bar.coolColor, Qt.rgba(bar.hotColor.r, bar.hotColor.g, bar.hotColor.b, index / 9)) : track.wash
                }
            }
        }
    }
}
