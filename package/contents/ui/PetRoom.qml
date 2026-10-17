import QtQuick
import QtQuick.Shapes

// The pet's room, in perspective: a ceiling, two side walls and the floor
// run back to a back wall with a big window. Furniture stands against the
// back wall, seen from the front, on the line where wall meets floor, so
// everything sits where it would in a real room. The window shows the real
// sky and weather.
//   style "nerd": a dark den. Bed with shelves above on the left, a desk
//     with two monitors and a gaming chair on the right, a city outside
//     (lit windows and neon after dark).
//   style "cozy": warm wallpaper and a honey floor. A bookshelf and plant
//     on the left, an armchair, lamp, picture and clock on the right, the
//     dog's own bed on the floor, hills and a cottage outside.
// Narrow tiles leave out what doesn't fit. Everything is drawn at the pet's
// scale (`px`); `spots` are where things are, as fractions of the width.
Item {
    id: room
    property real px: 2
    property real floorY: height * 0.6       // where the back wall meets the floor
    property real standY: height              // where things against the back wall stand
    property real footBack: standY            // the pet's feet at depth 0 ...
    property real footFront: height           // ... and at depth 1
    property var sky: null                    // Sky.at(...) for now
    property var app: null
    property bool bowlFull: false
    property bool showTub: false
    property string style: "nerd"             // nerd | cozy
    property int tick: 0
    property color accent: "#38bdf8"
    property date now: new Date()
    property string pixelFont: ""

    readonly property bool nerd: style === "nerd"
    readonly property bool night: !!sky && sky.dark
    readonly property string phase: sky ? sky.phase : "day"

    // ---- Geometry ----
    readonly property real sideW: width * 0.11
    readonly property real ceilH: floorY * 0.15
    readonly property real backL: sideW
    readonly property real backR: width - sideW
    readonly property real winW: Math.max(px * 26, (backR - backL) * 0.36)
    readonly property real winH: (floorY - ceilH) * 0.58
    readonly property real winX: width / 2 - winW / 2
    readonly property real winY: ceilH + (floorY - ceilH) * 0.13
    readonly property real curtain: px * 5
    // The wall either side of the window (and its curtains).
    readonly property real leftL: backL + px * 2
    readonly property real leftR: winX - curtain - px * 3
    readonly property real rightL: winX + winW + curtain + px * 3
    readonly property real rightR: backR - px * 2
    readonly property real sideSpace: leftR - leftL
    readonly property bool roomy: sideSpace >= px * 24

    // Floor edges at a height on screen: the floor narrows toward the back.
    function floorLeft(y) {
        var f = Math.max(0, Math.min(1, (y - floorY) / Math.max(1, height - floorY)));
        return sideW * (1 - f);
    }
    function floorRight(y) { return width - floorLeft(y); }
    function at(d) { return footBack + (footFront - footBack) * d; }

    readonly property real leftMid: (leftL + leftR) / 2 / width
    readonly property real rightMid: (rightL + rightR) / 2 / width
    readonly property var spots: ({
        bed: nerd ? leftMid : 0.24, bowl: 0.44, water: 0.53, tub: 0.5,
        basket: nerd ? rightMid : leftMid, chair: rightMid, desk: rightMid,
        window: 0.5, door: 1
    })
    // Where the pet naps (the nerd room's bed is against the back wall; the
    // dog bed is on the floor), and it goes out through the front.
    readonly property real bedDepth: nerd ? 0 : 0.6
    readonly property real bedRaise: nerd ? 13 * px : 3 * px
    // The door is in the right-hand wall, near the back: the pet goes to
    // the floor in front of it (the far right, at this depth).
    readonly property real doorT0: 0.08          // along the side wall: 0 = back corner, 1 = front
    readonly property real doorT1: 0.48
    function sideX(t) { return backR + (width - backR) * t; }
    function sideFloor(t) { return floorY + (height - floorY) * t; }
    function sideCeil(t) { return ceilH * (1 - t); }
    function doorTop(t) { return sideFloor(t) - (sideFloor(t) - sideCeil(t)) * 0.74; }
    readonly property real doorDepth: Math.max(0, Math.min(1, (sideFloor((doorT0 + doorT1) / 2) - footBack) / Math.max(1, footFront - footBack)))
    function leftOf(name, w) { return spots[name] * width - w / 2; }

    // ---- Colors ----
    readonly property var pal: nerd ? ({
        ceiling: "#262a38", side: "#1c1f2b", back: "#232736", backLine: "#2a2f40",
        floor: "#2b231e", boards: "#1f1914", skirting: "#15171f", lower: "#1f2230",
        frame: "#141720", curtain: "#1f3b46", curtainFold: "#18303a", sill: "#1a1d27", rug: ["#1d4a50", "#2f6f73", "#4fa3a0"]
    }) : ({
        ceiling: "#efe0c8", side: "#d9be9b", back: "#ecd3b2", backLine: "#e2c49e",
        floor: "#b98256", boards: "#9b6a43", skirting: "#7a4f33", lower: "#b98a63",
        frame: "#efe6d6", curtain: "#d99a7e", curtainFold: "#b8705a", sill: "#d9ccb4", rug: ["#b8705a", "#efe0c8", "#9fb79a"]
    })

    // ---- The shell ----
    component Quad: Shape {
        id: quad
        property color fill
        property var pts: []
        anchors.fill: parent
        antialiasing: false
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: quad.fill
            PathPolyline { path: quad.pts }
        }
    }
    Rectangle {     // back wall
        x: room.backL; y: room.ceilH
        width: room.backR - room.backL; height: room.floorY - room.ceilH
        color: room.pal.back
        Repeater {  // stripes (cozy) or panels (nerd)
            model: room.nerd ? 6 : Math.ceil(parent.width / (room.px * 12))
            Rectangle {
                required property int index
                x: room.nerd ? parent.width * index / 6 : index * room.px * 12
                width: room.nerd ? Math.max(1, room.px / 2) : room.px * 6
                height: parent.height
                color: room.pal.backLine
                opacity: room.nerd ? 1 : 0.6
            }
        }
    }
    Rectangle {     // cozy: wood panelling on the lower wall
        visible: !room.nerd
        x: room.backL; y: room.floorY - (room.floorY - room.ceilH) * 0.3
        width: room.backR - room.backL; height: (room.floorY - room.ceilH) * 0.3
        color: room.pal.lower
        Rectangle { width: parent.width; height: room.px * 1.5; color: "#8c5f3f" }
    }
    Rectangle {     // nerd: an LED strip where wall meets ceiling
        visible: room.nerd
        x: room.backL; y: room.ceilH
        width: room.backR - room.backL; height: Math.max(1, room.px * 0.7)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: room.accent }
            GradientStop { position: 0.5; color: "#c084fc" }
            GradientStop { position: 1; color: "#f472b6" }
        }
    }
    Rectangle {     // skirting
        x: room.backL; y: room.floorY - room.px * 2
        width: room.backR - room.backL; height: room.px * 2
        color: room.pal.skirting
    }
    Quad { fill: room.pal.ceiling; pts: [Qt.point(0, 0), Qt.point(room.width, 0), Qt.point(room.backR, room.ceilH), Qt.point(room.backL, room.ceilH)] }
    Quad { fill: room.pal.side; pts: [Qt.point(0, 0), Qt.point(room.backL, room.ceilH), Qt.point(room.backL, room.floorY), Qt.point(0, room.height)] }
    Quad { fill: room.pal.side; pts: [Qt.point(room.width, 0), Qt.point(room.backR, room.ceilH), Qt.point(room.backR, room.floorY), Qt.point(room.width, room.height)] }
    Quad { fill: room.pal.floor; pts: [Qt.point(room.backL, room.floorY), Qt.point(room.backR, room.floorY), Qt.point(room.width, room.height), Qt.point(0, room.height)] }
    Shape {         // floorboards, running to the back
        anchors.fill: parent
        antialiasing: false
        ShapePath {
            strokeColor: room.pal.boards
            strokeWidth: Math.max(1, room.px / 2)
            fillColor: "transparent"
            PathMultiline {
                paths: {
                    var out = [], n = 9;
                    for (var i = 1; i < n; i++)
                        out.push([Qt.point(room.backL + (room.backR - room.backL) * i / n, room.floorY),
                                  Qt.point(room.width * i / n, room.height)]);
                    return out;
                }
            }
        }
    }
    // The door, in perspective on the right wall: frame, panel, knob.
    Quad {
        fill: room.nerd ? "#11131b" : "#8c5f3f"
        pts: [Qt.point(room.sideX(room.doorT0), room.doorTop(room.doorT0) - room.px), Qt.point(room.sideX(room.doorT1), room.doorTop(room.doorT1) - room.px * 1.5),
              Qt.point(room.sideX(room.doorT1), room.sideFloor(room.doorT1)), Qt.point(room.sideX(room.doorT0), room.sideFloor(room.doorT0))]
    }
    Quad {
        readonly property real a: room.doorT0 + 0.025
        readonly property real b: room.doorT1 - 0.025
        fill: room.nerd ? "#2a3040" : "#b98256"
        pts: [Qt.point(room.sideX(a), room.doorTop(a) + room.px), Qt.point(room.sideX(b), room.doorTop(b) + room.px),
              Qt.point(room.sideX(b), room.sideFloor(b)), Qt.point(room.sideX(a), room.sideFloor(a))]
    }
    Quad {      // a panel on the door
        readonly property real a: room.doorT0 + 0.07
        readonly property real b: room.doorT1 - 0.07
        readonly property real f0: 0.15
        readonly property real f1: 0.45
        function along(t, f) { return room.doorTop(t) + (room.sideFloor(t) - room.doorTop(t)) * f; }
        fill: room.nerd ? "#232838" : "#a77a55"
        pts: [Qt.point(room.sideX(a), along(a, f0)), Qt.point(room.sideX(b), along(b, f0)), Qt.point(room.sideX(b), along(b, f1)), Qt.point(room.sideX(a), along(a, f1))]
    }
    Rectangle {     // knob
        readonly property real t: room.doorT1 - 0.06
        x: room.sideX(t) - width / 2
        y: room.doorTop(t) + (room.sideFloor(t) - room.doorTop(t)) * 0.55
        width: room.px * 1.5; height: room.px * 1.5; radius: width / 2
        color: room.nerd ? "#9aa5b1" : "#f5c84c"
    }

    // A rug in perspective: narrower at the back, a border and a middle band.
    readonly property real rugBack: at(0.35)
    readonly property real rugFront: at(0.85)
    function rugX(y, f) {      // f: -1 (left edge) .. 1 (right edge)
        var half = (width * 0.22) * (0.75 + 0.25 * (y - rugBack) / Math.max(1, rugFront - rugBack));
        return width / 2 + f * half;
    }
    Quad { fill: room.pal.rug[0]; pts: [Qt.point(room.rugX(room.rugBack, -1), room.rugBack), Qt.point(room.rugX(room.rugBack, 1), room.rugBack), Qt.point(room.rugX(room.rugFront, 1), room.rugFront), Qt.point(room.rugX(room.rugFront, -1), room.rugFront)] }
    Quad {
        readonly property real t: room.rugBack + room.px * 2
        readonly property real b: room.rugFront - room.px * 2
        fill: room.pal.rug[1]
        pts: [Qt.point(room.rugX(t, -0.88), t), Qt.point(room.rugX(t, 0.88), t), Qt.point(room.rugX(b, 0.88), b), Qt.point(room.rugX(b, -0.88), b)]
    }
    Quad {
        readonly property real t: room.rugBack + (room.rugFront - room.rugBack) * 0.38
        readonly property real b: room.rugBack + (room.rugFront - room.rugBack) * 0.62
        fill: room.pal.rug[2]
        pts: [Qt.point(room.rugX(t, -0.88), t), Qt.point(room.rugX(t, 0.88), t), Qt.point(room.rugX(b, 0.88), b), Qt.point(room.rugX(b, -0.88), b)]
    }

    // ---- The window ----
    Rectangle {
        x: room.winX - room.px * 2; y: room.winY - room.px * 2
        width: room.winW + room.px * 4; height: room.winH + room.px * 4
        color: room.pal.frame
    }
    Item {
        x: room.winX; y: room.winY
        width: room.winW; height: room.winH
        clip: true
        UptimeSky {
            anchors.fill: parent
            app: room.app
            now: room.now
            tick: room.tick
            landscape: !room.nerd       // hills and a cottage for the cozy room
            PetCity {
                visible: room.nerd
                anchors.fill: parent
                anchors.topMargin: parent.height * 0.25
                sky: room.sky
                tick: room.tick
                px: Math.max(1, Math.round(room.px * 0.67))
                pixelFont: room.pixelFont
            }
        }
    }
    Rectangle { x: room.winX + room.winW / 2 - width / 2; y: room.winY; width: room.px * 1.5; height: room.winH; color: room.pal.frame }
    Rectangle { x: room.winX; y: room.winY + room.winH * 0.45; width: room.winW; height: room.px * 1.5; color: room.pal.frame }
    Rectangle {
        x: room.winX - room.px * 3; y: room.winY + room.winH + room.px * 2
        width: room.winW + room.px * 6; height: room.px * 2
        color: room.pal.sill
    }
    Rectangle {     // curtain rail
        x: room.winX - room.curtain - room.px * 2; y: room.winY - room.px * 4
        width: room.winW + room.curtain * 2 + room.px * 4; height: room.px
        color: room.nerd ? "#0e1016" : "#8c5f3f"
    }
    Repeater {
        model: [-1, 1]
        Rectangle {
            required property int modelData
            x: modelData < 0 ? room.winX - room.curtain - room.px : room.winX + room.winW + room.px
            y: room.winY - room.px * 3
            width: room.curtain; height: room.winH + room.px * 6
            color: room.pal.curtain
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    x: room.px * (1 + index * 2)
                    width: Math.max(1, room.px / 2); height: parent.height
                    color: room.pal.curtainFold
                }
            }
        }
    }

    // ======== The nerd room's things ========
    Item {
        anchors.fill: parent
        visible: room.nerd
        // Left: shelves above the bed, the bed against the wall.
        Prop {
            name: "shelf_wall"; px: room.px
            // Above the bed's headboard, with a little gap.
            visible: room.roomy && y > room.ceilH + room.px
            x: room.leftL + (room.sideSpace - width) / 2
            y: Math.min(room.winY, room.standY - 24 * room.px - height - room.px * 2)
        }
        Prop {
            name: "bed_front"; px: room.px
            visible: room.sideSpace >= width
            x: room.spots.bed * room.width - width / 2
            y: room.standY - height
        }
        // Right: a poster, the desk with two monitors, the chair in front.
        Prop {
            name: "poster_invader"; px: room.px
            // Only where it clears the monitors on the desk below.
            visible: room.roomy && y + height + room.px < desk.y - room.px * 10
            x: room.rightL + (room.sideSpace - width) / 2
            y: room.winY
        }
        Item {
            id: desk
            visible: room.sideSpace >= width
            width: 28 * room.px; height: 20 * room.px
            x: room.spots.desk * room.width - width / 2
            y: room.standY - height
            Prop { name: "desk_front"; px: room.px }
            // Two monitors, switched off: dark glass with a faint sheen.
            component Screen: Item {
                id: scr
                width: room.px * 12; height: room.px * 10
                Rectangle { anchors.fill: parent; color: "#0d0f15"; radius: room.px * 0.5 }
                Rectangle {
                    x: room.px; y: room.px
                    width: scr.width - room.px * 2; height: room.px * 7
                    color: "#07080c"
                    clip: true
                    Rectangle {     // a soft reflection across the glass
                        x: parent.width * 0.15; y: -parent.height * 0.4
                        width: parent.width * 0.22; height: parent.height * 2
                        rotation: 30
                        color: "#ffffff"
                        opacity: 0.05
                    }
                }
                Rectangle { x: scr.width / 2 - room.px; y: scr.height; width: room.px * 2; height: room.px * 2; color: "#2a2f3d" }
            }
            Screen { x: room.px * 1; y: -room.px * 9 }
            Screen { x: room.px * 15; y: -room.px * 9 }
        }
        Prop {
            name: "chair_back"; px: room.px
            visible: desk.visible
            // Pulled out to the right, so the screens show.
            x: desk.x + desk.width * 0.78 - width / 2
            y: room.at(0.22) - height
        }
    }

    // ======== The cozy room's things ========
    Item {
        anchors.fill: parent
        visible: !room.nerd
        // Left: bookshelf and a plant.
        Prop {
            id: shelf
            name: "bookshelf"; px: room.px
            visible: room.sideSpace >= width
            x: room.leftL + (room.sideSpace - width) / 2 - (plant.visible ? room.px * 6 : 0)
            y: room.standY - height
        }
        Prop {
            id: plant
            name: "plant"; px: room.px
            visible: room.sideSpace >= width + shelf.width + room.px * 2
            x: shelf.x + shelf.width + room.px
            y: room.standY - height
        }
        // Right: a picture and a clock, the armchair with a lamp beside it.
        Prop {
            name: "picture"; px: room.px
            visible: room.roomy
            x: room.rightL + (room.sideSpace - width) / 2
            y: room.winY + room.px * 2
        }
        Prop {
            name: "clock"; px: room.px
            visible: room.roomy && room.winY > height + room.px * 2
            x: room.rightL + (room.sideSpace - width) / 2 + room.px * 4
            y: room.winY - height - room.px
        }
        Prop {
            id: armchair
            name: "armchair"; px: room.px
            visible: room.sideSpace >= width
            x: room.rightMid * room.width - width / 2 - (lamp.visible ? room.px * 5 : 0)
            y: room.standY - height
        }
        Prop {
            id: lamp
            name: "lamp"; px: room.px
            visible: room.sideSpace >= width + armchair.width + room.px * 2
            x: armchair.x + armchair.width + room.px
            y: room.standY - height
        }
        // On the floor: the dog's bed and a toy basket.
        Prop {
            name: "bed"; px: room.px
            x: Math.max(room.floorLeft(room.at(room.bedDepth)) + room.px, room.spots.bed * room.width - width / 2)
            y: room.at(room.bedDepth) - height + room.px * 2
        }
        Prop {
            name: "basket"; px: room.px
            visible: room.roomy
            x: room.floorRight(room.at(0.5)) - width - room.px * 6
            y: room.at(0.5) - height
        }
    }

    // Shared: bowls, and the tub at bath time.
    Prop { name: room.bowlFull ? "bowl_full" : "bowl"; px: room.px; x: room.leftOf("bowl", width); y: room.standY - height }
    Prop { name: "water"; px: room.px; x: room.leftOf("water", width); y: room.standY - height }
    Prop { name: "tub"; px: room.px; visible: room.showTub; x: room.leftOf("tub", width); y: room.standY - height + room.px * 2; z: 2 }

    // ---- Time of day ----
    // Sunrise and sunset: a little golden. Night: a little dimmer and bluer.
    Rectangle {
        anchors.fill: parent
        visible: room.phase === "dawn" || room.phase === "dusk" || room.night
        color: room.night ? "#141238" : "#ff9a5a"
        opacity: room.night ? (room.nerd ? 0.22 : 0.3) : 0.12
        z: 3
    }
}
