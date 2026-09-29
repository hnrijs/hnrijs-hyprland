pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root
    property var request: ({})
    property string deviceName: ""
    property string error: ""
    readonly property bool active: process.running
    function start(address, name) {
        if (active)
            return;
        error = "";
        request = ({});
        deviceName = name;
        process.exec(["python3", ShellState.scripts + "bluetooth-pair.py", address]);
    }
    function answer(accept, value) {
        process.write(JSON.stringify({
            id: request.id,
            accept: accept,
            value: value || ""
        }) + "\n");
    }
    function cancel() {
        if (active)
            process.signal(15);
        request = ({});
    }
    Process {
        id: process
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const event = JSON.parse(line);
                    if (event.type === "request")
                        root.request = event;
                    else if (event.type === "clear" || event.type === "result")
                        root.request = ({});
                    else if (event.type === "error")
                        root.error = event.message;
                } catch (e) {}
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim())
                root.error = text.trim()
        }
        onExited: root.request = ({})
    }
}
