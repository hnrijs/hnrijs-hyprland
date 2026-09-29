import QtQuick
import QtQuick.Controls
import qs

Button {
    id: root
    property string detail: ""
    property bool selected: false
    implicitWidth: 150
    implicitHeight: detail ? 72 : 44
    padding: width < 60 ? 5 : 12
    hoverEnabled: true
    ToolTip.visible: hovered && /apply|discard/i.test(text)
    ToolTip.text: text
    ToolTip.delay: 500
    focusPolicy: Qt.TabFocus
    font.family: Style.iconFontFamily
    font.pixelSize: 14
    background: Rectangle {
        radius: root.detail ? 20 : height / 2
        color: root.selected ? Style.activeFill : root.down ? Style.bg3 : root.hovered ? Style.bg2 : Style.bg1
        border.width: root.visualFocus ? 2 : 0
        border.color: Style.primary
        Behavior on color {
            ColorAnimation {
                duration: 130
            }
        }
    }
    contentItem: Item {
        Text {
            width: parent.width
            height: 22
            y: root.detail ? Math.max(0, (parent.height - 42) / 2) : (parent.height - height) / 2
            text: root.text
            font: root.font
            color: root.selected ? Style.activeText : Style.foreground
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        Text {
            visible: root.detail !== ""
            width: parent.width
            height: 20
            y: Math.max(0, (parent.height - 42) / 2) + 23
            text: root.detail
            font.family: root.font.family
            font.pixelSize: 12
            color: root.selected ? Style.activeText : Style.muted
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
}
