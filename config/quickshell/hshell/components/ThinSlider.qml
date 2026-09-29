import QtQuick
import QtQuick.Controls
import qs

Slider {
    id: root
    property string icon: ""
    property string caption: ""
    property string displayValue: Math.round(value * 100) + "%"
    property bool compact: true
    from: 0
    to: 1
    implicitHeight: 28
    leftPadding: icon ? 32 : 0
    rightPadding: displayValue ? 46 : 0
    wheelEnabled: true
    background: Rectangle {
        x: root.leftPadding
        y: (root.height - height) / 2
        width: root.availableWidth
        height: 5
        radius: 3
        color: Style.bg3
        Rectangle {
            width: parent.width * root.position
            height: parent.height
            radius: 3
            color: Style.foreground
        }
    }
    handle: Rectangle {
        x: root.leftPadding + root.position * root.availableWidth - width / 2
        y: (root.height - height) / 2
        width: root.pressed ? 12 : 0
        height: width
        radius: width / 2
        color: Style.foreground
    }
    Text {
        height: parent.height
        text: root.icon
        font.family: Style.iconFontFamily
        font.pixelSize: 18
        color: Style.foreground
        verticalAlignment: Text.AlignVCenter
    }
    Text {
        anchors.right: parent.right
        height: parent.height
        text: root.displayValue
        font.family: Style.fontFamily
        font.pixelSize: 12
        color: Style.foreground
        verticalAlignment: Text.AlignVCenter
    }
    Accessible.name: caption
}
