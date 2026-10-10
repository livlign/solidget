import QtQuick
import "../code/format.js" as Fmt
import "../code/palette.js" as Palette

GaugeTile {
    required property var app

    title: i18n("Memory")
    subtitle: app.memTotal.value > 0 ? Fmt.bytes(app.memTotal.value, 0) : ""
    accent: Palette.accent("memory")
    accent2: Palette.accent2("memory")
    value: app.memTotal.value > 0 ? app.memUsed.value / app.memTotal.value * 100 : 0
    details: [
        { label: i18n("In use"), value: Fmt.bytes(app.memUsed.value) },
        { label: i18n("Available"), value: Fmt.bytes(app.memTotal.value - app.memUsed.value) },
        { label: i18n("Cached"), value: Fmt.bytes(app.memCache.value) }
    ]
}
