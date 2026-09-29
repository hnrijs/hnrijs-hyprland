pragma Singleton
import QtQuick
import Quickshell
import qs
import Quickshell.Hyprland

Singleton {
    id: root
    property var quietEvents: ({})
    function silenceEvents(kind) {
        quietEvents = Object.assign({}, quietEvents, {
            [kind]: Date.now() + 15000
        });
    }
    function eventsQuiet(kind) {
        return (quietEvents[kind] || 0) > Date.now();
    }
    property string noticeKind: "workspace"
    function notice(kind, text) {
        if (!Preferences.eventEnabled(kind))
            return;
        noticeKind = kind;
        showNotice(text);
    }
    property bool locked: false

    property bool overviewOpen: false
    property string panel: "clock"
    property string activeScreen: ""
    property string leftPanel: ""
    property string rightPanel: ""
    property string toolName: ""
    property string detailName: ""
    property string returnPanel: "menu"
    property var navigation: []
    property string statusNotice: ""
    readonly property string workspaceText: statusNotice || "Workspace " + (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1)
    property string osd: ""
    property bool workspaceNotice: false
    property bool dnd: false
    property bool externalDialog: false
    property var notificationHistory: []
    property var liveNotifications: []
    property int nightLightTemperature: 4500
    property int keyboardNavigation: 0
    readonly property bool expanded: panel !== "clock"
    readonly property string scripts: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/scripts/"
    property string previousTool: ""
    onToolNameChanged: {
        cleanupTool(previousTool);
        previousTool = toolName;
    }
    function cleanupTool(name) {
        const task = {
            translate: Tasks.translate,
            words: Tasks.words,
            exif: Tasks.exif,
            ocr: Tasks.ocr,
            media: Tasks.media,
            download: Tasks.download,
            speed: Tasks.speed,
            ip: Tasks.ip,
            phone: Tasks.phone,
            color: Tasks.color
        }[name];
        if (!task)
            return;
        if (task.running)
            task.clearAfterFinish = true;
        task.result = ({});
        task.error = "";
        if (!task.running)
            task.progress = ({});
        if (name === "translate" || name === "words")
            task.inputText = "";
    }
    function currentScreen() {
        return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : (Quickshell.screens.length ? Quickshell.screens[0].name : "");
    }
    function setPanel(name) {
        if (locked && name !== "clock")
            return;
        if (!["clock", "control", "launcher", "clipboard", "calendar", "wallpaper", "power", "menu", "auth", "tool", "detail", "tools", "settings", "emoji", "color"].includes(name))
            return;
        if (!expanded)
            activeScreen = currentScreen();
        leftPanel = "";
        rightPanel = "";
        workspaceNotice = false;
        osd = "";
        keyboardNavigation = 0;
        overviewOpen = false;
        if (panel !== name || name === "clock") {
            cleanupTool(panel === "color" ? "color" : toolName);
        }
        panel = name;
    }
    function show(name) {
        navigation = [];
        if (name === "notifications")
            name = "control";
        if (name === "system")
            name = "settings";
        setPanel(panel === name ? "clock" : name);
    }
    function showOnScreen(name, screenName) {
        navigation = [];
        setPanel(name);
        activeScreen = screenName;
    }
    function dismissInterface() {
        if (Auth.active && Auth.flow) {
            Auth.previousPanel = "clock";
            Auth.flow.cancelAuthenticationRequest();
        } else
            close();
    }
    function close() {
        overviewOpen = false;
        BluetoothPairing.cancel();
        if (panel === "auth")
            return;
        navigation = [];
        setPanel("clock");
    }
    function terminal(action) {
        close();
        Quickshell.execDetached(["python3", scripts + "open-default.py", "terminal", "bash", scripts + "tools.sh", "terminal", action]);
    }
    function side(name, direction) {
        navigation = navigation.concat([
            {
                panel: panel,
                tool: toolName,
                detail: detailName
            }
        ]);
        if (["wifi", "bluetooth", "audio", "microphone", "nightlight", "powerprofile", "tray"].includes(name)) {
            detailName = name;
            returnPanel = "control";
            setPanel("detail");
            if (direction === "left")
                leftPanel = name;
            else
                rightPanel = name;
        } else {
            toolName = name;
            returnPanel = panel === "settings" ? "settings" : "tools";
            setPanel("tool");
        }
    }
    function back() {
        if (panel === "auth")
            return;
        if (navigation.length) {
            const previous = navigation[navigation.length - 1];
            navigation = navigation.slice(0, -1);
            toolName = previous.tool;
            detailName = previous.detail;
            setPanel(previous.panel);
        } else if (panel === "tools" || panel === "settings")
            setPanel("menu");
        else
            close();
    }
    property string noticeDetail: ""
    function showUsbNotice(title, body) {
        if (!Preferences.eventEnabled("usb"))
            return;
        noticeKind = "usb";
        statusNotice = title;
        noticeDetail = body || "USB Device";
        workspaceNotice = true;
        workspaceTimer.interval = Math.round(Preferences.notificationSeconds * 1000);
        workspaceTimer.restart();
    }
    function showNotice(text) {
        noticeDetail = "";
        workspaceTimer.interval = Math.round(Preferences.notificationSeconds * 1000);
        statusNotice = text;
        workspaceNotice = true;
        workspaceTimer.restart();
    }
    function showOsd(kind) {
        if (!Preferences.volumeOsd)
            return;
        if (!Preferences.eventEnabled(kind))
            return;
        noticeKind = kind;
        osd = kind;
        osdTimer.restart();
    }
    function rememberNotification(n) {
        notificationHistory = [
            {
                id: n.id,
                image: n.image || "",
                appIcon: n.appIcon || "",
                app: n.appName || "Notification",
                summary: n.summary || "",
                body: n.body || ""
            }
        ].concat(notificationHistory.filter(v => v.id !== n.id)).slice(0, 100);
    }
    function clearNotifications() {
        NotificationCenter.dismissCurrent();
        notificationHistory = [];
        liveNotifications.slice().forEach(n => n.dismiss());
    }
    function dismissNotification(id) {
        notificationHistory = notificationHistory.filter(n => n.id !== id);
        const found = liveNotifications.find(n => n.id === id);
        if (found)
            found.dismiss();
    }
    Timer {
        id: osdTimer
        interval: Math.round(Preferences.notificationSeconds * 1000)
        onTriggered: root.osd = ""
    }
    Timer {
        id: workspaceTimer
        interval: 1000
        onTriggered: root.workspaceNotice = false
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            if (root.panel !== "auth")
                root.close();
            root.osd = "";
            root.statusNotice = "";
            root.noticeDetail = "";
            workspaceTimer.interval = Math.round(Preferences.notificationSeconds * 1000);
            root.noticeKind = "workspace";
            root.workspaceNotice = Preferences.workspaceOsd && Preferences.eventEnabled("workspace");
            workspaceTimer.restart();
        }
    }
}
