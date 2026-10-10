import QtQuick
import "../code/format.js" as Fmt
import "../code/palette.js" as Palette

GaugeTile {
    required property var app

    readonly property var gpu: app.specs.gpus && app.specs.gpus.length ? app.specs.gpus[0] : null

    title: i18n("GPU")
    subtitle: gpu ? gpu.name : ""
    accent: Palette.accent("gpu")
    accent2: Palette.accent2("gpu")
    value: app.gpuUsage.value || 0
    history: app.gpuHistory.values
    details: [
        { label: i18n("VRAM"), value: Fmt.bytes(app.gpuVramUsed.value) + " / " + Fmt.bytes(app.gpuVramTotal.value, 0) },
        { label: i18n("Temperature"), value: Fmt.temp(app.gpuTemp.value), dot: Palette.heat(Palette.tempLevel(app.gpuTemp.value)) },
        { label: i18n("Power"), value: app.gpuWatts > 0 ? Math.round(app.gpuWatts) + " W" : "–" }
    ]
}
