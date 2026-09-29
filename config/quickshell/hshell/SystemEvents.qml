import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Io
import qs

Scope {
    id: root
    property bool ready: false
    property string previousProfile: ""
    property var bluetoothState: ({})
    property string wifiName: ""
    function notify(title, body) {
        const kind = title === "Power Profile" ? "power" : title.startsWith("Bluetooth") ? "bluetooth" : title.startsWith("Network") ? "wifi" : "charging";
        if (!Preferences.eventEnabled(kind))
            return;
        ShellState.noticeKind = kind;
        if (title === "Power Profile") {
            ShellState.showNotice(({
                    "power-saver": "Power Save",
                    balanced: "Balanced",
                    performance: "Performance"
                })[body] || body);
        } else
            ShellState.showNotice(title + (body ? " · " + body : ""));
    }
    Timer {
        interval: 2500
        running: true
        onTriggered: {
            root.previousProfile = Backend.powerProfile;
            root.wifiName = Controls.connectedWifi ? Controls.connectedWifi.name : "";
            root.ready = true;
        }
    }
    Connections {
        target: Controls.sink ? Controls.sink.audio : null
        function onVolumeChanged() {
            if (root.ready)
                ShellState.showOsd("volume");
        }
        function onMutedChanged() {
            if (root.ready)
                ShellState.showOsd("volume");
        }
    }
    Connections {
        target: Controls
        function onWifiOnChanged() {
            if (root.ready)
                ShellState.notice("wifi", Controls.wifiOn ? "Wi-Fi On" : "Wi-Fi Off");
        }
        function onBatteryChargingChanged() {
            if (root.ready && Controls.hasBattery)
                ShellState.notice("charging", (Controls.batteryCharging ? "Charging " : "On Battery ") + Math.round(Controls.batteryLevel * 100) + "%");
        }
    }
    Connections {
        target: Controls.adapter
        function onEnabledChanged() {
            if (root.ready)
                ShellState.notice("bluetooth", Controls.adapter.enabled ? "Bluetooth On" : "Bluetooth Off");
        }
    }
    Connections {
        target: Backend
        function onNightLightStatusChanged() {
            if (root.ready)
                ShellState.notice("nightlight", Backend.nightLightStatus === "on" ? "Night Light On" : "Night Light Off");
        }
        function onBrightnessChanged() {
            if (root.ready)
                ShellState.showOsd("brightness");
        }
        function onPowerProfileChanged() {
            if (root.ready && Backend.powerProfile !== root.previousProfile && Backend.powerProfile !== "unavailable")
                root.notify("Power Profile", Backend.powerProfile);
            root.previousProfile = Backend.powerProfile;
        }
    }
    Instantiator {
        model: Controls.bluetoothDevices
        delegate: QtObject {
            required property var modelData
            property bool wasConnected: modelData.connected
            property Connections watcher: Connections {
                target: modelData
                function onConnectedChanged() {
                    if (root.ready && modelData.connected !== wasConnected)
                        root.notify(modelData.connected ? "Bluetooth connected" : "Bluetooth disconnected", modelData.name || modelData.deviceName);
                    wasConnected = modelData.connected;
                }
            }
        }
    }
    Process {
        command: ["python3", ShellState.scripts + "usb-monitor.py"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const event = JSON.parse(line);
                    ShellState.showUsbNotice(event.summary, event.body);
                } catch (e) {}
            }
        }
    }
    Process {
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=backlight"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("change"))
                    Backend.refreshStatus();
            }
        }
    }
}
