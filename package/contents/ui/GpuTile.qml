import QtQuick
import "../code/format.js" as Fmt
import "../code/palette.js" as Palette

GaugeTile {
    required property var app

    readonly property var gpu: app.specs.gpus && app.specs.gpus.length ? app.specs.gpus[0] : null

    title: i18n("GPU")
    subtitle: gpu ? gpu.name : ""
    accent: app.accent("gpu")
    accent2: app.accent2("gpu")
    value: app.gpuUsage.value || 0
    history: app.gpuHistory.values
    details: [
        // Built-in graphics (most Intel, some AMD) share the system memory.
        app.gpuVramTotal.value > 0
            ? { label: i18n("VRAM"), value: app.bytesText(app.gpuVramUsed.value) + " / " + app.bytesText(app.gpuVramTotal.value, 0) }
            : { label: i18n("Memory"), value: i18n("Shared") },
        { label: i18n("Temperature"), value: app.tempText(app.gpuTemp.value), dot: app.tempColor(app.gpuTemp.value) },
        { label: i18n("Power"), value: app.gpuWatts > 0 ? Math.round(app.gpuWatts) + " W" : "–" }
    ]
}
