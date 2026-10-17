import QtQuick
import QtQuick.Shapes

// Uptime scene: a heartbeat monitor that sweeps. A bright pen runs left to
// right drawing the trace as it goes, with a small gap ahead of it where the
// old trace is wiped, then wraps round, like a hospital monitor. No two
// beats alike: the spike's height, the spacing, the small waves and the
// baseline all wander, with now and then a skipped or an extra beat. Busier
// CPU, faster and taller beats. `bpm` is shown by the tile.
// The pen moves on its own timer, a dozen steps a second, only while shown.
Item {
    id: pulse
    required property var app
    property int tick: 0
    property color color: "#f43f5e"
    property bool running: visible

    clip: true

    readonly property real load: (app.cpuUsage && app.cpuUsage.value) || 0
    readonly property real mid: height * 0.55
    readonly property real amp: height * 0.46
    readonly property real step: 3                      // pixels between samples
    readonly property int count: Math.max(10, Math.ceil(width / step))
    readonly property int gapN: Math.max(3, Math.round(count * 0.07))
    // One sweep across takes about four seconds.
    readonly property real samplesPerSec: count / 4
    property int bpm: 64

    // The trace: one y per sample; the pen is at `head`.
    property var ys: []
    property int head: 0
    property real phase: 0          // 0..1 through the current beat
    property var beat: newBeat()

    function vary(v, by) { return v * (1 + (Math.random() * 2 - 1) * by); }
    function newBeat() {
        var busy = Math.min(1, load / 100);
        var r = Math.random();
        bpm = Math.round(vary(62 + busy * 60, 0.06));
        return {
            dur: vary(60 / (62 + busy * 60), 0.18),     // seconds this beat lasts
            a: Math.min(1, vary(0.78 + busy * 0.2, 0.25)),
            p: vary(0.1, 0.6), s: vary(0.3, 0.5), t: vary(0.16, 0.5),
            drift: (Math.random() * 2 - 1) * 0.05,
            kind: r < 0.07 ? "flat" : r < 0.13 ? "double" : "beat"
        };
    }
    // Height of the trace (up is positive, 1 = full) at point f (0..1) of beat b.
    function ecg(f, b) {
        function lerp(x0, y0, x1, y1) { return y0 + (y1 - y0) * (f - x0) / (x1 - x0); }
        var y = 0;
        if (b.kind === "flat") y = f < 0.5 ? lerp(0, 0, 0.5, 0.05) : lerp(0.5, 0.05, 1, 0);
        else if (f < 0.12) y = 0;
        else if (f < 0.2) y = lerp(0.12, 0, 0.2, b.p);
        else if (f < 0.28) y = lerp(0.2, b.p, 0.28, 0);
        else if (f < 0.34) y = lerp(0.28, 0, 0.34, -0.1);
        else if (f < 0.4) y = lerp(0.34, -0.1, 0.4, b.a);
        else if (f < 0.47) y = lerp(0.4, b.a, 0.47, -b.s);
        else if (f < 0.53) y = lerp(0.47, -b.s, 0.53, 0);
        else if (b.kind === "double" && f < 0.6) y = lerp(0.53, 0, 0.6, b.a * 0.55);
        else if (b.kind === "double" && f < 0.66) y = lerp(0.6, b.a * 0.55, 0.66, 0);
        else if (f < 0.94) y = Math.max(0, Math.sin((f - 0.66) / 0.28 * Math.PI)) * b.t;
        return y + b.drift;
    }

    function advance(seconds) {
        if (ys.length !== count) {
            var fresh = [];
            for (var k = 0; k < count; k++) fresh.push(mid);
            ys = fresh;
            head = 0;
        }
        var n = Math.max(1, Math.round(seconds * samplesPerSec));
        var out = ys.slice();
        for (var i = 0; i < n; i++) {
            phase += 1 / (samplesPerSec * beat.dur);
            if (phase >= 1) { phase -= 1; beat = newBeat(); }
            out[head] = mid - amp * ecg(phase, beat);
            head = (head + 1) % count;
        }
        ys = out;
    }

    Timer {
        interval: 83
        running: pulse.running && pulse.width > 0
        repeat: true
        onTriggered: pulse.advance(interval / 1000)
    }

    // Points from sample a up to (not including) sample b.
    function points(a, b) {
        var pts = [];
        for (var i = a; i < b; i++) pts.push(Qt.point(i * step, ys[i]));
        return pts;
    }
    // Just drawn (left of the pen) and older (right of the gap).
    readonly property var fresh: ys.length === count ? points(0, head) : []
    readonly property var old: ys.length === count ? points(Math.min(count, head + gapN), count) : []

    // Faint baseline
    Rectangle {
        y: pulse.mid
        width: pulse.width; height: 1
        color: pulse.color
        opacity: 0.15
    }

    component Trace: Shape {
        property var pts: []
        anchors.fill: parent
        visible: pts.length > 1
        preferredRendererType: Shape.CurveRenderer
        ShapePath {     // glow
            strokeColor: Qt.rgba(pulse.color.r, pulse.color.g, pulse.color.b, 0.18)
            strokeWidth: Math.max(6, pulse.height / 18)
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathPolyline { path: pts }
        }
        ShapePath {
            strokeColor: pulse.color
            strokeWidth: Math.max(2, pulse.height / 55)
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathPolyline { path: pts }
        }
    }
    Trace { pts: pulse.old; opacity: 0.35 }
    Trace { pts: pulse.fresh }

    // The pen
    Rectangle {
        readonly property real d: Math.max(8, pulse.height / 14)
        visible: pulse.ys.length === pulse.count && pulse.head > 0
        x: (pulse.head - 1) * pulse.step - d / 2
        y: (pulse.ys[Math.max(0, pulse.head - 1)] || pulse.mid) - d / 2
        width: d; height: d; radius: d / 2
        color: pulse.color
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 2.4; height: width; radius: width / 2
            color: pulse.color
            opacity: 0.22
        }
    }
}
