import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.components

Column {
    id: root
    required property string kind
    required property var shellWindow
    spacing: 10
    Loader {
        width: parent.width
        height: item ? item.implicitHeight : 0
        sourceComponent: root.kind === "wifi" ? wifi : root.kind === "bluetooth" ? bluetooth : root.kind === "nightlight" ? night : root.kind === "powerprofile" ? power : audio
    }
    Component {
        id: wifi
        Column {
            spacing: 8
            BodyText {
                width: parent.width
                visible: !Controls.wifiDevice
                text: "No Wi-Fi adapter"
                color: Style.muted
            }
            BodyText {
                width: parent.width
                text: Controls.wifiError
                visible: text !== ""
            }
            Column {
                width: parent.width
                spacing: 6
                visible: !!Controls.pendingWifiNetwork
                BodyText {
                    width: parent.width
                    text: Controls.pendingWifiNetwork ? Controls.pendingWifiNetwork.name : ""
                }
                Field {
                    id: password
                    width: parent.width
                    echoMode: TextInput.Password
                    placeholderText: "Password"
                    onAccepted: {
                        Controls.connectWifi(text);
                        clear();
                    }
                }
                PillButton {
                    width: parent.width
                    text: "Connect"
                    onClicked: {
                        Controls.connectWifi(password.text);
                        password.clear();
                    }
                }
            }
            Repeater {
                model: Controls.wifiNetworks
                delegate: Column {
                    id: wifiRow
                    required property var modelData
                    property bool details: false
                    width: parent.width
                    spacing: 6
                    PillButton {
                        width: parent.width
                        height: 44
                        text: wifiRow.modelData.name || "Hidden network"
                        selected: wifiRow.modelData.connected
                        enabled: Controls.wifiOn && !wifiRow.modelData.stateChanging
                        rightPadding: 70
                        onClicked: Controls.selectWifi(wifiRow.modelData)
                        TapHandler {
                            acceptedButtons: Qt.RightButton
                            onTapped: wifiRow.details = !wifiRow.details
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: (wifiRow.modelData.connected ? "✓ " : "") + Math.round(wifiRow.modelData.signalStrength * 100) + "%"
                            color: wifiRow.modelData.connected ? Style.activeText : Style.muted
                            font.family: Style.fontFamily
                        }
                    }
                    PillButton {
                        visible: wifiRow.details && wifiRow.modelData.known
                        width: parent.width
                        text: "Forget"
                        onClicked: wifiRow.modelData.forget()
                    }
                }
            }
            BodyText {
                visible: Controls.wifiOn && Controls.wifiNetworks.length === 0
                text: "Searching for networks…"
                color: Style.muted
            }
        }
    }
    Component {
        id: bluetooth
        Column {
            spacing: 8
            BodyText {
                visible: !Controls.adapter
                text: "No Bluetooth adapter"
                color: Style.muted
            }
            BodyText {
                width: parent.width
                text: BluetoothPairing.error
                visible: text !== ""
                color: Style.muted
            }
            Column {
                width: parent.width
                spacing: 8
                visible: BluetoothPairing.active
                BodyText {
                    width: parent.width
                    text: "Pairing " + BluetoothPairing.deviceName
                }
                BodyText {
                    width: parent.width
                    visible: text !== ""
                    text: BluetoothPairing.request.value || ""
                    font.pixelSize: 22
                }
                Field {
                    id: pin
                    width: parent.width
                    visible: ["pin", "passkey"].includes(BluetoothPairing.request.kind)
                    placeholderText: "PIN"
                    onAccepted: {
                        BluetoothPairing.answer(true, text);
                        clear();
                    }
                }
                Row {
                    width: parent.width
                    spacing: 8
                    PillButton {
                        width: (parent.width - 8) / 2
                        text: "Cancel"
                        onClicked: BluetoothPairing.cancel()
                    }
                    PillButton {
                        width: (parent.width - 8) / 2
                        text: "Confirm"
                        visible: !!BluetoothPairing.request.id
                        selected: true
                        onClicked: {
                            BluetoothPairing.answer(true, pin.text);
                            pin.clear();
                        }
                    }
                }
            }
            Repeater {
                model: Controls.bluetoothDevices
                delegate: Column {
                    id: deviceRow
                    required property var modelData
                    property bool details: false
                    width: parent.width
                    spacing: 6
                    PillButton {
                        width: parent.width
                        text: deviceRow.modelData.name || deviceRow.modelData.deviceName
                        selected: deviceRow.modelData.connected
                        enabled: Controls.adapter && Controls.adapter.enabled
                        onClicked: Controls.connectBluetooth(deviceRow.modelData)
                        TapHandler {
                            acceptedButtons: Qt.RightButton
                            onTapped: deviceRow.details = !deviceRow.details
                        }
                    }
                    Row {
                        visible: deviceRow.details && (deviceRow.modelData.paired || deviceRow.modelData.bonded)
                        width: parent.width
                        spacing: 6
                        PillButton {
                            width: (parent.width - 6) / 2
                            text: deviceRow.modelData.trusted ? "Trusted ✓" : "Trust"
                            onClicked: deviceRow.modelData.trusted = !deviceRow.modelData.trusted
                        }
                        PillButton {
                            width: (parent.width - 6) / 2
                            text: "Forget"
                            onClicked: deviceRow.modelData.forget()
                        }
                    }
                }
            }
        }
    }
    Component {
        id: audio
        Column {
            spacing: 10
            Repeater {
                model: [false, true]
                delegate: Column {
                    id: audioGroup
                    required property bool modelData
                    property bool input: modelData
                    property var current: input ? Controls.source : Controls.sink
                    width: parent.width
                    spacing: 8
                    BodyText {
                        text: parent.input ? "Input device" : "Output device"
                        color: Style.muted
                        font.pixelSize: 12
                    }
                    Repeater {
                        model: parent.input ? Controls.audioSources : Controls.audioSinks
                        delegate: PillButton {
                            required property var modelData
                            width: parent.width
                            text: modelData.description || modelData.name
                            selected: modelData === audioGroup.current
                            onClicked: {
                                if (audioGroup.input)
                                    Pipewire.preferredDefaultAudioSource = modelData;
                                else
                                    Pipewire.preferredDefaultAudioSink = modelData;
                            }
                        }
                    }
                    PillSlider {
                        width: parent.width
                        enabled: !!parent.current
                        icon: parent.input ? "󰍬" : "󰕾"
                        caption: parent.input ? "Microphone" : "Volume"
                        value: parent.current ? parent.current.audio.volume : 0
                        onMoved: if (parent.current)
                            parent.current.audio.volume = value
                    }
                }
            }
        }
    }
    Component {
        id: night
        Column {
            spacing: 12
            PillSlider {
                width: parent.width
                from: 2500
                to: 6000
                stepSize: 50
                value: ShellState.nightLightTemperature
                icon: "󰖔"
                caption: "Temperature"
                displayValue: Math.round(value) + " K"
                onMoved: Backend.setNightLightTemperature(value)
            }
        }
    }
    Component {
        id: power
        Column {
            spacing: 8
            Task {
                id: profileList
                Component.onCompleted: start(["power-profiles"])
            }
            Repeater {
                model: profileList.result.profiles || []
                delegate: PillButton {
                    required property string modelData
                    width: parent.width
                    text: ({
                            "power-saver": "Power Save",
                            "balanced": "Balanced",
                            "performance": "Performance"
                        })[modelData] || modelData
                    selected: Backend.powerProfile === modelData
                    onClicked: Backend.setPowerProfile(modelData)
                }
            }
            TaskStatus {
                width: parent.width
                task: profileList
            }
        }
    }
}
