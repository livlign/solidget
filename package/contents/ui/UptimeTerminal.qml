import QtQuick

// Uptime scene for nerds: a little terminal window. Title bar with the three
// buttons, then `uptime -p` and `uptime -s` (when it started) at an
// oh-my-zsh style prompt, and a blinking block cursor. Everything is our
// own text, shown as plain text.
Item {
    id: term
    property int tick: 0
    property string pretty: ""       // "up 3 days, 2 hours, 5 minutes"
    property string since: ""        // "2026-10-12 19:21:04", or "" to leave it out
    property string title: "uptime"
    property color color: "#4ade80"  // the prompt arrow and cursor
    property color text: "#e5e7eb"
    property string fontFamily: "monospace"
    property real radius: 8

    readonly property var lines: {
        var l = [{ p: true, t: "uptime -p" }, { p: false, t: pretty }];
        if (since !== "") l.push({ p: true, t: "uptime -s" }, { p: false, t: since });
        l.push({ p: true, t: "", cursor: true });
        return l;
    }
    readonly property string arrow: "➜  "
    readonly property string dir: "~ "
    // As big as fits: the longest line across, all the lines down.
    readonly property int longest: {
        var n = 0;
        lines.forEach(function (l) { n = Math.max(n, (l.p ? arrow.length + dir.length : 0) + l.t.length + (l.cursor ? 1 : 0)); });
        return n;
    }
    readonly property real barH: Math.max(14, Math.min(height * 0.14, 26))
    readonly property real pad: Math.max(6, barH * 0.6)
    readonly property real fs: Math.max(8, Math.min((height - barH - pad * 2) / (lines.length * 1.8),
                                                    (width - pad * 2) / Math.max(12, longest * 0.62)))

    // The window
    Rectangle {
        anchors.fill: parent
        radius: term.radius
        color: "#0c0f16"
        opacity: 0.94
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.09)
    }
    // Title bar
    Rectangle {
        width: parent.width; height: term.barH
        radius: term.radius
        color: "#1a1f2b"
        Rectangle {     // square off the bottom corners of the bar
            anchors.bottom: parent.bottom
            width: parent.width; height: Math.min(parent.height, term.radius)
            color: parent.color
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: term.barH * 0.5
            spacing: term.barH * 0.32
            Repeater {
                model: ["#ff5f57", "#febc2e", "#28c840"]
                Rectangle {
                    required property string modelData
                    width: term.barH * 0.42; height: width; radius: width / 2
                    color: modelData
                }
            }
        }
        Text {
            anchors.centerIn: parent
            // Only when it clears the three buttons.
            visible: implicitWidth < parent.width - term.barH * 4.2
            textFormat: Text.PlainText
            text: term.title
            color: term.text
            opacity: 0.5
            font.family: term.fontFamily
            font.pixelSize: term.barH * 0.5
        }
    }

    // The session
    Column {
        x: term.pad
        y: term.barH + term.pad
        width: parent.width - term.pad * 2
        spacing: term.fs * 0.45
        Repeater {
            model: term.lines
            Row {
                required property var modelData
                Text {
                    visible: modelData.p
                    textFormat: Text.PlainText
                    text: term.arrow
                    color: term.color
                    font.family: term.fontFamily
                    font.pixelSize: term.fs
                    font.bold: true
                }
                Text {
                    visible: modelData.p
                    textFormat: Text.PlainText
                    text: term.dir
                    color: "#67e8f9"
                    font.family: term.fontFamily
                    font.pixelSize: term.fs
                    font.bold: true
                }
                Text {
                    textFormat: Text.PlainText
                    text: modelData.t
                    color: modelData.p ? term.text : Qt.rgba(term.text.r, term.text.g, term.text.b, 0.62)
                    font.family: term.fontFamily
                    font.pixelSize: term.fs
                }
                Rectangle {     // block cursor, blinking with the seconds
                    visible: !!modelData.cursor
                    width: term.fs * 0.62; height: term.fs * 1.2
                    color: term.color
                    opacity: term.tick % 2 === 0 ? 0.9 : 0
                }
            }
        }
    }
}
