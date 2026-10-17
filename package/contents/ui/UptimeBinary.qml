import QtQuick
import "../code/sky.js" as Sky

// Uptime scene for nerds: a binary clock. Days, hours, minutes and seconds,
// two digits each, every digit a column of four lights (8, 4, 2, 1), so the
// seconds flip every second. 0s and 1s rain down faintly behind it.
// Moves on the shared tick only.
Item {
    id: bin
    property int tick: 0
    property real seconds: 0
    property color color: "#4ade80"        // lit
    property color text: "#ffffff"          // unlit lights and labels
    property bool rain: true

    readonly property var parts: {
        var s = Math.max(0, Math.floor(seconds));
        return [Math.min(99, Math.floor(s / 86400)), Math.floor(s % 86400 / 3600), Math.floor(s % 3600 / 60), s % 60];
    }
    readonly property var labels: ["d", "h", "m", "s"]

    // ---- Bit rain ----
    readonly property real rainSize: Math.max(8, Math.min(width, height) / 11)
    readonly property int rainCols: Math.max(1, Math.floor(width / (rainSize * 1.1)))
    readonly property var seeds: Sky.scatter(40, 31)
    Item {
        anchors.fill: parent
        visible: bin.rain
        clip: true
        Repeater {
            model: bin.rainCols
            Text {
                required property int index
                readonly property var seed: bin.seeds[index % bin.seeds.length]
                readonly property int rows: Math.ceil(bin.height / (bin.rainSize * 1.05)) + 1
                // A fixed column of bits, written twice so it can scroll round.
                readonly property string bits: {
                    var out = [], v = Math.floor(seed.x * 65535) | 1;
                    for (var i = 0; i < rows; i++) { v = (v * 75 + 74) % 65537; out.push(v & 1 ? "1" : "0"); }
                    return out.concat(out).join("\n");
                }
                textFormat: Text.PlainText
                x: index * bin.rainSize * 1.1
                y: -((bin.tick * (1 + seed.phase % 3) + Math.floor(seed.y * rows)) % rows) * bin.rainSize * 1.05
                text: bits
                lineHeightMode: Text.FixedHeight
                lineHeight: bin.rainSize * 1.05
                font.family: "monospace"
                font.pixelSize: bin.rainSize
                color: bin.color
                opacity: 0.06 + seed.size * 0.12
            }
        }
    }

    // ---- The clock ----
    readonly property real dot: Math.max(4, Math.min(height / 5.6, width / 14))
    readonly property real step: dot * 1.3
    readonly property real groupGap: dot * 0.9
    readonly property real clockW: 8 * step + 3 * groupGap - (step - dot)
    Item {
        x: (bin.width - bin.clockW) / 2
        y: (bin.height - (4 * bin.step + bin.dot * 0.9)) / 2
        width: bin.clockW
        height: 4 * bin.step + bin.dot
        Repeater {
            model: 8      // two digit columns per part
            Item {
                id: col
                required property int index
                readonly property int part: Math.floor(index / 2)
                readonly property int digit: index % 2 === 0 ? Math.floor(bin.parts[part] / 10) : bin.parts[part] % 10
                x: index * bin.step + part * bin.groupGap
                width: bin.dot
                height: parent.height
                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        readonly property bool on: (col.digit >> (3 - index)) & 1
                        y: index * bin.step
                        width: bin.dot; height: bin.dot
                        radius: bin.dot * 0.28
                        color: on ? bin.color : Qt.rgba(bin.text.r, bin.text.g, bin.text.b, 0.09)
                        // Lit lights glow a little.
                        Rectangle {
                            visible: parent.on
                            anchors.centerIn: parent
                            width: parent.width * 1.7; height: width; radius: width / 2
                            color: bin.color
                            opacity: 0.16
                            z: -1
                        }
                    }
                }
                Text {     // d h m s under each pair
                    visible: col.index % 2 === 1
                    textFormat: Text.PlainText
                    x: -bin.step / 2 - width / 2 + bin.dot / 2
                    y: 4 * bin.step
                    text: bin.labels[col.part]
                    color: bin.text
                    opacity: 0.55
                    font.family: "monospace"
                    font.pixelSize: bin.dot * 0.8
                }
            }
        }
    }
}
