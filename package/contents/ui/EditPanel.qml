import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import "../code/layout.js" as Bento

// Side sheet over the live dashboard. Every change applies and saves
// immediately, so the board behind it is the preview.
GlassTile {
    id: panel
    required property var app

    title: i18n("Settings")
    accent: "#818cf8"
    accent2: "#c084fc"
    level: 0.35
    bodyOpacity: 0.95

    component SectionLabel: PlasmaComponents.Label {
        Layout.topMargin: Kirigami.Units.largeSpacing
        opacity: 0.7
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.8
    }

    component Choice: RowLayout {
        id: choice
        property string label
        property var options: []      // [{ value, text }]
        property var current
        signal picked(var value)
        Layout.fillWidth: true
        PlasmaComponents.Label { text: choice.label; Layout.fillWidth: true; elide: Text.ElideRight }
        Repeater {
            model: choice.options
            PlasmaComponents.Button {
                required property var modelData
                text: modelData.text
                checkable: true
                checked: choice.current === modelData.value
                onClicked: choice.picked(modelData.value)
            }
        }
    }

    PlasmaComponents.ToolButton {
        anchors.right: parent.right
        anchors.bottom: parent.top
        anchors.bottomMargin: -Kirigami.Units.smallSpacing
        icon.name: "dialog-ok-apply"
        text: i18n("Done")
        display: QQC2.AbstractButton.TextBesideIcon
        onClicked: panel.app.showSettings = false
    }

    PlasmaComponents.ScrollView {
        id: scroller
        anchors.fill: parent
        contentWidth: availableWidth
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        ColumnLayout {
            width: scroller.availableWidth
            spacing: Kirigami.Units.smallSpacing

            // ---- Edit layout ----
            PlasmaComponents.Button {
                Layout.fillWidth: true
                visible: !panel.app.editing
                icon.name: "transform-move"
                text: i18n("Edit layout")
                onClicked: { panel.app.showSettings = false; panel.app.editing = true; }
                QQC2.ToolTip.text: i18n("Drag tiles to move them, drag a corner to resize")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            // ---- Placement ----
            SectionLabel { text: i18n("Place on this screen") }
            PlasmaComponents.Label {
                visible: !panel.app.canPlace()
                text: i18n("Placement works when Solidget is on the desktop.")
                opacity: 0.6
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            GridLayout {
                visible: panel.app.canPlace()
                Layout.fillWidth: true
                columns: 4
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: panel.app.placements
                    QQC2.AbstractButton {
                        id: placeButton
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: width * 0.62
                        hoverEnabled: true
                        onClicked: panel.app.place(modelData.r)
                        QQC2.ToolTip.text: modelData.name
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                        background: Rectangle {
                            radius: Kirigami.Units.cornerRadius
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, placeButton.hovered ? 0.14 : 0.06)
                            border.width: 1
                            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

                            Rectangle {
                                readonly property real m: 3
                                x: m + placeButton.modelData.r[0] * (parent.width - 2 * m)
                                y: m + placeButton.modelData.r[1] * (parent.height - 2 * m)
                                width: placeButton.modelData.r[2] * (parent.width - 2 * m)
                                height: placeButton.modelData.r[3] * (parent.height - 2 * m)
                                radius: 2
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: panel.accent }
                                    GradientStop { position: 1; color: panel.accent2 }
                                }
                                opacity: placeButton.hovered ? 1 : 0.75
                            }
                        }
                    }
                }
            }

            // ---- Density ----
            SectionLabel { text: i18n("Tile size") }
            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Repeater {
                    model: [
                        { id: "auto", name: i18n("Auto") },
                        { id: "compact", name: i18n("Compact") },
                        { id: "comfortable", name: i18n("Comfortable") },
                        { id: "large", name: i18n("Large") },
                        { id: "huge", name: i18n("Huge") }
                    ]
                    PlasmaComponents.Button {
                        required property var modelData
                        text: modelData.name
                        checkable: true
                        checked: panel.app.density === modelData.id
                        onClicked: panel.app.setDensity(modelData.id)
                    }
                }
            }

            // ---- Weather ----
            SectionLabel { text: i18n("Weather on the clock") }
            RowLayout {
                Layout.fillWidth: true
                PlasmaComponents.Switch {
                    id: weatherSwitch
                    checked: Plasmoid.configuration.weatherEnabled
                    onToggled: Plasmoid.configuration.weatherEnabled = checked
                }
                PlasmaComponents.TextField {
                    id: cityField
                    Layout.fillWidth: true
                    enabled: weatherSwitch.checked
                    placeholderText: panel.app.shownPlace
                        ? i18n("Automatic (%1)", panel.app.shownPlace) : i18n("Automatic location")
                    text: Plasmoid.configuration.weatherCity
                    onEditingFinished: Plasmoid.configuration.weatherCity = text.trim()
                }
            }
            PlasmaComponents.Label {
                visible: weatherSwitch.checked && (panel.app.weather.error !== "" || cityField.text === "")
                text: panel.app.weather.error !== "" ? panel.app.weather.error
                    : i18n("Location is guessed from your internet connection; type a city if it's off.")
                opacity: 0.6
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            // ---- Units ----
            SectionLabel { text: i18n("Units") }
            Choice {
                label: i18n("Temperature")
                options: [{ value: false, text: "°C" }, { value: true, text: "°F" }]
                current: panel.app.useFahrenheit
                onPicked: (v) => Plasmoid.configuration.weatherUnit = v ? "f" : "c"
            }
            Choice {
                label: i18n("Sizes")
                options: [{ value: false, text: "GiB" }, { value: true, text: "GB" }]
                current: panel.app.decimalUnits
                onPicked: (v) => Plasmoid.configuration.dataUnits = v ? "decimal" : "binary"
            }
            Choice {
                label: i18n("Network speed")
                options: [{ value: false, text: "MB/s" }, { value: true, text: "Mbps" }]
                current: panel.app.networkBits
                onPicked: (v) => Plasmoid.configuration.networkBits = v
            }

            // ---- Privacy ----
            SectionLabel { text: i18n("Privacy") }
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    PlasmaComponents.Label { text: i18n("Hide personal info"); Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        text: i18n("Computer name, network name, IP address and weather location. Keep on to share screenshots safely.")
                        opacity: 0.6
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
                PlasmaComponents.Switch {
                    checked: Plasmoid.configuration.maskSensitive
                    onToggled: Plasmoid.configuration.maskSensitive = checked
                }
            }

            // ---- Presets ----
            SectionLabel { text: i18n("Start from a preset") }
            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Repeater {
                    model: panel.app.presetIds
                    PlasmaComponents.Button {
                        required property string modelData
                        text: panel.app.presets[modelData].name
                        checkable: true
                        checked: panel.app.currentPreset === modelData && !panel.app.customized
                        onClicked: panel.app.applyPreset(modelData)
                        QQC2.ToolTip.text: panel.app.presets[modelData].hint
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                }
            }

            // ---- Tiles ----
            SectionLabel { text: i18n("Tiles") }
            Repeater {
                model: panel.app.order

                Rectangle {
                    id: row
                    required property string modelData
                    required property int index
                    readonly property bool available: panel.app.isAvailable(modelData)
                    readonly property bool shown: panel.app.hidden.indexOf(modelData) < 0
                    readonly property var spanChoices: Bento.SPANS[modelData] || [[1, 1]]

                    Layout.fillWidth: true
                    implicitHeight: rowLayout.implicitHeight + Kirigami.Units.smallSpacing * 2
                    radius: Kirigami.Units.cornerRadius
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, shown && available ? 0.07 : 0.025)

                    RowLayout {
                        id: rowLayout
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.largeSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            source: panel.app.tileInfo[row.modelData].icon
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            opacity: row.shown && row.available ? 1 : 0.4
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: panel.app.tileInfo[row.modelData].name
                                elide: Text.ElideRight
                                opacity: row.shown && row.available ? 1 : 0.5
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                visible: !row.available
                                text: i18n("Not detected on this PC")
                                opacity: 0.5
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                            }
                        }
                        PlasmaComponents.ComboBox {
                            id: sizeBox
                            // Auto, the tile's suggested sizes, and the current
                            // hand-made size if it isn't one of those.
                            // In a hand-edited layout, the size on screen.
                            readonly property var cur: panel.app.manualRects && panel.app.boardRef && panel.app.boardRef.rectsById[row.modelData]
                                ? { w: panel.app.boardRef.rectsById[row.modelData].w, h: panel.app.boardRef.rectsById[row.modelData].h }
                                : panel.app.spans[row.modelData]
                            readonly property int match: {
                                if (cur === undefined) return 0;
                                if (typeof cur === "number") return cur + 1;
                                for (var i = 0; i < row.spanChoices.length; i++)
                                    if (row.spanChoices[i][0] === cur.w && row.spanChoices[i][1] === cur.h) return i + 1;
                                return row.spanChoices.length + 1;
                            }
                            visible: row.shown && row.available
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 4.5
                            model: [i18n("Auto")]
                                .concat(row.spanChoices.map(function (s) { return s[0] + " × " + s[1]; }))
                                .concat(match > row.spanChoices.length ? [cur.w + " × " + cur.h] : [])
                            currentIndex: match
                            onActivated: (i) => {
                                if (i === 0) panel.app.setTileSpan(row.modelData, null);
                                else if (i <= row.spanChoices.length)
                                    panel.app.setTileSpan(row.modelData, { w: row.spanChoices[i - 1][0], h: row.spanChoices[i - 1][1] });
                            }
                            QQC2.ToolTip.text: i18n("Size in grid cells (columns × rows). Tip: drag a tile's corner in edit mode.")
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }
                        PlasmaComponents.ToolButton {
                            icon.name: "go-up"
                            visible: !panel.app.manualRects   // order only matters in the automatic layout
                            enabled: row.index > 0
                            onClicked: panel.app.moveTile(row.modelData, -1)
                            QQC2.ToolTip.text: i18n("Move up")
                            QQC2.ToolTip.visible: hovered
                        }
                        PlasmaComponents.ToolButton {
                            icon.name: "go-down"
                            visible: !panel.app.manualRects   // order only matters in the automatic layout
                            enabled: row.index < panel.app.order.length - 1
                            onClicked: panel.app.moveTile(row.modelData, 1)
                            QQC2.ToolTip.text: i18n("Move down")
                            QQC2.ToolTip.visible: hovered
                        }
                        PlasmaComponents.Switch {
                            checked: row.shown && row.available
                            enabled: row.available
                            onToggled: panel.app.setTileShown(row.modelData, checked)
                        }
                    }
                }
            }
        }
    }
}
