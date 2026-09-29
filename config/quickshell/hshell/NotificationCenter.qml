pragma Singleton
import QtQuick
import Quickshell
import qs

Singleton {
    id: root
    property var current: null
    property string screenName: ""
    property bool hovered: false
    function setHovered(value) {
        hovered = value;
        if (value)
            expiry.stop();
        else
            dismissCurrent();
    }
    function present(notification) {
        const previous = current;
        if (!Preferences.notifications || !Preferences.eventEnabled("applications") || ShellState.dnd) {
            dismissCurrent();
            notification.expire();
            return;
        }
        const nextScreen = ShellState.currentScreen();
        const keepHover = hovered && screenName === nextScreen;
        screenName = nextScreen;
        current = notification;
        hovered = keepHover;
        if (previous && previous !== notification)
            previous.expire();
        if (!hovered)
            expiry.restart();
    }
    function dismissCurrent() {
        const old = current;
        current = null;
        hovered = false;
        expiry.stop();
        if (old)
            old.expire();
    }
    Timer {
        id: expiry
        interval: Math.round(Preferences.notificationSeconds * 1000)
        onTriggered: root.dismissCurrent()
    }
    Connections {
        target: ShellState
        function onDndChanged() {
            if (ShellState.dnd)
                root.dismissCurrent();
        }
    }
    Connections {
        target: root.current
        function onClosed(reason) {
            root.current = null;
            root.hovered = false;
            expiry.stop();
        }
    }
}
