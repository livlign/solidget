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
    property real u: Kirigami.Units.gridUnit

    readonly property real frac: Math.max(0, Math.min(1, celsius / 100))
    Layout.fillWidth: true
    spacing: u * 0.25

    RowLayout {
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
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(3, bar.u * 0.32)
        radius: bar.square ? 0 : height / 2
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
        Rectangle {
            height: parent.height
            radius: parent.radius
            width: parent.width * bar.frac
            Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: bar.coolColor }
                GradientStop { position: 1; color: bar.hotColor }
            }
        }
    }
}
