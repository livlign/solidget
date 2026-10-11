import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../code/format.js" as Fmt
import "../code/palette.js" as Palette

// Big clock + date, with the weather beside it (wide tiles) or under it
// (narrow ones), and a short forecast when the tile is tall enough.
GlassTile {
    id: tile
    required property var app

    readonly property var w: app.weather
    readonly property bool hasWeather: w.enabled && w.ready
    // Sky-tinted glow on the default themes; other themes keep their own colors.
    readonly property bool skyMood: app.themeId === "plasma" || app.themeId === "aurora"
    readonly property var mood: hasWeather && skyMood ? w.mood(w.code, w.isDay) : [app.accent("clock"), app.accent2("clock")]

    property date now: new Date()
    readonly property bool twelveHour: Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().indexOf("ap") >= 0
    readonly property string hhmm: Qt.formatTime(now, twelveHour ? "h:mm" : "HH:mm")
    readonly property string ampm: twelveHour ? Qt.formatTime(now, "AP") : ""
    readonly property int hour: now.getHours()

    // Layout modes
    readonly property bool side: hasWeather && area.width >= area.height * 2.1
    // Weather block beside the clock: icon + a text column that must hold "26°C".
    readonly property real weatherW: area.width * 0.42 - u
    readonly property real weatherIcon: Math.min(topH * 0.75, weatherW * 0.3)
    readonly property real weatherTextW: weatherW - weatherIcon - u * 0.6
    readonly property real weatherTempSize: Math.max(Kirigami.Units.gridUnit, Math.min(topH * 0.42, u * 3.6, weatherTextW / 2.4))
    readonly property bool showForecast: hasWeather && w.daily.length > 1 && area.height > u * 9
    readonly property real forecastH: showForecast ? Math.min(area.height * 0.36, u * 5.5) : 0
    readonly property real topH: area.height - forecastH - (showForecast ? u * 0.6 : 0)

    title: hour < 5 ? i18n("Good night") : hour < 12 ? i18n("Good morning") : hour < 18 ? i18n("Good afternoon") : i18n("Good evening")
    subtitle: hasWeather && app.shownPlace ? app.shownPlace : (app.uptime.value ? i18n("Up %1", Fmt.uptime(app.uptime.value)) : "")
    accent: mood[0]
    accent2: mood[1]
    level: hasWeather ? 0.5 : 0.35
    Behavior on accent { ColorAnimation { duration: 1200 } }
    Behavior on accent2 { ColorAnimation { duration: 1200 } }

    // Updated on the shared tick (same frame as everything else).
    Connections { target: app; function onTickChanged() { tile.now = new Date(); } }

    function temp(v) { return isNaN(v) ? "–" : Math.round(v) + "°"; }

    Item {
        id: area
        anchors.fill: parent
        clip: true

        // ---- Time + date -------------------------------------------------
        ColumnLayout {
            id: timeBlock
            x: 0
            width: tile.side ? area.width * 0.58 : area.width
            height: tile.side ? tile.topH : tile.topH - (tile.hasWeather ? nowLine.height : 0)
            spacing: 0

            Item { Layout.fillHeight: true }
            Row {
                spacing: tile.u * 0.3
                PlasmaComponents.Label {
                    id: time
                    readonly property real px: Math.max(Kirigami.Units.gridUnit,
                        Math.min(timeBlock.height * 0.56, timeBlock.width / (tile.hhmm.length * 0.62 + (tile.ampm ? 1 : 0))))
                    text: tile.hhmm
                    font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
                    font.pixelSize: px
                    font.weight: tile.numberFamily ? Font.Normal : Font.ExtraLight
                    font.letterSpacing: -px * 0.04
                    font.features: { "tnum": 1 }
                }
                PlasmaComponents.Label {
                    anchors.baseline: time.baseline
                    text: tile.ampm
                    visible: text !== ""
                    opacity: 0.6
                    font.pixelSize: time.px * 0.22
                }
            }
            PlasmaComponents.Label {
                text: Qt.formatDate(tile.now, "dddd, d MMMM yyyy")
                opacity: 0.75
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, time.px * 0.16)
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Item { Layout.fillHeight: true }
        }

        // ---- Current weather: beside the clock -----------------------------
        RowLayout {
            visible: tile.side
            anchors.right: parent.right
            y: 0
            height: tile.topH
            width: tile.weatherW
            spacing: tile.u * 0.6

            Kirigami.Icon {
                source: tile.w.icon
                Layout.preferredWidth: tile.weatherIcon
                Layout.preferredHeight: Layout.preferredWidth
                Layout.alignment: Qt.AlignVCenter
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0
                BigNumber {
                family: tile.numberFamily
                    text: tile.temp(tile.w.temp)
                    unit: tile.w.fahrenheit ? "F" : "C"
                    size: tile.weatherTempSize
                }
                PlasmaComponents.Label {
                    text: tile.w.summary
                    font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, Math.min(tile.u * 0.9, tile.weatherTempSize * 0.32))
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                PlasmaComponents.Label {
                    visible: tile.topH > tile.u * 5.5
                    text: i18n("Feels %1 · %2%", tile.temp(tile.w.feelsLike), tile.w.humidity)
                    opacity: 0.6
                    font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, Math.min(tile.u * 0.72, tile.weatherTempSize * 0.27))
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        // ---- Current weather: under the clock ------------------------------
        RowLayout {
            id: nowLine
            visible: tile.hasWeather && !tile.side
            y: timeBlock.height
            width: area.width
            height: visible ? Math.max(Kirigami.Units.iconSizes.small, tile.u * 1.6) : 0
            spacing: tile.u * 0.4

            Kirigami.Icon {
                source: tile.w.icon
                Layout.preferredWidth: nowLine.height
                Layout.preferredHeight: nowLine.height
            }
            PlasmaComponents.Label {
                text: tile.temp(tile.w.temp)
                font.pixelSize: nowLine.height * 0.7
                font.weight: Font.Light
            }
            PlasmaComponents.Label {
                text: tile.w.summary
                opacity: 0.75
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, nowLine.height * 0.45)
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        // ---- Forecast ------------------------------------------------------
        RowLayout {
            visible: tile.showForecast
            anchors.bottom: parent.bottom
            width: area.width
            height: tile.forecastH
            spacing: tile.u * 0.5

            Repeater {
                // Today is already shown above; next days, as many as fit.
                model: tile.w.daily.slice(1, 1 + Math.max(1, Math.min(4, Math.floor(area.width / (tile.u * 5.5)))))

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Kirigami.Units.cornerRadius
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: tile.u * 0.1
                        PlasmaComponents.Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.locale().dayName(new Date(modelData.date + "T12:00").getDay(), Locale.ShortFormat)
                            opacity: 0.65
                            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.72)
                        }
                        Kirigami.Icon {
                            Layout.alignment: Qt.AlignHCenter
                            source: tile.w.iconFor(modelData.code, true)
                            Layout.preferredWidth: Math.min(tile.forecastH * 0.42, tile.u * 2.4)
                            Layout.preferredHeight: Layout.preferredWidth
                        }
                        PlasmaComponents.Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: tile.temp(modelData.max) + "  <font color='" + Kirigami.Theme.disabledTextColor + "'>" + tile.temp(modelData.min) + "</font>"
                            textFormat: Text.StyledText
                            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.8)
                            font.features: { "tnum": 1 }
                        }
                    }
                }
            }
        }
    }
}
