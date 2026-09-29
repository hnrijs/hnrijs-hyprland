import QtQuick
import qs
import qs.components

Column {
    id: root
    required property string kind
    spacing: 10
    Loader {
        width: parent.width
        height: item ? item.implicitHeight : 0
        sourceComponent: root.kind === "power-settings" ? powerSettings : root.kind === "keybinds" ? keybinds : root.kind === "defaults" ? defaults : root.kind === "maintenance" ? maintenance : root.kind === "timezone" ? timezone : root.kind === "monitor" ? monitors : root.kind === "user" ? users : input
    }
    Component {
        id: powerSettings
        PowerSettingsPanel {}
    }
    Component {
        id: keybinds
        KeybindsPanel {}
    }
    Component {
        id: defaults
        DefaultAppsPanel {}
    }
    Component {
        id: timezone
        TimezonePanel {}
    }
    Component {
        id: monitors
        MonitorSettingsPanel {}
    }
    Component {
        id: users
        UserSettingsPanel {}
    }
    Component {
        id: input
        InputSettingsPanel {
            kind: root.kind
        }
    }
    Component {
        id: maintenance
        Column {
            spacing: 10
            ControlTile {
                width: parent.width
                symbol: "󰚰"
                text: "System Update"
                detail: "Pacman and Yay"
                onClicked: ShellState.terminal("update")
            }
            ControlTile {
                width: parent.width
                symbol: "󰃢"
                text: "System Clean"
                detail: "Packages and Cache"
                onClicked: ShellState.terminal("clean")
            }
        }
    }
}
