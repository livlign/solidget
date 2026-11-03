import QtQuick
import org.kde.kirigami as Kirigami

// A horizontal bar for one value (0..1): continuous, or in `segments` like
// a game's health bar (Pixel).
Item {
    id: meter

    property real value: 0
    property real value2: 0         // a faint second reach behind it (Memory: + cache)
    property color accent: "#38bdf8"
    property color accent2: accent
    property int segments: 0
    property bool rounded: true

    property real shown: Math.max(0, Math.min(1, value))
    Behavior on shown { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }
    readonly property color wash: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

    Rectangle {
        visible: meter.segments === 0
        anchors.fill: parent
        radius: meter.rounded ? height / 2 : 0
        color: meter.wash
        Rectangle {
            height: parent.height
            width: parent.width * Math.max(0, Math.min(1, meter.value2))
            radius: parent.radius
            color: Qt.rgba(meter.accent.r, meter.accent.g, meter.accent.b, 0.28)
        }
        Rectangle {
            height: parent.height
            width: Math.max(meter.shown > 0 ? height : 0, parent.width * meter.shown)
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: meter.accent }
                GradientStop { position: 1; color: meter.accent2 }
            }
        }
    }

    Row {
        visible: meter.segments > 0
        anchors.fill: parent
        spacing: Math.max(2, height * 0.25)
        Repeater {
            model: meter.segments
            Rectangle {
                required property int index
                readonly property bool lit: index < Math.ceil(meter.shown * meter.segments - 0.001) && meter.shown > 0
                width: (meter.width - parent.spacing * (meter.segments - 1)) / meter.segments
                height: meter.height
                color: lit ? Qt.tint(meter.accent, Qt.rgba(meter.accent2.r, meter.accent2.g, meter.accent2.b, index / Math.max(1, meter.segments - 1))) : meter.wash
                // A highlight along the top of lit blocks.
                Rectangle { visible: parent.lit; width: parent.width; height: Math.max(1, parent.height * 0.25); color: Qt.rgba(1, 1, 1, 0.3) }
            }
        }
    }
}
