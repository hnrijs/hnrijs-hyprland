import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property var result: ({})
    property var progress: ({})
    property string error: ""
    property bool cancelling: false
    property bool clearAfterFinish: false
    readonly property bool running: process.running
    signal finished(bool success)
    property var pendingInput: null
    function startText(args, text) {
        start(args, text);
    }
    function start(args, input) {
        if (process.running)
            return;
        pendingInput = input === undefined ? null : input;
        process.stdinEnabled = pendingInput !== null;
        error = "";
        cancelling = false;
        progress = ({});
        process.exec(["python3", (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/scripts/hshell-task.py"].concat(args));
    }
    function cancel() {
        cancelling = true;
        process.signal(15);
    }
    Process {
        id: process
        onStarted: {
            if (root.pendingInput !== null) {
                write(root.pendingInput);
                stdinEnabled = false;
                root.pendingInput = null;
            }
        }
        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data);
                    if (event.type === "result") {
                        root.result = event.data;
                        root.progress = ({});
                    } else if (event.type === "progress")
                        root.progress = event.data;
                    else if (event.type === "error")
                        root.error = String(event.data);
                } catch (error) {}
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim())
                root.error = text.trim()
        }
        onExited: code => {
            root.pendingInput = null;
            if (root.cancelling) {
                root.error = "";
                root.progress = ({
                        message: "Stopped"
                    });
            } else if (code !== 0 && !root.error)
                root.error = "Task stopped (" + code + ")";
            root.finished(code === 0);
            if (root.clearAfterFinish) {
                root.result = ({});
                root.error = "";
                root.clearAfterFinish = false;
            }
        }
    }
}
