import QtQuick
import QtQuick.Controls
import Quickshell
import qs
import qs.components

Column {
    id: root
    spacing: 10
    function takeInitialFocus() {
        query.forceActiveFocus();
    }
    Field {
        id: query
        width: parent.width
        placeholderText: "Search emoji…"
        Component.onCompleted: forceActiveFocus()
    }
    GridView {
        id: grid
        width: parent.width
        height: Math.min(350, Math.ceil(count / Math.max(1, Math.floor(width / cellWidth))) * cellHeight)
        cellWidth: 50
        cellHeight: 50
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Emoji.entries.filter(e => (e[0] + " " + e[1]).toLowerCase().includes(query.text.toLowerCase()))
        ScrollBar.vertical: ScrollBar {}
        delegate: PillButton {
            required property var modelData
            width: 46
            height: 46
            text: modelData[0]
            font.family: "Noto Color Emoji"
            font.pixelSize: 27
            Accessible.name: modelData[1]
            onClicked: {
                Quickshell.execDetached(["wl-copy", "--", modelData[0]]);
                ShellState.close();
            }
        }
    }
    BodyText {
        visible: grid.count === 0
        text: "No matching emoji"
        color: Style.muted
    }
}
