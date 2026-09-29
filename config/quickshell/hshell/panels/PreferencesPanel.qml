import QtQuick
import qs
import qs.components

Column {
    id: root
    property bool embedded: true
    property string category: "Notifications"
    property bool dirty: false
    property real draftSeconds: Preferences.notificationSeconds
    property var draft: JSON.parse(JSON.stringify(Preferences.options))
    spacing: 6
    readonly property var eventNames: ({
            volume: "Volume",
            brightness: "Brightness",
            power: "Power Plan",
            battery: "Low Battery",
            charging: "Charging",
            usb: "USB Devices",
            wifi: "Wi-Fi",
            bluetooth: "Bluetooth",
            dnd: "Do Not Disturb",
            idle: "Idle",
            keyboard: "Keyboard Layout",
            capslock: "Caps Lock",
            nightlight: "Night Light",
            applications: "Applications",
            download: "Download",
            screenshot: "Screenshot",
            ocr: "Image to Text",
            color: "Color Picker",
            search: "Screen Search",
            measure: "Screen Measure",
            workspace: "Workspace",
            fullscreenNotifications: "In Fullscreen"
        })
    function change(key, value) {
        draft = Object.assign({}, draft, {
            [key]: value
        });
        dirty = true;
    }
    function nested(key, name, value) {
        change(key, Object.assign({}, draft[key] || {}, {
            [name]: value
        }));
    }
    Connections {
        target: Preferences
        function onOptionsChanged() {
            if (!root.dirty)
                root.draft = JSON.parse(JSON.stringify(Preferences.options));
        }
        function onSaveErrorChanged() {
            if (Preferences.saveError)
                root.dirty = true;
        }
    }
    Repeater {
        model: root.category === "Lock Screen" ? [["lockMuteAudio", "Mute Audio on Lock"], ["lockMuteMic", "Mute Microphone on Lock"]] : []
        Item {
            required property var modelData
            width: parent.width
            height: 40
            BodyText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 64
                text: modelData[1]
            }
            Toggle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: root.draft[modelData[0]] !== false
                onToggled: root.change(modelData[0], checked)
            }
        }
    }
    Repeater {
        model: root.category === "Folders" ? [["serverFolder", "Server"], ["isoFolder", "ISO"], ["downloadFolder", "Downloads"], ["screenshotFolder", "Screenshots"]] : []
        Column {
            required property var modelData
            width: parent.width
            spacing: 6
            BodyText {
                text: modelData[1]
            }
            Field {
                width: parent.width
                text: root.draft[modelData[0]] || ""
                onTextEdited: root.change(modelData[0], text)
            }
        }
    }
    Column {
        width: parent.width
        spacing: 8
        visible: root.category === "Notifications"
        BodyText {
            text: "Duration · " + root.draftSeconds.toFixed(1) + " s"
        }
        ThinSlider {
            width: parent.width
            icon: "󰔛"
            value: (root.draftSeconds - 0.1) / 9.9
            displayValue: root.draftSeconds.toFixed(1) + " s"
            onMoved: {
                root.draftSeconds = Math.round((value * 9.9 + 0.1) * 10) / 10;
                root.dirty = true;
            }
        }
        Grid {
            width: parent.width
            columns: 2
            columnSpacing: 20
            rowSpacing: 2
            Repeater {
                model: Object.keys(root.eventNames)
                Item {
                    required property string modelData
                    property string group: "events"
                    width: (parent.width - parent.columnSpacing) / 2
                    height: 40
                    BodyText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 64
                        text: root.eventNames[modelData]
                    }
                    Toggle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: modelData === "fullscreenNotifications" ? root.draft.fullscreenNotifications !== false : (root.draft.events || {})[modelData] !== false
                        onToggled: modelData === "fullscreenNotifications" ? root.change(modelData, checked) : root.nested("events", modelData, checked)
                    }
                }
            }
        }
    }
    Row {
        width: parent.width
        spacing: 8
        ActionIcon {
            width: 44
            height: 44
            hint: "Discard changes"
            text: "↶"
            onClicked: {
                root.draft = JSON.parse(JSON.stringify(Preferences.options));
                root.draftSeconds = Preferences.notificationSeconds;
                root.dirty = false;
            }
        }
        Item {
            width: parent.width - 104
            height: 44
        }
        ActionIcon {
            width: 44
            height: 44
            hint: "Apply changes"
            text: Preferences.saving ? "…" : "✓"
            onClicked: {
                Preferences.setOptions(root.draft);
                if (root.category === "Notifications")
                    Preferences.save("notificationSeconds", String(root.draftSeconds));
                root.dirty = false;
            }
        }
    }
    BodyText {
        width: parent.width
        visible: !!Preferences.saveError
        text: Preferences.saveError
        color: Style.muted
    }
}
