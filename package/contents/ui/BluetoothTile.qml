import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Connected Bluetooth devices and their batteries. The device list lives in
// BluetoothDevices.qml, loaded on its own: it needs KDE's Bluetooth library
// (BluezQt), and without it only this tile should go blank, not the widget.
GlassTile {
    id: tile
    required property var app

    readonly property var devices: loader.item

    title: i18n("Bluetooth")
    subtitle: !devices ? "" : !devices.on ? i18n("Off")
            : devices.count ? i18np("%1 connected", "%1 connected", devices.count) : ""
    accent: app.accent("bluetooth")
    accent2: app.accent2("bluetooth")
    // Glow when something's battery runs low.
    level: devices && devices.lowest >= 0 ? Math.max(0.15, 1 - devices.lowest / 100) : 0.15

    Loader {
        id: loader
        anchors.fill: parent
        source: "BluetoothDevices.qml"
        onLoaded: {
            item.tile = tile;
            item.masked = Qt.binding(function () { return tile.app.masked; });
        }
    }

    PlasmaComponents.Label {
        visible: loader.status === Loader.Error
        anchors.fill: parent
        textFormat: Text.PlainText
        text: i18n("Needs KDE's Bluetooth support (bluez-qt)")
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        opacity: 0.6
        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.8)
    }
}
