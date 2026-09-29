import QtQuick
import Quickshell
import qs

Scope {
    id: root
    property var sent: ({})
    function check() {
        if (!Controls.hasBattery)
            return;
        if (Controls.batteryCharging) {
            sent = ({});
            return;
        }
        const percent = Math.round(Controls.batteryLevel * 100);
        const levels = Preferences.option("batteryThresholds", [15, 5]).slice().sort((a, b) => a - b);
        const threshold = levels.find(t => percent <= t && !sent[t]);
        if (threshold !== undefined) {
            let next = Object.assign({}, sent);
            levels.filter(t => t >= threshold).forEach(t => next[t] = true);
            sent = next;
            ShellState.notice("battery", "Battery · " + percent + "%");
        }
    }
    Connections {
        target: Controls
        function onBatteryLevelChanged() {
            root.check();
        }
        function onBatteryChargingChanged() {
            root.check();
        }
    }
    Timer {
        interval: 3000
        running: true
        onTriggered: root.check()
    }
}
