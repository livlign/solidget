import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.bluezqt as BluezQt

// The Bluetooth tile's body: one row per connected device, with its battery
// when the device reports one.
Item {
    id: body

    property Item tile: null
    property bool masked: true
    readonly property real u: tile ? tile.u : Kirigami.Units.gridUnit

    readonly property bool on: BluezQt.Manager.bluetoothOperational
    // Plain arrays: QML list properties don't have filter() or reduce().
    readonly property var connected: on ? Array.prototype.slice.call(BluezQt.Manager.connectedDevices) : []
    readonly property int count: connected.length
    readonly property int paired: Array.prototype.filter.call(BluezQt.Manager.devices, function (d) { return d.paired; }).length
    // Lowest battery among connected devices, -1 when none report one.
    readonly property int lowest: connected.reduce(function (low, d) {
        return d.battery && (low < 0 || d.battery.percentage < low) ? d.battery.percentage : low;
    }, -1)

    // Device names often carry the owner's name ("Linh's AirPods"), so the
    // privacy mask shows what kind of device it is instead.
    function kind(icon) {
        var kinds = [["audio-headset", i18n("Headset")], ["audio-headphones", i18n("Headphones")],
                     ["audio", i18n("Speaker")], ["input-mouse", i18n("Mouse")],
                     ["input-keyboard", i18n("Keyboard")], ["input-gaming", i18n("Controller")],
                     ["input-tablet", i18n("Tablet")], ["phone", i18n("Phone")],
                     ["computer", i18n("Computer")], ["camera", i18n("Camera")]];
        for (var i = 0; i < kinds.length; i++)
            if ((icon || "").indexOf(kinds[i][0]) === 0) return kinds[i][1];
        return i18n("Device");
    }

    // Nothing connected, or Bluetooth is off.
    ColumnLayout {
        visible: body.count === 0
        anchors.centerIn: parent
        width: parent.width
        spacing: body.u * 0.2
        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: body.u * 2.2
            Layout.preferredHeight: Layout.preferredWidth
            source: body.on ? "network-bluetooth" : "network-bluetooth-inactive"
            opacity: 0.45
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            textFormat: Text.PlainText
            text: !body.on ? i18n("Bluetooth is off") : i18n("Nothing connected")
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            opacity: 0.6
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, body.u * 0.8)
        }
        PlasmaComponents.Label {
            visible: body.on && body.paired > 0 && body.height > body.u * 5
            Layout.fillWidth: true
            textFormat: Text.PlainText
            text: i18np("%1 paired device", "%1 paired devices", body.paired)
            horizontalAlignment: Text.AlignHCenter
            opacity: 0.4
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, body.u * 0.7)
        }
    }

    ColumnLayout {
        visible: body.count > 0
        anchors.fill: parent
        spacing: body.u * 0.35

        Repeater {
            model: body.connected
            RowLayout {
                id: row
                required property var modelData
                readonly property int pct: modelData.battery ? modelData.battery.percentage : -1
                readonly property color barColor: pct >= 0 && pct <= 15 ? "#f43f5e"
                    : body.tile ? body.tile.accent : Kirigami.Theme.highlightColor
                // Only as many rows as fit.
                visible: index * body.u * 1.9 + body.u * 1.6 <= body.height
                required property int index
                Layout.fillWidth: true
                spacing: body.u * 0.5

                Kirigami.Icon {
                    Layout.preferredWidth: body.u * 1.3
                    Layout.preferredHeight: Layout.preferredWidth
                    source: row.modelData.icon || "preferences-system-bluetooth"
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: body.u * 0.12
                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            textFormat: Text.PlainText
                            text: body.masked ? body.kind(row.modelData.icon) : row.modelData.name
                            elide: Text.ElideRight
                            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, body.u * 0.8)
                        }
                        PlasmaComponents.Label {
                            textFormat: Text.PlainText
                            text: row.pct >= 0 ? i18nc("battery level", "%1%", row.pct) : i18n("Connected")
                            opacity: row.pct >= 0 ? 0.9 : 0.5
                            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, body.u * 0.8)
                            font.features: { "tnum": 1 }
                        }
                    }
                    // Battery bar.
                    Rectangle {
                        visible: row.pct >= 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(2, body.u * 0.18)
                        radius: height / 2
                        color: Qt.rgba(row.barColor.r, row.barColor.g, row.barColor.b, 0.18)
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, row.pct / 100))
                            height: parent.height
                            radius: parent.radius
                            color: row.barColor
                        }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
