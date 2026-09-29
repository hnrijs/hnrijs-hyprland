import QtQuick
import qs
import qs.components

Column {
    spacing: 12
    readonly property var task: Tasks.network
    Component.onCompleted: task.start(["network-settings", "firewall-status"])
    ControlTile {
        width: parent.width
        symbol: "󰒃"
        text: "Firewall"
        detail: task.result.firewall ? "On" : "Off"
        selected: !!task.result.firewall
        enabled: !task.running
        onClicked: task.start(["network-settings", "firewall", task.result.firewall ? "off" : "on"])
    }
    Row {
        width: parent.width
        spacing: 8
        PillButton {
            width: (parent.width - 8) / 2
            text: "Incoming"
            detail: task.result.incoming || "—"
            enabled: false
        }
        PillButton {
            width: (parent.width - 8) / 2
            text: "Outgoing"
            detail: task.result.outgoing || "—"
            enabled: false
        }
    }
    PillButton {
        width: parent.width
        text: "View Rules"
        enabled: !task.running
        onClicked: task.start(["network-settings", "firewall-rules"])
    }
    BodyText {
        width: parent.width
        text: task.result.rules || ""
        font.pixelSize: 12
    }
    TaskStatus {
        width: parent.width
        task: parent.task
        showCancel: false
    }
}
