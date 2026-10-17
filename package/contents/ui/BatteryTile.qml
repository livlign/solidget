import QtQuick
import "../code/palette.js" as Palette
import "../code/format.js" as Fmt

GaugeTile {
    required property var app

    readonly property var bat: app.batteryState

    title: i18n("Battery")
    subtitle: bat.status || ""
    accent: (bat.percent || 0) <= 15 ? "#f43f5e" : app.accent("battery")
    accent2: (bat.percent || 0) <= 15 ? "#f97316" : app.accent2("battery")
    value: bat.percent || 0
    details: [
        { label: i18n("Status"), value: bat.status || "–" },
        { label: i18n("Charger"), value: bat.ac ? i18n("Plugged in") : i18n("Unplugged") },
        { label: bat.status === "Charging" ? i18n("Full in") : i18n("Time left"),
          value: bat.minutes > 0 ? Fmt.uptime(bat.minutes * 60) : "–" }
    ]
}
