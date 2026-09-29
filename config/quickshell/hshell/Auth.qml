pragma Singleton
import QtQuick
import Quickshell
import qs
import Quickshell.Services.Polkit

Singleton {
    id: root
    readonly property var flow: agent.flow
    readonly property bool active: agent.isActive
    readonly property bool registered: agent.isRegistered
    property string previousPanel: "clock"
    property string savedLeft: ""
    property string savedRight: ""
    PolkitAgent {
        id: agent
        onIsActiveChanged: {
            if (isActive) {
                root.previousPanel = ShellState.panel;
                root.savedLeft = ShellState.leftPanel;
                root.savedRight = ShellState.rightPanel;
                ShellState.setPanel("auth");
            } else if (ShellState.panel === "auth") {
                ShellState.setPanel(root.previousPanel === "auth" ? "clock" : root.previousPanel);
                ShellState.leftPanel = root.savedLeft;
                ShellState.rightPanel = root.savedRight;
            }
        }
    }
}
