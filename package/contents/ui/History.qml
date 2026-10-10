import QtQuick

// Rolling window of samples for sparklines. Lives in main.qml so history
// survives tiles being hidden, reordered or recreated.
QtObject {
    property int length: 60
    property var values: []

    function push(v) {
        var next = values.slice();
        next.push(isNaN(v) ? 0 : v);
        if (next.length > length)
            next.splice(0, next.length - length);
        values = next;
    }
}
