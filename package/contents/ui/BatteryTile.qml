import QtQuick
import "../code/palette.js" as Palette

GaugeTile {
    required property var app

    readonly property var bat: app.batteryState

    title: i18n("Battery")
    subtitle: bat.status || ""
    accent: (bat.percent || 0) <= 15 ? "#f43f5e" : Palette.accent("battery")
    accent2: (bat.percent || 0) <= 15 ? "#f97316" : Palette.accent2("battery")
    value: bat.percent || 0
    details: [
        { label: i18n("Status"), value: bat.status || "–" }
    ]
}
