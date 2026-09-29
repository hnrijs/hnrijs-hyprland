import QtQuick
import QtQuick.Controls
import qs
import qs.components

Column {
    id: root
    spacing: 10
    property var bindings: []
    property string selectedId: ""
    property bool dirty: false
    function select(entry) {
        selectedId = entry.id;
        shortcut.text = entry.key;
        command.text = entry.command || "";
        enabledToggle.checked = !entry.disabled;
    }
    function updateEntry() {
        const scroll = bindingsList.contentY;
        bindings = bindings.map(entry => entry.id === selectedId ? Object.assign({}, entry, {
                key: shortcut.text,
                command: command.text,
                disabled: !enabledToggle.checked
            }) : entry);
        dirty = true;
        Qt.callLater(() => bindingsList.contentY = Math.min(scroll, Math.max(0, bindingsList.contentHeight - bindingsList.height)));
    }
    Component.onCompleted: Tasks.device.start(["system-settings", "keybinds"])
    Connections {
        target: Tasks.device
        function onFinished(success) {
            if (success && Tasks.device.result.bindings) {
                root.bindings = Tasks.device.result.bindings;
                root.dirty = false;
            }
        }
    }
    Row {
        width: parent.width
        spacing: 8
        Field {
            id: search
            width: parent.width - 52
            placeholderText: "Search Keybinds"
        }
        PillButton {
            width: 44
            text: "+"
            Accessible.name: "Add Keybind"
            onClicked: {
                const entry = {
                    id: "custom:" + Date.now(),
                    key: "SUPER + F12",
                    label: "Custom Command",
                    command: "",
                    disabled: false
                };
                root.bindings = root.bindings.concat([entry]);
                root.select(entry);
                root.dirty = true;
            }
        }
    }
    ListView {
        id: bindingsList
        width: parent.width
        height: Math.min(contentHeight, 240)
        clip: true
        spacing: 6
        model: root.bindings.filter(entry => (entry.key + " " + entry.label + " " + entry.command).toLowerCase().includes(search.text.toLowerCase()))
        delegate: ControlTile {
            required property var modelData
            width: ListView.view.width
            implicitHeight: 58
            symbol: "󰌌"
            text: modelData.key
            detail: modelData.command || modelData.label
            selected: root.selectedId === modelData.id
            onClicked: root.select(modelData)
        }
        ScrollBar.vertical: ScrollBar {}
    }
    Column {
        width: parent.width
        spacing: 8
        visible: root.selectedId !== ""
        Field {
            id: shortcut
            width: parent.width
            placeholderText: "SUPER + SHIFT + E"
            onTextEdited: root.updateEntry()
        }
        Field {
            id: command
            width: parent.width
            placeholderText: "Keep Original Action"
            onTextEdited: root.updateEntry()
        }
        CheckToggle {
            id: enabledToggle
            text: "Enabled"
            onClicked: root.updateEntry()
        }
    }
    PillButton {
        width: parent.width
        text: "Apply Keybinds"
        enabled: !Tasks.device.running
        onClicked: Tasks.device.start(["system-settings", "save-keybinds", JSON.stringify({
                bindings: root.bindings
            })])
    }
    TaskStatus {
        width: parent.width
        task: Tasks.device
        showCancel: false
    }
}
