import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.bluezqt as BluezQt

// The Bluetooth tile's body, laid out like the Temperatures tile: a readout
// row per device with its battery bar, drawn the look's way (HeatBar), and
// one device's charge in big figures when it's the only one.
Item {
    id: body

    property Item tile: null
    property bool masked: true
    readonly property real u: tile ? tile.u : Kirigami.Units.gridUnit
    readonly property var opt: tile && tile.app && tile.app.bluetoothOptions
        ? tile.app.bluetoothOptions : ({ names: "name", colors: "accent", low: 20 })

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

    // "Rainbow": each device takes the next of the colors' six hues, by way
    // of tiles that sit on different ones.
    readonly property var rainbowIds: ["bluetooth", "gpu", "disk", "clock", "cpu", "power"]
    readonly property color lowColor: "#f43f5e"
    function colorFor(i, pct) {
        if (pct >= 0 && opt.low > 0 && pct <= opt.low) return lowColor;
        if (opt.colors === "rainbow" && tile && tile.app)
            return tile.app.accent(rainbowIds[i % rainbowIds.length]);
        if (opt.colors === "charge" && pct >= 0)
            return pct >= 50 ? "#22c55e" : pct >= 25 ? "#f59e0b" : "#f97316";
        return tile ? tile.accent : Kirigami.Theme.highlightColor;
    }
    // Where the bar's color ramp starts.
    function color2For(i, pct) {
        if (pct >= 0 && opt.low > 0 && pct <= opt.low) return "#f97316";
        if (opt.colors === "accent" && tile) return tile.accent2;
        return colorFor(i, pct);
    }

    // Line icons, in the text color; the full-color ones turn into blobs
    // when tinted.
    function symbolic(icon) {
        icon = String(icon || "network-bluetooth").replace(/-symbolic$/, "");
        return (icon.indexOf("input-gaming") === 0 ? "input-gamepad" : icon) + "-symbolic";
    }

    // One per connected device.
    readonly property var items: connected.map(function (d, i) {
        var pct = d.battery ? d.battery.percentage : -1;
        var k = kind(d.icon);
        return {
            name: masked || opt.names === "kind" ? k : String(d.name || k),
            kind: k,
            icon: symbolic(d.icon),
            pct: pct,
            low: pct >= 0 && opt.low > 0 && pct <= opt.low,
            color: colorFor(i, pct),
            color2: color2For(i, pct)
        };
    })

    // No battery reported: a dash, as other tiles show a missing reading.
    function pctText(d) { return d.pct >= 0 ? i18nc("battery level", "%1%", d.pct) : "–"; }

    // ---- The readout ----
    readonly property bool single: items.length === 1
    readonly property bool wide: width > height * 1.6
    // Wide: a second column only when one won't hold every row (one
    // device: its number beside its row).
    // A row is about 2.5 bar units tall with the gap below it (as on
    // Temperatures); rows shrink to fit, down to a readable floor, and
    // past that the last one says how many more there are.
    readonly property real minBarU: u * 0.62
    readonly property int slotsPerCol: Math.max(1, Math.floor((height / minBarU + 0.5) / 2.5))
    readonly property int cols: wide && count > slotsPerCol ? 2 : 1
    readonly property bool overflow: Math.ceil(count / cols) > slotsPerCol
    readonly property int shownCount: overflow ? slotsPerCol * cols - 1 : count
    readonly property int perCol: Math.ceil((shownCount + (overflow ? 1 : 0)) / cols)
    // One device, stacked: the big number takes the top, like the other tiles.
    readonly property bool bigNumber: single && items[0].pct >= 0
    readonly property real figure: tile ? tile.figureSize : u * 3
    readonly property real barU: Math.max(minBarU, Math.min(u, height / Math.max(1, perCol * 2.5 - 0.5),
        bigNumber && !wide ? (height - figure * 1.4 - u * 0.5) / 2 : u))

    GridLayout {
        visible: body.count > 0
        anchors.fill: parent
        columns: body.bigNumber && body.wide ? 2 : 1
        columnSpacing: body.u
        rowSpacing: body.u * 0.5

        BigNumber {
            visible: body.bigNumber && size >= body.u * 1.4
            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
            family: body.tile ? body.tile.numberFamily : ""
            figures: body.tile ? body.tile.figureFamily : ""
            weight: body.tile ? body.tile.figureWeight : Font.Light
            plain: body.tile ? body.tile.nativeOn : false
            value: body.bigNumber ? body.items[0].pct : 0
            unit: "%"
            color: body.bigNumber && body.items[0].low ? body.items[0].color : Kirigami.Theme.textColor
            size: Math.min(body.figure, body.wide ? body.height : (body.height - body.barU * 2 - body.u * 0.5) / 1.4)
        }
        GridLayout {
            Layout.fillWidth: true
            Layout.alignment: body.bigNumber ? Qt.AlignBottom : Qt.AlignVCenter
            columns: body.cols
            columnSpacing: body.u * 1.2
            rowSpacing: body.barU * 0.5
            flow: GridLayout.TopToBottom
            rows: body.perCol
            Repeater {
                model: body.items.slice(0, body.shownCount)
                RowLayout {
                    id: row
                    required property var modelData
                    readonly property var d: modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: body.barU * 0.45
                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: body.barU * 1.15
                        Layout.preferredHeight: Layout.preferredWidth
                        source: row.d.icon
                        fallback: "network-bluetooth-symbolic"
                        isMask: true
                        color: row.d.low ? row.d.color : Kirigami.Theme.textColor
                        opacity: row.d.low ? 1 : 0.7
                    }
                    HeatBar {
                        Layout.fillWidth: true
                        u: body.barU
                        label: row.d.name
                        celsius: Math.max(0, row.d.pct)
                        valueText: body.pctText(row.d)
                        hotColor: row.d.color
                        coolColor: row.d.color2
                        scaleEnd: row.d.color
                        showBar: row.d.pct >= 0
                        showDot: false
                        square: body.tile ? body.tile.radius === 0 : false
                        kind: body.tile && body.tile.look && body.tile.look.heatBar ? body.tile.look.heatBar : "thin"
                        detailKind: body.tile ? body.tile.detailStyle : ""
                        family: body.tile ? body.tile.figureFamily : ""
                    }
                }
            }
            PlasmaComponents.Label {
                visible: body.overflow
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                textFormat: Text.PlainText
                text: i18np("+%1 more", "+%1 more", body.count - body.shownCount)
                opacity: 0.55
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, body.barU * 0.75)
            }
        }
    }

    readonly property real fs: Math.max(Kirigami.Theme.smallFont.pixelSize, u * 0.8)

    // Nothing connected, or Bluetooth is off: the mark, quietly (struck
    // through when it's off).
    ColumnLayout {
        visible: body.count === 0
        anchors.centerIn: parent
        width: parent.width
        spacing: body.u * 0.35
        // In an Item: a Shape sized by a layout loops on its own bounds.
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: Math.max(body.u * 1.6, Math.min(body.height * 0.3, body.u * 3.5))
            Layout.preferredWidth: Layout.preferredHeight * 0.8
            BluetoothRune {
                anchors.fill: parent
                weight: 0.07
                color: Kirigami.Theme.textColor
                opacity: 0.45
            }
            Rectangle {
                visible: !body.on
                anchors.centerIn: parent
                width: parent.height * 0.95; height: Math.max(1.5, parent.height * 0.06)
                radius: height / 2
                rotation: -45
                color: Kirigami.Theme.textColor
                opacity: 0.45
            }
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            textFormat: Text.PlainText
            text: !body.on ? i18n("Bluetooth is off") : i18n("Nothing connected")
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            opacity: 0.7
            font.pixelSize: body.fs
        }
        PlasmaComponents.Label {
            visible: body.on && body.paired > 0 && body.height > body.u * 6
            Layout.fillWidth: true
            Layout.topMargin: -body.u * 0.25
            textFormat: Text.PlainText
            text: i18np("%1 paired device", "%1 paired devices", body.paired)
            horizontalAlignment: Text.AlignHCenter
            opacity: 0.45
            font.pixelSize: body.fs * 0.9
        }
    }
}
