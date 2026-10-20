import QtQuick
import "../code/health.js" as Health

// One score out of 100 for how the PC is doing, with the reasons:
// drive self-checks, free space, heat, memory, failed services, updates.
GaugeTile {
    id: tile
    required property var app

    readonly property var checks: Health.checks({
        cpuTemp: app.cpuTempValue,
        gpuTemp: app.gpuTemp.value,
        ssdTemp: app.nvmeTemp.value,
        memPct: app.memTotal.value > 0 ? app.memUsed.value / app.memTotal.value * 100 : 0,
        swapPct: app.swapTotal.value > 0 ? app.swapUsed.value / app.swapTotal.value * 100 : 0,
        helper: app.healthState
    })
    // As a string first: QML only signals a string when it really changes, so
    // the rows aren't rebuilt every time a sensor ticks.
    readonly property string key: JSON.stringify(checks)
    readonly property var list: JSON.parse(key)
    readonly property int score: Health.score(list)
    readonly property string grade: Health.grade(score)

    title: i18n("Health")
    subtitle: ({ great: i18n("Great"), good: i18n("Good"), care: i18n("Needs care"), trouble: i18n("Trouble") })[grade]
    accent: grade === "trouble" ? "#f43f5e" : grade === "care" ? "#f59e0b" : app.accent("health")
    accent2: grade === "trouble" ? "#f97316" : grade === "care" ? "#f97316" : app.accent2("health")
    value: score
    valueText: String(score)
    unit: ""
    // The glow means trouble here, not load.
    level: 1 - score / 100

    readonly property color okDot: Qt.rgba(accent.r, accent.g, accent.b, 0.55)
    function line(c) {
        switch (c.id) {
        case "driveFailing":    return { label: c.name, value: i18n("Failing") };
        case "driveWorn":       return { label: c.name, value: i18n("%1% worn", c.n) };
        case "drivesOk":        return { label: i18np("Drive", "Drives", c.n), value: i18n("Healthy") };
        case "lowSpace":        return { label: i18n("Space on %1", c.name), value: i18n("%1% free", c.n) };
        case "spaceOk":         return { label: i18n("Free space"), value: i18n("Plenty") };
        case "cpuHot":          return { label: i18n("CPU"), value: app.tempText(c.n) };
        case "gpuHot":          return { label: i18n("GPU"), value: app.tempText(c.n) };
        case "ssdHot":          return { label: i18n("SSD"), value: app.tempText(c.n) };
        case "coolOk":          return { label: i18n("Temperatures"), value: i18n("Cool") };
        case "memoryFull":      return { label: i18n("Memory"), value: i18n("%1% used", c.n) };
        case "swapFull":        return { label: i18n("Swap"), value: i18n("%1% used", c.n) };
        case "memoryOk":        return { label: i18n("Memory"), value: i18n("OK") };
        case "failedServices":  return { label: i18np("Failed service", "Failed services", c.n), value: c.n === 1 ? c.name : String(c.n) };
        case "servicesOk":      return { label: i18n("Services"), value: i18n("All running") };
        case "securityUpdates": return { label: i18n("Security updates"), value: String(c.n) };
        case "updates":         return { label: i18n("Updates"), value: String(c.n) };
        case "updatesOk":       return { label: i18n("Updates"), value: c.n ? String(c.n) : i18n("Up to date") };
        case "restart":         return { label: i18n("Restart"), value: i18n("Needed") };
        }
        return { label: c.id, value: "" };
    }
    details: list.map(function (c) {
        var l = line(c);
        l.dot = c.ok ? tile.okDot : c.cost >= 10 ? "#f43f5e" : "#f59e0b";
        return l;
    })
}
