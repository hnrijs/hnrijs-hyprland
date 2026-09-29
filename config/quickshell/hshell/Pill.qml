import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.components

Scope {
    id: root
    required property var screen
    readonly property bool expanded: ShellState.expanded && ShellState.activeScreen === screen.name
    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === root.screen.name) || null
    readonly property bool fullscreen: Preferences.hideFullscreen && monitor && monitor.activeWorkspace && monitor.activeWorkspace.hasFullscreen
    readonly property bool showingNotification: Preferences.notifications && !ShellState.dnd && !expanded && !!NotificationCenter.current && NotificationCenter.screenName === screen.name
    PanelWindow {
        screen: root.screen
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 58
        exclusiveZone: root.fullscreen ? 0 : implicitHeight
        visible: !root.fullscreen && !ShellState.locked
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "hshell-space"
    }
    PanelWindow {
        id: window
        visible: !ShellState.locked && (root.expanded || !root.fullscreen || (root.showingNotification && Preferences.option("fullscreenNotifications", true)) || ((ShellState.workspaceNotice || ShellState.osd !== "") && Preferences.option("fullscreenNotifications", true)))
        screen: root.screen
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: root.screen.height
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "hshell"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.expanded && !ShellState.externalDialog ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        HyprlandFocusGrab {
            active: false
            windows: [window]
            onCleared: if (!ShellState.externalDialog)
                ShellState.close()
        }
        mask: Region {
            item: card
            radius: 26
        }
        Rectangle {
            id: card
            focus: root.expanded
            onFocusChanged: if (focus)
                forceActiveFocus()
            x: (parent.width - width) / 2
            y: 8
            width: root.expanded ? Math.min(root.screen.width - 24, ShellState.panel === "calendar" ? 460 : ShellState.panel === "tool" && ShellState.toolName === "periodic" ? 1040 : ShellState.panel === "wallpaper" ? 900 : ShellState.panel === "menu" ? 540 : 620) : root.showingNotification ? Math.min(root.screen.width - 24, 520) : compact.desiredWidth
            height: root.expanded ? Math.min(root.screen.height - card.y - 16, Math.max(70, panelLoader.item ? panelLoader.item.implicitHeight : 70)) : root.showingNotification ? (notificationLoader.item ? notificationLoader.item.implicitHeight : 90) : compact.desiredHeight
            radius: 26
            color: Style.bg0
            clip: true
            border.color: Style.bg3
            border.width: root.expanded ? 1 : 0
            Behavior on width {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on height {
                NumberAnimation {
                    id: grow
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
            HoverHandler {
                id: cardHover
            }
            CompactPill {
                id: compact
                externalHover: true
                hovered: Preferences.hoverExpand && cardHover.hovered && !root.expanded && !root.showingNotification
                width: parent.width
                visible: !root.expanded && !root.showingNotification
                screenName: root.screen.name
            }
            Loader {
                id: notificationLoader
                width: parent.width
                active: root.showingNotification
                visible: active
                sourceComponent: Component {
                    NotificationView {
                        expanded: false
                        viewHeight: card.height
                    }
                }
            }
            Loader {
                id: panelLoader
                anchors.fill: parent
                active: root.expanded
                visible: root.expanded
                sourceComponent: Component {
                    PanelContent {
                        shellWindow: window
                    }
                }
            }
            Keys.onEscapePressed: ShellState.dismissInterface()
        }
    }
}
