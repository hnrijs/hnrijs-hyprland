import QtQuick
import Quickshell
import qs
import qs.components

Column {
    spacing: 10
    PillButton {
        width: parent.width
        text: "󰈋  Pick Screen Color"
        enabled: !Tasks.color.running
        onClicked: {
            ShellState.close();
            Tasks.color.start(["pick-color"]);
        }
    }
    TaskStatus {
        width: parent.width
        task: Tasks.color
    }
}
