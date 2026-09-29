//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RHI_BACKEND=vulkan
//@ pragma Env QSG_RENDER_LOOP=threaded
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs

ShellRoot {
    id: root
    property bool authReady: Auth.registered
    NotificationServer {
        id: notifications
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: false
        imageSupported: true
        onNotification: notification => {
            notification.tracked = true;
            ShellState.rememberNotification(notification);
            NotificationCenter.present(notification);
        }
    }
    Binding {
        target: ShellState
        property: "liveNotifications"
        value: notifications.trackedNotifications.values
    }
    LowBatteryMonitor {}
    SystemEvents {}
    Overview {}

    Variants {
        model: Quickshell.screens
        Pill {
            required property var modelData
            screen: modelData
        }
    }
    IpcHandler {
        target: "hshell"
        function lockvisible(value: bool) {
            ShellState.locked = value;
            if (value)
                ShellState.close();
        }
        function lockstate(): string {
            return JSON.stringify({
                power: Backend.powerProfile,
                dnd: ShellState.dnd,
                nightlight: Backend.nightLightStatus === "on",
                awake: !!Tasks.caffeine.result.enabled,
                notifications: ShellState.notificationHistory.slice(0, 3).map(n => (n.summary || "") + " · " + (n.body || ""))
            });
        }
        function notice(kind: string, text: string) {
            if (Object.keys(Preferences.option("events", {})).includes(kind))
                ShellState.notice(kind, text);
        }
        function ruler() {
            ShellState.close();
            Quickshell.execDetached(["bash", ShellState.scripts + "screen-measure.sh"]);
        }
        function overview() {
            if (Auth.active)
                return;
            const opening = !ShellState.overviewOpen;
            ShellState.close();
            ShellState.activeScreen = ShellState.currentScreen();
            ShellState.overviewOpen = opening;
        }
        function ping(): string {
            return "hshell";
        }
        function toggle(panel: string) {
            if (!Auth.active)
                ShellState.show(panel);
        }
        function close() {
            ShellState.close();
        }
        function terminal(action: string) {
            if (["update", "clean", "password"].includes(action))
                ShellState.terminal(action);
        }
        function profile() {
            Backend.cyclePowerProfile();
        }
        function nightlight() {
            ShellState.nightLightTemperature = 4500;
            Backend.toggleNightLight();
        }
        function pickcolor() {
            ShellState.close();
            Tasks.color.start(["pick-color"]);
        }
        function dnd() {
            ShellState.dnd = !ShellState.dnd;
            ShellState.notice("dnd", "Peace " + (ShellState.dnd ? "On" : "Off"));
        }
        function osd(kind: string) {
            if (kind === "brightness")
                Backend.refreshStatus();
            if (["volume", "brightness"].includes(kind))
                ShellState.showOsd(kind);
        }
        function tool(name: string) {
            if (!Auth.active) {
                ShellState.navigation = [];
                ShellState.setPanel("menu");
                ShellState.side(name, "left");
            }
        }
        function caffeine() {
            Tasks.caffeine.start(["caffeine", "toggle"]);
        }
    }
}
