import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.ksysguard.sensors as Sensors
import "../code/palette.js" as Palette

// GPU power draw plus every fan the system reports, with live-spinning fans.
GlassTile {
    id: tile
    required property var app

    readonly property var fans: app.specs.sensors ? app.specs.sensors.fans : []
    readonly property real watts: app.gpuWatts

    title: i18n("Power & fans")
    subtitle: wide && app.specs.gpus && app.specs.gpus.length ? i18n("GPU board power") : ""
    accent: app.accent("power")
    accent2: app.accent2("power")
    level: Math.min(1, watts / 200)

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
                color: tile.accent
                font.pixelSize: big.size * 0.6
            }
            BigNumber {
                family: tile.numberFamily
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

            PlasmaComponents.Label {
                textFormat: Text.PlainText
                visible: tile.fans.length === 0
                text: i18n("No fan sensors found")
                opacity: 0.5
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.75)
            }

            Repeater {
                model: tile.fans
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
