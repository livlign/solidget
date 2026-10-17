import QtQuick

// Uptime scene: a watch dial running round the edge of the tile, following
// its rounded border. 60 ticks, every fifth one longer, like the marks on a
// clock. The lit tick moves on a step every second with a fading trail in
// the tile's color: once round per minute. Moves on the shared tick, with
// a short fade so the sweep looks smooth.
Item {
    id: ring
    property int tick: 0
    property real seconds: 0
    property color color: "#ffffff"      // resting ticks
    property color accent: "#38bdf8"     // the sweep
    property real margin: 4              // from the card's edge to the ticks' outer ends
    property real length: 10             // a minor tick; major ones are longer
    property real thickness: 2
    property real cornerRadius: 12

    readonly property int count: 60
    readonly property int trail: 20
    readonly property int head: Math.floor(seconds) % count

    // Points along the rounded rectangle, starting top middle, going clockwise:
    // [x, y, angle], where angle is which way the edge faces (0 = up, 90 = right).
    readonly property var spots: {
        var m = margin, a = width - 2 * m, b = height - 2 * m;
        if (a <= 0 || b <= 0) return [];
        var rc = Math.max(0, Math.min(cornerRadius, a / 2, b / 2));
        var arc = Math.PI / 2 * rc;
        function line(x0, y0, x1, y1, ang) {
            return { len: Math.hypot(x1 - x0, y1 - y0), at: function (t) { return [x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, ang]; } };
        }
        function corner(cx, cy, from) {
            return { len: arc, at: function (t) {
                var th = from + 90 * t, r = th * Math.PI / 180;
                return [cx + rc * Math.sin(r), cy - rc * Math.cos(r), th];
            } };
        }
        var segs = [
            line(m + a / 2, m, m + a - rc, m, 0),
            corner(m + a - rc, m + rc, 0),
            line(m + a, m + rc, m + a, m + b - rc, 90),
            corner(m + a - rc, m + b - rc, 90),
            line(m + a - rc, m + b, m + rc, m + b, 180),
            corner(m + rc, m + b - rc, 180),
            line(m, m + b - rc, m, m + rc, 270),
            corner(m + rc, m + rc, 270),
            line(m + rc, m, m + a / 2, m, 360)
        ];
        var total = 0;
        segs.forEach(function (sg) { total += sg.len; });
        var out = [];
        for (var i = 0; i < count; i++) {
            var d = total * i / count, k = 0;
            while (k < segs.length - 1 && d > segs[k].len) { d -= segs[k].len; k++; }
            out.push(segs[k].at(segs[k].len > 0 ? d / segs[k].len : 0));
        }
        return out;
    }

    Repeater {
        model: ring.spots
        Item {
            id: mark
            required property var modelData
            required property int index
            readonly property bool major: index % 5 === 0
            // How many seconds ago the sweep passed here (0 = it's here now).
            readonly property int age: (ring.head - index + ring.count) % ring.count
            // 1 at the head, fading to 0 along the trail.
            readonly property real lit: age < ring.trail ? Math.pow(1 - age / ring.trail, 1.6) : 0
            x: modelData[0]
            y: modelData[1]
            rotation: modelData[2]
            transformOrigin: Item.TopLeft

            // A soft glow behind the lit tick.
            Rectangle {
                visible: mark.age === 0
                x: -width / 2
                y: -ring.thickness
                width: ring.thickness * 4
                height: (mark.major ? ring.length * 1.5 : ring.length) + ring.thickness * 2
                radius: width / 2
                color: ring.accent
                opacity: 0.3
            }
            Rectangle {
                x: -width / 2
                width: mark.major ? ring.thickness * 1.6 : ring.thickness
                height: mark.major ? ring.length * 1.5 : ring.length
                radius: width / 2
                color: Qt.tint(ring.color, Qt.rgba(ring.accent.r, ring.accent.g, ring.accent.b, Math.min(1, mark.lit * 1.3)))
                opacity: (mark.major ? 0.42 : 0.22) + (1 - (mark.major ? 0.42 : 0.22)) * mark.lit
                Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 450 } }
            }
        }
    }
}
