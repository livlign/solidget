import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Edit-mode chrome over one tile: drag anywhere to move, drag the corner
// grip to resize (snaps to grid cells), hide / back-to-auto-size buttons.
Item {
    id: overlay

    // Named so they can't shadow the ids passed in (`board: board` would
    // resolve to this object's own, still-empty property).
    required property var app
    required property var boardItem
    required property var tileSlot

    readonly property string tileId: slot.modelData
    readonly property bool manual: !!slot.r.manual
    readonly property real radius: Math.min(Kirigami.Units.gridUnit * 1.2, Math.min(width, height) * 0.12)
    readonly property color accent: "#818cf8"
    property bool resizing: false

    // Tint + dashed outline so it's obvious the board is editable.
    Rectangle {
        anchors.fill: parent
        radius: overlay.radius
        color: Qt.rgba(0.5, 0.55, 1, overlay.tileSlot.dragging || overlay.resizing ? 0.16 : 0.06)
    }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: "transparent"
            strokeColor: overlay.tileSlot.dragging || overlay.resizing ? overlay.accent : Qt.rgba(1, 1, 1, 0.45)
            strokeWidth: overlay.tileSlot.dragging || overlay.resizing ? 2 : 1.5
            strokeStyle: ShapePath.DashLine
            dashPattern: [4, 3]
            PathRectangle { x: 1; y: 1; width: overlay.width - 2; height: overlay.height - 2; radius: overlay.radius }
        }
    }

    // ---- Move ----
    MouseArea {
        id: mover
        anchors.fill: parent
        cursorShape: overlay.tileSlot.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        preventStealing: true
        property point start
        property point origin

        onPressed: (mouse) => {
            start = mapToItem(overlay.boardItem, mouse.x, mouse.y);
            origin = Qt.point(overlay.tileSlot.x, overlay.tileSlot.y);
            overlay.tileSlot.dragX = origin.x;
            overlay.tileSlot.dragY = origin.y;
            overlay.tileSlot.dragging = true;
            overlay.boardItem.beginDrag(overlay.tileId, start);
        }
        onPositionChanged: (mouse) => {
            if (!overlay.tileSlot.dragging) return;
            var p = mapToItem(overlay.boardItem, mouse.x, mouse.y);
            overlay.tileSlot.dragX = origin.x + p.x - start.x;
            overlay.tileSlot.dragY = origin.y + p.y - start.y;
            overlay.boardItem.dragMove(overlay.tileId, p);
        }
        onReleased: {
            overlay.tileSlot.dragging = false;
            overlay.boardItem.endDrag();
        }
        onCanceled: released(null)
    }

    // ---- Size badge ----
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Kirigami.Units.smallSpacing * 1.5
        width: badge.implicitWidth + Kirigami.Units.largeSpacing
        height: badge.implicitHeight + Kirigami.Units.smallSpacing
        radius: height / 2
        color: overlay.manual || overlay.resizing ? overlay.accent : Qt.rgba(0, 0, 0, 0.55)
        PlasmaComponents.Label {
            id: badge
            anchors.centerIn: parent
            text: overlay.tileSlot.r.w + " × " + overlay.tileSlot.r.h + (overlay.manual ? "" : "  " + i18n("auto"))
            color: "white"
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.weight: Font.DemiBold
        }
    }

    // ---- Buttons ----
    RowLayout {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        component RoundButton: QQC2.AbstractButton {
            id: btn
            property string iconName
            property string tip
            implicitWidth: Kirigami.Units.iconSizes.medium
            implicitHeight: implicitWidth
            hoverEnabled: true
            QQC2.ToolTip.text: tip
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            background: Rectangle {
                radius: width / 2
                color: btn.hovered ? overlay.accent : Qt.rgba(0, 0, 0, 0.6)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.2)
            }
            contentItem: Kirigami.Icon {
                source: btn.iconName
                color: "white"
                isMask: true
                anchors.centerIn: parent
                implicitWidth: Kirigami.Units.iconSizes.small
                implicitHeight: implicitWidth
            }
        }

        RoundButton {
            visible: overlay.manual
            iconName: "zoom-fit-best"
            tip: i18n("Default size")
            onClicked: overlay.app.setTileSpan(overlay.tileId, null)
        }
        RoundButton {
            iconName: "view-hidden"
            tip: i18n("Hide this tile")
            onClicked: overlay.app.setTileShown(overlay.tileId, false)
        }
    }

    // ---- Resize grip ----
    Rectangle {
        id: grip
        width: Kirigami.Units.gridUnit * 1.5
        height: width
        radius: width / 2
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: -width * 0.25
        color: resizer.containsMouse || overlay.resizing ? overlay.accent : Qt.rgba(0, 0, 0, 0.7)
        border.width: 2
        border.color: "white"

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.small
            height: width
            source: "transform-scale"
            color: "white"
            isMask: true
        }

        MouseArea {
            id: resizer
            anchors.fill: parent
            anchors.margins: -Kirigami.Units.smallSpacing
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.SizeFDiagCursor
            property point start
            property int startW
            property int startH

            onPressed: (mouse) => {
                start = mapToItem(overlay.boardItem, mouse.x, mouse.y);
                startW = overlay.tileSlot.r.w;
                startH = overlay.tileSlot.r.h;
                overlay.resizing = true;
            }
            onPositionChanged: (mouse) => {
                if (!overlay.resizing) return;
                var p = mapToItem(overlay.boardItem, mouse.x, mouse.y);
                var plan = overlay.boardItem.plan;
                var dw = Math.round((p.x - start.x) / (plan.cellW + overlay.boardItem.gap));
                var dh = Math.round((p.y - start.y) / (plan.cellH + overlay.boardItem.gap));
                overlay.boardItem.resizeTo(overlay.tileId, startW + dw, startH + dh);
            }
            onReleased: {
                overlay.resizing = false;
                overlay.boardItem.endResize(overlay.tileId);
            }
            onCanceled: released(null)
        }
    }
}
