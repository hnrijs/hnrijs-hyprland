pragma Singleton
import QtQuick
import Quickshell
import qs
import Quickshell.Io

Singleton {
    id: root

    readonly property string helper: Quickshell.env("XDG_CONFIG_HOME") ? Quickshell.env("XDG_CONFIG_HOME") + "/scripts/shell-actions.sh" : Quickshell.env("HOME") + "/.config/scripts/shell-actions.sh"
    Process {
        command: ["bash", "-c", "pgrep -u \"$UID\" -x hyprlock >/dev/null"]
        running: true
        onExited: code => {
            if (code === 0)
                ShellState.locked = true;
        }
    }
    property bool capsLock: false
    property bool capsLockReady: false
    Process {
        command: ["python3", (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/scripts/caps-lock-monitor.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const enabled = data.trim() === "on";
                if (root.capsLockReady && enabled !== root.capsLock)
                    ShellState.notice("capslock", "Caps Lock " + (enabled ? "On" : "Off"));
                root.capsLock = enabled;
                root.capsLockReady = true;
            }
        }
    }
    property bool brightnessAvailable: false
    property int brightness: 0
    property int brightnessInFlight: -1
    property int nightLightTemperatureInFlight: -1
    property int nightLightGeneration: 0
    property int nightLightReadGeneration: 0
    property string nightLightStatus: "off"
    property string powerProfile: "unavailable"
    property var powerQueue: []
    property int powerGeneration: 0
    property int powerReadGeneration: 0
    property var clipboardItems: []
    Process {
        command: ["bash", (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/scripts/start-clipboard.sh"]
        running: true
    }
    property string clipboardContents: ""
    property string clipboardImageSource: ""
    property bool clipboardContentsLoading: false
    property string clipboardContentsRequestedId: ""
    property string clipboardContentsInFlightId: ""
    property string lastError: ""

    function refreshStatus() {
        if (!brightnessCommit.running && !brightnessSetProcess.running)
            brightnessProcess.running = true;
        refreshQuickControls();
    }

    function refreshQuickControls() {
        if (!nightLightStatusProcess.running && !nightLightToggleProcess.running) {
            nightLightReadGeneration = nightLightGeneration;
            nightLightStatusProcess.running = true;
        }
        if (!powerProfileStatusProcess.running && !powerProfileToggleProcess.running && !powerQueue.length) {
            powerReadGeneration = powerGeneration;
            powerProfileStatusProcess.running = true;
        }
    }

    function toggleNightLight() {
        if (nightLightToggleProcess.running)
            return;
        nightLightGeneration++;
        nightLightStatus = nightLightStatus === "on" ? "off" : "on";
        if (nightLightStatus === "off")
            nightLightCommit.stop();
        nightLightToggleProcess.exec([helper, "night-light-switch", String(ShellState.nightLightTemperature), nightLightStatus]);
    }

    function setNightLightTemperature(value) {
        ShellState.nightLightTemperature = Math.max(2500, Math.min(6000, Math.round(value / 50) * 50));
        nightLightCommit.restart();
    }

    function enqueuePower(args) {
        powerGeneration++;
        powerQueue = powerQueue.concat([args]);
        drainPower();
    }
    function drainPower() {
        if (powerProfileToggleProcess.running || !powerQueue.length)
            return;
        const args = powerQueue[0];
        powerQueue = powerQueue.slice(1);
        powerProfileToggleProcess.exec([helper].concat(args));
    }
    function setPowerProfile(profile) {
        enqueuePower(["power-profile-set", profile]);
    }
    function cyclePowerProfile() {
        enqueuePower(["power-profile-cycle"]);
    }

    function setBrightness(value) {
        brightness = Math.max(0, Math.min(100, Math.round(value)));
        if (!brightnessCommit.running && !brightnessSetProcess.running)
            brightnessCommit.start();
    }

    function commitBrightness() {
        if (brightnessSetProcess.running)
            return;

        brightnessInFlight = brightness;
        brightnessSetProcess.exec([helper, "brightness-set", String(brightnessInFlight)]);
    }

    function refreshClipboard() {
        clipboardProcess.running = true;
    }

    function pasteClipboard(id) {
        pasteProcess.exec([helper, "clipboard-paste", String(id)]);
    }

    function loadClipboardContents(id, itemPreview, imageSource) {
        clipboardContentsRequestedId = "";
        clipboardImageSource = imageSource || "";
        if (clipboardImageSource) {
            clipboardContents = "";
            clipboardContentsLoading = false;
            return;
        }
        clipboardContents = "";
        clipboardContentsLoading = true;
        clipboardContentsRequestedId = String(id);
        startClipboardContentsLoad();
    }

    function startClipboardContentsLoad() {
        if (clipboardContentsProcess.running || !clipboardContentsRequestedId)
            return;

        clipboardContentsInFlightId = clipboardContentsRequestedId;
        clipboardContentsProcess.exec(["python3", ShellState.scripts + "clipboard-content.py", clipboardContentsInFlightId]);
    }

    function power(action) {
        if (action === "lock") {
            Quickshell.execDetached(["bash", ShellState.scripts + "lock.sh"]);
            return;
        }
        actionProcess.exec([helper, "power", action]);
    }

    Process {
        id: brightnessProcess

        command: [root.helper, "brightness-get"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim() ? Number(text.trim()) : -1;
                root.brightnessAvailable = isFinite(value) && value >= 0;
                root.brightness = root.brightnessAvailable ? Math.min(100, value) : 0;
            }
        }
    }

    Process {
        id: brightnessSetProcess

        onExited: exitCode => {
            if (exitCode !== 0) {
                brightnessProcess.running = true;
                return;
            }
            if (root.brightness !== root.brightnessInFlight)
                brightnessCommit.start();
        }
    }

    Process {
        id: nightLightStatusProcess

        command: [root.helper, "night-light-status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: if (!nightLightToggleProcess.running && root.nightLightReadGeneration === root.nightLightGeneration)
                root.nightLightStatus = text.trim() || "off"
        }
    }

    Process {
        command: [root.helper, "night-light-temperature-get"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const temperature = Number(text.trim());
                if (temperature >= 2500 && temperature <= 6000)
                    ShellState.nightLightTemperature = temperature;
            }
        }
    }

    Process {
        id: powerProfileStatusProcess

        command: [root.helper, "power-profile-status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.powerReadGeneration === root.powerGeneration && !powerProfileToggleProcess.running && !root.powerQueue.length)
                    root.powerProfile = text.trim() || "unavailable";
            }
        }
    }

    Process {
        id: nightLightToggleProcess

        onExited: root.refreshQuickControls()
    }

    Process {
        id: powerProfileToggleProcess
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.powerProfile = text.trim();
            }
        }
        onExited: Qt.callLater(() => {
            if (root.powerQueue.length)
                root.drainPower();
            else
                root.refreshQuickControls();
        })
    }

    Process {
        id: nightLightSetProcess

        onExited: {
            root.refreshQuickControls();
            if (root.nightLightStatus === "on" && ShellState.nightLightTemperature !== root.nightLightTemperatureInFlight)
                nightLightCommit.restart();
        }
    }

    Process {
        id: clipboardProcess

        command: [root.helper, "clipboard-list"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.clipboardItems = text.trim().split("\n").filter(line => {
                    return line.length > 0;
                }).map(line => {
                    const separator = line.indexOf("\t");
                    const fields = separator < 0 ? [] : line.slice(separator + 1).split("\t");
                    const imageSource = fields.length > 1 && fields[fields.length - 1].startsWith("file://") ? fields.pop() : "";
                    return {
                        "id": separator < 0 ? line : line.slice(0, separator),
                        "preview": separator < 0 ? line : fields.join(" "),
                        "imageSource": imageSource
                    };
                });
            }
        }
    }

    Process {
        id: clipboardContentsProcess

        onExited: {
            const finishedId = root.clipboardContentsInFlightId;
            root.clipboardContentsInFlightId = "";
            if (finishedId === root.clipboardContentsRequestedId)
                root.clipboardContentsLoading = false;
            else if (root.clipboardContentsRequestedId)
                Qt.callLater(root.startClipboardContentsLoad);
        }

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.clipboardContentsInFlightId === root.clipboardContentsRequestedId) {
                    try {
                        const content = JSON.parse(text);
                        root.clipboardContents = content.text || "";
                        root.clipboardImageSource = content.image || "";
                    } catch (e) {
                        root.clipboardContents = "Preview unavailable";
                    }
                }
            }
        }
    }

    Process {
        id: actionProcess

        onExited: root.refreshStatus()
    }

    Process {
        id: pasteProcess
    }

    Timer {
        id: brightnessCommit

        interval: 40
        onTriggered: root.commitBrightness()
    }

    Timer {
        id: nightLightCommit

        interval: 120
        onTriggered: {
            if (!nightLightSetProcess.running) {
                root.nightLightTemperatureInFlight = ShellState.nightLightTemperature;
                nightLightSetProcess.exec([root.helper, "night-light-set", String(root.nightLightTemperatureInFlight)]);
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refreshStatus()
    }
}
