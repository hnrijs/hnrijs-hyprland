import QtQuick
import Quickshell
import qs
import qs.components

Column {
    id: root
    spacing: 10
    property string expandedRole: ""
    Component.onCompleted: Tasks.device.start(["app-defaults", "status"])
    Repeater {
        model: [["terminal", "󰆍", "Terminal"], ["browser", "󰖟", "Web Browser"], ["text", "󰷈", "Text Editor"], ["image", "󰋩", "Image Viewer"], ["video", "󰕧", "Video Player"], ["pdf", "󰈦", "PDF Viewer"]]
        delegate: Column {
            id: group
            required property var modelData
            readonly property var choices: (Tasks.device.result.choices || {})[modelData[0]] || []
            readonly property string selectedId: (Tasks.device.result.selected || {})[modelData[0]] || ""
            readonly property var selectedApp: choices.find(a => a.id === selectedId) || null
            width: parent.width
            spacing: 6
            ControlTile {
                width: parent.width
                symbol: group.modelData[1]
                text: group.modelData[2]
                detail: group.selectedApp ? group.selectedApp.name : "Choose Application"
                onClicked: root.expandedRole = root.expandedRole === group.modelData[0] ? "" : group.modelData[0]
            }
            Repeater {
                model: root.expandedRole === group.modelData[0] ? group.choices : []
                delegate: ControlTile {
                    required property var modelData
                    width: parent.width
                    text: modelData.name
                    detail: modelData.binary
                    iconSource: Quickshell.iconPath(modelData.icon)
                    selected: group.selectedId === modelData.id
                    enabled: !Tasks.device.running
                    onClicked: {
                        Tasks.device.start(["app-defaults", "set", group.modelData[0], modelData.id]);
                        root.expandedRole = "";
                    }
                }
            }
        }
    }
    TaskStatus {
        width: parent.width
        task: Tasks.device
        showCancel: false
    }
}
