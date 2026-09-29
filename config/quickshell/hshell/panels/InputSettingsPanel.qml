import QtQuick
import qs
import qs.components

Column {
    id: root
    required property string kind
    property real sensitivity: 0
    property string accel: "flat"
    property bool natural: false
    property int follow: 1
    property bool loaded: false
    spacing: 12
    function load() {
        const data = Tasks.device.result;
        if (data.sensitivity === undefined)
            return;
        loaded = true;
        sensitivity = Number(data.sensitivity);
        accel = data.accel || "flat";
        natural = !!data.natural;
        follow = Number(data.follow || 0);
        layouts.text = data.layouts || "lv";
        variants.text = data.variants || "";
        options.text = data.options || "";
    }
    function save() {
        if (!loaded)
            return;
        if (Tasks.device.running) {
            return;
        }
        Tasks.device.start(["system-settings", "save-input", JSON.stringify({
                sensitivity: sensitivity,
                accel: accel,
                natural: natural,
                follow: follow,
                layouts: layouts.text,
                variants: variants.text,
                options: options.text
            })]);
    }
    Component.onCompleted: Tasks.device.start(["system-settings", "input"])
    Connections {
        target: Tasks.device
        function onFinished(success) {
            if (success && !commit.running)
                root.load();
        }
    }
    Timer {
        id: commit
        interval: 300
        onTriggered: root.save()
    }
    BodyText {
        visible: root.kind === "mouse"
        text: "Sensitivity"
    }
    ThinSlider {
        visible: root.kind === "mouse"
        width: parent.width
        icon: "󰍽"
        value: (root.sensitivity + 1) / 2
        displayValue: root.sensitivity.toFixed(2)
        enabled: root.loaded
        onMoved: {
            root.sensitivity = Math.round((value * 2 - 1) * 100) / 100;
        }
    }
    Field {
        visible: root.kind === "mouse"
        width: parent.width
        text: root.sensitivity.toFixed(2)
        placeholderText: "−1.00 to 1.00"
        onEditingFinished: if (isFinite(Number(text)) && Number(text) >= -1 && Number(text) <= 1) {
            root.sensitivity = Number(text);
        }
    }
    Row {
        visible: root.kind === "mouse"
        width: parent.width
        spacing: 8
        ControlTile {
            width: (parent.width - 8) / 2
            symbol: "󰍽"
            text: "Flat"
            detail: "No Acceleration"
            selected: root.accel === "flat"
            onClicked: {
                root.accel = "flat";
            }
        }
        ControlTile {
            width: (parent.width - 8) / 2
            symbol: "󰓅"
            text: "Adaptive"
            detail: "Pointer Acceleration"
            selected: root.accel === "adaptive"
            onClicked: {
                root.accel = "adaptive";
            }
        }
    }
    ControlTile {
        visible: root.kind === "mouse"
        width: parent.width
        symbol: "󰟸"
        text: "Natural Scrolling"
        detail: "Touchpad"
        selected: root.natural
        onClicked: {
            root.natural = !root.natural;
        }
    }
    BodyText {
        visible: root.kind === "keyboard"
        text: "Layouts"
    }
    Field {
        id: layouts
        visible: root.kind === "keyboard"
        width: parent.width
        placeholderText: "lv,us,de"
    }
    BodyText {
        visible: root.kind === "keyboard"
        text: "Variants"
    }
    Field {
        id: variants
        visible: root.kind === "keyboard"
        width: parent.width
        placeholderText: "Default"
    }
    BodyText {
        visible: root.kind === "keyboard"
        text: "XKB Options"
    }
    Field {
        id: options
        visible: root.kind === "keyboard"
        width: parent.width
        placeholderText: "Default"
    }
    PillButton {
        width: parent.width
        text: "Apply"
        enabled: root.loaded && !Tasks.device.running
        onClicked: root.save()
    }
    TaskStatus {
        width: parent.width
        task: Tasks.device
        showCancel: false
    }
}
