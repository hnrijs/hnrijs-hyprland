import QtQuick
import QtQuick.Controls
import qs

AbstractButton {
    id: root
    implicitWidth: label.implicitWidth + 8
    implicitHeight: 36
    hoverEnabled: true
    Accessible.name: text
    contentItem: Text {
        id: label
        text: root.text
        font.family: Style.fontFamily
        font.pixelSize: 14
        color: root.enabled ? Style.foreground : Style.muted
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Item {}
}
