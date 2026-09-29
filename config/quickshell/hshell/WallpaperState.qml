pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string helper: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/scripts/wallpaper.py"
    property var wallpapers: []
    property string error: ""
    property string currentPath: ""
    property string pendingPath: ""
    property string applyingPath: ""
    property bool busy: wallpaperProcess.running
    property bool wallpaperRefreshPending: false

    function refreshWallpapers() {
        if (wallpaperListProcess.running) {
            wallpaperRefreshPending = true;
            return;
        }
        wallpaperListProcess.running = true;
    }

    function setWallpaper(path) {
        pendingPath = path;
        applyPending();
    }
    function applyPending() {
        if (busy || !pendingPath)
            return;
        applyingPath = pendingPath;
        pendingPath = "";
        error = "";
        wallpaperProcess.exec(["python3", helper, "wallpaper", applyingPath]);
    }
    function openWallpaperFolder() {
        if (!folderProcess.running)
            folderProcess.exec(["python3", helper, "open-wallpapers"]);
    }

    Component.onCompleted: {
        refreshWallpapers();
        currentProcess.running = true;
    }

    Process {
        id: currentProcess
        command: ["python3", root.helper, "current"]
        stdout: StdioCollector {
            onStreamFinished: root.currentPath = text.trim()
        }
    }
    Process {
        id: wallpaperListProcess
        command: ["python3", root.helper, "wallpapers"]
        onExited: {
            if (root.wallpaperRefreshPending) {
                root.wallpaperRefreshPending = false;
                wallpaperListProcess.running = true;
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.wallpapers = JSON.parse(text || "[]");
                    root.error = "";
                } catch (error) {
                    root.error = "Unable to read wallpapers";
                }
            }
        }
    }

    Process {
        id: wallpaperProcess
        onExited: exitCode => {
            if (exitCode !== 0 && !root.error)
                root.error = "Wallpaper switch failed";
            if (exitCode === 0)
                root.currentPath = root.applyingPath;
            Qt.callLater(root.applyPending);
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim())
                root.error = text.trim()
        }
    }

    Process {
        id: folderProcess
        stderr: StdioCollector {
            onStreamFinished: if (text.trim())
                root.error = text.trim()
        }
    }
}
