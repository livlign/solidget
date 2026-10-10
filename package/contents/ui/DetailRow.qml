import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// "label ........ value" line that scales with its tile (`u`).
RowLayout {
    id: row

    property string label
    property string value
    property color dot: "transparent"
    property real u: Kirigami.Units.gridUnit
    property real maxValueWidth: Kirigami.Units.gridUnit * 12

    Layout.fillWidth: true
    spacing: u * 0.4

    Rectangle {
        visible: row.dot.a > 0
        Layout.preferredWidth: row.u * 0.4
        Layout.preferredHeight: Layout.preferredWidth
        radius: width / 2
        color: row.dot
    }
    PlasmaComponents.Label {
        text: row.label
        opacity: 0.6
        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, row.u * 0.8)
        Layout.fillWidth: true
        elide: Text.ElideRight
    }
    PlasmaComponents.Label {
        text: row.value
        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, row.u * 0.85)
        font.weight: Font.Medium
        font.features: { "tnum": 1 }
        Layout.maximumWidth: row.maxValueWidth
        elide: Text.ElideLeft
    }
}
