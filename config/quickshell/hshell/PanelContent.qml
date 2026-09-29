import QtQuick
import Quickshell
import QtQuick.Controls
import qs
import qs.components
import qs.panels

Item {
    id: root
    focus: true
    Keys.onEscapePressed: ShellState.dismissInterface()
    readonly property bool headerless: ["launcher", "calendar", "power", "auth", "wallpaper", "menu"].includes(page)
    readonly property real topInset: headerless ? 18 : 72
    implicitHeight: topInset + 18 + content.height
    required property var shellWindow
    property string page: ShellState.panel
    readonly property string title: page === "tool" ? ({
            fstab: "Filesystems",
            initramfs: "Initramfs",
            "boot-entries": "Boot Entries",
            "boot-settings": "Boot Settings",
            preferences: "Preferences",
            "power-settings": "Power",
            keybinds: "Keybinds",
            qr: "QR Code",
            firewall: "Firewall",
            translate: "Translate",
            server: "Local Server",
            words: "Word Counter",
            ocr: "Image to Text",
            phone: "Phone Mirror",
            iso: "ISO Flash",
            defaults: "Default Apps",
            timezone: "Timezone",
            mouse: "Mouse",
            keyboard: "Keyboard",
            monitor: "Monitor",
            user: "User",
            maintenance: "Maintenance",
            interface: "Interface",
            system: "System",
            calculator: "Calculator",
            disks: "Disk space",
            apps: "App Manager",
            search: "File search",
            speed: "Speed Test",
            emoji: "Emoji",
            color: "Color Picker",
            media: "Media Tools",
            exif: "EXIF",
            download: "Downloader",
            ip: "IP Locator",
            periodic: "Periodic Table",
            config: "Hyprland",
            startup: "Startup",
            account: "Account",
            update: "System Update",
            clean: "System Clean",
            network: "Network",
            diagnostics: "Diagnostics"
        })[ShellState.toolName] || "Tools" : ({
            control: "Control Center",
            menu: "Menu",
            tools: "Tools",
            settings: "Settings",
            emoji: "Emoji",
            color: "Colors",
            calendar: "Calendar",
            wallpaper: "Wallpaper",
            launcher: "Applications",
            clipboard: "Clipboard",
            power: "Session",
            overview: "Workspaces",
            auth: "Authentication",
            detail: ({
                    wifi: "Wi-Fi",
                    bluetooth: "Bluetooth",
                    audio: "Audio",
                    microphone: "Audio",
                    nightlight: "Night Light",
                    powerprofile: "Power Profile",
                    tray: "Tray apps"
                })[ShellState.detailName]
        })[page] || "hshell"
    Row {
        id: navigation
        visible: !root.headerless
        x: 20
        y: 14
        width: parent.width - 40
        height: 44
        spacing: 12
        PillButton {
            width: 44
            height: 44
            text: "‹"
            visible: root.page !== "auth"
            onClicked: ShellState.back()
        }
        BodyText {
            width: navigation.width - (root.page === "auth" ? 0 : 112)
            height: 44
            text: root.title
            font.pixelSize: 19
            verticalAlignment: Text.AlignVCenter
            maximumLineCount: 1
            elide: Text.ElideRight
        }
        PillButton {
            width: 44
            height: 44
            text: root.page === "control" ? "󰌾" : root.page === "clipboard" ? "󰃢" : ""
            visible: ["control", "clipboard"].includes(root.page)
            Accessible.name: root.page === "control" ? "Power menu" : "Clear clipboard history"
            onClicked: {
                if (root.page === "control") {
                    ShellState.setPanel("power");
                } else
                    Tasks.clipboard.start(["clipboard-clear"]);
            }
        }
        Toggle {
            visible: root.page === "detail" && ["wifi", "bluetooth", "nightlight"].includes(ShellState.detailName)
            checked: ShellState.detailName === "wifi" ? Controls.wifiOn : ShellState.detailName === "bluetooth" ? !!Controls.adapter && Controls.adapter.enabled : Backend.nightLightStatus === "on"
            Accessible.name: root.title
            onToggled: {
                if (ShellState.detailName === "wifi")
                    Controls.wifi();
                else if (ShellState.detailName === "bluetooth")
                    Controls.bluetooth();
                else
                    Backend.toggleNightLight();
            }
        }
    }

    Rectangle {
        x: 20
        visible: false
        y: 70
        width: parent.width - 40
        height: 1
        color: Style.bg3
    }
    Flickable {
        id: viewport
        objectName: "panelViewport"
        x: 20
        y: root.topInset
        width: parent.width - 40
        height: Math.max(0, parent.height - y - 18)
        contentWidth: width
        contentHeight: content.height
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            visible: size < 1
            width: 6
            contentItem: Rectangle {
                radius: 3
                color: Style.muted
            }
        }
        Loader {
            id: content
            objectName: "pageLoader"
            width: viewport.width
            height: item ? item.implicitHeight : 0
            sourceComponent: ({
                    control: controls,
                    menu: menu,
                    tools: menu,
                    settings: settings,
                    emoji: emoji,
                    color: color,
                    calendar: calendar,
                    wallpaper: wallpaper,
                    launcher: launcher,
                    clipboard: clipboard,
                    power: power,
                    tool: tool,
                    detail: details,
                    auth: auth
                })[root.page] || null
            onLoaded: {
                viewport.contentY = 0;
                if (["launcher", "clipboard", "auth", "power", "wallpaper"].includes(root.page))
                    Qt.callLater(() => {
                        if (item)
                            item.takeInitialFocus();
                    });
                reveal.restart();
            }
            NumberAnimation {
                id: reveal
                target: content
                property: "y"
                from: 10
                to: 0
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }
    Component {
        id: controls
        ControlPanel {
            shellWindow: root.shellWindow
        }
    }
    Component {
        id: menu
        MenuPanel {
            kind: root.page
        }
    }
    Component {
        id: settings
        SettingsPanel {}
    }
    Component {
        id: calendar
        CalendarPanel {}
    }
    Component {
        id: wallpaper
        WallpaperPanel {}
    }
    Component {
        id: launcher
        LauncherPanel {}
    }
    Component {
        id: power
        PowerPanel {}
    }
    Component {
        id: emoji
        ToolPanel {
            kind: "emoji"
        }
    }
    Component {
        id: color
        ColorPanel {}
    }
    Component {
        id: tool
        ToolPanel {
            kind: ShellState.toolName
        }
    }
    Component {
        id: details
        DetailsPanel {
            kind: ShellState.detailName
            shellWindow: root.shellWindow
        }
    }
    Component {
        id: auth
        AuthPanel {}
    }
    Component {
        id: clipboard
        Column {
            spacing: 12
            function takeInitialFocus() {
                clips.takeInitialFocus();
            }

            ClipboardPanel {
                id: clips
                width: parent.width
                height: implicitHeight
            }
        }
    }
}
