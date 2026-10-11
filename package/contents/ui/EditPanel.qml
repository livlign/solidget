import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import "../code/palette.js" as Palette

// Settings sheet over the live dashboard, in tabs. It wears the chosen style
// and theme itself (own controls, since Plasma's buttons can't take theme
// colors). Every change applies and saves immediately; the board behind is
// the preview.
GlassTile {
    id: panel
    required property var app

    // ---- Theme for the panel's own controls ----
    readonly property color pText: app.boardText
    readonly property color pAccent: app.accent("cpu")
    readonly property color pOnAccent: pAccent.hslLightness > 0.6 ? "#111111" : "#ffffff"
    readonly property bool pSharp: app.look.radius === 0
    readonly property real pRadius: pSharp ? 0 : Kirigami.Units.cornerRadius * 1.5
    readonly property int pBorder: app.look.bevel ? 2 : 1
    readonly property string pFont: app.look.fontFamily
    function tint(a) { return Qt.rgba(pText.r, pText.g, pText.b, a); }

    property int tab: 0

    look: app.look
    title: i18n("Settings")
    accent: pAccent
    accent2: app.accent2("cpu")
    level: 0.35
    bodyOpacity: 0.97

    // Labels inside follow the theme's text color.
    Kirigami.Theme.inherit: false
    Kirigami.Theme.textColor: pText
    Kirigami.Theme.backgroundColor: app.look.body

    // ---- Controls ----------------------------------------------------------

    component Heading: PlasmaComponents.Label {
        Layout.topMargin: Kirigami.Units.largeSpacing
        color: panel.pText
        opacity: 0.7
        font.family: panel.pFont || Kirigami.Theme.defaultFont.family
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.8
    }

    component Hint: PlasmaComponents.Label {
        color: panel.pText
        opacity: 0.6
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    // Button; `checked` (set by binding) or `primary` fills it with the accent.
    component SButton: QQC2.AbstractButton {
        id: b
        property bool primary: false
        property string iconName: ""
        property string tip: ""
        readonly property bool filled: checked || primary
        hoverEnabled: true
        padding: Kirigami.Units.smallSpacing * 1.4
        leftPadding: Kirigami.Units.largeSpacing
        rightPadding: Kirigami.Units.largeSpacing
        opacity: enabled ? 1 : 0.4
        QQC2.ToolTip.text: tip
        QQC2.ToolTip.visible: tip !== "" && hovered
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        background: Rectangle {
            radius: panel.pRadius
            color: b.filled ? (b.hovered ? Qt.lighter(panel.pAccent, 1.12) : panel.pAccent)
                            : panel.tint(b.hovered ? 0.16 : 0.07)
            border.width: panel.pBorder
            border.color: b.filled ? Qt.darker(panel.pAccent, 1.35) : panel.tint(0.16)
        }
        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Icon {
                visible: b.iconName !== ""
                source: b.iconName
                color: b.filled ? panel.pOnAccent : panel.pText
                isMask: true
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            PlasmaComponents.Label {
                visible: b.text !== ""
                text: b.text
                color: b.filled ? panel.pOnAccent : panel.pText
                font.family: panel.pFont || Kirigami.Theme.defaultFont.family
                font.weight: b.filled ? Font.DemiBold : Font.Normal
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
    }

    component SToggle: QQC2.AbstractButton {
        id: tgl
        checkable: true
        hoverEnabled: true
        implicitWidth: Kirigami.Units.gridUnit * 2.4
        implicitHeight: Kirigami.Units.gridUnit * 1.3
        background: Rectangle {
            radius: panel.pSharp ? 0 : height / 2
            color: tgl.checked ? panel.pAccent : panel.tint(tgl.hovered ? 0.28 : 0.2)
            border.width: panel.pSharp ? panel.pBorder : 0
            border.color: panel.tint(0.25)
            Rectangle {
                width: parent.height - 6; height: width
                radius: panel.pSharp ? 0 : width / 2
                y: 3
                x: tgl.checked ? parent.width - width - 3 : 3
                color: tgl.checked ? panel.pOnAccent : "#ffffff"
                Behavior on x { NumberAnimation { duration: Kirigami.Units.shortDuration } }
            }
        }
    }

    component SField: Rectangle {
        id: fld
        property alias text: input.text
        property string placeholder
        signal edited(string value)
        implicitHeight: Kirigami.Units.gridUnit * 1.9
        radius: panel.pRadius
        color: panel.tint(input.activeFocus ? 0.12 : 0.06)
        border.width: panel.pBorder
        border.color: input.activeFocus ? panel.pAccent : panel.tint(0.16)
        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.largeSpacing
            anchors.rightMargin: Kirigami.Units.largeSpacing
            verticalAlignment: TextInput.AlignVCenter
            color: panel.pText
            selectionColor: panel.pAccent
            selectedTextColor: panel.pOnAccent
            font: Kirigami.Theme.defaultFont
            clip: true
            onEditingFinished: fld.edited(text.trim())
        }
        PlasmaComponents.Label {
            anchors.fill: input
            verticalAlignment: Text.AlignVCenter
            visible: input.text === "" && !input.activeFocus
            text: fld.placeholder
            color: panel.pText
            opacity: 0.45
            elide: Text.ElideRight
        }
    }

    // Label + a row of mutually exclusive buttons.
    component Choice: RowLayout {
        id: choice
        property string label
        property var options: []      // [{ value, text }]
        property var current
        signal picked(var value)
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        PlasmaComponents.Label { text: choice.label; color: panel.pText; Layout.fillWidth: true; elide: Text.ElideRight }
        Repeater {
            model: choice.options
            SButton {
                required property var modelData
                text: modelData.text
                checked: choice.current === modelData.value
                onClicked: choice.picked(modelData.value)
            }
        }
    }

    // One scrollable tab page.
    component Page: Flickable {
        id: page
        default property alias content: col.data
        clip: true
        contentWidth: width
        contentHeight: col.implicitHeight + Kirigami.Units.largeSpacing
        boundsBehavior: Flickable.StopAtBounds
        QQC2.ScrollBar.vertical: PlasmaComponents.ScrollBar { visible: page.contentHeight > page.height }
        ColumnLayout {
            id: col
            width: page.width - Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing
        }
    }

    // ---- Done (in the header row) -----------------------------------------
    SButton {
        anchors.right: parent.right
        anchors.bottom: parent.top
        anchors.bottomMargin: -Kirigami.Units.smallSpacing
        iconName: "dialog-ok-apply"
        text: i18n("Done")
        primary: true
        onClicked: panel.app.showSettings = false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        // ---- Tabs ----
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            Repeater {
                model: [
                    { text: i18n("Look"), icon: "color-management" },
                    { text: i18n("Layout"), icon: "view-grid" },
                    { text: i18n("Tiles"), icon: "view-list-details" },
                    { text: i18n("General"), icon: "configure" }
                ]
                SButton {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    text: modelData.text
                    iconName: panel.width > Kirigami.Units.gridUnit * 22 ? modelData.icon : ""
                    checked: panel.tab === index
                    onClicked: panel.tab = index
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: panel.tab

            // ================= Look =================
            Page {
                Heading { text: i18n("Ready-made looks"); Layout.topMargin: 0 }
                Flow {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    Repeater {
                        model: Palette.LOOKS
                        SButton {
                            required property var modelData
                            text: modelData.name
                            checked: panel.app.styleId === modelData.style && panel.app.themeId === modelData.theme
                            onClicked: panel.app.applyLook(modelData.style, modelData.theme)
                        }
                    }
                }

                Heading { text: i18n("Style") }
                Hint { text: i18n("Shape and material of the tiles. Works with any theme.") }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Kirigami.Units.smallSpacing
                    rowSpacing: Kirigami.Units.smallSpacing
                    Repeater {
                        model: Palette.STYLE_ORDER
                        SButton {
                            required property string modelData
                            Layout.fillWidth: true
                            text: Palette.STYLES[modelData].name
                            tip: Palette.STYLES[modelData].hint
                            checked: panel.app.styleId === modelData
                            onClicked: Plasmoid.configuration.style = modelData
                        }
                    }
                }

                Heading { text: i18n("Theme") }
                Hint { text: i18n("Colors only. Follow Plasma uses your system's light or dark colors.") }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Kirigami.Units.smallSpacing
                    rowSpacing: Kirigami.Units.smallSpacing
                    Repeater {
                        model: Palette.THEME_ORDER
                        QQC2.AbstractButton {
                            id: swatch
                            required property string modelData
                            readonly property var th: Palette.THEMES[modelData]
                            readonly property bool current: panel.app.themeId === modelData
                            Layout.fillWidth: true
                            implicitHeight: Kirigami.Units.gridUnit * 2.2
                            hoverEnabled: true
                            onClicked: Plasmoid.configuration.theme = modelData
                            background: Rectangle {
                                radius: panel.pRadius
                                color: swatch.th.body || panel.app.look.body
                                border.width: swatch.current ? 3 : panel.pBorder
                                border.color: swatch.current ? panel.pAccent : panel.tint(swatch.hovered ? 0.45 : 0.18)
                            }
                            contentItem: RowLayout {
                                spacing: Kirigami.Units.smallSpacing
                                Row {
                                    Layout.leftMargin: Kirigami.Units.smallSpacing
                                    spacing: 2
                                    Repeater {
                                        model: ["cpu", "gpu", "memory", "processes"]
                                        Rectangle {
                                            required property string modelData
                                            width: Kirigami.Units.gridUnit * 0.55; height: width
                                            radius: panel.pSharp ? 0 : width / 2
                                            color: Palette.accentPair(swatch.modelData, modelData)[0]
                                        }
                                    }
                                }
                                PlasmaComponents.Label {
                                    text: swatch.th.name
                                    color: swatch.th.text || panel.app.plasmaText
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            // ================= Layout =================
            Page {
                SButton {
                    Layout.fillWidth: true
                    visible: !panel.app.editing
                    primary: true
                    iconName: "transform-move"
                    text: i18n("Edit layout")
                    tip: i18n("Drag tiles to move them, drag a corner to resize")
                    onClicked: { panel.app.showSettings = false; panel.app.editing = true; }
                }
                SButton {
                    Layout.fillWidth: true
                    iconName: "edit-undo"
                    text: i18n("Reset layout")
                    tip: i18n("Back to the %1 preset: its tiles, order and automatic sizes", panel.app.presets[panel.app.currentPreset].name)
                    onClicked: panel.app.resetLayout()
                }

                Heading { text: i18n("Place on this screen") }
                Hint { visible: !panel.app.canPlace(); text: i18n("Placement works when Solidget is on the desktop.") }
                GridLayout {
                    visible: panel.app.canPlace()
                    Layout.fillWidth: true
                    columns: panel.app.isPortrait ? 6 : 4
                    columnSpacing: Kirigami.Units.smallSpacing
                    rowSpacing: Kirigami.Units.smallSpacing
                    Repeater {
                        model: panel.app.placements
                        QQC2.AbstractButton {
                            id: placeButton
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: width * (panel.app.isPortrait ? 1.5 : 0.62)
                            hoverEnabled: true
                            onClicked: panel.app.place(modelData.r)
                            QQC2.ToolTip.text: modelData.name
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                            background: Rectangle {
                                radius: panel.pSharp ? 0 : Kirigami.Units.cornerRadius
                                color: panel.tint(placeButton.hovered ? 0.14 : 0.06)
                                border.width: panel.pBorder
                                border.color: panel.tint(0.15)
                                Rectangle {
                                    readonly property real m: 3
                                    x: m + placeButton.modelData.r[0] * (parent.width - 2 * m)
                                    y: m + placeButton.modelData.r[1] * (parent.height - 2 * m)
                                    width: placeButton.modelData.r[2] * (parent.width - 2 * m)
                                    height: placeButton.modelData.r[3] * (parent.height - 2 * m)
                                    radius: panel.pSharp ? 0 : 2
                                    color: panel.pAccent
                                    opacity: placeButton.hovered ? 1 : 0.75
                                }
                            }
                        }
                    }
                }

                Heading { text: i18n("Screen") }
                Choice {
                    label: i18n("Orientation")
                    options: [{ value: "auto", text: i18n("Auto") }, { value: "landscape", text: i18n("Landscape") }, { value: "portrait", text: i18n("Portrait") }]
                    current: panel.app.orientationSetting
                    onPicked: (v) => Plasmoid.configuration.orientation = v
                }

                Heading { text: i18n("Tile size") }
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
                        SButton {
                            required property var modelData
                            text: modelData.name
                            checked: panel.app.density === modelData.id
                            onClicked: panel.app.setDensity(modelData.id)
                        }
                    }
                }

                Heading { text: i18n("Start from a preset") }
                Flow {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    Repeater {
                        model: panel.app.presetIds
                        SButton {
                            required property string modelData
                            text: panel.app.presets[modelData].name
                            tip: panel.app.presets[modelData].hint
                            checked: panel.app.currentPreset === modelData && !panel.app.customized
                            onClicked: panel.app.applyPreset(modelData)
                        }
                    }
                }
            }

            // ================= Tiles =================
            Page {
                Hint {
                    text: i18n("Show or hide tiles and pick their size (columns × rows). For free placement use Edit layout.")
                }
                Repeater {
                    model: panel.app.order

                    Rectangle {
                        id: row
                        required property string modelData
                        required property int index
                        readonly property bool available: panel.app.isAvailable(modelData)
                        readonly property bool shown: panel.app.hidden.indexOf(modelData) < 0
                        readonly property var choices: panel.app.spanChoices(modelData)
                        // Current size: on screen in a hand-edited layout, else the saved choice.
                        readonly property var cur: panel.app.manualRects && panel.app.boardRef && panel.app.boardRef.rectsById[modelData]
                            ? { w: panel.app.boardRef.rectsById[modelData].w, h: panel.app.boardRef.rectsById[modelData].h }
                            : panel.app.spans[modelData]
                        readonly property int match: {
                            if (cur === undefined) return 0;
                            if (typeof cur === "number") return cur + 1;
                            for (var i = 0; i < choices.length; i++)
                                if (choices[i][0] === cur.w && choices[i][1] === cur.h) return i + 1;
                            return -1;
                        }

                        Layout.fillWidth: true
                        implicitHeight: rowLayout.implicitHeight + Kirigami.Units.smallSpacing * 2
                        radius: panel.pRadius
                        color: panel.tint(shown && available ? 0.07 : 0.025)

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
                                    color: panel.pText
                                    elide: Text.ElideRight
                                    opacity: row.shown && row.available ? 1 : 0.5
                                }
                                Hint { visible: !row.available; text: i18n("Not detected on this PC") }
                            }
                            // Size: click to step through Auto and the tile's sizes.
                            SButton {
                                visible: row.shown && row.available
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                text: row.match === 0 ? i18n("Auto")
                                    : row.match > 0 ? row.choices[row.match - 1][0] + " × " + row.choices[row.match - 1][1]
                                    : row.cur.w + " × " + row.cur.h
                                tip: i18n("Click to change size")
                                onClicked: {
                                    var next = (Math.max(0, row.match) + 1) % (row.choices.length + 1);
                                    if (next === 0) panel.app.setTileSpan(row.modelData, null);
                                    else panel.app.setTileSpan(row.modelData, { w: row.choices[next - 1][0], h: row.choices[next - 1][1] });
                                }
                            }
                            SButton {
                                visible: !panel.app.manualRects   // order only matters in the automatic layout
                                iconName: "go-up"
                                enabled: row.index > 0
                                tip: i18n("Move up")
                                onClicked: panel.app.moveTile(row.modelData, -1)
                            }
                            SButton {
                                visible: !panel.app.manualRects
                                iconName: "go-down"
                                enabled: row.index < panel.app.order.length - 1
                                tip: i18n("Move down")
                                onClicked: panel.app.moveTile(row.modelData, 1)
                            }
                            SToggle {
                                checked: row.shown && row.available
                                enabled: row.available
                                onToggled: panel.app.setTileShown(row.modelData, checked)
                            }
                        }
                    }
                }
            }

            // ================= General =================
            Page {
                Heading { text: i18n("Weather on the clock"); Layout.topMargin: 0 }
                RowLayout {
                    Layout.fillWidth: true
                    SToggle {
                        id: weatherSwitch
                        checked: Plasmoid.configuration.weatherEnabled
                        onToggled: Plasmoid.configuration.weatherEnabled = checked
                    }
                    SField {
                        Layout.fillWidth: true
                        enabled: weatherSwitch.checked
                        opacity: enabled ? 1 : 0.5
                        text: Plasmoid.configuration.weatherCity
                        placeholder: panel.app.shownPlace ? i18n("Automatic (%1)", panel.app.shownPlace) : i18n("Automatic location")
                        onEdited: (v) => Plasmoid.configuration.weatherCity = v
                    }
                }
                Hint {
                    visible: weatherSwitch.checked
                    text: panel.app.weather.error !== "" ? panel.app.weather.error
                        : i18n("Location is guessed from your internet connection; type a city if it's off.")
                }

                Heading { text: i18n("Units") }
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

                Heading { text: i18n("Privacy") }
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        PlasmaComponents.Label { text: i18n("Hide personal info"); color: panel.pText; Layout.fillWidth: true }
                        Hint { text: i18n("Computer name, network name, IP address and weather location. Keep on to share screenshots safely.") }
                    }
                    SToggle {
                        checked: Plasmoid.configuration.maskSensitive
                        onToggled: Plasmoid.configuration.maskSensitive = checked
                    }
                }
            }
        }
    }
}
