import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.ksysguard.process as Process
import "../code/palette.js" as Palette
import "../code/format.js" as Fmt

// Apps using the most CPU right now, grouped per application like
// System Monitor does (all Chrome processes count as one "Google Chrome").
GlassTile {
    id: tile
    required property var app

    property var topApps: []
    // A list wants many readable rows, not glance-sized text: size rows to
    // fit about 10 apps (within sane bounds) and derive the type from that.
    readonly property real rowH: Math.max(Kirigami.Units.gridUnit * 1.6, Math.min(Kirigami.Units.gridUnit * 2.6, list.height / 10))
    readonly property real lu: rowH / 2.2
    readonly property int maxRows: Math.max(1, Math.floor(list.height / rowH))

    title: i18n("Top apps")
    subtitle: i18n("by CPU")
    accent: app.accent("processes")
    accent2: app.accent2("processes")
    level: topApps.length ? Math.min(1, topApps[0].cpu / 25) : 0.2

    Process.ApplicationDataModel {
        id: apps
        enabled: tile.visible
        enabledAttributes: ["appName", "iconName", "usage", "memory"]
        cgroupMapping: { "session.slice": "services", "background.slice": "services" }
        applicationOverrides: { "services": { "menuId": "services", "appName": i18n("Background Services"), "iconName": "preferences-system-services" } }
    }

    // "700.1 MiB" -> bytes (the model's display text is the only unit-safe form).
    // KDE's formatter puts a zero-width space inside the unit ("Mi\u200BB").
    function parseSize(text) {
        var m = /([\d.,]+)\s*([KMGT]?i?B)/.exec(String(text || "").replace(/\u200B/g, ""));
        if (!m) return 0;
        var mult = { "B": 1, "KiB": 1024, "MiB": 1048576, "GiB": 1073741824, "TiB": 1099511627776,
                     "KB": 1000, "MB": 1e6, "GB": 1e9, "TB": 1e12 }[m[2]] || 1;
        return parseFloat(m[1].replace(",", ".")) * mult;
    }

    function refresh() {
        var nameCol = apps.enabledAttributes.indexOf("appName");
        var iconCol = apps.enabledAttributes.indexOf("iconName");
        var cpuCol = apps.enabledAttributes.indexOf("usage");
        var memCol = apps.enabledAttributes.indexOf("memory");
        // The model can list one app several times (e.g. two Chrome
        // entries); merge them by name, summing CPU and memory.
        var byName = {};
        var rows = [];
        for (var r = 0; r < apps.rowCount(); r++) {
            var pids = apps.data(apps.index(r, 0), Process.ProcessDataModel.PIDs);
            if (!pids || pids.length === 0) continue;
            // Normalize so look-alike names (odd spaces, zero-width
            // characters) merge into one entry.
            var name = String(apps.data(apps.index(r, nameCol), Qt.DisplayRole) || "")
                .replace(/[\u200B-\u200D\uFEFF]/g, "").replace(/\s+/g, " ").trim();
            var cpu = Number(apps.data(apps.index(r, cpuCol), Process.ProcessDataModel.Value)) || 0;
            var mem = parseSize(apps.data(apps.index(r, memCol), Qt.DisplayRole));
            if (byName[name]) {
                byName[name].cpu += cpu;
                byName[name].mem += mem;
                continue;
            }
            byName[name] = { name: name, icon: apps.data(apps.index(r, iconCol), Qt.DisplayRole) || "", cpu: cpu, mem: mem };
            rows.push(byName[name]);
        }
        rows.forEach(function (row) { row.memText = row.mem > 0 ? app.bytesText(row.mem) : ""; });
        // The model reports per-core percent (one busy thread = 100%);
        // show share of the whole CPU like System Monitor does.
        var threads = app.specs.cpu ? app.specs.cpu.threads : 1;
        rows.forEach(function (row) {
            row.cpu = row.cpu / threads;
            row.cpuText = row.cpu.toFixed(1) + "%";
        });
        rows.sort(function (a, b) { return b.cpu - a.cpu; });
        topApps = rows.slice(0, 20);
    }

    // Every other shared tick.
    Connections { target: app; function onTickChanged() { if (app.tick % 2 === 0 && tile.visible) tile.refresh(); } }

    ColumnLayout {
        id: list
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: tile.topApps.slice(0, tile.maxRows)

            RowLayout {
                id: row
                required property var modelData
                required property int index
                readonly property real share: tile.topApps.length && tile.topApps[0].cpu > 0 ? modelData.cpu / tile.topApps[0].cpu : 0
                Layout.fillWidth: true
                Layout.preferredHeight: tile.rowH
                spacing: tile.lu * 0.6

                Kirigami.Icon {
                    source: row.modelData.icon
                    fallback: "application-x-executable"
                    Layout.preferredWidth: Math.min(tile.rowH * 0.72, Kirigami.Units.iconSizes.large)
                    Layout.preferredHeight: Layout.preferredWidth
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: tile.lu * 0.18
                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: row.modelData.name
                            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.lu * 0.85)
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        PlasmaComponents.Label {
                            text: row.modelData.memText
                            visible: tile.width > Kirigami.Units.gridUnit * 18
                            opacity: 0.55
                            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.lu * 0.75)
                            font.features: { "tnum": 1 }
                        }
                        PlasmaComponents.Label {
                            text: row.modelData.cpuText
                            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.lu * 0.85)
                            font.weight: Font.DemiBold
                            font.features: { "tnum": 1 }
                            Layout.minimumWidth: tile.lu * 3
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(2, tile.lu * 0.18)
                        radius: tile.radius > 0 ? height / 2 : 0
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
                        Rectangle {
                            height: parent.height
                            radius: parent.radius
                            width: parent.width * row.share
                            Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: tile.accent }
                                GradientStop { position: 1; color: tile.accent2 }
                            }
                        }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
