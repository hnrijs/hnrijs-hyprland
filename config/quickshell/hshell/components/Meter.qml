import QtQuick
import QtQuick.Controls
import qs

ProgressBar {
    id: root
    implicitHeight: 8
    background: Rectangle {
        color: Style.bg1
        radius: 4
    }
    contentItem: Item {
        Rectangle {
            width: root.indeterminate ? parent.width / 3 : parent.width * root.position
            height: parent.height
            radius: 4
            color: Style.primary
        }
    }
}
