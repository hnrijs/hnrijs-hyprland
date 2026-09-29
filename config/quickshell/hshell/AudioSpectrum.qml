import QtQuick
import Quickshell.Io
import qs

Item {
    id: root
    property bool active: false
    property bool subscribed: false
    function sync() {
        if (active === subscribed)
            return;
        Cava.consumers += active ? 1 : -1;
        subscribed = active;
    }
    onActiveChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: if (subscribed)
        Cava.consumers = Math.max(0, Cava.consumers - 1)
    readonly property var levels: Cava.levels
    Row {
        anchors.fill: parent
        spacing: 3
        Repeater {
            model: 5
            delegate: Rectangle {
                required property int index
                width: Math.max(2, (root.width - 12) / 5)
                height: Math.max(2, root.height * root.levels[index * 2] / 100)
                Behavior on height {
                    NumberAnimation {
                        duration: 32
                        easing.type: Easing.Linear
                    }
                }
                y: root.height - height
                radius: width / 2
                color: Style.primary
            }
        }
    }
}
