import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs as Dialogs
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
    // Plasma style: Plasma's own controls instead of the themed ones.
    readonly property bool stock: app.nativeStyle
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
        textFormat: Text.PlainText
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
        // Plasma style: plain groups on the dialog, like a settings page.
        color: panel.stock ? "transparent" : panel.tint(0.045)
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

    // The controls below come in two builds: Plasma's own (the Plasma style,
    // where theme colors are the system's) and our own drawn ones, which can
    // wear any theme. Each is a small wrapper that loads one or the other.

    // Button; `checked` (set by binding) or `primary` fills it with the accent.
    component SButton: Item {
        id: sb
        property string text
        property string iconName: ""
        property string tip: ""
        property bool primary: false
        property bool checked: false
        signal clicked()
        implicitWidth: sbLoader.implicitWidth
        implicitHeight: sbLoader.implicitHeight
        Loader {
            id: sbLoader
            anchors.fill: parent
            sourceComponent: panel.stock ? (sb.text === "" ? sbStockIcon : sbStock) : sbOwn
        }
        Component {
            id: sbStock
            PlasmaComponents.Button {
                text: sb.text
                icon.name: sb.iconName
                checked: sb.checked
                QQC2.ToolTip.text: sb.tip
                QQC2.ToolTip.visible: sb.tip !== "" && hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                onClicked: sb.clicked()
            }
        }
        Component {
            id: sbStockIcon
            PlasmaComponents.ToolButton {
                icon.name: sb.iconName
                checked: sb.checked
                QQC2.ToolTip.text: sb.tip
                QQC2.ToolTip.visible: sb.tip !== "" && hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                Accessible.name: sb.tip
                onClicked: sb.clicked()
            }
        }
        Component {
            id: sbOwn
            QQC2.AbstractButton {
                id: b
                readonly property bool filled: sb.checked || sb.primary
                text: sb.text
                hoverEnabled: true
                padding: Kirigami.Units.smallSpacing * 1.4
                leftPadding: Kirigami.Units.largeSpacing
                rightPadding: Kirigami.Units.largeSpacing
                opacity: enabled ? 1 : 0.4
                QQC2.ToolTip.text: sb.tip
                QQC2.ToolTip.visible: sb.tip !== "" && hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                Accessible.name: sb.text || sb.tip
                onClicked: sb.clicked()
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
                        visible: sb.iconName !== ""
                        source: sb.iconName
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
        }
    }

    // On/off switch. Toggling sets `checked` and emits toggled(); the inner
    // control is re-bound afterwards so later outside changes still show.
    component SToggle: Item {
        id: tg
        property bool checked: false
        signal toggled()
        implicitWidth: tgLoader.implicitWidth
        implicitHeight: tgLoader.implicitHeight
        function flip(on, ctl) {
            tg.checked = on;
            tg.toggled();
            ctl.checked = Qt.binding(function () { return tg.checked; });
        }
        Loader {
            id: tgLoader
            anchors.fill: parent
            sourceComponent: panel.stock ? tgStock : tgOwn
        }
        Component {
            id: tgStock
            PlasmaComponents.Switch {
                id: sw
                checked: tg.checked
                onToggled: tg.flip(checked, sw)
            }
        }
        Component {
            id: tgOwn
            QQC2.AbstractButton {
                id: tgl
                checkable: true
                checked: tg.checked
                hoverEnabled: true
                implicitWidth: Kirigami.Units.gridUnit * 2.4
                implicitHeight: Kirigami.Units.gridUnit * 1.3
                onToggled: tg.flip(checked, tgl)
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
        }
    }

    // One-line text field; edited() fires when editing finishes.
    component SField: Item {
        id: fld
        property string text
        property string placeholder
        signal edited(string value)
        implicitWidth: fldLoader.implicitWidth
        implicitHeight: fldLoader.implicitHeight
        function finish(input) {
            fld.edited(input.text.trim());
            input.text = Qt.binding(function () { return fld.text; });
        }
        Loader {
            id: fldLoader
            anchors.fill: parent
            sourceComponent: panel.stock ? fldStock : fldOwn
        }
        Component {
            id: fldStock
            PlasmaComponents.TextField {
                id: tf
                text: fld.text
                placeholderText: fld.placeholder
                onEditingFinished: fld.finish(tf)
            }
        }
        Component {
            id: fldOwn
            Rectangle {
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
                    text: fld.text
                    color: panel.pText
                    selectionColor: panel.pAccent
                    selectedTextColor: panel.pOnAccent
                    font: Kirigami.Theme.defaultFont
                    clip: true
                    onEditingFinished: fld.finish(input)
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
        }
    }

    // Pick one of a few options side by side (also the panel's tabs).
    component Segmented: Item {
        id: seg
        property var options: []      // [{ value, text }]
        property var current
        signal picked(var value)
        implicitWidth: segLoader.implicitWidth
        implicitHeight: segLoader.implicitHeight
        Loader {
            id: segLoader
            anchors.fill: parent
            sourceComponent: panel.stock ? segStock : segOwn
        }
        Component {
            id: segStock
            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Repeater {
                    model: seg.options
                    PlasmaComponents.ToolButton {
                        required property var modelData
                        Layout.fillWidth: true
                        text: modelData.text
                        // Shown as checked by binding; clicking never un-checks it.
                        checked: seg.current === modelData.value
                        onClicked: seg.picked(modelData.value)
                    }
                }
            }
        }
        Component {
            id: segOwn
            Rectangle {
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

    // Mini tile drawn in a given style and theme, over a bit of wallpaper:
    // its corners, card, title mark, number and dial are the style's own.
    component Preview: Item {
        id: pv
        property string styleKey: "glass"
        property string themeKey: "plasma"
        readonly property var st: Palette.STYLES[styleKey]
        readonly property var th: Palette.THEMES[themeKey]
        readonly property bool plasmaFrame: st.plasmaFrame === true
        readonly property bool dark: th.dark === null ? panel.app.plasmaDark : th.dark
        readonly property color body: th.body || panel.app.plasmaBody
        readonly property color ink: th.text || panel.app.plasmaText
        readonly property color acc: panel.app.accentPair(themeKey, "cpu", plasmaFrame)[0]
        readonly property color acc2: panel.app.accentPair(themeKey, "cpu", plasmaFrame)[1]
        readonly property real s: Math.min(width, height)
        readonly property real cardR: plasmaFrame ? s * 0.06 : Math.min(s * 0.2, st.radius * s * 0.09)
        readonly property real alpha: th.opaque || st.bodyAlpha === 1 || st.bodyAlpha >= 0.97 ? 1
            : st.bodyAlpha === null ? 0.72 : typeof st.bodyAlpha === "object" ? (dark ? 0.45 : 0.7) : st.bodyAlpha
        readonly property string header: plasmaFrame ? "plain" : (st.header || "caps")
        implicitWidth: Kirigami.Units.gridUnit * 4
        implicitHeight: Kirigami.Units.gridUnit * 3

        // Wallpaper, so see-through styles look see-through.
        Rectangle {
            anchors.fill: parent
            radius: panel.pSharp ? 0 : Kirigami.Units.cornerRadius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: pv.dark ? Qt.darker(pv.acc, 2.6) : Qt.lighter(pv.acc, 1.7) }
                GradientStop { position: 1; color: pv.dark ? "#141726" : "#d8d2c8" }
            }
        }
        Item {
            id: pvCard
            anchors.fill: parent
            anchors.margins: pv.s * 0.11
            Rectangle {   // hard shadow (Pixel)
                visible: pv.st.hardShadow
                x: 3; y: 3; width: parent.width; height: parent.height
                color: Qt.rgba(0, 0, 0, 0.5)
            }
            Rectangle {   // soft shadow (Glass, Bento)
                visible: pv.st.shadow && !pv.st.hardShadow
                x: 0; y: pv.s * 0.03; width: parent.width; height: parent.height
                radius: pv.cardR
                color: Qt.rgba(0, 0, 0, pv.dark ? 0.35 : 0.12)
            }
            Rectangle {
                anchors.fill: parent
                radius: pv.cardR
                color: {
                    var c = pv.st.tint > 0 && !pv.th.opaque ? Qt.tint(pv.body, Qt.rgba(pv.acc.r, pv.acc.g, pv.acc.b, pv.st.tint)) : pv.body;
                    return Qt.rgba(c.r, c.g, c.b, pv.alpha);
                }
                border.width: pv.st.bevel ? 2 : (pv.st.border > 0 || pv.th.edge) && !pv.plasmaFrame ? 1 : 0
                border.color: pv.th.edge ? pv.th.edge : pv.st.bevel ? Qt.rgba(1, 1, 1, 0.3)
                    : Qt.rgba(pv.ink.r, pv.ink.g, pv.ink.b, 0.14)
            }
            // Flat: the thick rule on top.
            Rectangle {
                visible: pv.header === "bar"
                width: parent.width; height: Math.max(2, pv.s * 0.035)
                color: pv.ink
            }
            // Title row: the color mark and a stand-in title.
            Row {
                x: pvCard.width * 0.12; y: pvCard.height * 0.14
                spacing: pv.s * 0.04
                Rectangle {
                    visible: pv.header !== "bar" && pv.header !== "quiet"
                    width: pv.s * (pv.header === "plain" ? 0.1 : 0.065); height: width
                    anchors.verticalCenter: parent.verticalCenter
                    radius: pv.header === "plain" ? width * 0.3 : pv.header === "rule" || pv.st.radius === 0 ? 0 : width / 2
                    color: pv.acc
                }
                Rectangle {
                    width: pvCard.width * (pv.header === "caps" ? 0.34 : 0.26)
                    height: Math.max(2, pv.s * (pv.header === "plain" ? 0.06 : 0.04))
                    anchors.verticalCenter: parent.verticalCenter
                    radius: pv.st.radius === 0 || pv.header === "rule" ? 0 : height / 2
                    color: Qt.rgba(pv.ink.r, pv.ink.g, pv.ink.b, pv.header === "plain" ? 0.8 : 0.45)
                }
            }
            Row {   // Instrument: the dashed line under the title
                visible: pv.header === "rule"
                x: pvCard.width * 0.12; y: pvCard.height * 0.32
                spacing: 2
                Repeater {
                    model: 9
                    Rectangle { width: 3; height: 1; color: Qt.rgba(pv.ink.r, pv.ink.g, pv.ink.b, 0.3) }
                }
            }
            // A big number in the style's own figures.
            PlasmaComponents.Label {
                textFormat: Text.PlainText
                x: pvCard.width * 0.12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: pvCard.height * 0.08
                text: "23"
                color: pv.ink
                font.family: pv.st.font === "pixel" ? panel.app.pixelFontName
                           : pv.st.figures === "mono" ? "JetBrains Mono" : pv.st.figures === "round" ? "Manrope" : Kirigami.Theme.defaultFont.family
                font.pixelSize: pv.s * (pv.st.font === "pixel" ? 0.26 : 0.34)
                font.weight: pv.st.font === "pixel" || pv.plasmaFrame ? Font.Normal
                           : ({ hairline: Font.Thin, thin: Font.ExtraLight, bold: Font.Bold, heavy: Font.ExtraBold })[pv.st.figureWeight] || Font.Light
            }
            // Bar styles (Plasma, Flat, Pixel): a bar under the number.
            Row {
                visible: pv.st.gauge === "bar" || pv.st.gauge === "hp"
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: pvCard.width * 0.1
                spacing: pv.st.gauge === "hp" ? 1 : 0
                Repeater {
                    model: pv.st.gauge === "hp" ? 5 : 1
                    Rectangle {
                        required property int index
                        width: pv.st.gauge === "hp" ? pv.s * 0.07 : pv.s * 0.38
                        height: Math.max(2, pv.s * 0.06)
                        radius: pv.st.roundCaps ? height / 2 : 0
                        color: pv.st.gauge === "hp" && index > 2 ? Qt.rgba(pv.ink.r, pv.ink.g, pv.ink.b, 0.15) : pv.acc
                    }
                }
            }
            // The dial: ring, blocks or ticks.
            Item {
                id: dial
                visible: pv.st.gauge !== "bar" && pv.st.gauge !== "hp"
                width: pv.s * 0.36; height: width
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: pvCard.width * 0.1
                Rectangle {
                    visible: pv.st.meter === "ring" || pv.st.meter === "thick" || pv.st.meter === "hairline"
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: pv.st.meter === "hairline" ? 1 : Math.max(2, width * (pv.st.meter === "thick" ? 0.18 : 0.12))
                    border.color: pv.acc
                }
                Grid {
                    visible: pv.st.meter === "blocks"
                    anchors.centerIn: parent
                    columns: 3; spacing: 1
                    Repeater {
                        model: 9
                        Rectangle {
                            required property int index
                            width: dial.width * 0.28; height: width
                            color: index < 6 ? (index % 2 ? pv.acc2 : pv.acc) : Qt.rgba(pv.ink.r, pv.ink.g, pv.ink.b, 0.15)
                        }
                    }
                }
                Repeater {
                    model: pv.st.meter === "ticks" ? 11 : 0
                    Rectangle {
                        required property int index
                        readonly property real a: (135 + 27 * index) * Math.PI / 180
                        width: 1.5; height: dial.width * 0.22
                        x: dial.width / 2 + dial.width * 0.4 * Math.cos(a) - width / 2
                        y: dial.height / 2 + dial.width * 0.4 * Math.sin(a) - height / 2
                        rotation: a * 180 / Math.PI + 90
                        antialiasing: true
                        color: index < 5 ? pv.acc : Qt.rgba(pv.ink.r, pv.ink.g, pv.ink.b, 0.25)
                    }
                }
            }
        }
    }

    // A picture of a look with its name under it; picks it when clicked.
    component LookThumb: QQC2.AbstractButton {
        id: thumb
        property string styleKey
        property string themeKey
        property string tip
        hoverEnabled: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1     // equal columns, whatever the names
        implicitHeight: Kirigami.Units.gridUnit * 4.4
        padding: Kirigami.Units.smallSpacing
        Accessible.name: thumb.text
        QQC2.ToolTip.text: thumb.tip
        QQC2.ToolTip.visible: thumb.tip !== "" && hovered
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        background: Rectangle {
            radius: panel.pRadius
            color: thumb.checked ? Qt.rgba(panel.pAccent.r, panel.pAccent.g, panel.pAccent.b, 0.16)
                 : panel.tint(thumb.hovered ? 0.08 : 0)
            border.width: thumb.checked ? 2 : 0
            border.color: panel.pAccent
        }
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            Preview {
                styleKey: thumb.styleKey
                themeKey: thumb.themeKey
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            PlasmaComponents.Label {
                textFormat: Text.PlainText
                text: thumb.text
                color: panel.pText
                font.family: panel.pFont || Kirigami.Theme.defaultFont.family
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.weight: thumb.checked ? Font.DemiBold : Font.Normal
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                Layout.fillWidth: true
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

        // A new version is out: say so on every tab.
        Section {
            id: updateBanner
            visible: panel.app.updateAvailable
            border.width: 1
            border.color: panel.pAccent
            readonly property string upgradeCommand: "sudo dnf upgrade solidget"   // guard: text only
            SettingRow {
                label: i18n("Solidget %1 is out", panel.app.latestVersion)
                hint: panel.app.systemInstall
                    ? i18n("You have %1. Your package manager updates it: %2", panel.app.version, updateBanner.upgradeCommand)
                    : i18n("You have %1. Update it in Discover, or get it from the Releases page. Installed with install.sh? Run git pull, then ./install.sh.", panel.app.version)
                RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    SButton {
                        visible: panel.app.updateNotice
                        text: i18n("Later")
                        tip: i18n("Hide the desktop button until the next version")
                        onClicked: Plasmoid.configuration.updateDismissed = panel.app.latestVersion
                    }
                    SButton {
                        visible: panel.app.systemInstall
                        text: i18n("Copy")
                        tip: i18n("Copy the update command")
                        onClicked: panel.app.copyToClipboard(updateBanner.upgradeCommand)
                    }
                    SButton {
                        text: i18n("What's new")
                        primary: true
                        onClicked: panel.app.openReleases()
                    }
                }
            }
        }

        // Tabs
        Segmented {
            Layout.fillWidth: true
            options: [
                { value: 0, text: i18n("Look") },
                { value: 1, text: i18n("Layout") },
                { value: 2, text: i18n("Tiles") },
                { value: 3, text: i18n("Personal") },
                { value: 4, text: i18n("General") }
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
                id: lookPage
                // The ready-made look being worn, or null for a mix.
                readonly property var currentLook: {
                    for (var i = 0; i < Palette.LOOKS.length; i++)
                        if (Palette.LOOKS[i].style === panel.app.styleId && Palette.LOOKS[i].theme === panel.app.themeId)
                            return Palette.LOOKS[i];
                    return null;
                }
                // Grid columns for the thumbnails: as many as fit.
                readonly property int thumbColumns: Math.max(2, Math.min(6, Math.floor(width / (Kirigami.Units.gridUnit * 7))))
                property bool mixOpen: currentLook === null
                property string themeFilter: "all"

                // What's on now, big, with a way to try something new.
                Section {
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: panel.gap
                        Preview {
                            styleKey: panel.app.styleId
                            themeKey: panel.app.themeId
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 4.5
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            PlasmaComponents.Label {
                                textFormat: Text.PlainText
                                text: lookPage.currentLook ? lookPage.currentLook.name : i18n("Your own mix")
                                color: panel.pText
                                font.family: panel.pFont || Kirigami.Theme.defaultFont.family
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.3
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Hint {
                                text: panel.app.nativeStyle ? Palette.STYLES.plasma.hint
                                    : i18n("%1 style, %2 colors", Palette.STYLES[panel.app.styleId].name, Palette.THEMES[panel.app.themeId].name)
                            }
                            SButton {
                                iconName: "roll"
                                text: i18n("Surprise me")
                                tip: i18n("Wear a random style with random colors")
                                onClicked: {
                                    var styles = Palette.STYLE_ORDER.filter(function (k) { return k !== "plasma" && k !== panel.app.styleId; });
                                    var themes = Palette.THEME_ORDER.filter(function (k) { return k !== "plasma" && k !== panel.app.themeId; });
                                    panel.app.applyLook(styles[Math.floor(Math.random() * styles.length)],
                                                        themes[Math.floor(Math.random() * themes.length)]);
                                }
                            }
                        }
                    }
                }

                Section {
                    title: i18n("Ready-made looks")
                    hint: i18n("One click sets a style and colors that go together.")
                    GridLayout {
                        Layout.fillWidth: true
                        columns: lookPage.thumbColumns
                        columnSpacing: Kirigami.Units.smallSpacing
                        rowSpacing: Kirigami.Units.smallSpacing
                        Repeater {
                            model: Palette.LOOKS
                            LookThumb {
                                required property var modelData
                                text: modelData.name
                                tip: i18n("%1 style, %2 colors", Palette.STYLES[modelData.style].name, Palette.THEMES[modelData.theme].name)
                                styleKey: modelData.style
                                themeKey: modelData.theme
                                checked: panel.app.styleId === modelData.style && panel.app.themeId === modelData.theme
                                onClicked: panel.app.applyLook(modelData.style, modelData.theme)
                            }
                        }
                    }
                }

                // Style and colors picked apart. Folded away while a
                // ready-made look is on, so the page stays short.
                Section {
                    SettingRow {
                        label: i18n("Mix your own")
                        hint: i18n("Any style with any colors.")
                        SButton {
                            text: lookPage.mixOpen ? i18n("Hide") : i18n("Show")
                            iconName: lookPage.mixOpen ? "go-up" : "go-down"
                            onClicked: lookPage.mixOpen = !lookPage.mixOpen
                        }
                    }

                    ColumnLayout {
                        visible: lookPage.mixOpen
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.Label {
                            textFormat: Text.PlainText
                            text: i18n("Style")
                            color: panel.pText
                            font.family: panel.pFont || Kirigami.Theme.defaultFont.family
                            font.weight: Font.DemiBold
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: lookPage.thumbColumns
                            columnSpacing: Kirigami.Units.smallSpacing
                            rowSpacing: Kirigami.Units.smallSpacing
                            Repeater {
                                model: Palette.STYLE_ORDER
                                LookThumb {
                                    required property string modelData
                                    text: Palette.STYLES[modelData].name
                                    tip: Palette.STYLES[modelData].hint
                                    styleKey: modelData
                                    // Each style shown in the colors it would get.
                                    themeKey: Palette.STYLES[modelData].plasmaFrame ? "plasma" : panel.app.themeSetting
                                    checked: panel.app.styleId === modelData
                                    onClicked: Plasmoid.configuration.style = modelData
                                }
                            }
                        }
                        Hint { text: Palette.STYLES[panel.app.styleId].hint }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: panel.gap
                            PlasmaComponents.Label {
                                textFormat: Text.PlainText
                                text: i18n("Colors")
                                color: panel.pText
                                font.family: panel.pFont || Kirigami.Theme.defaultFont.family
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                            }
                            Segmented {
                                visible: !panel.app.nativeStyle
                                options: [
                                    { value: "all", text: i18n("All") },
                                    { value: "dark", text: i18n("Dark") },
                                    { value: "light", text: i18n("Light") }
                                ]
                                current: lookPage.themeFilter
                                onPicked: (v) => lookPage.themeFilter = v
                            }
                        }
                        Hint {
                            visible: panel.app.nativeStyle
                            text: i18n("The Plasma style always uses your system's colors and accent. Pick another style to use these.")
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            enabled: !panel.app.nativeStyle
                            opacity: enabled ? 1 : 0.5
                            columns: Math.max(2, lookPage.thumbColumns - 1)
                            columnSpacing: Kirigami.Units.smallSpacing
                            rowSpacing: Kirigami.Units.smallSpacing
                            Repeater {
                                // Follow Plasma fits both lists: it's light or dark with the system.
                                model: Palette.THEME_ORDER.filter(function (k) {
                                    var d = Palette.THEMES[k].dark;
                                    return lookPage.themeFilter === "all" || d === null
                                        || d === (lookPage.themeFilter === "dark");
                                })
                                QQC2.AbstractButton {
                                    id: swatch
                                    required property string modelData
                                    readonly property var th: Palette.THEMES[modelData]
                                    readonly property bool current: panel.app.themeSetting === modelData
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1     // equal columns, whatever the names
                                    implicitHeight: Kirigami.Units.gridUnit * 2.2
                                    hoverEnabled: true
                                    Accessible.name: swatch.th.name
                                    onClicked: Plasmoid.configuration.theme = modelData
                                    background: Rectangle {
                                        radius: panel.pRadius
                                        color: swatch.th.body || panel.app.plasmaBody
                                        border.width: swatch.current ? 2 : panel.pBorder
                                        border.color: swatch.current ? panel.pAccent : panel.tint(swatch.hovered ? 0.45 : 0.15)
                                    }
                                    contentItem: RowLayout {
                                        spacing: Kirigami.Units.smallSpacing
                                        Row {
                                            Layout.leftMargin: Kirigami.Units.smallSpacing
                                            spacing: -Kirigami.Units.gridUnit * 0.15   // overlapping dots, like paint drops
                                            Repeater {
                                                model: ["cpu", "gpu", "memory", "processes"]
                                                Rectangle {
                                                    required property string modelData
                                                    width: Kirigami.Units.gridUnit * 0.6; height: width
                                                    radius: panel.pSharp ? 0 : width / 2
                                                    color: panel.app.accentPair(swatch.modelData, modelData)[0]
                                                    border.width: 1
                                                    border.color: swatch.th.body || panel.app.plasmaBody
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
                                            opacity: swatch.current ? 1 : 0   // keeps its space, so cards never resize
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

            // ================= Personal =================
            Page {
                Section {
                    title: i18n("Uptime")
                    hint: i18n("How long your PC has been on, over a scene. Tip: click the tile to try the next scene.")

                    // Scenes, two to a row.
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Kirigami.Units.smallSpacing
                        rowSpacing: Kirigami.Units.smallSpacing
                        Repeater {
                            model: [
                                { value: "sky",    text: i18n("Sky"),    tip: i18n("Sunrise, day, sunset and stars, with the real moon and weather") },
                                { value: "ticks",  text: i18n("Ticks"),  tip: i18n("Ticks around the edge, a seconds hand going round") },
                                { value: "binary", text: i18n("Binary"), tip: i18n("A binary clock, with 0s and 1s raining behind it") },
                                { value: "terminal", text: i18n("Terminal"), tip: i18n("uptime -p, in a little terminal") },
                                { value: "pulse",  text: i18n("Pulse"),  tip: i18n("A heartbeat that races with the CPU") },
                                { value: "mood",   text: i18n("Mood"),   tip: i18n("A face that gets sleepier the longer you stay up") },
                                { value: "orbit",  text: i18n("Orbit"),  tip: i18n("Planets for minutes, hours, days and weeks") },
                                { value: "aurora", text: i18n("Aurora"), tip: i18n("Soft colors drifting, in your theme") },
                                { value: "image",  text: i18n("Picture"), tip: i18n("Your own picture") },
                                { value: "plain",  text: i18n("Plain"),  tip: i18n("Just the numbers") }
                            ]
                            SButton {
                                required property var modelData
                                Layout.fillWidth: true
                                text: modelData.text
                                tip: modelData.tip
                                checked: panel.app.uptimeOptions.scene === modelData.value
                                onClicked: Plasmoid.configuration.uptimeScene = modelData.value
                            }
                        }
                    }

                    // The picture scene
                    ColumnLayout {
                        visible: panel.app.uptimeOptions.scene === "image"
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        RowLayout {
                            Layout.fillWidth: true
                            SButton {
                                Layout.fillWidth: true
                                iconName: "document-open"
                                text: panel.app.uptimeOptions.image ? i18n("Change picture…") : i18n("Choose a picture…")
                                onClicked: imagePicker.open()
                            }
                            SButton {
                                visible: panel.app.uptimeOptions.image !== ""
                                iconName: "edit-clear"
                                tip: i18n("Remove the picture")
                                onClicked: Plasmoid.configuration.uptimeImage = ""
                            }
                        }
                        Hint {
                            visible: panel.app.uptimeOptions.image !== ""
                            text: decodeURIComponent(panel.app.uptimeOptions.image.replace(/^file:\/\//, ""))
                            elide: Text.ElideMiddle
                            maximumLineCount: 1
                        }
                        SettingRow {
                            label: i18n("Picture")
                            Segmented {
                                options: [{ value: "fill", text: i18n("Fill") }, { value: "fit", text: i18n("Fit") }]
                                current: panel.app.uptimeOptions.fit
                                onPicked: (v) => Plasmoid.configuration.uptimeImageFit = v
                            }
                        }
                        SettingRow {
                            label: i18n("Darken")
                            Segmented {
                                options: [{ value: 0, text: "0" }, { value: 25, text: "25%" }, { value: 50, text: "50%" }, { value: 75, text: "75%" }]
                                current: panel.app.uptimeOptions.dim
                                onPicked: (v) => Plasmoid.configuration.uptimeImageDim = v
                            }
                        }
                        Dialogs.FileDialog {
                            id: imagePicker
                            title: i18n("Choose a picture")
                            nameFilters: [i18n("Pictures (*.png *.jpg *.jpeg *.webp *.gif *.bmp)")]
                            onAccepted: Plasmoid.configuration.uptimeImage = selectedFile.toString()
                        }
                    }

                    SettingRow {
                        label: i18n("Show as")
                        Segmented {
                            options: [{ value: "short", text: "3d 2h" }, { value: "long", text: i18n("Words") },
                                      { value: "clock", text: "74:12:05" }, { value: "days", text: i18n("Days") }]
                            current: panel.app.uptimeOptions.format
                            onPicked: (v) => Plasmoid.configuration.uptimeFormat = v
                        }
                    }
                    SettingRow {
                        label: i18n("Title")
                        SField {
                            width: Kirigami.Units.gridUnit * 9
                            text: Plasmoid.configuration.uptimeLabel
                            placeholder: i18n("Up for")
                            onEdited: (v) => Plasmoid.configuration.uptimeLabel = v.slice(0, 40)
                        }
                    }
                    SettingRow {
                        label: i18n("Font")
                        PlasmaComponents.ComboBox {
                            id: fontBox
                            width: Kirigami.Units.gridUnit * 10
                            readonly property var families: [""].concat(["pixel"], Qt.fontFamilies())
                            model: families.map(function (f) { return f === "" ? i18n("Same as the look") : f === "pixel" ? i18n("Pixel") : f; })
                            currentIndex: Math.max(0, families.indexOf(panel.app.uptimeOptions.font))
                            onActivated: (i) => Plasmoid.configuration.uptimeFont = families[i]
                        }
                    }
                    SettingRow {
                        label: i18n("Weight")
                        Segmented {
                            options: [{ value: "auto", text: i18n("Auto") }, { value: "light", text: i18n("Thin") },
                                      { value: "regular", text: i18n("Normal") }, { value: "bold", text: i18n("Bold") }]
                            current: panel.app.uptimeOptions.weight
                            onPicked: (v) => Plasmoid.configuration.uptimeWeight = v
                        }
                    }
                    SettingRow {
                        label: i18n("Size")
                        Segmented {
                            options: [{ value: "s", text: "S" }, { value: "m", text: "M" }, { value: "l", text: "L" }, { value: "xl", text: "XL" }]
                            current: panel.app.uptimeOptions.size
                            onPicked: (v) => Plasmoid.configuration.uptimeSize = v
                        }
                    }
                    SettingRow {
                        label: i18n("Color")
                        Segmented {
                            options: [{ value: "auto", text: i18n("Auto") }, { value: "light", text: i18n("Light") },
                                      { value: "dark", text: i18n("Dark") }, { value: "accent", text: i18n("Accent") }]
                            current: panel.app.uptimeOptions.color
                            onPicked: (v) => Plasmoid.configuration.uptimeColor = v
                        }
                    }
                    SettingRow {
                        label: i18n("Position")
                        Segmented {
                            options: [{ value: "top", text: i18n("Top") }, { value: "center", text: i18n("Middle") }, { value: "bottom", text: i18n("Bottom") }]
                            current: panel.app.uptimeOptions.align
                            onPicked: (v) => Plasmoid.configuration.uptimeAlign = v
                        }
                    }
                    SettingRow {
                        label: i18n("Show when it started")
                        SToggle {
                            checked: Plasmoid.configuration.uptimeShowBoot
                            onToggled: Plasmoid.configuration.uptimeShowBoot = checked
                        }
                    }
                    SettingRow {
                        label: i18n("Show your record")
                        hint: i18n("The longest your PC has stayed on.")
                        SToggle {
                            checked: Plasmoid.configuration.uptimeShowRecord
                            onToggled: Plasmoid.configuration.uptimeShowRecord = checked
                        }
                    }
                }

                Section {
                    title: i18n("Desk pet")
                    hint: i18n("Use the buttons on the tile to pet, feed, wash, clean up after, walk and play with it. Click the pet to pet it.")
                    SettingRow {
                        label: i18n("Pet")
                        Segmented {
                            options: [{ value: "dog", text: i18n("Poodle") }, { value: "cat", text: i18n("Cat") }]
                            current: panel.app.petKind
                            onPicked: (v) => Plasmoid.configuration.petKind = v
                        }
                    }
                    SettingRow {
                        label: i18n("Name")
                        SField {
                            width: Kirigami.Units.gridUnit * 9
                            text: Plasmoid.configuration.petName
                            placeholder: i18n("No name")
                            onEdited: (v) => Plasmoid.configuration.petName = v.slice(0, 24)
                        }
                    }
                    SettingRow {
                        label: i18n("Size")
                        Segmented {
                            options: [{ value: "s", text: i18n("Small") }, { value: "m", text: i18n("Medium") }, { value: "l", text: i18n("Large") }]
                            current: panel.app.petOptions.size
                            onPicked: (v) => Plasmoid.configuration.petSize = v
                        }
                    }
                    SettingRow {
                        label: i18n("Walks go to")
                        hint: i18n("Mix picks somewhere new each time. Weather goes out in the snow when it's snowing where you are.")
                        PlasmaComponents.ComboBox {
                            width: Kirigami.Units.gridUnit * 8
                            readonly property var values: ["mix", "auto", "grass", "snow", "sand"]
                            model: [i18n("Mix"), i18n("Weather"), i18n("The park"), i18n("The snow"), i18n("The beach")]
                            currentIndex: Math.max(0, values.indexOf(panel.app.petOptions.ground))
                            onActivated: (i) => Plasmoid.configuration.petGround = values[i]
                        }
                    }
                    SettingRow {
                        label: i18n("Care buttons")
                        Segmented {
                            options: [{ value: "always", text: i18n("Always") }, { value: "hover", text: i18n("On hover") }, { value: "off", text: i18n("Off") }]
                            current: panel.app.petOptions.buttons
                            onPicked: (v) => Plasmoid.configuration.petButtons = v
                        }
                    }
                    SettingRow {
                        label: i18n("Needs looking after")
                        hint: i18n("Food, fun, baths and walks run down over time, only while it's on screen. Off: always happy.")
                        SToggle {
                            checked: Plasmoid.configuration.petNeeds
                            onToggled: Plasmoid.configuration.petNeeds = checked
                        }
                    }
                    SettingRow {
                        label: i18n("Furnished room")
                        hint: i18n("Off shows just the pet, like before.")
                        SToggle {
                            checked: Plasmoid.configuration.petRoom
                            onToggled: Plasmoid.configuration.petRoom = checked
                        }
                    }
                    SettingRow {
                        visible: Plasmoid.configuration.petRoom
                        label: i18n("Room")
                        hint: i18n("Nerd: a dark den with a desk setup, game covers and a server rack.")
                        Segmented {
                            options: [{ value: "cozy", text: i18n("Cozy") }, { value: "nerd", text: i18n("Nerd") }]
                            current: panel.app.petOptions.roomStyle
                            onPicked: (v) => Plasmoid.configuration.petRoomStyle = v
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
                        label: i18n("Clocks")
                        Segmented {
                            options: [{ value: "auto", text: i18n("Auto") }, { value: "12", text: i18n("12-hour") }, { value: "24", text: i18n("24-hour") }]
                            current: panel.app.clockFormat
                            onPicked: (v) => Plasmoid.configuration.clockFormat = v === "auto" ? "" : v
                        }
                    }
                    SettingRow {
                        label: i18n("Weather")
                        Segmented {
                            options: [{ value: false, text: "°C" }, { value: true, text: "°F" }]
                            current: panel.app.weatherFahrenheit
                            onPicked: (v) => Plasmoid.configuration.weatherUnit = v ? "f" : "c"
                        }
                    }
                    SettingRow {
                        label: i18n("PC temperatures")
                        Segmented {
                            options: [{ value: false, text: "°C" }, { value: true, text: "°F" }]
                            current: panel.app.useFahrenheit
                            onPicked: (v) => Plasmoid.configuration.sensorUnit = v ? "f" : "c"
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

                // What's missing on this system, and how to get it.
                Section {
                    id: sysCheck
                    title: i18n("System check")
                    readonly property var specs: panel.app.specs
                    readonly property bool helperOk: specs.cpu !== undefined
                    // Give the sensors a few seconds before calling them missing.
                    readonly property bool sensorsOk: panel.app.memTotal.value > 0 || panel.app.tick < 5
                    readonly property var missing: specs.check ? specs.check.missing : []
                    readonly property bool allGood: helperOk && sensorsOk && missing.length === 0

                    Hint {
                        text: sysCheck.specs.system
                            ? i18n("%1 · Plasma %2", sysCheck.specs.system.os, sysCheck.specs.system.plasma || "6")
                            : ""
                        visible: text !== ""
                    }
                    SettingRow {
                        visible: sysCheck.allGood
                        label: i18n("Everything's in place")
                        hint: i18n("All tiles have what they need.")
                    }
                    SettingRow {
                        visible: !sysCheck.helperOk && panel.app.tick > 5
                        label: i18n("Can't read your hardware")
                        hint: i18n("PC specs, fans and battery need python3. Install it, then restart Plasma.")
                    }
                    SettingRow {
                        visible: !sysCheck.sensorsOk
                        label: i18n("No live stats")
                        hint: i18n("CPU, memory and network numbers come from KDE's system monitor service. Install the \"ksystemstats\" package, then restart Plasma.")
                    }
                    Repeater {
                        model: sysCheck.missing
                        SettingRow {
                            required property var modelData
                            label: modelData.purpose
                            hint: modelData.install
                                ? i18n("Needs %1. To add it: %2", modelData.tool, modelData.install)
                                : i18n("Needs %1 from your distribution.", modelData.tool)
                            SButton {
                                visible: modelData.install !== ""
                                text: i18n("Copy")
                                tip: i18n("Copy the install command")
                                onClicked: panel.app.copyToClipboard(modelData.install)
                            }
                        }
                    }
                }

                Section {
                    title: i18n("Updates")
                    SettingRow {
                        label: i18n("Solidget %1", panel.app.version)
                        hint: panel.app.updateAvailable ? i18n("Version %1 is out: see the top of Settings.", panel.app.latestVersion)
                            : Plasmoid.configuration.updateCheck ? i18n("You have the latest version.") : ""
                    }
                    SettingRow {
                        label: i18n("Check for new versions")
                        hint: i18n("Once a day, asks GitHub for the latest version number. Nothing is installed by itself.")
                        SToggle {
                            checked: Plasmoid.configuration.updateCheck
                            onToggled: Plasmoid.configuration.updateCheck = checked
                        }
                    }
                }

                Section {
                    title: i18n("Settings button")
                    SettingRow {
                        label: i18n("Show when hovering")
                        hint: i18n("Off: right-click the widget and pick Configure Solidget to open Settings.")
                        SToggle {
                            checked: Plasmoid.configuration.settingsButton
                            onToggled: Plasmoid.configuration.settingsButton = checked
                        }
                    }
                }

                Section {
                    title: i18n("Privacy")
                    SettingRow {
                        label: i18n("Hide personal info")
                        hint: i18n("Computer name, network name, IP address, Bluetooth device names and weather location. Keep on to share screenshots safely.")
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
