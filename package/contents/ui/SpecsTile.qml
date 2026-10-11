import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../code/format.js" as Fmt
import "../code/palette.js" as Palette

// The "show off your build" card: CPU and GPU as hero lines with vendor
// badges, everything else in a grid that adds columns as the tile widens.
GlassTile {
    id: tile
    required property var app

    readonly property var s: app.specs
    readonly property var gpu: s.gpus && s.gpus.length ? s.gpus[0] : null

    title: app.shownHostname
    subtitle: s.system ? s.system.os : ""
    accent: s.cpu && app.vendorColor(s.cpu.vendor) ? app.vendorColor(s.cpu.vendor) : app.accent("specs")
    accent2: gpu && app.vendorColor(gpu.vendor) ? app.vendorColor(gpu.vendor) : app.accent2("specs")
    level: 0.45

    function memoryLine() {
        var m = s.memory || {};
        var line = m.nominalGB + " GB";
        if (m.type) line += " " + m.type + (m.speed ? "-" + m.speed : "");
        return line;
    }
    function heroes() {
        var h = [];
        if (s.cpu) {
            var d = [i18n("%1 cores", s.cpu.cores), i18n("%1 threads", s.cpu.threads)];
            if (s.cpu.maxGHz) d.push(i18n("%1 GHz boost", s.cpu.maxGHz.toFixed(2)));
            h.push({ kind: i18n("Processor"), name: s.cpu.name, detail: d.join(" · "), vendor: s.cpu.vendor });
        }
        (s.gpus || []).forEach(function (g) {
            h.push({ kind: i18n("Graphics"), name: g.name, detail: g.vramBytes ? i18n("%1 VRAM", app.bytesText(g.vramBytes, 0)) : "", vendor: g.vendor });
        });
        return h;
    }
    function facts() {
        var f = [];
        if (!s.cpu) return f;
        f.push({ label: i18n("Memory"), value: memoryLine(), detail: (s.memory || {}).layout || "" });
        if (s.board && s.board.name)
            f.push({ label: i18n("Motherboard"), value: (s.board.vendor + " " + s.board.name).trim(), detail: "" });
        (s.drives || []).forEach(function (d) {
            f.push({ label: i18n("Storage"), value: d.model, detail: Fmt.driveSize(d.sizeBytes) + " " + d.kind });
        });
        (s.displays || []).forEach(function (d, i) {
            f.push({ label: s.displays.length > 1 ? i18n("Display %1", i + 1) : i18n("Display"), value: d.width + " × " + d.height, detail: d.hz + " Hz" });
        });
        if (s.system)
            f.push({ label: i18n("System"), value: s.system.os, detail: ["Linux " + s.system.kernel, s.system.plasma ? "Plasma " + s.system.plasma : ""].filter(Boolean).join(" · ") });
        return f;
    }
    function asText() {
        var lines = [app.shownHostname + " — specs"];
        heroes().forEach(function (h) { lines.push(h.kind + ": " + h.name + (h.detail ? " (" + h.detail + ")" : "")); });
        facts().forEach(function (f) { lines.push(f.label + ": " + f.value + (f.detail ? " (" + f.detail + ")" : "")); });
        lines.push("Shared with Solidget");
        return lines.join("\n");
    }

    // Shrink the type until everything fits the tile (the card can land in
    // anything from a 2x2 corner slot to half a 4K screen): limited by the
    // height of all rows, and by the longest value fitting its column.
    readonly property var heroList: heroes()
    readonly property var factList: facts()
    readonly property real innerW: width - pad * 2
    readonly property int longestFact: factList.reduce(function (m, f) { return Math.max(m, f.value.length); }, 8)
    readonly property int longestHero: heroList.reduce(function (m, h) { return Math.max(m, h.name.length); }, 8)
    function suFor(cols) {
        var needed = heroList.length * 4.4 + 1.4 + Math.ceil(factList.length / cols) * 3.9 + 3.2;
        return Math.min(u * 1.25,
                        (height - pad * 2 - u * 1.6) / needed,
                        (innerW / cols - u) / (longestFact * 0.5 * 0.95),
                        (innerW - u * 4.5) / (longestHero * 0.55 * 1.55));
    }
    // Whichever column count allows the biggest type wins.
    readonly property int factCols: {
        var best = 1;
        for (var c = 2; c <= 3; c++) if (suFor(c) > suFor(best) * 1.05) best = c;
        return best;
    }
    readonly property real su: Math.max(Kirigami.Units.gridUnit * 0.5, suFor(factCols))
    readonly property real nameSize: su * 1.55

    PlasmaComponents.Label {
        textFormat: Text.PlainText
        visible: !tile.s.cpu
        text: i18n("Reading your hardware…")
        opacity: 0.6
    }

    ColumnLayout {
        anchors.fill: parent
        visible: !!tile.s.cpu
        clip: true
        spacing: tile.su * 0.7

        // Hero lines
        Repeater {
            model: tile.heroList
            RowLayout {
                id: hero
                required property var modelData
                Layout.fillWidth: true
                spacing: tile.su * 0.7

                Rectangle {
                    visible: !tile.nativeOn   // the name already says AMD/Intel/NVIDIA
                    readonly property color vc: app.vendorColor(hero.modelData.vendor) || tile.accent
                    Layout.preferredWidth: badge.implicitWidth + tile.su * 0.9
                    Layout.preferredHeight: tile.nameSize * 1.25
                    Layout.alignment: Qt.AlignTop
                    radius: tile.radius > 0 ? height * 0.28 : 0
                    color: Qt.rgba(vc.r, vc.g, vc.b, 0.16)
                    border.width: 1
                    border.color: Qt.rgba(vc.r, vc.g, vc.b, 0.55)
                    PlasmaComponents.Label {
                        id: badge
                        textFormat: Text.PlainText
                        anchors.centerIn: parent
                        text: (hero.modelData.vendor || "?").toUpperCase()
                        color: parent.vc
                        font.pixelSize: tile.nameSize * 0.5
                        font.weight: Font.Black
                        font.letterSpacing: tile.su * 0.08
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    PlasmaComponents.Label {
                        textFormat: Text.PlainText
                        text: hero.modelData.kind
                        opacity: 0.55
                        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.su * 0.72)
                        font.capitalization: tile.nativeOn ? Font.MixedCase : Font.AllUppercase
                        font.letterSpacing: tile.nativeOn ? 0 : tile.su * 0.08
                    }
                    PlasmaComponents.Label {
                        text: hero.modelData.name
                        textFormat: Text.PlainText
                        font.pixelSize: tile.nameSize
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    PlasmaComponents.Label {
                        textFormat: Text.PlainText
                        text: hero.modelData.detail
                        visible: text !== ""
                        opacity: 0.7
                        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.su * 0.8)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(tile.accent.r, tile.accent.g, tile.accent.b, 0.5) }
                GradientStop { position: 1; color: Qt.rgba(tile.accent2.r, tile.accent2.g, tile.accent2.b, 0.0) }
            }
        }

        // Fact grid
        GridLayout {
            Layout.fillWidth: true
            columns: tile.factCols
            columnSpacing: tile.su
            rowSpacing: tile.su * 0.55

            Repeater {
                model: tile.factList
                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 0
                    PlasmaComponents.Label {
                        textFormat: Text.PlainText
                        text: modelData.label
                        opacity: 0.55
                        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.su * 0.7)
                        font.capitalization: tile.nativeOn ? Font.MixedCase : Font.AllUppercase
                        font.letterSpacing: tile.nativeOn ? 0 : tile.su * 0.06
                    }
                    PlasmaComponents.Label {
                        textFormat: Text.PlainText
                        text: modelData.value
                        font.pixelSize: Math.max(Kirigami.Theme.defaultFont.pixelSize * 0.9, tile.su * 0.95)
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    PlasmaComponents.Label {
                        textFormat: Text.PlainText
                        text: modelData.detail
                        visible: text !== ""
                        opacity: 0.6
                        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.su * 0.72)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                textFormat: Text.PlainText
                text: app.uptime.value ? i18n("Up %1", Fmt.uptime(app.uptime.value)) : ""
                opacity: 0.5
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.su * 0.7)
                Layout.fillWidth: true
            }
            PlasmaComponents.ToolButton {
                id: copyButton
                property bool copied: false
                icon.name: copied ? "dialog-ok-apply" : "edit-copy"
                text: copied ? i18n("Copied") : i18n("Copy specs")
                display: QQC2.AbstractButton.TextBesideIcon
                onClicked: {
                    app.copyToClipboard(tile.asText());
                    copied = true;
                    resetTimer.restart();
                }
                Timer {
                    id: resetTimer
                    interval: 2000
                    onTriggered: copyButton.copied = false
                }
            }
        }
    }
}
