import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Times around the world. Offsets come from main.qml (DST-aware, hourly).
GlassTile {
    id: tile
    required property var app

    property date now: new Date()
    Connections { target: app; function onTickChanged() { if (app.tick % 10 === 0) tile.now = new Date(); } }
    readonly property bool twelveHour: Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().indexOf("ap") >= 0
    readonly property int localOffset: -now.getTimezoneOffset()

    title: i18n("World clocks")
    accent: app.accent("worldclock")
    accent2: app.accent2("worldclock")
    level: 0.3

    function timeIn(zone) {
        var off = app.tzOffsets[zone];
        if (off === undefined) return null;
        return new Date(now.getTime() + (off - localOffset) * 60000);
    }

    PlasmaComponents.Label {
        anchors.centerIn: parent
        visible: app.worldClocks.length === 0
        text: i18n("Add cities in Settings → General")
        opacity: 0.6
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Repeater {
            model: app.worldClocks
            RowLayout {
                id: cityRow
                required property var modelData
                readonly property date t: tile.timeIn(modelData.zone) || tile.now
                readonly property bool known: app.tzOffsets[modelData.zone] !== undefined
                readonly property bool day: t.getHours() >= 6 && t.getHours() < 18
                readonly property int diffH: known ? Math.round((app.tzOffsets[modelData.zone] - tile.localOffset) / 60) : 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: tile.u * 0.5

                Kirigami.Icon {
                    source: cityRow.day ? "weather-clear" : "weather-clear-night"
                    Layout.preferredWidth: Math.min(tile.u * 1.6, Kirigami.Units.iconSizes.medium)
                    Layout.preferredHeight: Layout.preferredWidth
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    PlasmaComponents.Label {
                        text: cityRow.modelData.name
                        font.pixelSize: Math.max(Kirigami.Theme.defaultFont.pixelSize * 0.9, tile.u * 0.9)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    PlasmaComponents.Label {
                        text: !cityRow.known ? "" : cityRow.diffH === 0 ? i18n("Same time") : (cityRow.diffH > 0 ? "+" : "") + i18n("%1 h", cityRow.diffH)
                        opacity: 0.55
                        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.7)
                    }
                }
                BigNumber {
                    family: tile.numberFamily
                    text: cityRow.known ? Qt.formatTime(cityRow.t, tile.twelveHour ? "h:mm" : "HH:mm") : "–"
                    unit: cityRow.known && tile.twelveHour ? Qt.formatTime(cityRow.t, "AP") : ""
                    size: Math.min(tile.u * 2, tile.height / Math.max(3, app.worldClocks.length * 1.8))
                }
            }
        }
    }
}
