import QtQuick
import QtQuick.Effects
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
    readonly property bool twelveHour: app.twelveHour
    readonly property string hhmm: app.hoursMinutes(now)
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

    // Bento: the weather sits in its own colored card inside the ink clock.
    readonly property bool weatherInset: spot === "ink" && side
    // Text on that card: near-black on a bright color, white otherwise
    // (by how bright the color looks, not its lightness: purple is dark).
    readonly property color insetText: 0.2126 * accent.r + 0.7152 * accent.g + 0.0722 * accent.b > 0.55 ? "#1d1a17" : "#ffffff"
    // Instrument: the seconds, small, in the tile's color.
    readonly property bool showSeconds: monoFigures && !nativeOn
    // Glass: gradient digits.
    readonly property bool gradientDigits: glowOn && headerStyle === "caps" && !numberFamily && !nativeOn

    Item {
        id: area
        anchors.fill: parent
        clip: true
        // Clear: no card under the clock, so a soft shadow keeps it readable
        // on any wallpaper.
        layer.enabled: tile.cardless
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: tile.dark ? "#000000" : "#ffffff"
            shadowBlur: 0.6
            shadowOpacity: 0.55
            shadowVerticalOffset: 0
            shadowHorizontalOffset: 0
        }

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
                // Glass: the digits are a soft gradient, drawn by masking a
                // gradient with the text.
                Item {
                    id: timeWrap
                    implicitWidth: time.implicitWidth
                    implicitHeight: time.implicitHeight
                    baselineOffset: time.baselineOffset
                    PlasmaComponents.Label {
                        id: time
                        // Pixel: a hard drop shadow under the digits.
                        PlasmaComponents.Label {
                            visible: tile.hardShadowOn
                            z: -1
                            x: Math.round(time.px * 0.06); y: x
                            text: time.text
                            textFormat: Text.PlainText
                            font: time.font
                            color: Qt.darker(tile.accent, 2.4)
                        }
                        textFormat: Text.PlainText
                        readonly property real px: Math.max(Kirigami.Units.gridUnit,
                            Math.min(timeBlock.height * 0.56, timeBlock.width / (tile.hhmm.length * 0.62 + (tile.ampm ? 1 : 0))))
                        text: tile.hhmm
                        font.family: tile.numberFamily || tile.figureFamily || Kirigami.Theme.defaultFont.family
                        font.pixelSize: px
                        font.weight: tile.numberFamily || tile.nativeOn ? Font.Normal
                                   : tile.figureWeight > Font.Normal ? tile.figureWeight : Math.min(tile.figureWeight, Font.ExtraLight)
                        // Fixed-width digits give the colon a whole digit's room: pull them in.
                        font.letterSpacing: tile.nativeOn ? 0 : -px * (tile.monoFigures ? 0.1 : 0.04)
                        font.features: { "tnum": 1 }
                    }
                    ShaderEffectSource {
                        id: timeMask
                        anchors.fill: time
                        sourceItem: time
                        hideSource: tile.gradientDigits
                        visible: false
                    }
                    Rectangle {
                        anchors.fill: time
                        visible: tile.gradientDigits
                        gradient: Gradient {
                            GradientStop { position: 0.25; color: Kirigami.Theme.textColor }
                            GradientStop { position: 1; color: Qt.tint(Kirigami.Theme.textColor, Qt.rgba(tile.accent.r, tile.accent.g, tile.accent.b, 0.6)) }
                        }
                        layer.enabled: visible
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: timeMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1
                        }
                    }
                }
                PlasmaComponents.Label {
                    textFormat: Text.PlainText
                    anchors.baseline: timeWrap.baseline
                    visible: tile.showSeconds
                    text: Qt.formatTime(tile.now, "ss")
                    color: app.accent("cpu")      // the theme's lead color
                    font.family: time.font.family
                    font.weight: time.font.weight
                    font.pixelSize: time.px * 0.36
                    font.features: { "tnum": 1 }
                }
                PlasmaComponents.Label {
                    textFormat: Text.PlainText
                    anchors.baseline: timeWrap.baseline
                    text: tile.ampm
                    visible: text !== ""
                    opacity: 0.6
                    font.pixelSize: time.px * 0.22
                }
            }
            PlasmaComponents.Label {
                textFormat: Text.PlainText
                text: Qt.formatDate(tile.now, "dddd, d MMMM yyyy")
                opacity: 0.75
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, time.px * 0.16)
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Item { Layout.fillHeight: true }
        }

        // ---- Current weather: beside the clock -----------------------------
        // Bento: its own card, stacked: icon, big temperature, then the words
        // with room for two lines.
        Rectangle {
            visible: tile.weatherInset
            anchors.right: parent.right
            y: 0
            height: tile.topH
            width: tile.weatherW
            radius: tile.radius * 0.75
            color: tile.accent
            Kirigami.Theme.inherit: false
            Kirigami.Theme.textColor: tile.insetText

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: tile.u * 0.8
                spacing: 0
                Kirigami.Icon {
                    source: tile.w.icon
                    Layout.preferredWidth: Math.min(tile.u * 2.6, parent.height * 0.32)
                    Layout.preferredHeight: Layout.preferredWidth
                }
                Item { Layout.fillHeight: true }
                BigNumber {
                    family: tile.numberFamily
                    figures: tile.figureFamily
                    weight: tile.figureWeight
                    plain: tile.nativeOn
                    color: Kirigami.Theme.textColor
                    text: tile.temp(tile.w.temp)
                    unit: tile.w.fahrenheit ? "F" : "C"
                    size: Math.min(tile.u * 3.4, parent.height * 0.36, parent.width * 0.4)
                }
                PlasmaComponents.Label {
                    textFormat: Text.PlainText
                    text: tile.w.summary
                    font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.8)
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                PlasmaComponents.Label {
                    textFormat: Text.PlainText
                    visible: tile.topH > tile.u * 9
                    text: i18n("Feels %1 · %2%", tile.temp(tile.w.feelsLike), tile.w.humidity)
                    opacity: 0.75
                    font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.7)
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }
        RowLayout {
            visible: tile.side && !tile.weatherInset
            anchors.right: parent.right
            anchors.rightMargin: tile.weatherInset ? tile.u * 0.8 : 0
            y: 0
            height: tile.topH
            width: tile.weatherW - (tile.weatherInset ? tile.u * 1.6 : 0)
            spacing: tile.u * 0.6
            // On the colored inset card, text in near-black or white.
            Kirigami.Theme.inherit: !tile.weatherInset
            Kirigami.Theme.textColor: tile.insetText

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
                figures: tile.figureFamily
                weight: tile.figureWeight
                plain: tile.nativeOn
                    text: tile.temp(tile.w.temp)
                    unit: tile.w.fahrenheit ? "F" : "C"
                    size: tile.weatherTempSize
                }
                PlasmaComponents.Label {
                    textFormat: Text.PlainText
                    text: tile.w.summary
                    font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, Math.min(tile.u * 0.9, tile.weatherTempSize * 0.32))
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                PlasmaComponents.Label {
                    textFormat: Text.PlainText
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
                textFormat: Text.PlainText
                text: tile.temp(tile.w.temp)
                font.pixelSize: nowLine.height * 0.7
                font.weight: tile.nativeOn ? Font.Normal : Font.Light
            }
            PlasmaComponents.Label {
                textFormat: Text.PlainText
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
                            textFormat: Text.PlainText
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
