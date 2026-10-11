import QtQuick
import "../code/format.js" as Fmt
import "../code/palette.js" as Palette

GaugeTile {
    required property var app

    title: i18n("Storage")
    subtitle: app.diskTotal.value > 0 ? app.bytesText(app.diskTotal.value, 0) : ""
    accent: app.accent("disk")
    accent2: app.accent2("disk")
    value: app.diskTotal.value > 0 ? app.diskUsed.value / app.diskTotal.value * 100 : 0
    // Read and write over the last minute, like Network; the dots match the lines.
    details: [
        { label: i18n("Read"), value: app.rateText(app.diskRead.value), dot: accent },
        { label: i18n("Write"), value: app.rateText(app.diskWrite.value), dot: accent2 },
        { label: i18n("Free"), value: app.bytesText(app.diskTotal.value - app.diskUsed.value) }
    ]
    history: app.readHistory.values
    history2: app.writeHistory.values
    historyMax: 0
    historyMinMax: 256 * 1024
    historySqrt: true
    preferChart: true
}
