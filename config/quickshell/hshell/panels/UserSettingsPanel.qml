import QtQuick
import Quickshell
import qs
import qs.components

Column {
    id: root
    spacing: 10
    property string confirming: ""
    function password(name) {
        ShellState.close();
        Quickshell.execDetached(["python3", ShellState.scripts + "open-default.py", "terminal", "bash", ShellState.scripts + "tools.sh", "terminal", "user-password", name]);
    }
    Component.onCompleted: Tasks.device.start(["system-settings", "users"])
    Repeater {
        model: Tasks.device.result.users || []
        delegate: Column {
            required property var modelData
            width: parent.width
            spacing: 6
            ControlTile {
                width: parent.width
                symbol: "󰀄"
                text: modelData.name
                detail: modelData.name === Tasks.device.result.current ? "Current User" : modelData.home
                selected: modelData.name === Tasks.device.result.current
                onClicked: root.password(modelData.name)
            }
            Row {
                width: parent.width
                spacing: 8
                PillButton {
                    width: (parent.width - 16) / 3
                    text: "Set Password"
                    onClicked: root.password(modelData.name)
                }
                PillButton {
                    width: (parent.width - 16) / 3
                    text: root.confirming === modelData.name ? "Confirm Removal" : "Remove User"
                    enabled: modelData.name !== Tasks.device.result.current && !Tasks.device.running
                    onClicked: {
                        if (root.confirming !== modelData.name)
                            root.confirming = modelData.name;
                        else {
                            Tasks.device.start(["system-settings", "delete-user", modelData.name]);
                            root.confirming = "";
                        }
                    }
                }
                PillButton {
                    width: (parent.width - 16) / 3
                    text: root.confirming === modelData.name + "/home" ? "Confirm Delete" : "Remove User + Home"
                    enabled: modelData.name !== Tasks.device.result.current && !Tasks.device.running
                    onClicked: {
                        if (root.confirming !== modelData.name + "/home")
                            root.confirming = modelData.name + "/home";
                        else {
                            Tasks.device.start(["system-settings", "delete-user-home", modelData.name, modelData.home]);
                            root.confirming = "";
                        }
                    }
                }
            }
            BodyText {
                width: parent.width
                visible: root.confirming === modelData.name + "/home"
                text: "Permanently remove this user and " + modelData.home
                color: Style.muted
            }
        }
    }
    BodyText {
        text: "New User"
    }
    Row {
        width: parent.width
        spacing: 8
        Field {
            id: username
            width: parent.width - 112
            placeholderText: "Username"
        }
        PillButton {
            width: 104
            text: "Add User"
            enabled: !Tasks.device.running && /^[a-z_][a-z0-9_-]{0,30}$/.test(username.text)
            onClicked: Tasks.device.start(["system-settings", "add-user", username.text])
        }
    }
    TaskStatus {
        width: parent.width
        task: Tasks.device
        showCancel: false
    }
}
