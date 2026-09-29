import QtQuick
import QtQuick.Controls
import Quickshell
import qs
import qs.components

Column {
    id: root
    property var selected: Elements.entries[0]
    spacing: 10
    Field {
        id: search
        width: parent.width
        placeholderText: "Search..."
    }
    BodyText {
        width: parent.width
        height: 32
        verticalAlignment: Text.AlignVCenter
        text: root.selected.number + "  ·  " + root.selected.symbol + "  ·  " + root.selected.name
        font.pixelSize: 18
    }
    Row {
        width: parent.width
        spacing: 8
        PillButton {
            id: searchElement
            width: 44
            text: "󰍉"
            onClicked: {
                ShellState.close();
                Quickshell.execDetached(["xdg-open", Preferences.searchUrl("Google", root.selected.name + " chemical element")]);
            }
        }
        Item {
            width: Math.max(0, parent.width - searchElement.width - 60)
            height: 44
        }
        PillButton {
            width: 44
            text: "󰆏"
            Accessible.name: "Copy Element Symbol"
            onClicked: Quickshell.execDetached(["wl-copy", "--", root.selected.symbol])
        }
    }
    ScrollView {
        width: parent.width
        height: 432
        contentWidth: Math.max(810, width)
        Item {
            width: Math.max(810, root.width)
            height: 432
            Repeater {
                model: Elements.entries
                delegate: Rectangle {
                    required property var modelData
                    x: (modelData.col - 1) * (parent.width / 18)
                    y: (modelData.row - 1) * 42
                    width: parent.width / 18 - 4
                    height: 38
                    radius: 10
                    color: root.selected.number === modelData.number ? Style.primary : Style.bg1
                    readonly property bool matched: !search.text || String(modelData.name + modelData.symbol + modelData.number).toLowerCase().includes(search.text.toLowerCase())
                    Text {
                        x: 4
                        y: 2
                        text: modelData.number
                        font.family: Style.fontFamily
                        font.pixelSize: 8
                        color: root.selected.number === modelData.number ? Style.bg0 : Style.muted
                    }
                    BodyText {
                        anchors.centerIn: parent
                        text: modelData.symbol
                        color: root.selected.number === modelData.number ? Style.bg0 : parent.matched ? Style.foreground : Style.bg3
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.selected = modelData
                    }
                }
            }
        }
    }
    BodyText {
        width: parent.width
        visible: root.width < 810
        text: "Scroll horizontally to see all groups."
        color: Style.muted
    }
}
