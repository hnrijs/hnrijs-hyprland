import QtQuick
import qs
import qs.components

Column {
    id: root
    spacing: 12
    property bool loaded: false
    function load() {
        if (Tasks.device.result.lock === undefined)
            return;
        lockTime.text = String(Tasks.device.result.lock / 60);
        sleepTime.text = String(Tasks.device.result.suspend / 60);
        loaded = true;
    }
    Component.onCompleted: Tasks.device.start(["system-settings", "power"])
    Connections {
        target: Tasks.device
        function onFinished(success) {
            if (success)
                root.load();
        }
    }
    BodyText {
        text: "Lock After · Minutes"
    }
    Field {
        id: lockTime
        width: parent.width
        placeholderText: "1"
        inputMethodHints: Qt.ImhFormattedNumbersOnly
    }
    BodyText {
        text: "Suspend After · Minutes"
    }
    Field {
        id: sleepTime
        width: parent.width
        placeholderText: "5"
        inputMethodHints: Qt.ImhFormattedNumbersOnly
    }
    PillButton {
        width: parent.width
        text: "Apply"
        enabled: root.loaded && !Tasks.device.running && Number(lockTime.text) > 0 && Number(sleepTime.text) > Number(lockTime.text)
        onClicked: Tasks.device.start(["system-settings", "save-power", JSON.stringify({
                lock: Math.round(Number(lockTime.text) * 60),
                suspend: Math.round(Number(sleepTime.text) * 60)
            })])
    }
    TaskStatus {
        width: parent.width
        task: Tasks.device
        showCancel: false
    }
    BodyText {
        text: "Lock Screen"
    }
    PreferencesPanel {
        width: parent.width
        embedded: true
        category: "Lock Screen"
    }
}
