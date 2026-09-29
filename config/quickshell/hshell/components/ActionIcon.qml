import QtQuick
import QtQuick.Controls
import qs

AbstractButton {
    id: root
    property string hint: ""
    implicitWidth: 36
    implicitHeight: 36
    hoverEnabled: true
    Accessible.name: hint
    ToolTip.visible: hovered && hint !== ""
    ToolTip.text: hint
    ToolTip.delay: 650
    background: Rectangle {
        radius: height / 2
        color: root.down ? Style.bg3 : root.hovered || root.visualFocus ? Style.bg1 : "transparent"
    }
    contentItem: Text {
        text: root.text
        color: root.enabled ? Style.foreground : Style.muted
        font.family: Style.iconFontFamily
        font.pixelSize: 18
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
