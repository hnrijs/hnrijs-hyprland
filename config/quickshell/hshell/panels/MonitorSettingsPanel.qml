import QtQuick
import qs
import qs.components

Column {
    id: root
    spacing: 10
    property int selectedIndex: 0
    property var displays: []
    property int vrr: 0
    property var movedPositions: ({})
    readonly property var selectedDisplay: displays[selectedIndex] || null
    function populate() {
        if (!selectedDisplay)
            return;
        const m = selectedDisplay;
        mode.text = m.width > 0 && m.height > 0 ? m.width + "x" + m.height + "@" + Number(m.refreshRate).toFixed(2) : "preferred";
        position.text = m.x + "x" + m.y;
        scale.text = String(m.scale);
        rotation.currentIndex = Number(m.transform || 0);
        workspace.text = String(m.workspace || 1);
    }
    function update() {
        if (!Tasks.device.result.monitors)
            return;
        displays = Tasks.device.result.monitors;
        movedPositions = ({});
        vrr = Number(Tasks.device.result.vrr || 0);
        selectedIndex = Math.min(selectedIndex, Math.max(0, displays.length - 1));
        populate();
    }
    Component.onCompleted: Tasks.device.start(["system-settings", "monitors"])
    Connections {
        target: Tasks.device
        function onFinished(success) {
            if (success)
                root.update();
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: !!Tasks.device.result.pending
        property int ticks: 0
        onTriggered: {
            if (++ticks >= 21 && !Tasks.device.running) {
                ticks = 0;
                Tasks.device.start(["system-settings", "monitors"]);
            }
        }
    }
    Rectangle {
        id: map
        width: parent.width
        height: 170
        radius: 18
        color: Style.bg1
        readonly property real minX: root.displays.length ? Math.min(...root.displays.map(m => m.x)) : 0
        readonly property real minY: root.displays.length ? Math.min(...root.displays.map(m => m.y)) : 0
        function logicalWidth(m) {
            return (Number(m.transform) % 2 ? m.height : m.width) / (m.scale || 1);
        }
        function logicalHeight(m) {
            return (Number(m.transform) % 2 ? m.width : m.height) / (m.scale || 1);
        }
        readonly property real spanX: Math.max(1, ...root.displays.map(m => m.x + logicalWidth(m) - minX))
        readonly property real spanY: Math.max(1, ...root.displays.map(m => m.y + logicalHeight(m) - minY))
        readonly property real factor: Math.min((width - 24) / spanX, (height - 24) / spanY)
        Repeater {
            model: root.displays
            delegate: Rectangle {
                id: displayRect
                required property var modelData
                required property int index
                x: (map.width - map.spanX * map.factor) / 2 + (modelData.x - map.minX) * map.factor + offsetX
                y: (map.height - map.spanY * map.factor) / 2 + (modelData.y - map.minY) * map.factor + offsetY
                width: map.logicalWidth(modelData) * map.factor - 2
                height: map.logicalHeight(modelData) * map.factor - 2
                radius: 6
                color: root.selectedIndex === index ? Style.primary : Style.bg3
                BodyText {
                    anchors.centerIn: parent
                    text: modelData.name
                    color: root.selectedIndex === index ? Style.activeText : Style.foreground
                    font.pixelSize: 11
                }
                objectName: "monitor-" + modelData.name
                border.width: pointer.containsMouse ? 2 : 0
                border.color: Style.foreground
                property real offsetX: 0
                property real offsetY: 0
                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    property point origin
                    property real startX
                    property real startY
                    property real dragFactor
                    onPressed: mouse => {
                        root.selectedIndex = index;
                        root.populate();
                        origin = mapToItem(map, mouse.x, mouse.y);
                        startX = modelData.x;
                        startY = modelData.y;
                        dragFactor = map.factor;
                    }
                    onPositionChanged: mouse => {
                        if (!pressed)
                            return;
                        const point = mapToItem(map, mouse.x, mouse.y);
                        displayRect.offsetX = point.x - origin.x;
                        displayRect.offsetY = point.y - origin.y;
                        position.text = Math.round(startX + displayRect.offsetX / dragFactor) + "x" + Math.round(startY + displayRect.offsetY / dragFactor);
                    }
                    onReleased: {
                        const data = root.displays.slice();
                        data[index] = Object.assign({}, modelData, {
                            x: Math.round(startX + displayRect.offsetX / dragFactor),
                            y: Math.round(startY + displayRect.offsetY / dragFactor)
                        });
                        displayRect.offsetX = 0;
                        displayRect.offsetY = 0;
                        root.movedPositions = Object.assign({}, root.movedPositions, {
                            [modelData.name]: [data[index].x, data[index].y]
                        });
                        root.displays = data;
                    }
                    onCanceled: {
                        displayRect.offsetX = 0;
                        displayRect.offsetY = 0;
                        root.populate();
                    }
                }
            }
        }
    }
    Flow {
        width: parent.width
        spacing: 8
        Repeater {
            model: root.displays
            delegate: PillButton {
                required property var modelData
                required property int index
                width: (parent.width - 8) / 2
                text: modelData.name
                selected: root.selectedIndex === index
                onClicked: {
                    root.selectedIndex = index;
                    root.populate();
                }
            }
        }
    }
    BodyText {
        text: "Resolution and Refresh Rate"
    }
    Choice {
        width: parent.width
        model: root.selectedDisplay ? root.selectedDisplay.availableModes || [] : []
        onActivated: mode.text = currentText.replace("Hz", "")
    }
    Field {
        id: mode
        width: parent.width
        placeholderText: "1920x1080@280"
    }
    Row {
        width: parent.width
        spacing: 8
        Column {
            width: (parent.width - 8) / 2
            spacing: 6
            BodyText {
                text: "Position · XxY"
            }
            Field {
                id: position
                objectName: "monitorPosition"
                width: parent.width
                placeholderText: "1080x1080"
            }
        }
        Column {
            width: (parent.width - 8) / 2
            spacing: 6
            BodyText {
                text: "Scale"
            }
            Field {
                id: scale
                width: parent.width
                placeholderText: "1"
            }
        }
    }
    BodyText {
        text: "Rotation"
    }
    Choice {
        id: rotation
        width: parent.width
        model: ["Normal", "90°", "180°", "270°", "Flipped", "Flipped 90°", "Flipped 180°", "Flipped 270°"]
    }
    Row {
        width: parent.width
        spacing: 8
        Column {
            width: (parent.width - 8) / 2
            spacing: 6
            BodyText {
                text: "Default Workspace"
            }
            Field {
                id: workspace
                width: parent.width
                placeholderText: "1"
            }
        }
        Column {
            width: (parent.width - 8) / 2
            spacing: 6
            BodyText {
                text: "VRR"
            }
            Choice {
                width: parent.width
                model: ["Off", "On", "Fullscreen Only"]
                currentIndex: root.vrr
                onActivated: root.vrr = currentIndex
            }
        }
    }
    PillButton {
        width: parent.width
        text: "Apply Display"
        enabled: !!root.selectedDisplay && !Tasks.device.running && !Tasks.device.result.pending
        onClicked: Tasks.device.start(["system-settings", "apply-monitor", JSON.stringify({
                name: root.selectedDisplay.name,
                mode: mode.text,
                position: position.text,
                scale: scale.text,
                transform: rotation.currentIndex,
                workspace: workspace.text,
                positions: root.movedPositions,
                vrr: root.vrr
            })])
    }
    Row {
        visible: !!Tasks.device.result.pending
        width: parent.width
        spacing: 8
        PillButton {
            width: (parent.width - 8) / 2
            text: "Keep · 20 Seconds"
            onClicked: Tasks.device.start(["system-settings", "keep-monitor"])
        }
        PillButton {
            width: (parent.width - 8) / 2
            text: "Revert"
            onClicked: Tasks.device.start(["system-settings", "revert-monitor"])
        }
    }
    TaskStatus {
        width: parent.width
        task: Tasks.device
        showCancel: false
    }
}
