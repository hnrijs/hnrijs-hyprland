import QtQuick
import Quickshell
import qs
import qs.components

Flow {
    id: root
    property string kind: "menu"
    spacing: 10
    Repeater {
        model: root.kind === "menu" ? [["settings", "󰒓", "Settings", "System and Interface"], ["tools", "󰛣", "Tools", "Applications and Utilities"]] : ToolRegistry.entries
        delegate: ControlTile {
            required property var modelData
            width: (parent.width - 10) / 2
            symbol: modelData[1]
            text: modelData[2]
            detail: modelData[3]
            onClicked: {
                if (["screen-search", "screen-measure"].includes(modelData[0])) {
                    const name = modelData[0];
                    ShellState.close();
                    Quickshell.execDetached(["bash", ShellState.scripts + name + ".sh"]);
                } else if (modelData[0] === "color") {
                    ShellState.close();
                    Tasks.color.start(["pick-color"]);
                } else if (root.kind === "menu")
                    ShellState.setPanel(modelData[0]);
                else
                    ShellState.side(modelData[0], "left");
            }
        }
    }
}
