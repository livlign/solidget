import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Month view with today marked, plus sunrise/sunset and the moon phase.
GlassTile {
    id: tile
    required property var app

    property date today: new Date()
    // Swap the date only when the day changes, so the grid isn't rebuilt every minute.
    Connections { target: app; function onTickChanged() { var d = new Date(); if (d.getDate() !== tile.today.getDate()) tile.today = d; } }

    readonly property int firstDow: Qt.locale().firstDayOfWeek          // 0 = Sunday
    readonly property var cells: {
        var y = today.getFullYear(), m = today.getMonth();
        var first = new Date(y, m, 1);
        var lead = (first.getDay() - firstDow + 7) % 7;
        var days = new Date(y, m + 1, 0).getDate();
        var out = [];
        for (var i = 0; i < lead; i++) out.push(0);
        for (var d = 1; d <= days; d++) out.push(d);
        while (out.length % 7) out.push(0);
        return out;
    }
    // Moon phase from the synodic month (no network needed).
    readonly property real moonAge: {
        var jd = today.getTime() / 86400000 + 2440587.5;
        var p = ((jd - 2451550.1) / 29.530588853) % 1;
        return p < 0 ? p + 1 : p;
    }
    readonly property var moon: {
        var names = [i18n("New moon"), i18n("Waxing crescent"), i18n("First quarter"), i18n("Waxing gibbous"),
                     i18n("Full moon"), i18n("Waning gibbous"), i18n("Last quarter"), i18n("Waning crescent")];
        var glyphs = ["🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"];
        var i = Math.round(moonAge * 8) % 8;
        return { name: names[i], glyph: glyphs[i] };
    }
    readonly property var todayWeather: app.weather.daily.length ? app.weather.daily[0] : null
    function hm(iso) { return iso ? Qt.formatTime(new Date(iso), Qt.locale().timeFormat(Locale.ShortFormat)) : "–"; }

    title: Qt.locale().standaloneMonthName(today.getMonth()) + " " + today.getFullYear()
    accent: app.accent("calendar")
    accent2: app.accent2("calendar")
    level: 0.3

    ColumnLayout {
        anchors.fill: parent
        spacing: tile.u * 0.3

        // Fixed math instead of GridLayout: every column is exactly 1/7 of
        // the width, whatever the labels' natural sizes.
        Item {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            readonly property int rows: tile.cells.length / 7 + 1     // + weekday header
            readonly property real cw: width / 7
            readonly property real ch: height / rows

            Repeater {
                model: 7
                PlasmaComponents.Label {
                    textFormat: Text.PlainText
                    required property int index
                    x: index * grid.cw; y: 0
                    width: grid.cw; height: grid.ch
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: Qt.locale().dayName((tile.firstDow + index) % 7, Locale.NarrowFormat)
                    opacity: 0.5
                    font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, Math.min(tile.u * 0.7, grid.ch * 0.45))
                    font.weight: Font.DemiBold
                }
            }
            Repeater {
                model: tile.cells
                Item {
                    required property int modelData
                    required property int index
                    readonly property bool isToday: modelData === tile.today.getDate()
                    x: (index % 7) * grid.cw
                    y: (Math.floor(index / 7) + 1) * grid.ch
                    width: grid.cw; height: grid.ch
                    Rectangle {
                        anchors.centerIn: parent
                        visible: parent.isToday
                        width: Math.min(parent.width, parent.height) * 0.9
                        height: width
                        radius: tile.radius > 0 ? width / 2 : 0
                        color: tile.accent
                    }
                    PlasmaComponents.Label {
                        textFormat: Text.PlainText
                        anchors.centerIn: parent
                        visible: parent.modelData > 0
                        text: parent.modelData
                        color: parent.isToday ? (tile.accent.hslLightness > 0.6 ? "#111111" : "#ffffff") : Kirigami.Theme.textColor
                        font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
                        font.weight: parent.isToday ? Font.Bold : Font.Normal
                        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, Math.min(tile.u * 0.95, parent.height * 0.5, parent.width * 0.42))
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: tile.height > tile.u * 10
            spacing: tile.u * 0.8
            PlasmaComponents.Label {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                elide: Text.ElideRight
                visible: !!tile.todayWeather
                text: "↑ " + tile.hm(tile.todayWeather ? tile.todayWeather.sunrise : "") + "   ↓ " + tile.hm(tile.todayWeather ? tile.todayWeather.sunset : "")
                opacity: 0.75
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.75)
            }
            PlasmaComponents.Label {
                textFormat: Text.PlainText
                Layout.maximumWidth: tile.width * 0.45
                // Name only when there's room; the symbol alone otherwise.
                text: tile.moon.glyph + (tile.width > tile.u * 20 ? " " + tile.moon.name : "")
                opacity: 0.75
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.75)
                elide: Text.ElideRight
            }
        }
    }
}
