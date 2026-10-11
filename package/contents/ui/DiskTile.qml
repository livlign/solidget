import QtQuick
import "../code/format.js" as Fmt
import "../code/palette.js" as Palette

GaugeTile {
    required property var app

    title: i18n("Storage")
    subtitle: app.diskTotal.value > 0 ? app.bytesText(app.diskTotal.value, 0) : ""
    accent: Palette.accent("disk")
    accent2: Palette.accent2("disk")
    value: app.diskTotal.value > 0 ? app.diskUsed.value / app.diskTotal.value * 100 : 0
    details: [
        { label: i18n("Free"), value: app.bytesText(app.diskTotal.value - app.diskUsed.value) },
        { label: i18n("Read"), value: app.rateText(app.diskRead.value) },
        { label: i18n("Write"), value: app.rateText(app.diskWrite.value) }
    ]
}
