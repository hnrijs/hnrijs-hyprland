pragma Singleton
import QtQuick
import Quickshell
import qs

Singleton {
    id: root
    property string timeText: "--:--"
    property string dateText: ""
    property int year: new Date().getFullYear()
    property int month: new Date().getMonth() + 1
    property int day: new Date().getDate()
    function update(value) {
        if (!value || !value.time)
            return;
        timeText = value.time;
        dateText = value.date;
        year = value.year;
        month = value.month;
        day = value.day;
    }
    function refresh() {
        if (!reader.running)
            reader.start(["clock"]);
    }
    Task {
        id: reader
        onResultChanged: root.update(result)
    }
    Connections {
        target: Tasks.device
        function onResultChanged() {
            root.update(Tasks.device.result.clock);
        }
    }
    Timer {
        interval: 60000 - Date.now() % 60000 + 20
        running: true
        repeat: true
        onTriggered: {
            root.refresh();
            interval = 60000 - Date.now() % 60000 + 20;
        }
    }
    Component.onCompleted: refresh()
}
