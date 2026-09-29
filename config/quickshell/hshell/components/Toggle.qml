import QtQuick
import QtQuick.Controls
import qs

Switch {
    id: root
    implicitWidth: 50
    implicitHeight: 44
    padding: 0
    indicator: Rectangle {
        anchors.centerIn: parent
        width: 46
        height: 26
        radius: 13
        color: root.checked ? Style.foreground : Style.bg3
        Rectangle {
            x: root.checked ? 23 : 3
            y: 3
            width: 20
            height: 20
            radius: 10
            color: root.checked ? Style.bg0 : Style.muted
            Behavior on x {
                NumberAnimation {
                    duration: 130
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
    contentItem: Item {}
}
