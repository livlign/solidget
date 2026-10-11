import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Pomodoro-style focus timer; state lives in main.qml.
GlassTile {
    id: tile
    required property var app

    readonly property bool onBreak: app.focusPhase === "break"
    readonly property real progress: 1 - app.focusRemaining / Math.max(1, app.focusLength)
    readonly property string clock: Math.floor(app.focusRemaining / 60) + ":" + ("0" + app.focusRemaining % 60).slice(-2)

    title: onBreak ? i18n("Break") : i18n("Focus")
    subtitle: app.focusDone > 0 ? i18np("%1 session", "%1 sessions", app.focusDone) : ""
    accent: onBreak ? app.accent("calendar") : app.accent("focus")
    accent2: onBreak ? app.accent2("calendar") : app.accent2("focus")
    level: app.focusRunning ? 0.7 : 0.25

    component RoundButton: QQC2.AbstractButton {
        id: rb
        property string iconName
        property string tip
        implicitWidth: Math.max(Kirigami.Units.iconSizes.medium, tile.u * 2.2)
        implicitHeight: implicitWidth
        hoverEnabled: true
        QQC2.ToolTip.text: tip
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        background: Rectangle {
            radius: tile.radius > 0 ? width / 2 : 0
            color: rb.hovered ? tile.accent : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
        }
        contentItem: Kirigami.Icon {
            source: rb.iconName
            isMask: true
            color: rb.hovered ? "#ffffff" : Kirigami.Theme.textColor
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: implicitWidth
        }
    }

    GridLayout {
        anchors.fill: parent
        columns: tile.wide ? 2 : 1
        columnSpacing: tile.u
        rowSpacing: tile.u * 0.4

        RingGauge {
            id: ring
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: tile.u * 4
            value: tile.progress * 100
            accent: tile.accent
            accent2: tile.accent2
            glow: tile.glowOn
            roundCaps: tile.look ? tile.look.roundCaps : true
            blocks: tile.look ? tile.look.meter === "blocks" : false
            BigNumber {
                anchors.centerIn: parent
                family: tile.numberFamily
                text: tile.clock
                size: ring.width * 0.2
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: tile.u * 0.5
            RoundButton {
                iconName: app.focusRunning ? "media-playback-pause" : "media-playback-start"
                tip: app.focusRunning ? i18n("Pause") : i18n("Start")
                onClicked: app.focusToggle()
            }
            RoundButton { iconName: "media-skip-forward"; tip: tile.onBreak ? i18n("Skip break") : i18n("Finish now"); onClicked: app.focusSkip() }
            RoundButton { iconName: "view-refresh"; tip: i18n("Reset"); onClicked: app.focusReset() }
        }
    }
}
