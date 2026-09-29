import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs
import qs.components

Column {
    id: root
    required property string kind
    spacing: 10
    function terminal(action) {
        ShellState.terminal(action);
    }
    function refresh() {
        if (kind === "disks")
            Tasks.disks.start(["disks"]);
    }
    Component.onCompleted: refresh()
    onKindChanged: refresh()
    Loader {
        width: parent.width
        height: item ? item.implicitHeight : 0
        sourceComponent: root.kind === "preferences" ? preferences : ["translate", "server", "words", "ocr", "phone", "iso"].includes(root.kind) ? utilities : ["power-settings", "keybinds", "defaults", "timezone", "mouse", "keyboard", "monitor", "user", "maintenance"].includes(root.kind) ? deviceSettings : root.kind === "firewall" ? firewallSettings : root.kind === "qr" ? qrCode : root.kind === "interface" ? interfaceSettings : root.kind === "system" ? systemSettings : root.kind === "network" ? networkSettings : root.kind === "calculator" ? calculator : root.kind === "color" ? color : root.kind === "exif" ? exif : root.kind === "disks" ? disks : root.kind === "speed" ? speed : root.kind === "download" ? download : root.kind === "media" ? media : root.kind === "ip" ? ip : root.kind === "emoji" ? emoji : root.kind === "periodic" ? periodic : settings
    }
    Component {
        id: preferences
        PreferencesPanel {}
    }
    Component {
        id: utilities
        UtilityPanel {
            kind: root.kind
        }
    }
    Component {
        id: firewallSettings
        FirewallPanel {}
    }
    Component {
        id: qrCode
        QrPanel {}
    }
    Component {
        id: deviceSettings
        DeviceSettingsPanel {
            kind: root.kind
        }
    }
    Component {
        id: disks
        Column {
            spacing: 10
            PillButton {
                width: parent.width
                text: "Refresh disks"
                enabled: !Tasks.disks.running
                onClicked: Tasks.disks.start(["disks"])
            }
            TaskStatus {
                width: parent.width
                task: Tasks.disks
            }
            Repeater {
                model: Tasks.disks.result.disks || []
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: dc.implicitHeight + 24
                    radius: 18
                    color: Style.bg1
                    Column {
                        id: dc
                        x: 12
                        y: 12
                        width: parent.width - 24
                        spacing: 8
                        BodyText {
                            width: parent.width
                            text: (modelData.label || modelData.model || modelData.name) + " · " + (modelData.size / 1073741824).toFixed(1) + " GiB"
                        }
                        BodyText {
                            width: parent.width
                            text: modelData.mountpoint || modelData.name
                            color: Style.muted
                        }
                        Meter {
                            width: parent.width
                            visible: !!modelData.total
                            value: modelData.total ? modelData.used / modelData.total : 0
                        }
                        BodyText {
                            visible: !!modelData.total
                            text: (modelData.free / 1073741824).toFixed(1) + " GiB free"
                        }
                        PillButton {
                            width: parent.width
                            visible: !!modelData.fstype && modelData.mountpoint !== "/"
                            text: modelData.mountpoint ? "Unmount" : "Mount"
                            enabled: !Tasks.disks.running
                            onClicked: Tasks.disks.start([modelData.mountpoint ? "unmount" : "mount", modelData.name])
                        }
                    }
                }
            }
        }
    }
    Component {
        id: speed
        Column {
            spacing: 16
            Rectangle {
                width: Math.min(parent.width, 260)
                anchors.horizontalCenter: parent.horizontalCenter
                height: width
                radius: width / 2
                color: Style.bg1
                border.color: Style.primary
                border.width: 3
                Column {
                    anchors.centerIn: parent
                    width: parent.width - 28
                    spacing: 10
                    BodyText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Tasks.speed.running ? (Tasks.speed.progress.phase || "Connecting…") : "Speed Test"
                        color: Style.primary
                    }
                    BodyText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 34
                        text: Number((Tasks.speed.running ? Tasks.speed.progress.download : Tasks.speed.result.download) || 0).toFixed(1)
                    }
                    BodyText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "Mbps download"
                    }
                    BodyText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Number((Tasks.speed.running ? Tasks.speed.progress.upload : Tasks.speed.result.upload) || 0).toFixed(1) + " Mbps upload"
                    }
                    BodyText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Number((Tasks.speed.running ? Tasks.speed.progress.ping : Tasks.speed.result.ping) || 0).toFixed(0) + " ms ping"
                    }
                }
            }
            BodyText {
                width: parent.width
                visible: !!Tasks.speed.result.server
                text: Tasks.speed.result.server || ""
                color: Style.muted
            }
            PillButton {
                width: parent.width
                text: Tasks.speed.running ? "Stop" : "Start"
                onClicked: Tasks.speed.running ? Tasks.speed.cancel() : Tasks.speed.start(["speed"])
            }
            TaskStatus {
                width: parent.width
                task: Tasks.speed
                showCancel: false
            }
            PillButton {
                width: 44
                text: "󰆏"
                onClicked: Quickshell.execDetached(["wl-copy", "--", JSON.stringify(Tasks.speed.result, null, 2)])
            }
        }
    }
    Component {
        id: download
        Column {
            spacing: 10
            Choice {
                id: format
                width: parent.width
                model: ["MP4", "MP3", "File", "Magnet", "Torrent", "HTML", "Git"]
            }
            Field {
                id: url
                width: parent.width
                visible: format.currentText !== "Torrent"
                placeholderText: "https://… or magnet:…"
            }
            FileField {
                id: torrent
                width: parent.width
                visible: format.currentText === "Torrent"
                caption: "Choose Torrent"
            }
            Field {
                id: directory
                width: parent.width
                text: Preferences.folder("downloadFolder", "~/Downloads")
                placeholderText: "Destination folder"
            }
            CheckToggle {
                id: playlist
                text: "Download playlist"
                palette.windowText: Style.foreground
            }
            PillButton {
                width: parent.width
                text: "Download"
                enabled: (format.currentText === "Torrent" ? torrent.path.trim() !== "" : url.text.trim() !== "") && !Tasks.download.running
                onClicked: Tasks.download.start(["download", format.currentText.toLowerCase(), format.currentText === "Torrent" ? torrent.path : url.text, directory.text, playlist.checked ? "true" : "false"])
            }
            TaskStatus {
                width: parent.width
                task: Tasks.download
            }
        }
    }
    Component {
        id: media
        Column {
            id: editor
            spacing: 10
            property string mediaKind: ""
            property var formats: mediaKind === "video" ? ["MP4", "MKV", "WEBM", "MOV"] : mediaKind === "image" ? ["PNG", "JPG", "WEBP", "TIFF", "BMP"] : ["MP3", "M4A", "FLAC", "WAV", "OPUS", "OGG"]
            property var enabledEdits: ({})
            function toggle(name) {
                let next = Object.assign({}, enabledEdits);
                next[name] = !next[name];
                enabledEdits = next;
            }
            Row {
                width: parent.width
                spacing: 8
                Repeater {
                    model: ["Video", "Audio", "Image"]
                    PillButton {
                        required property string modelData
                        width: (editor.width - 16) / 3
                        objectName: "media-kind-" + modelData.toLowerCase()
                        text: modelData
                        selected: editor.mediaKind === modelData.toLowerCase()
                        onClicked: {
                            editor.mediaKind = modelData.toLowerCase();
                            editor.enabledEdits = ({});
                            outputFormat.currentIndex = 0;
                        }
                    }
                }
            }
            FileField {
                id: file
                width: parent.width
                visible: editor.mediaKind !== ""
            }
            Choice {
                id: outputFormat
                visible: editor.mediaKind !== ""
                width: parent.width
                model: editor.formats
            }
            Flow {
                visible: editor.mediaKind !== ""
                width: parent.width
                spacing: 8
                Repeater {
                    model: editor.mediaKind === "video" ? ["Resize", "FPS", "Mute", "Rotate", "Mirror"] : editor.mediaKind === "image" ? ["Resize", "Rotate", "Mirror", "Grayscale"] : ["Mute", "Normalize"]
                    PillButton {
                        required property string modelData
                        required property int index
                        width: editor.mediaKind === "video" && index < 3 ? (editor.width - 16) / 3 : (editor.width - 8) / 2
                        objectName: "media-edit-" + modelData.toLowerCase()
                        text: ({
                                Resize: "󰩨",
                                FPS: "󰓅",
                                Mute: "󰝟",
                                Rotate: "󰑋",
                                Mirror: "󰓉",
                                Grayscale: "󰏘",
                                Normalize: "󰕾"
                            })[modelData] + "  " + modelData
                        selected: !!editor.enabledEdits[modelData.toLowerCase()]
                        onClicked: editor.toggle(modelData.toLowerCase())
                    }
                }
            }
            Field {
                id: rotation
                width: parent.width
                visible: !!editor.enabledEdits.rotate
                text: "90"
                placeholderText: "Angle in degrees"
            }
            Field {
                id: dimensions
                objectName: "media-dimensions"
                width: parent.width
                visible: !!editor.enabledEdits.resize
                placeholderText: "Width × Height · 1280x720 / 1080x1080"
            }
            Row {
                width: parent.width
                spacing: 8
                visible: editor.mediaKind === "video" && !!editor.enabledEdits.fps
                Choice {
                    id: fpsPreset
                    objectName: "media-fps"
                    width: currentIndex === 4 ? (parent.width - 8) / 2 : parent.width
                    model: ["24 FPS", "30 FPS", "60 FPS", "120 FPS", "Custom FPS"]
                    currentIndex: 1
                }
                Field {
                    id: fpsCustom
                    width: (parent.width - 8) / 2
                    visible: fpsPreset.currentIndex === 4
                    placeholderText: "FPS · 59.94"
                }
            }
            PillButton {
                width: parent.width
                visible: editor.mediaKind !== ""
                text: "󰐊  Run"
                enabled: file.path !== "" && !Tasks.media.running
                onClicked: {
                    let options = Object.assign({}, editor.enabledEdits);
                    options.kind = editor.mediaKind;
                    options.format = editor.formats[outputFormat.currentIndex].toLowerCase();
                    options.size = dimensions.text;
                    options.angle = rotation.text;
                    options.rate = fpsPreset.currentIndex === 4 ? fpsCustom.text : String([24, 30, 60, 120][fpsPreset.currentIndex]);
                    Tasks.media.start(["media-edit", file.path, JSON.stringify(options)]);
                }
            }
            TaskStatus {
                width: parent.width
                task: Tasks.media
            }
            BodyText {
                width: parent.width
                text: Tasks.media.result.path || Tasks.media.result.text || ""
                font.pixelSize: 12
            }
        }
    }

    Component {
        id: ip
        Column {
            spacing: 10
            Field {
                id: address
                width: parent.width
                placeholderText: "IP address (blank = your public IP)"
                onAccepted: Tasks.ip.start(["ip", text])
            }
            PillButton {
                width: parent.width
                text: "Look Up"
                enabled: !Tasks.ip.running
                onClicked: Tasks.ip.start(["ip", address.text])
            }
            TaskStatus {
                width: parent.width
                task: Tasks.ip
            }
            BodyText {
                width: parent.width
                text: [Tasks.ip.result.ip, Tasks.ip.result.city, Tasks.ip.result.region, Tasks.ip.result.country, Tasks.ip.result.isp, Tasks.ip.result.timezone].filter(Boolean).join("\n")
            }
            BodyText {
                width: parent.width
                text: "Approximate public-IP location from ipwho.is."
                color: Style.muted
            }
            Row {
                width: parent.width
                PillButton {
                    width: 44
                    text: "󰆏"
                    Accessible.name: "Copy IP Result"
                    onClicked: Quickshell.execDetached(["wl-copy", "--", [Tasks.ip.result.ip, Tasks.ip.result.city, Tasks.ip.result.region, Tasks.ip.result.country, Tasks.ip.result.isp, Tasks.ip.result.timezone].filter(Boolean).join("\n")])
                }
                Item {
                    width: parent.width - 88
                    height: 44
                }
                PillButton {
                    width: 44
                    text: "󰃢"
                    Accessible.name: "Clear IP Result"
                    enabled: !Tasks.ip.running
                    onClicked: {
                        Tasks.ip.result = ({});
                        Tasks.ip.error = "";
                        address.text = "";
                    }
                }
            }
        }
    }
    Component {
        id: emoji
        EmojiPanel {}
    }
    Component {
        id: exif
        ExifPanel {}
    }
    Component {
        id: periodic
        PeriodicPanel {}
    }
    Component {
        id: settings
        Column {
            spacing: 10
            BodyText {
                width: parent.width
                text: ({
                        apps: "",
                        search: "Search your files and open a result with its default app.",
                        color: "Select a screen pixel; its hex value is copied to the clipboard.",
                        config: "Edit your own Hyprland configuration. No sudo is used.",
                        startup: "Autostart commands are grouped inside hyprland.lua.",
                        update: "Upgrade official packages and installed AUR packages when an AUR helper is present.",
                        clean: "Review cache cleanup and unused packages in a terminal.",
                        account: "Change your password or leave this session to choose another user.",
                        network: "Edit connections, addresses and DNS using NetworkManager.",
                        appearance: "Browse wallpapers.",
                        power: "Lock, log out, suspend or power off.",
                        diagnostics: "Inspect monitors, input devices and graphics logs."
                    })[root.kind] || ""
            }
            Repeater {
                model: ({
                        apps: [["Install", "install-app"], ["Uninstall", "remove-app"]],
                        search: [["Search files", "find-file"], ["Search file contents", "find-text"]],
                        color: [["Pick color", "color"]],
                        config: [["Edit hyprland.lua", "edit-hypr"]],
                        startup: [["Edit startup commands", "edit-hypr"]],
                        update: [["Update system", "update"]],
                        clean: [["Clean system", "clean"]],
                        account: [["Change password", "password"], ["Switch user / log out", "logout"]],
                        network: [["Connections / DNS", "network"], ["Network diagnostics", "network-info"]],
                        appearance: [["Wallpapers", "appearance"]],
                        power: [["Session controls", "power"]],
                        diagnostics: [["System information", "info"], ["Monitors", "monitors"], ["Collect diagnostics", "diagnostics"]]
                    })[root.kind] || []
                delegate: PillButton {
                    required property var modelData
                    width: parent.width
                    text: modelData[0]
                    onClicked: {
                        if (modelData[1] === "appearance")
                            ShellState.setPanel("wallpaper");
                        else if (["power", "logout"].includes(modelData[1]))
                            ShellState.setPanel("power");
                        else if (modelData[1] === "color") {
                            ShellState.close();
                            Quickshell.execDetached(["hyprpicker", "-a"]);
                        } else
                            root.terminal(modelData[1]);
                    }
                }
            }
        }
    }
    Component {
        id: interfaceSettings
        InterfacePanel {}
    }
    Component {
        id: systemSettings
        SystemPanel {}
    }
    Component {
        id: networkSettings
        NetworkPanel {}
    }
    Component {
        id: calculator
        CalculatorPanel {}
    }
    Component {
        id: color
        ColorPanel {}
    }
}
