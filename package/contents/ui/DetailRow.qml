import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// "label ........ value" line that scales with its tile (`u`), drawn the
// style's way (`kind`): "rows" plain, "ruled" with a thin rule above,
// "readout" with a dotted leader in a fixed-width font (Instrument), "caps"
// with the label in capitals (Pixel). Bento's chips are DetailChip.
Item {
    id: row

    property string label
    property string value
    property color dot: "transparent"
    property real u: Kirigami.Units.gridUnit
    property real maxValueWidth: Kirigami.Units.gridUnit * 12
    property string kind: "rows"
    property string family: ""     // fixed-width font for readouts

    readonly property bool readout: kind === "readout"
    readonly property color ink: Kirigami.Theme.textColor

    Layout.fillWidth: true
    implicitWidth: Kirigami.Units.gridUnit * 6
    implicitHeight: line.implicitHeight

    // Flat: a hairline above each row.
    Rectangle {
        visible: row.kind === "ruled"
        width: parent.width
        y: Math.round(row.height * 0.08)
        height: 1
        color: Qt.rgba(row.ink.r, row.ink.g, row.ink.b, 0.14)
    }

    RowLayout {
        id: line
        anchors.fill: parent
        spacing: row.u * 0.4
        Rectangle {
            visible: row.dot.a > 0
            Layout.preferredWidth: row.u * 0.4
            Layout.preferredHeight: Layout.preferredWidth
            radius: row.readout ? 0 : width / 2
            color: row.dot
        }
        PlasmaComponents.Label {
            id: labelText
            textFormat: Text.PlainText
            text: row.label
            opacity: row.readout ? 0.55 : 0.6
            font.family: row.readout && row.family ? row.family : Kirigami.Theme.defaultFont.family
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, row.u * (row.readout || row.kind === "caps" ? 0.7 : 0.8))
            font.capitalization: row.readout || row.kind === "caps" ? Font.AllUppercase : Font.MixedCase
            font.letterSpacing: row.readout || row.kind === "caps" ? row.u * 0.05 : 0
            Layout.fillWidth: !row.readout
            // A readout's label gives way to its value when both won't fit.
            Layout.maximumWidth: row.readout ? Math.max(0, row.width - valueText.implicitWidth - row.u * (row.dot.a > 0 ? 1.6 : 0.8)) : Number.POSITIVE_INFINITY
            elide: Text.ElideRight
        }
        // Instrument: a dotted leader from the label to the value.
        Shape {
            id: leader
            visible: row.readout
            Layout.fillWidth: true
            Layout.preferredWidth: 0      // not its path's width, or the row loops
            Layout.minimumWidth: 0        // gives way first when the value is long
            Layout.preferredHeight: 1
            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: row.u * 0.3
            ShapePath {
                strokeWidth: 1
                strokeColor: Qt.rgba(row.ink.r, row.ink.g, row.ink.b, 0.25)
                strokeStyle: ShapePath.DashLine
                dashPattern: [1, 2]
                fillColor: "transparent"
                startX: 0; startY: 0.5
                PathLine { x: leader.width; y: 0.5 }
            }
        }
        PlasmaComponents.Label {
            id: valueText
            textFormat: Text.PlainText
            text: row.value
            font.family: row.readout && row.family ? row.family : Kirigami.Theme.defaultFont.family
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, row.u * 0.85)
            font.weight: Font.Medium
            font.features: { "tnum": 1 }
            // Whatever the label doesn't need: a long value ("707 MiB / 8 GiB"
            // in a fixed-width font) shouldn't be cut while there's room.
            // A readout's value takes what it needs: the dotted leader gives
            // way first, then the label.
            Layout.maximumWidth: row.readout ? Number.POSITIVE_INFINITY
                : Math.max(row.maxValueWidth, row.width - labelText.implicitWidth - row.u * 1.5)
            Layout.minimumWidth: row.readout ? Math.min(implicitWidth, row.width * 0.8) : 0
            elide: Text.ElideLeft
        }
    }
}
