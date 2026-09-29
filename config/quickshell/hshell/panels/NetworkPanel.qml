import QtQuick
import qs
import qs.components

Column {
    id: root
    spacing: 12
    property int selected: 0
    property string selectedUuid: ""
    property string pendingDns: ""
    readonly property var connection: (network.result.connections || []).find(c => c.uuid === selectedUuid) || (network.result.connections || [])[0] || null
    readonly property var network: Tasks.network
    Component.onCompleted: network.start(["network-settings", "status"])
    BodyText {
        text: "Connection"
    }
    Repeater {
        model: network.result.connections || []
        delegate: PillButton {
            required property var modelData
            required property int index
            width: parent.width
            text: modelData.name
            selected: root.connection && root.connection.uuid === modelData.uuid
            onClicked: {
                root.selected = index;
                root.selectedUuid = modelData.uuid;
                root.pendingDns = "";
            }
        }
    }
    BodyText {
        visible: !(network.result.connections || []).length
        text: "Connect to Wi-Fi or Ethernet to Configure DNS"
    }
    Flow {
        width: parent.width
        spacing: 8
        Repeater {
            model: [["dhcp", "󰈀", "Automatic"], ["cloudflare", "󰅟", "Cloudflare"], ["google", "󰊭", "Google DNS"], ["custom", "󰒓", "Custom"]]
            delegate: ControlTile {
                required property var modelData
                property var connection: root.connection
                width: (parent.width - 24) / 4
                symbol: modelData[1]

                text: modelData[2]
                detail: modelData[0] === "custom" ? "Your DNS" : modelData[0] === "dhcp" ? "From Router" : modelData[0] === "google" ? "8.8.8.8" : "1.1.1.1"
                selected: !!connection && (root.pendingDns || connection.preset) === modelData[0]
                enabled: !!connection && !network.running
                onClicked: root.pendingDns = modelData[0]
            }
        }
    }
    Field {
        id: customDns
        width: parent.width
        visible: root.pendingDns === "custom"
        placeholderText: "DNS IP addresses, separated by commas"
    }
    PillButton {
        width: parent.width
        text: "Apply"
        enabled: !!root.connection && !!root.pendingDns && !network.running
        onClicked: {
            const args = ["network-settings", "dns", root.connection.uuid, root.pendingDns];
            if (root.pendingDns === "custom")
                args.push(customDns.text);
            network.start(args);
        }
    }
    ControlTile {
        width: parent.width
        symbol: "󰓅"
        text: "Speed Test"
        detail: "Download, Upload and Ping"
        onClicked: ShellState.side("speed", "left")
    }
    TaskStatus {
        width: parent.width
        task: network
        showCancel: false
    }
    Row {
        width: parent.width
        spacing: 8
        PillButton {
            width: (parent.width - 8) / 2
            text: "Refresh"
            enabled: !network.running
            onClicked: network.start(["network-settings", "status"])
        }
        PillButton {
            width: (parent.width - 8) / 2
            text: "Ping"
            enabled: !!root.connection && !network.running
            onClicked: network.start(["network-settings", "ping", root.connection.uuid])
        }
    }
}
