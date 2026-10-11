import QtQuick
import "../code/format.js" as Fmt
import "../code/palette.js" as Palette

GaugeTile {
    required property var app

    title: i18n("CPU")
    subtitle: app.specs.cpu ? app.specs.cpu.name : ""
    accent: Palette.accent("cpu")
    accent2: Palette.accent2("cpu")
    value: app.cpuUsage.value || 0
    history: app.cpuHistory.values
    details: [
        { label: i18n("Clock"), value: Fmt.ghz(app.cpuFreq.value) },
        { label: i18n("Temperature"), value: app.tempText(app.cpuTempValue), dot: Palette.heat(Palette.tempLevel(app.cpuTempValue)) },
        { label: i18n("Threads"), value: app.specs.cpu ? String(app.specs.cpu.threads) : "–" }
    ]
}
