import QtQuick
import qs
import qs.components

Row {
    spacing: 10
    Repeater {
        model: [["system", "󰒓", "System", "Devices and Maintenance"], ["interface", "󰏘", "Interface", "Pill, Wallpaper and Colors"]]
        delegate: ControlTile {
            required property var modelData
            width: (parent.width - 10) / 2
            symbol: modelData[1]
            text: modelData[2]
            detail: modelData[3]
            onClicked: ShellState.side(modelData[0], "left")
        }
    }
}
