import QtQuick
import QtQuick.Controls
import qs

Button {
    id: root
    objectName: "control-" + text
    property string symbol: ""
    property string iconSource: ""
    property string detail: ""
    property bool selected: false
    signal secondaryClicked
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.secondaryClicked()
    }
    implicitHeight: 72
    padding: 12
    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    background: Rectangle {
        radius: 23
        color: root.selected ? Style.activeFill : root.hovered ? Style.bg3 : Style.bg1
        border.width: root.visualFocus ? 2 : 0
        border.color: Style.primary
    }
    contentItem: Item {
        Rectangle {
            x: 0
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            height: 38
            radius: 19
            color: root.selected ? Qt.darker(Style.activeFill, 1.12) : Style.bg3
            Image {
                anchors.centerIn: parent
                width: 22
                height: 22
                source: root.iconSource
                fillMode: Image.PreserveAspectFit
            }
            Text {
                visible: root.iconSource === ""
                anchors.centerIn: parent
                text: root.symbol
                font.family: Style.iconFontFamily
                font.pixelSize: 18
                color: root.selected ? Style.activeText : Style.foreground
            }
        }
        Text {
            x: 48
            y: root.detail ? 5 : (parent.height - height) / 2
            width: parent.width - 48
            height: 20
            text: root.text
            font.family: Style.fontFamily
            font.pixelSize: 14
            font.bold: true
            color: root.selected ? Style.activeText : Style.foreground
            elide: Text.ElideRight
        }
        Text {
            x: 48
            y: 27
            width: parent.width - 48
            height: 18
            text: root.detail
            font.family: Style.fontFamily
            font.pixelSize: 11
            color: root.selected ? Style.activeText : Style.muted
            elide: Text.ElideRight
        }
    }
}
