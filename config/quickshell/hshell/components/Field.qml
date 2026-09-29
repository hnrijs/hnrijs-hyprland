import QtQuick
import QtQuick.Controls
import qs

TextField {
    id: root
    Keys.onEscapePressed: ShellState.dismissInterface()
    implicitHeight: 44
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize
    color: Style.foreground
    placeholderTextColor: Style.muted
    selectByMouse: true
    leftPadding: 14
    rightPadding: 14
    background: Rectangle {
        color: Style.bg1
        radius: 18
        border.width: 1
        border.color: root.activeFocus ? Style.primary : Style.bg3
    }
}
