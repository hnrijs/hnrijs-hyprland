import QtQuick
import QtQuick.Controls
import qs

Slider {
    id: root
    property string icon: ""
    property string caption: ""
    property string displayValue: Math.round(value * 100) + "%"
    property bool compact: false
    from: 0
    to: 1
    implicitHeight: compact ? 28 : 48
    padding: 0
    hoverEnabled: true
    wheelEnabled: true
    focusPolicy: Qt.TabFocus
    background: Rectangle {
        width: root.width
        height: root.height
        radius: height / 2
        color: Style.bg1
        Rectangle {
            width: Math.max(height, parent.width * root.position)
            height: parent.height
            radius: height / 2
            color: root.enabled ? Style.activeFill : Style.bg3
        }
        Text {
            x: 16
            height: parent.height
            width: 24
            text: root.icon
            font.family: Style.iconFontFamily
            font.pixelSize: root.compact ? 14 : 21
            verticalAlignment: Text.AlignVCenter
            color: root.enabled ? Style.activeText : Style.muted
        }
        Item {
            anchors.right: parent.right
            anchors.rightMargin: 16
            height: parent.height
            width: label.implicitWidth
            Text {
                id: label
                height: parent.height
                text: root.displayValue
                font.family: Style.fontFamily
                font.pixelSize: 13
                color: Style.foreground
                verticalAlignment: Text.AlignVCenter
            }
            Item {
                height: parent.height
                width: Math.max(0, Math.min(parent.width, Math.max(root.height, root.width * root.position) - (root.width - 16 - parent.width)))
                clip: true
                Text {
                    height: parent.height
                    text: root.displayValue
                    font: label.font
                    color: root.enabled ? Style.activeText : Style.muted
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
    handle: Item {}
    Accessible.name: caption
}
