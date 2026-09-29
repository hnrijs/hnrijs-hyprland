import QtQuick
import qs

Item {
    id: root
    property bool expanded: false
    property real viewHeight: 120
    readonly property real historyHeight: latest.implicitHeight
    implicitHeight: latest.implicitHeight
    height: viewHeight
    NotificationCard {
        id: latest
        width: parent.width
        notification: NotificationCenter.current
    }
}
