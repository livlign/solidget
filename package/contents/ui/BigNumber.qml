import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Large thin numeral with a small unit, counting smoothly to new values.
Row {
    id: big

    property real value: 0
    property int decimals: 0
    property string text: ""        // overrides the animated number when set
    property string unit: ""
    property real size: Kirigami.Units.gridUnit * 2.5
    property color color: Kirigami.Theme.textColor
    property bool animated: true
    property string family: ""      // the Pixel style's pixel font

    property real shown: value
    Behavior on shown { enabled: big.animated; NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }

    spacing: size * 0.06

    PlasmaComponents.Label {
        id: number
        text: big.text !== "" ? big.text : (isNaN(big.shown) ? "–" : big.shown.toFixed(big.decimals))
        color: big.color
        font.family: big.family || Kirigami.Theme.defaultFont.family
        // Pixel glyphs are much wider than the system font's.
        font.pixelSize: big.family ? big.size * 0.72 : big.size
        font.weight: big.family ? Font.Normal : Font.Light
        font.letterSpacing: big.family ? 0 : -big.size * 0.03
        font.features: { "tnum": 1 }
    }
    PlasmaComponents.Label {
        text: big.unit
        visible: text !== ""
        color: big.color
        opacity: 0.6
        font.pixelSize: (big.family ? big.size * 0.72 : big.size) * 0.38
        font.weight: Font.Normal
        anchors.baseline: number.baseline
    }
}
