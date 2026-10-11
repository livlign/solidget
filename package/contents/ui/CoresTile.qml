import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.ksysguard.sensors as Sensors
import "../code/palette.js" as Palette

// Every CPU thread as a live heat cell.
GlassTile {
    id: tile
    required property var app

    readonly property int count: app.specs.cpu ? app.specs.cpu.threads : 0
    // Grid shape that best matches the tile's aspect ratio.
    readonly property int cols: {
        if (count <= 0) return 1;
        var best = 1, bestScore = 1e9;
        var aspect = grid.width / Math.max(1, grid.height);
        for (var c = 1; c <= count; c++) {
            var r = Math.ceil(count / c);
            var score = Math.abs(Math.log((c / r) / aspect)) + (c * r - count) * 0.15;
            if (score < bestScore) { bestScore = score; best = c; }
        }
        return best;
    }
    readonly property int rows: Math.max(1, Math.ceil(count / cols))

    title: i18n("Cores")
    subtitle: count ? i18n("%1 threads", count) : ""
    accent: app.accent("cores")
    accent2: app.heat(Math.min(1, app.cpuUsage.value / 60))
    level: app.cpuUsage.value / 100

    Item {
        id: grid
        anchors.fill: parent
        readonly property real gap: Math.max(3, tile.u * 0.3)
        readonly property real cellW: (width - gap * (tile.cols - 1)) / tile.cols
        readonly property real cellH: (height - gap * (tile.rows - 1)) / tile.rows

        Repeater {
            model: tile.count
            Rectangle {
                id: cell
                required property int index
                // Sampled on the shared tick so all cells change in one frame.
                property real load: 0
                Connections { target: app; function onTickChanged() { cell.load = sensor.value || 0; } }
                x: (index % tile.cols) * (grid.cellW + grid.gap)
                y: Math.floor(index / tile.cols) * (grid.cellH + grid.gap)
                width: grid.cellW
                height: grid.cellH
                radius: tile.radius > 0 ? Math.min(width, height) * 0.18 : 0
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                Sensors.Sensor {
                    id: sensor
                    sensorId: "cpu/cpu" + cell.index + "/usage"
                    updateRateLimit: 1000
                }
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    id: fill
                    color: app.heat(cell.load / 100)
                    opacity: 0.12 + Math.min(1, cell.load / 100) * 0.85
                    Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Kirigami.Units.longDuration } }
                }
                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: cell.width > tile.u * 2.2 && cell.height > tile.u * 1.4
                    text: Math.round(cell.load) + "%"
                    font.pixelSize: Math.min(cell.height * 0.32, cell.width * 0.26)
                    font.weight: Font.Medium
                    font.features: { "tnum": 1 }
                    // On a strong fill, pick dark or light text by how bright the fill is
                    // (Ink & Paper fills busy cores near-black).
                    color: cell.load <= 55 ? Kirigami.Theme.textColor : fill.color.hslLightness > 0.5 ? "#0b1020" : "#ffffff"
                    opacity: 0.85
                }
            }
        }
    }
}
