import QtQuick
import QtQuick.Controls
import qs

CheckBox {
    id: root
    implicitHeight: 44
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize
    indicator: Rectangle {
        x: 0
        y: (root.height - height) / 2
        width: 28
        height: 28
        radius: 14
        color: root.checked ? Style.primary : Style.bg1
        border.width: root.visualFocus ? 2 : 1
        border.color: Style.primary
        Text {
            anchors.centerIn: parent
            text: root.checked ? "✓" : ""
            color: Style.bg0
            font.pixelSize: 18
        }
    }
    contentItem: Text {
        text: root.text
        color: Style.foreground
        font: root.font
        leftPadding: 38
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
    }
}
