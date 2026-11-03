import QtQuick
import org.kde.plasma.private.volume

// The default audio output (speakers, headphones, …) and its volume, from
// Plasma's audio service. Its own file: without plasma-pa the import fails
// and only the output line goes missing, not the whole tile.
Item {
    id: out

    property bool masked: true
    property var sink: null
    readonly property bool ready: sink !== null
    readonly property int percent: sink ? Math.round(sink.volume / PulseAudio.NormalVolume * 100) : 0
    readonly property bool muted: sink ? sink.muted : false
    readonly property bool bluetooth: sink ? String(sink.name).indexOf("bluez_") === 0 : false
    // The port ("Headphones", "HDMI / DisplayPort") says more than the
    // card's long name. A Bluetooth output is named after its owner's
    // device, so it's generic when personal info is hidden.
    readonly property string port: sink && sink.ports && sink.ports[sink.activePortIndex]
        ? String(sink.ports[sink.activePortIndex].description || "") : ""
    readonly property string name: !sink ? ""
        : bluetooth && masked ? i18n("Bluetooth audio")
        : port || String(sink.description || "")

    function setPercent(p) {
        if (sink) sink.volume = Math.round(Math.max(0, Math.min(100, p)) / 100 * PulseAudio.NormalVolume);
    }
    function toggleMute() { if (sink) sink.muted = !sink.muted; }

    Instantiator {
        model: SinkModel { }
        delegate: QtObject {
            required property var model
            readonly property bool isDefault: model.Default
            onIsDefaultChanged: if (isDefault) out.sink = model.PulseObject
            Component.onCompleted: if (isDefault) out.sink = model.PulseObject
            Component.onDestruction: if (out.sink === model.PulseObject) out.sink = null
        }
    }
}
