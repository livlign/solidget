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
    readonly property real pRadius: pSharp ? 0 : Kirigami.Units.cornerRadius * 1.6
    readonly property int pBorder: app.look.bevel ? 2 : 1
    readonly property string pFont: app.look.fontFamily
    readonly property real gap: Kirigami.Units.largeSpacing
    function tint(a) { return Qt.rgba(pText.r, pText.g, pText.b, a); }

    property int tab: 0

    look: app.look
    solid: true
    showHeader: false
    accent: pAccent
    accent2: app.accent2("cpu")
    level: 0.3

    // Labels inside follow the theme's text color.
    Kirigami.Theme.inherit: false
    Kirigami.Theme.textColor: pText
    Kirigami.Theme.backgroundColor: app.look.body

    // ---- Building blocks -----------------------------------------------------

    component Hint: PlasmaComponents.Label {
        color: panel.pText
        opacity: 0.6
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    // A titled group on a soft card.
    component Section: Rectangle {
        id: sec
        property string title
        property string hint
        default property alias content: inner.data
        Layout.fillWidth: true
        implicitHeight: secCol.implicitHeight + panel.gap * 2
        radius: panel.pRadius
        color: panel.tint(0.045)
        border.width: panel.pSharp ? panel.pBorder : 0
        border.color: panel.tint(0.1)
        ColumnLayout {
            id: secCol
            anchors.fill: parent
            anchors.margins: panel.gap
            spacing: Kirigami.Units.smallSpacing
            PlasmaComponents.Label {
                textFormat: Text.PlainText
                text: sec.title
                visible: text !== ""
                color: panel.pText
                font.family: panel.pFont || Kirigami.Theme.defaultFont.family
                font.weight: Font.DemiBold
            }
            Hint { visible: sec.hint !== ""; text: sec.hint }
            ColumnLayout {
                id: inner
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing
            }
        }
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
                            : panel.tint(b.hovered ? 0.14 : 0.06)
            border.width: panel.pBorder
            border.color: b.filled ? Qt.darker(panel.pAccent, 1.35) : panel.tint(0.14)
        }
        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Item { Layout.fillWidth: true; visible: b.text !== "" }
            Kirigami.Icon {
                visible: b.iconName !== ""
                source: b.iconName
                color: b.filled ? panel.pOnAccent : panel.pText
                isMask: true
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            PlasmaComponents.Label {
                textFormat: Text.PlainText
                visible: b.text !== ""
                text: b.text
                color: b.filled ? panel.pOnAccent : panel.pText
                font.family: panel.pFont || Kirigami.Theme.defaultFont.family
                font.weight: b.filled ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }
            Item { Layout.fillWidth: true; visible: b.text !== "" }
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
            textFormat: Text.PlainText
            anchors.fill: input
            verticalAlignment: Text.AlignVCenter
            visible: input.text === "" && !input.activeFocus
            text: fld.placeholder
            color: panel.pText
            opacity: 0.45
            elide: Text.ElideRight
        }
    }

    // Segmented control: options side by side in one bar.
    component Segmented: Rectangle {
        id: seg
        property var options: []      // [{ value, text }]
        property var current
        signal picked(var value)
        implicitHeight: Kirigami.Units.gridUnit * 1.8
        implicitWidth: segRow.implicitWidth + 6
        radius: panel.pRadius
        color: panel.tint(0.07)
        border.width: panel.pBorder
        border.color: panel.tint(0.12)
        RowLayout {
            id: segRow
            anchors.fill: parent
            anchors.margins: 3
            spacing: 2
            Repeater {
                model: seg.options
                QQC2.AbstractButton {
                    id: opt
                    required property var modelData
                    readonly property bool on: seg.current === modelData.value
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    hoverEnabled: true
                    leftPadding: Kirigami.Units.largeSpacing
                    rightPadding: Kirigami.Units.largeSpacing
                    onClicked: seg.picked(modelData.value)
                    background: Rectangle {
                        radius: panel.pSharp ? 0 : panel.pRadius - 2
                        color: opt.on ? panel.pAccent : opt.hovered ? panel.tint(0.1) : "transparent"
                    }
                    contentItem: PlasmaComponents.Label {
                        text: opt.modelData.text
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: opt.on ? panel.pOnAccent : panel.pText
                        font.family: panel.pFont || Kirigami.Theme.defaultFont.family
                        font.weight: opt.on ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    // "Label ...... [control]" row.
    component SettingRow: RowLayout {
        id: srow
        property string label
        property string hint
        default property alias control: slot.data
        Layout.fillWidth: true
        spacing: panel.gap
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            PlasmaComponents.Label { textFormat: Text.PlainText; text: srow.label; color: panel.pText; Layout.fillWidth: true; elide: Text.ElideRight }
            Hint { visible: srow.hint !== ""; text: srow.hint }
        }
        Item {
            id: slot
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }

    // Mini tile drawn in a given style and theme: used by the look/style cards.
    component Preview: Item {
        id: pv
        property string styleKey: "glass"
        property string themeKey: "plasma"
        readonly property var st: Palette.STYLES[styleKey]
        readonly property var th: Palette.THEMES[themeKey]
        readonly property color body: th.body || panel.app.look.body
        readonly property color acc: Palette.accentPair(themeKey, "cpu")[0]
        readonly property color acc2: Palette.accentPair(themeKey, "cpu")[1]
        readonly property real r: st.radius === 0 ? 0 : Math.min(width, height) * 0.22
        implicitWidth: Kirigami.Units.gridUnit * 2.6
        implicitHeight: implicitWidth

        Rectangle {   // hard shadow (Pixel)
            visible: pv.st.hardShadow
            x: 3; y: 3; width: parent.width; height: parent.height
            color: Qt.rgba(0, 0, 0, 0.5)
        }
        Rectangle {
            anchors.fill: parent
            radius: pv.r
            color: pv.st.tint > 0 ? Qt.tint(pv.body, Qt.rgba(pv.acc.r, pv.acc.g, pv.acc.b, pv.st.tint)) : pv.body
            opacity: pv.styleKey === "clear" ? 0.75 : 1
            border.width: pv.st.border
            border.color: Qt.rgba(1, 1, 1, 0.18)
            gradient: pv.st.glow ? glowGrad : null
            Gradient {
                id: glowGrad
                GradientStop { position: 0; color: Qt.tint(pv.body, Qt.rgba(pv.acc.r, pv.acc.g, pv.acc.b, 0.45)) }
                GradientStop { position: 1; color: pv.body }
            }
        }
        Rectangle {   // bevel (Pixel)
            visible: pv.st.bevel
            anchors.fill: parent
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(1, 1, 1, 0.25)
        }
        // A tiny gauge: ring, or blocks for Pixel
        Rectangle {
            visible: pv.st.meter !== "blocks"
            anchors.centerIn: parent
            width: parent.width * 0.5; height: width; radius: width / 2
            color: "transparent"
            border.width: Math.max(2, width * 0.14)
            border.color: pv.acc
        }
        Grid {
            visible: pv.st.meter === "blocks"
            anchors.centerIn: parent
            columns: 3; spacing: 2
            Repeater {
                model: 9
                Rectangle {
                    required property int index
                    width: pv.width * 0.14; height: width
                    color: index < 6 ? (index % 2 ? pv.acc2 : pv.acc) : Qt.rgba(1, 1, 1, 0.15)
                }
            }
        }
    }

    // Selectable card with a preview, a title and a line of text.
    component PreviewCard: QQC2.AbstractButton {
        id: card
        property string styleKey
        property string themeKey
        property string subtitle
        hoverEnabled: true
        Layout.fillWidth: true
        implicitHeight: Kirigami.Units.gridUnit * 3.6
        padding: Kirigami.Units.smallSpacing * 1.5
        background: Rectangle {
            radius: panel.pRadius
            color: card.checked ? Qt.rgba(panel.pAccent.r, panel.pAccent.g, panel.pAccent.b, 0.16) : panel.tint(card.hovered ? 0.1 : 0.05)
            border.width: card.checked ? 2 : panel.pBorder
            border.color: card.checked ? panel.pAccent : panel.tint(0.12)
        }
        contentItem: RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Preview {
                styleKey: card.styleKey
                themeKey: card.themeKey
                Layout.preferredWidth: card.availableHeight
                Layout.preferredHeight: card.availableHeight
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                PlasmaComponents.Label {
                    textFormat: Text.PlainText
                    text: card.text
                    color: panel.pText
                    font.family: panel.pFont || Kirigami.Theme.defaultFont.family
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Hint { text: card.subtitle; maximumLineCount: 2; elide: Text.ElideRight }
            }
        }
    }

    // One scrollable tab page.
    component Page: Flickable {
        id: page
        default property alias content: col.data
        clip: true
        contentWidth: width
        contentHeight: col.implicitHeight + panel.gap
        boundsBehavior: Flickable.StopAtBounds
        QQC2.ScrollBar.vertical: PlasmaComponents.ScrollBar { visible: page.contentHeight > page.height }
        ColumnLayout {
            id: col
            width: page.width - (page.contentHeight > page.height ? Kirigami.Units.largeSpacing : 0)
            spacing: panel.gap
        }
    }

    // ---- Layout ------------------------------------------------------------------

    ColumnLayout {
        anchors.fill: parent
        spacing: panel.gap

        // Header
        RowLayout {
            Layout.fillWidth: true
            Kirigami.Icon {
                source: "configure"
                color: panel.pAccent
                isMask: true
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }
            PlasmaComponents.Label {
                textFormat: Text.PlainText
                text: i18n("Settings")
                color: panel.pText
                font.family: panel.pFont || Kirigami.Theme.defaultFont.family
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.35
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            SButton {
                iconName: "dialog-ok-apply"
                text: i18n("Done")
                primary: true
                onClicked: panel.app.showSettings = false
            }
        }

        // Tabs
        Segmented {
            Layout.fillWidth: true
            options: [
                { value: 0, text: i18n("Look") },
                { value: 1, text: i18n("Layout") },
                { value: 2, text: i18n("Tiles") },
                { value: 3, text: i18n("General") }
            ]
            current: panel.tab
            onPicked: (v) => panel.tab = v
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: panel.tab

            // ================= Look =================
            Page {
                Section {
                    title: i18n("Ready-made looks")
                    hint: i18n("One click sets a style and a theme together.")
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Kirigami.Units.smallSpacing
                        rowSpacing: Kirigami.Units.smallSpacing
                        Repeater {
                            model: Palette.LOOKS
                            PreviewCard {
                                required property var modelData
                                text: modelData.name
                                subtitle: Palette.STYLES[modelData.style].name + " · " + Palette.THEMES[modelData.theme].name
                                styleKey: modelData.style
                                themeKey: modelData.theme
                                checked: panel.app.styleId === modelData.style && panel.app.themeId === modelData.theme
                                onClicked: panel.app.applyLook(modelData.style, modelData.theme)
                            }
                        }
                    }
                }

                Section {
                    title: i18n("Style")
                    hint: i18n("Shape and material of the tiles. Works with any theme.")
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Kirigami.Units.smallSpacing
                        rowSpacing: Kirigami.Units.smallSpacing
                        Repeater {
                            model: Palette.STYLE_ORDER
                            PreviewCard {
                                required property string modelData
                                text: Palette.STYLES[modelData].name
                                subtitle: Palette.STYLES[modelData].hint
                                styleKey: modelData
                                themeKey: panel.app.themeId
                                checked: panel.app.styleId === modelData
                                onClicked: Plasmoid.configuration.style = modelData
                            }
                        }
                    }
                }

                Section {
                    title: i18n("Theme")
                    hint: i18n("Colors only. Follow Plasma uses your system's light or dark colors.")
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
                                    border.width: swatch.current ? 2 : panel.pBorder
                                    border.color: swatch.current ? panel.pAccent : panel.tint(swatch.hovered ? 0.45 : 0.15)
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
                                        textFormat: Text.PlainText
                                        text: swatch.th.name
                                        color: swatch.th.text || panel.app.plasmaText
                                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Kirigami.Icon {
                                        visible: swatch.current
                                        source: "checkmark"
                                        color: swatch.th.text || panel.app.plasmaText
                                        isMask: true
                                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                        Layout.rightMargin: Kirigami.Units.smallSpacing
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ================= Layout =================
            Page {
                Section {
                    title: i18n("Arrange")
                    hint: i18n("Drag tiles to move them and drag a corner to resize. Reset goes back to the preset's automatic layout.")
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        SButton {
                            Layout.fillWidth: true
                            visible: !panel.app.editing
                            primary: true
                            iconName: "transform-move"
                            text: i18n("Edit layout")
                            onClicked: { panel.app.showSettings = false; panel.app.editing = true; }
                        }
                        SButton {
                            Layout.fillWidth: true
                            iconName: "edit-undo"
                            text: i18n("Reset layout")
                            tip: i18n("Back to the %1 preset", panel.app.presets[panel.app.currentPreset].name)
                            onClicked: panel.app.resetLayout()
                        }
                    }
                }

                Section {
                    title: i18n("Place on this screen")
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
                                Layout.preferredHeight: width * (panel.app.isPortrait ? 1.4 : 0.62)
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
                                        opacity: placeButton.hovered ? 1 : 0.7
                                    }
                                }
                            }
                        }
                    }
                }

                Section {
                    title: i18n("Grid")
                    SettingRow {
                        label: i18n("Screen orientation")
                        Segmented {
                            options: [{ value: "auto", text: i18n("Auto") }, { value: "landscape", text: i18n("Landscape") }, { value: "portrait", text: i18n("Portrait") }]
                            current: panel.app.orientationSetting
                            onPicked: (v) => Plasmoid.configuration.orientation = v
                        }
                    }
                    PlasmaComponents.Label { textFormat: Text.PlainText; text: i18n("Tile size"); color: panel.pText; Layout.topMargin: Kirigami.Units.smallSpacing }
                    Segmented {
                        Layout.fillWidth: true
                        options: [
                            { value: "auto", text: i18n("Auto") },
                            { value: "compact", text: i18n("S") },
                            { value: "comfortable", text: i18n("M") },
                            { value: "large", text: i18n("L") },
                            { value: "huge", text: i18n("XL") }
                        ]
                        current: panel.app.density
                        onPicked: (v) => panel.app.setDensity(v)
                    }
                }

                Section {
                    title: i18n("Presets")
                    hint: i18n("Which tiles to show, in a ready-made arrangement.")
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Kirigami.Units.smallSpacing
                        rowSpacing: Kirigami.Units.smallSpacing
                        Repeater {
                            model: panel.app.presetIds
                            SButton {
                                required property string modelData
                                Layout.fillWidth: true
                                text: panel.app.presets[modelData].name
                                tip: panel.app.presets[modelData].hint
                                checked: panel.app.currentPreset === modelData && !panel.app.customized
                                onClicked: panel.app.applyPreset(modelData)
                            }
                        }
                    }
                }
            }

            // ================= Tiles =================
            Page {
                Section {
                    title: i18n("Tiles")
                    hint: i18n("Show or hide tiles and pick their size in grid cells (columns × rows).")
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
                            color: panel.tint(shown && available ? 0.06 : 0.02)

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
                                        textFormat: Text.PlainText
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
            }

            // ================= General =================
            Page {
                Section {
                    title: i18n("Weather")
                    SettingRow {
                        label: i18n("Show weather on the clock")
                        SToggle {
                            id: weatherSwitch
                            checked: Plasmoid.configuration.weatherEnabled
                            onToggled: Plasmoid.configuration.weatherEnabled = checked
                        }
                    }
                    SField {
                        Layout.fillWidth: true
                        visible: weatherSwitch.checked
                        text: Plasmoid.configuration.weatherCity
                        placeholder: panel.app.shownPlace ? i18n("Automatic (%1)", panel.app.shownPlace) : i18n("City — leave empty for automatic")
                        onEdited: (v) => Plasmoid.configuration.weatherCity = v
                    }
                    Hint {
                        visible: weatherSwitch.checked
                        text: panel.app.weather.error !== "" ? panel.app.weather.error
                            : i18n("Location is guessed from your internet connection; type a city if it's off.")
                    }
                }

                Section {
                    title: i18n("World clocks")
                    hint: i18n("Up to 6 cities, separated by commas. Each name is looked up once to find its time zone.")
                    SField {
                        Layout.fillWidth: true
                        text: panel.app.worldClocks.map(function (c) { return c.name; }).join(", ")
                        placeholder: i18n("London, New York, Tokyo")
                        onEdited: (v) => panel.app.setWorldCities(v)
                    }
                }

                Section {
                    title: i18n("Focus timer")
                    SettingRow {
                        label: i18n("Focus / break")
                        Segmented {
                            options: [{ value: "25/5", text: "25 / 5" }, { value: "50/10", text: "50 / 10" }, { value: "15/3", text: "15 / 3" }]
                            current: Plasmoid.configuration.focusMinutes + "/" + Plasmoid.configuration.breakMinutes
                            onPicked: (v) => {
                                var p = v.split("/");
                                Plasmoid.configuration.focusMinutes = parseInt(p[0]);
                                Plasmoid.configuration.breakMinutes = parseInt(p[1]);
                                panel.app.focusReset();
                            }
                        }
                    }
                }

                Section {
                    title: i18n("Units")
                    SettingRow {
                        label: i18n("Temperature")
                        Segmented {
                            options: [{ value: false, text: "°C" }, { value: true, text: "°F" }]
                            current: panel.app.useFahrenheit
                            onPicked: (v) => Plasmoid.configuration.weatherUnit = v ? "f" : "c"
                        }
                    }
                    SettingRow {
                        label: i18n("Sizes")
                        Segmented {
                            options: [{ value: false, text: "GiB" }, { value: true, text: "GB" }]
                            current: panel.app.decimalUnits
                            onPicked: (v) => Plasmoid.configuration.dataUnits = v ? "decimal" : "binary"
                        }
                    }
                    SettingRow {
                        label: i18n("Network speed")
                        Segmented {
                            options: [{ value: false, text: "MB/s" }, { value: true, text: "Mbps" }]
                            current: panel.app.networkBits
                            onPicked: (v) => Plasmoid.configuration.networkBits = v
                        }
                    }
                }

                Section {
                    title: i18n("Privacy")
                    SettingRow {
                        label: i18n("Hide personal info")
                        hint: i18n("Computer name, network name, IP address and weather location. Keep on to share screenshots safely.")
                        SToggle {
                            checked: Plasmoid.configuration.maskSensitive
                            onToggled: Plasmoid.configuration.maskSensitive = checked
                        }
                    }
                }
            }
        }
    }
}
