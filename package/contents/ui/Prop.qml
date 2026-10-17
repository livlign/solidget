import QtQuick
import "../code/props.js" as Props

// One picture from images/props.png (see tools/props.py), scaled up by `px`
// with sharp pixels. Bottom-center is the natural anchor for things that
// stand on the floor: set `foot` and `floor` instead of x/y.
Item {
    id: prop
    property string name
    property real px: 2
    property bool flip: false
    readonly property var at: Props.AT[name] || [0, 0, 1, 1]

    width: at[2] * px
    height: at[3] * px
    clip: true

    Image {
        source: "../images/props.png"
        smooth: false
        width: Props.SHEET[0] * prop.px
        height: Props.SHEET[1] * prop.px
        x: -prop.at[0] * prop.px
        y: -prop.at[1] * prop.px
    }
    transform: Scale { origin.x: prop.width / 2; xScale: prop.flip ? -1 : 1 }
}
