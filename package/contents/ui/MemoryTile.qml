import QtQuick
import "../code/format.js" as Fmt
import "../code/palette.js" as Palette

GaugeTile {
    required property var app

    title: i18n("Memory")
    subtitle: app.memTotal.value > 0 ? app.bytesText(app.memTotal.value, 0) : ""
    accent: app.accent("memory")
    accent2: app.accent2("memory")
    value: app.memTotal.value > 0 ? app.memUsed.value / app.memTotal.value * 100 : 0
    details: [
        { label: i18n("In use"), value: app.bytesText(app.memUsed.value) },
        { label: i18n("Available"), value: app.bytesText(app.memTotal.value - app.memUsed.value) },
        { label: i18n("Cached"), value: app.bytesText(app.memCache.value) }
    ]
}
