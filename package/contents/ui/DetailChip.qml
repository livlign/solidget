import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Bento: a detail as a small rounded tag ("3.99 GHz", "● 65°C"). The label
// is left out when the value says enough on its own; `full` keeps it.
Rectangle {
    id: chip

    property string label
    property string value
    property color dot: "transparent"
    property real u: Kirigami.Units.gridUnit
    property bool full: true

    readonly property color ink: Kirigami.Theme.textColor
    implicitWidth: chipRow.implicitWidth + u * 0.9
    implicitHeight: Math.max(Kirigami.Units.gridUnit * 1.2, u * 1.45)
    radius: height / 2
    // A light wash on any card: white on pastel, ink on dark.
    color: Kirigami.Theme.backgroundColor.hslLightness > 0.5 ? Qt.rgba(1, 1, 1, 0.7) : Qt.rgba(ink.r, ink.g, ink.b, 0.1)

    RowLayout {
        id: chipRow
        anchors.centerIn: parent
        spacing: chip.u * 0.3
        Rectangle {
            visible: chip.dot.a > 0
            Layout.preferredWidth: chip.u * 0.4
            Layout.preferredHeight: Layout.preferredWidth
            radius: width / 2
            color: chip.dot
        }
        PlasmaComponents.Label {
            textFormat: Text.PlainText
            visible: chip.full && chip.label !== ""
            text: chip.label
            opacity: 0.6
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, chip.u * 0.72)
            font.weight: Font.DemiBold
        }
        PlasmaComponents.Label {
            textFormat: Text.PlainText
            text: chip.value
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, chip.u * 0.75)
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }
    }
}
