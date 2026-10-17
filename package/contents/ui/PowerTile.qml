import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.ksysguard.sensors as Sensors
import "../code/palette.js" as Palette
import "../code/format.js" as Fmt

// GPU power draw plus every fan the system reports, with live-spinning fans.
// On a laptop: whether the charger is plugged in, and the battery's
// charge/drain rate when there's no GPU power reading.
GlassTile {
    id: tile
    required property var app

    readonly property var fans: app.specs.sensors ? app.specs.sensors.fans : []
    readonly property var bat: app.batteryState
    readonly property bool laptop: !!bat.present
    // On a laptop, GPU watts only if the GPU reports power at all (a hybrid
    // laptop's GPU sleeps at idle and reads 0; don't flip back and forth).
    readonly property bool showGpu: !laptop || !!(app.specs.sensors && app.specs.sensors.gpuPowerFile)
    readonly property real watts: showGpu ? app.gpuWatts : (bat.watts || 0)
    readonly property string chargeText: !laptop ? ""
        : bat.ac ? (bat.status === "Charging" ? i18n("Plugged in · charging") : i18n("Plugged in"))
        : i18n("On battery")

    title: i18n("Power & fans")
    subtitle: wide && showGpu && app.specs.gpus && app.specs.gpus.length ? i18n("GPU board power")
        : wide && laptop ? i18n("Battery draw") : ""
    // Fan rows that fit under the number (and the charger line, on a laptop).
    readonly property int fanRows: Math.max(laptop ? 0 : 1, Math.floor((height - pad * 2 - u * (wide ? 2 : 5.4) - (laptop ? u * 1.8 : 0)) / (u * 1.7)))
    accent: app.accent("power")
    accent2: app.accent2("power")
    level: Math.min(1, watts / (showGpu ? 200 : 60))

    GridLayout {
        anchors.fill: parent
        columns: tile.wide ? 2 : 1
        columnSpacing: tile.u * 1.5
        rowSpacing: tile.u * 0.4

        RowLayout {
            spacing: tile.u * 0.3
            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
            PlasmaComponents.Label {
                textFormat: Text.PlainText
                text: "⚡"
                visible: !tile.nativeOn   // Plasma's own widgets don't decorate numbers
                color: tile.accent
                font.pixelSize: big.size * 0.6
            }
            BigNumber {
                family: tile.numberFamily
                plain: tile.nativeOn
                id: big
                value: tile.watts
                unit: "W"
                size: Math.min(tile.u * 3.4, tile.height * 0.3)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom
            spacing: tile.u * 0.4

            // Laptop: the charger, and how long the battery lasts (or takes to fill).
            RowLayout {
                visible: tile.laptop
                Layout.fillWidth: true
                spacing: tile.u * 0.4
                Kirigami.Icon {
                    source: tile.bat.ac ? "battery-charging-080" : "battery-080"
                    Layout.preferredWidth: Math.max(Kirigami.Units.iconSizes.small, tile.u * 1.3)
                    Layout.preferredHeight: Layout.preferredWidth
                }
                PlasmaComponents.Label {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.8)
                    text: {
                        var parts = [tile.chargeText];
                        if (tile.bat.percent !== null && tile.bat.percent !== undefined) parts.push(tile.bat.percent + "%");
                        if (tile.bat.minutes > 0)
                            parts.push(tile.bat.status === "Charging" ? i18n("full in %1", Fmt.uptime(tile.bat.minutes * 60))
                                                                      : i18n("%1 left", Fmt.uptime(tile.bat.minutes * 60)));
                        if (tile.showGpu && tile.bat.watts > 0) parts.push(tile.bat.watts + " W");
                        return parts.join(" · ");
                    }
                }
            }

            PlasmaComponents.Label {
                textFormat: Text.PlainText
                visible: tile.fans.length === 0 && !tile.laptop
                text: i18n("No fan sensors found")
                opacity: 0.5
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.75)
            }

            Repeater {
                model: tile.fans.slice(0, tile.fanRows)
                RowLayout {
                    id: fanRow
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: tile.u * 0.5

                    Sensors.Sensor { id: rpmSensor; sensorId: fanRow.modelData.id; updateRateLimit: 2000 }
                    QtObject { id: rpm; property real value: 0 }
                    Connections { target: app; function onTickChanged() { rpm.value = rpmSensor.value || 0; } }

                    FanIcon {
                        id: fanIcon
                        rpm: rpm.value || 0
                        color: tile.accent
                        Layout.preferredWidth: Math.max(Kirigami.Units.iconSizes.small, tile.u * 1.5)
                        Layout.preferredHeight: Layout.preferredWidth
                    }
                    PlasmaComponents.Label {
                        textFormat: Text.PlainText
                        text: fanRow.modelData.label
                        opacity: 0.6
                        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.8)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    PlasmaComponents.Label {
                        textFormat: Text.PlainText
                        text: rpm.value > 0 ? Math.round(rpm.value) + " RPM" : i18n("Idle")
                        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.85)
                        font.weight: Font.Medium
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }
    }
}
