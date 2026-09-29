pragma Singleton
import QtQuick
import QtQml.Models
import Quickshell
import qs
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Singleton {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var wifiDevice: Networking.devices.values.find(device => {
        return device.type === DeviceType.Wifi;
    }) || null
    readonly property var wifiNetworks: wifiDevice ? wifiDevice.networks.values.slice().sort((left, right) => {
        if (left.connected !== right.connected)
            return left.connected ? -1 : 1;

        return right.signalStrength - left.signalStrength;
    }) : []
    readonly property var connectedWifi: wifiNetworks.find(network => {
        return network.connected;
    }) || null
    readonly property var knownWifiNetworks: wifiNetworks.filter(network => network.known)
    readonly property var availableWifiNetworks: wifiNetworks.filter(network => !network.known)
    readonly property var audioSinks: Pipewire.nodes.values.filter(node => {
        return node.isSink && !node.isStream && node.audio;
    }).slice().sort((left, right) => {
        if (sink && left.id === sink.id)
            return -1;

        if (sink && right.id === sink.id)
            return 1;

        return (left.description || left.nickname || left.name).localeCompare(right.description || right.nickname || right.name);
    })
    readonly property var audioSources: Pipewire.nodes.values.filter(node => {
        return !node.isSink && !node.isStream && node.audio;
    }).slice().sort((left, right) => {
        if (source && left.id === source.id)
            return -1;

        if (source && right.id === source.id)
            return 1;

        return (left.description || left.nickname || left.name).localeCompare(right.description || right.nickname || right.name);
    })
    readonly property var bluetoothDevices: adapter ? adapter.devices.values.filter(device => {
        return device.name || device.deviceName;
    }).slice().sort((left, right) => {
        if (left.connected !== right.connected)
            return left.connected ? -1 : 1;

        if (left.paired !== right.paired)
            return left.paired ? -1 : 1;

        return (left.name || left.deviceName).localeCompare(right.name || right.deviceName);
    }) : []
    readonly property var knownBluetoothDevices: bluetoothDevices.filter(device => device.paired || device.bonded)
    readonly property var availableBluetoothDevices: bluetoothDevices.filter(device => !device.paired && !device.bonded)
    readonly property var connectedDevices: adapter ? adapter.devices.values.filter(device => {
        return device.connected;
    }) : []
    readonly property real batteryLevel: UPower.displayDevice ? UPower.displayDevice.percentage : 0
    readonly property bool batteryCharging: UPower.displayDevice && (!UPower.onBattery || UPower.displayDevice.state === UPowerDeviceState.Charging || UPower.displayDevice.state === UPowerDeviceState.PendingCharge)

    readonly property string batteryIcon: batteryCharging ? ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"][Math.max(0, Math.min(10, Math.floor(batteryLevel * 10)))] : ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.max(0, Math.min(10, Math.floor(batteryLevel * 10)))]
    readonly property string wifiIcon: !connectedWifi ? "󰤭" : connectedWifi.signalStrength >= 0.75 ? "󰤨" : connectedWifi.signalStrength >= 0.50 ? "󰤥" : connectedWifi.signalStrength >= 0.25 ? "󰤢" : "󰤟"
    readonly property string powerIcon: Backend.powerProfile === "power-saver" ? "󰌪" : Backend.powerProfile === "performance" ? "󱐋" : "󰾅"
    property var pendingWifiNetwork: null
    property string wifiError: ""
    property bool wifiPending: false
    property bool wifiTarget: false
    readonly property bool wifiOn: wifiPending ? wifiTarget : Networking.wifiEnabled
    Timer {
        id: wifiSettle
        interval: 450
        onTriggered: if (Networking.wifiEnabled === root.wifiTarget) {
            root.wifiPending = false;
            wifiTimeout.stop();
        }
    }
    Timer {
        id: wifiTimeout
        interval: 5000
        onTriggered: {
            root.wifiPending = false;
            if (Networking.wifiEnabled !== root.wifiTarget)
                root.wifiError = "Wi-Fi could not be switched";
        }
    }
    Connections {
        target: Networking
        function onWifiEnabledChanged() {
            if (root.wifiPending)
                wifiSettle.restart();
        }
    }
    readonly property bool hasBattery: UPower.displayDevice && UPower.displayDevice.isPresent
    function volume(value) {
        if (sink && sink.audio)
            sink.audio.volume = Math.max(0, Math.min(1, value));
    }
    function mute() {
        if (sink && sink.audio)
            sink.audio.muted = !sink.audio.muted;
    }
    function mic() {
        if (source && source.audio)
            source.audio.muted = !source.audio.muted;
    }
    function wifi() {
        ShellState.silenceEvents("network");
        if (wifiPending)
            return;
        wifiError = "";
        wifiTarget = !wifiOn;
        wifiPending = true;
        Networking.wifiEnabled = wifiTarget;
        wifiSettle.restart();
        wifiTimeout.restart();
    }
    function bluetooth() {
        ShellState.silenceEvents("bluetooth");
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }
    function scan() {
        if (wifiDevice)
            wifiDevice.scannerEnabled = wifiOn && ShellState.leftPanel === "wifi";
    }
    function selectWifi(network) {
        if (network.stateChanging)
            return;
        wifiError = "";
        if (network.connected)
            network.disconnect();
        else if (!network.known && [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(network.security))
            pendingWifiNetwork = network;
        else
            network.connect();
    }
    Task {
        id: temporaryWifi
        onFinished: success => {
            if (!success)
                root.wifiError = error || "Connection failed";
        }
    }
    function connectWifi(password) {
        if (!pendingWifiNetwork || !password)
            return;
        if (!temporaryWifi.running)
            temporaryWifi.startText(["wifi-connect"], JSON.stringify({
                interface: wifiDevice.name,
                name: pendingWifiNetwork.name,
                password: password,
                sae: pendingWifiNetwork.security === WifiSecurityType.Sae
            }));
        pendingWifiNetwork = null;
    }
    function connectBluetooth(device) {
        if (device.connected)
            device.disconnect();
        else if (device.paired || device.bonded)
            device.connect();
        else
            BluetoothPairing.start(device.address, device.name || device.deviceName);
    }
    function duration(value) {
        return Math.floor(value / 60) + ":" + String(Math.floor(value % 60)).padStart(2, "0");
    }
    PwObjectTracker {
        objects: root.audioSinks.concat(root.audioSources)
    }
    Connections {
        target: ShellState
        function onLeftPanelChanged() {
            root.scan();
            root.pendingWifiNetwork = null;
        }
        function onRightPanelChanged() {
            if (root.adapter)
                root.adapter.discovering = root.adapter.enabled && ShellState.rightPanel === "bluetooth";
        }
    }
    onWifiDeviceChanged: scan()
    onWifiOnChanged: scan()
    Connections {
        target: root.adapter
        function onEnabledChanged() {
            if (root.adapter)
                root.adapter.discovering = root.adapter.enabled && ShellState.rightPanel === "bluetooth";
        }
    }
    Instantiator {
        model: root.wifiNetworks
        delegate: Connections {
            required property var modelData
            target: modelData
            function onConnectionFailed(reason) {
                if (reason === ConnectionFailReason.NoSecrets && [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(modelData.security))
                    root.pendingWifiNetwork = modelData;
                root.wifiError = "Could not connect to " + modelData.name + " (" + reason + ")";
            }
        }
    }
}
