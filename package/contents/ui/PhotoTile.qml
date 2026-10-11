import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Bing's image of the day, edge to edge, with its title and credit.
GlassTile {
    id: tile
    required property var app

    property string imageUrl: ""
    property string caption: ""
    property string credit: ""
    property string link: ""
    property string loadedDay: ""

    showHeader: false
    accent: app.accent("photo")
    accent2: app.accent2("photo")
    level: 0.2

    function refresh() {
        var day = Qt.formatDate(new Date(), "yyyy-MM-dd");
        if (day === loadedDay && imageUrl) return;
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr.status !== 200) return;
            try {
                var img = JSON.parse(xhr.responseText).images[0];
                // Only a plain path on bing.com ("@host/..." would turn the URL into another host).
                if (!/^\/[A-Za-z0-9_.?=&%\/-]+$/.test(img.urlbase || "")) return;
                // Full HD is plenty for a tile.
                tile.imageUrl = "https://www.bing.com" + img.urlbase + "_1920x1080.jpg";
                tile.caption = String(img.title || "").slice(0, 120);
                var c = String(img.copyright || "").slice(0, 200);
                var open = c.lastIndexOf("(");
                tile.credit = open > 0 ? c.slice(open + 1, -1) : "";
                if (!tile.caption) tile.caption = open > 0 ? c.slice(0, open).trim() : c;
                var link = img.copyrightlink || "";
                tile.link = /^https:\/\/[^\s"']+$/.test(link) ? link : "";
                tile.loadedDay = day;
            } catch (e) {}
        };
        xhr.open("GET", "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=" + Qt.locale().name.replace("_", "-"));
        xhr.send();
    }
    Component.onCompleted: refresh()
    // Check hourly; only fetches again on a new day.
    Connections { target: app; function onTickChanged() { if (app.tick % 3600 === 0) tile.refresh(); } }

    // The photo fills the whole card (masked to its rounded shape), with the
    // caption on a dark gradient at the bottom.
    Item {
        id: frame
        parent: tile
        anchors.fill: parent
        anchors.margins: tile.bevelOn ? tile.bevelW : 0
        z: 1

        Rectangle {
            id: mask
            anchors.fill: parent
            radius: tile.radius
            visible: false
            layer.enabled: true
        }
        Image {
            id: photo
            anchors.fill: parent
            source: tile.imageUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.veryLongDuration } }
            layer.enabled: tile.radius > 0
            layer.effect: MultiEffect { maskEnabled: true; maskSource: mask }
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * 0.45
            radius: tile.radius
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.75) }
            }
        }

        PlasmaComponents.Label {
            textFormat: Text.PlainText
            visible: photo.status !== Image.Ready
            anchors.centerIn: parent
            text: tile.imageUrl ? i18n("Loading photo…") : i18n("Photo of the day needs an internet connection")
            opacity: 0.6
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: tile.pad
            spacing: 0
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: tile.caption
                textFormat: Text.PlainText   // text from outside; never render it as HTML
                color: "white"
                font.pixelSize: Math.max(Kirigami.Theme.defaultFont.pixelSize, tile.u * 1.05)
                font.weight: Font.DemiBold
                font.family: tile.numberFamily || Kirigami.Theme.defaultFont.family
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: tile.credit
                textFormat: Text.PlainText
                visible: text !== ""
                color: "white"
                opacity: 0.7
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, tile.u * 0.7)
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: tile.link !== "" && !app.editing
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: Qt.openUrlExternally(tile.link)
        }
    }
}
