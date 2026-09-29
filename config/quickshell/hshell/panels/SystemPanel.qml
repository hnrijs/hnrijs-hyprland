import QtQuick
import qs
import qs.components

Flow {
    spacing: 8
    Component.onCompleted: Tasks.network.start(["network-settings", "status"])
    Repeater {
        model: [["audio", "󰕾", "Audio"], ["bluetooth", "󰂯", "Bluetooth"], ["network", "󰈀", "Network"], ["firewall", "󰒃", "Firewall"], ["timezone", "󰥔", "Timezone"], ["power-settings", "󰐥", "Power"], ["keyboard", "󰌌", "Keyboard"], ["mouse", "󰍽", "Mouse"], ["monitor", "󰍹", "Monitor"], ["keybinds", "󰌌", "Keybinds"], ["defaults", "󰒓", "Default Apps"], ["maintenance", "󰃢", "Maintenance"]]
        delegate: ControlTile {
            required property var modelData
            width: (parent.width - 8) / 2
            implicitHeight: 60
            symbol: modelData[1]
            text: modelData[2]
            onClicked: {
                if (modelData[0] === "password")
                    ShellState.terminal("password");
                else
                    ShellState.side(modelData[0], "left");
            }
        }
    }
    TaskStatus {
        width: parent.width
        task: Tasks.network
        showCancel: false
    }
}
