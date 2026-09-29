import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.components

PanelWindow {
    id: root
    visible: ShellState.overviewOpen && !Auth.active && !ShellState.locked
    screen: Quickshell.screens.find(s => s.name === ShellState.activeScreen) || Quickshell.screens[0]
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: Preferences.option("overviewTransparent", false) && Preferences.option("overviewBlur", true) ? "hshell-overview-blur" : "hshell-overview"
    color: "transparent"
    property bool pointerHeld: false
    property bool dragging: false
    property string draggedAddress: ""
    property Item draggedItem: null
    property size draggedSize: Qt.size(180, 100)
    property point dragOffset: Qt.point(0, 0)
    property int dropWorkspace: 0
    property point pointer: Qt.point(0, 0)
    property bool selectOnRefresh: true
    property int selected: 1
    property var state: ({})
    property string layoutKey: ""
    readonly property var spaces: {
        let ids = Array.from({
            length: 10
        }, (_, i) => ({
                    id: i + 1,
                    name: String(i + 1),
                    destination: String(i + 1)
                }));
        for (const ws of state.workspaces || []) {
            if (ws.id > 10)
                ids.push({
                    id: ws.id,
                    name: String(ws.id),
                    destination: String(ws.id)
                });
            if (ws.id < 0)
                ids.push({
                    id: ws.id,
                    name: ws.name.replace("special:", ""),
                    destination: ws.name
                });
        }
        return ids;
    }
    function refresh() {
        if (visible && !pointerHeld && !snapshot.running && !action.running)
            snapshot.start(["overview", "status"]);
    }
    function openSpace(destination) {
        if (action.running || pointerHeld)
            return;
        action.moveRequest = false;
        action.start(["overview", "workspace", destination]);
    }
    function release(point, address) {
        if (action.running) {
            pointerHeld = false;
            dragging = false;
            return;
        }
        action.moveRequest = dragging;
        pointerHeld = false;
        if (dragging) {
            for (let i = 0; i < tiles.count; i++) {
                const tile = tiles.itemAt(i);
                const p = tile.mapFromItem(surface, point.x, point.y);
                if (p.x >= 0 && p.y >= 0 && p.x < tile.width && p.y < tile.height) {
                    action.start(["overview", "move", address, tile.modelData.destination]);
                    break;
                }
            }
        } else
            action.start(["overview", "focus", address]);
        dragging = false;
        draggedItem = null;
        dropWorkspace = 0;
    }
    onVisibleChanged: if (visible) {
        selectOnRefresh = true;
        refresh();
        surface.forceActiveFocus();
    } else {
        dragging = false;
        pointerHeld = false;
        draggedItem = null;
        dropWorkspace = 0;
    }
    Task {
        id: snapshot
        objectName: "overviewSnapshot"
        onResultChanged: {
            if (root.pointerHeld || action.running)
                return;
            const key = JSON.stringify({
                clients: (result.clients || []).map(c => [c.address, c.at, c.size, c.workspace, c.class]),
                workspaces: (result.workspaces || []).map(w => [w.id, w.name, w.monitor]),
                monitors: (result.monitors || []).map(m => [m.name, m.x, m.y, m.width, m.height, m.scale, m.transform])
            });
            if (key !== root.layoutKey) {
                root.layoutKey = key;
                root.state = result;
            }
            if (root.selectOnRefresh) {
                root.selected = result.active || 1;
                root.selectOnRefresh = false;
            }
        }
    }
    Task {
        id: action
        objectName: "overviewAction"
        property bool moveRequest: false
        onFinished: success => {
            if (success && !moveRequest)
                ShellState.close();
            else
                root.refresh();
        }
    }
    Timer {
        interval: 2000
        running: root.visible
        repeat: true
        onTriggered: root.refresh()
    }
    Item {
        id: surface
        Rectangle {
            anchors.fill: parent
            color: "#18000000"
            visible: Preferences.option("overviewTransparent", false) && Preferences.option("overviewBlur", true)
        }
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: ShellState.close()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
                root.selected = root.selected % 10 + 1;
            else if (event.key === Qt.Key_Left)
                root.selected = (root.selected + 8) % 10 + 1;
            else if (event.key === Qt.Key_Down)
                root.selected = (root.selected + 4) % 10 + 1;
            else if (event.key === Qt.Key_Up)
                root.selected = (root.selected + 4) % 10 + 1;
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                root.openSpace(String(root.selected));
            else
                return;
            event.accepted = true;
        }
        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.close()
        }
        Rectangle {
            id: box
            anchors.centerIn: parent
            width: Math.min(parent.width - 48, 1740)
            height: Math.min(parent.height - 64, grid.implicitHeight + 32)
            color: Preferences.option("overviewTransparent", false) ? "transparent" : Style.bg0
            radius: 0
            border.color: "#080808"
            border.width: Preferences.option("overviewTransparent", false) ? 0 : 1
            MouseArea {
                anchors.fill: parent
            }

            ScrollView {
                x: 16
                y: 16
                width: parent.width - 32
                height: parent.height - 32
                clip: true
                contentWidth: availableWidth
                Grid {
                    id: grid
                    width: parent.width
                    columns: width < 850 ? 2 : 5
                    spacing: 10
                    Repeater {
                        id: tiles
                        model: root.spaces
                        Rectangle {
                            id: tile
                            objectName: "overview-workspace-" + modelData.id
                            required property var modelData
                            width: (grid.width - (grid.columns - 1) * 10) / grid.columns
                            height: width * 0.72 + 12
                            radius: 0
                            color: Preferences.option("overviewTransparent", false) ? "transparent" : Style.bg1
                            border.width: Preferences.option("overviewTransparent", false) ? 0 : root.dropWorkspace === modelData.id || (tile.clients.length === 0 && root.selected === modelData.id) ? 2 : 1
                            border.color: root.dropWorkspace === modelData.id || (tile.clients.length === 0 && root.selected === modelData.id) ? Style.primary : "#080808"
                            readonly property var workspace: (root.state.workspaces || []).find(w => w.id === modelData.id)
                            readonly property var monitor: (root.state.monitors || []).find(m => tile.workspace && m.name === tile.workspace.monitor) || (root.state.monitors || [])[0] || {
                                x: 0,
                                y: 0,
                                width: 1920,
                                height: 1080,
                                scale: 1,
                                transform: 0
                            }
                            readonly property real monitorWidth: ((monitor.transform || 0) % 2 ? monitor.height : monitor.width) / (monitor.scale || 1)
                            readonly property real monitorHeight: ((monitor.transform || 0) % 2 ? monitor.width : monitor.height) / (monitor.scale || 1)
                            readonly property var clients: (root.state.clients || []).filter(c => c.workspace.id === modelData.id)
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.openSpace(tile.modelData.destination)
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: tile.clients.length === 0 && Preferences.option("overviewNumbers", true)
                                text: tile.modelData.name
                                color: Style.muted
                                font.pixelSize: 30
                                font.family: Style.fontFamily
                            }
                            Item {
                                id: canvas
                                anchors.centerIn: parent
                                readonly property real ratio: tile.monitorWidth / Math.max(1, tile.monitorHeight)
                                width: Math.min(parent.width - 12, (parent.height - 12) * ratio)
                                height: width / ratio
                                clip: true
                                Repeater {
                                    model: tile.clients
                                    Rectangle {
                                        id: windowCard
                                        required property int index
                                        objectName: "overview-window-" + modelData.address
                                        required property var modelData
                                        x: Math.max(0, Math.min(canvas.width - 30, (modelData.at[0] - tile.monitor.x) / tile.monitorWidth * canvas.width))
                                        y: Math.max(0, Math.min(canvas.height - 24, (modelData.at[1] - tile.monitor.y) / tile.monitorHeight * canvas.height))
                                        readonly property real availableWidth: Math.max(8, Math.min(canvas.width - x, modelData.size[0] / tile.monitorWidth * canvas.width))
                                        readonly property real availableHeight: Math.max(8, Math.min(canvas.height - y, modelData.size[1] / tile.monitorHeight * canvas.height))
                                        readonly property real captureRatio: preview.hasContent && preview.sourceSize.height > 0 ? preview.sourceSize.width / preview.sourceSize.height : availableWidth / availableHeight
                                        width: Math.min(availableWidth, availableHeight * captureRatio)
                                        height: width / captureRatio
                                        color: "transparent"
                                        radius: 0
                                        clip: true
                                        border.width: 1
                                        border.color: "#080808"
                                        readonly property var handle: Hyprland.toplevels.values.find(t => t.address.replace(/^0x/, "") === modelData.address.replace(/^0x/, ""))
                                        ScreencopyView {
                                            id: preview
                                            anchors.fill: parent
                                            captureSource: windowCard.handle ? windowCard.handle.wayland : null
                                            live: false
                                            onCaptureSourceChanged: captureDelay.restart()
                                            paintCursor: false
                                            constraintSize: Qt.size(width, height)
                                        }
                                        Timer {
                                            id: captureDelay
                                            interval: 100 + windowCard.index * 90 + (tile.modelData.id > 0 ? tile.modelData.id : 11) * 70
                                            running: root.visible
                                            onTriggered: {
                                                if (!root.visible || !windowCard.handle)
                                                    return;
                                                if (root.pointerHeld) {
                                                    restart();
                                                    return;
                                                }
                                                preview.captureFrame();
                                            }
                                        }
                                        Connections {
                                            target: root
                                            function onVisibleChanged() {
                                                if (root.visible)
                                                    captureDelay.restart();
                                                else
                                                    captureDelay.stop();
                                            }
                                        }
                                        Rectangle {
                                            anchors.fill: parent
                                            color: "transparent"
                                            radius: 0
                                            border.width: windowPointer.containsMouse ? 2 : 1
                                            border.color: windowPointer.containsMouse ? Style.primary : "#080808"
                                            z: 2
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            width: parent.width - 8
                                            visible: !preview.hasContent
                                            text: windowCard.modelData.class || windowCard.modelData.title
                                            color: Style.foreground
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        MouseArea {
                                            id: windowPointer
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            preventStealing: true
                                            enabled: !action.running
                                            property point startPoint
                                            onPressed: mouse => {
                                                root.pointerHeld = true;
                                                startPoint = mapToItem(surface, mouse.x, mouse.y);
                                                root.pointer = startPoint;
                                                root.draggedAddress = windowCard.modelData.address;
                                                root.draggedItem = windowCard;
                                                root.draggedSize = Qt.size(windowCard.width, windowCard.height);
                                                root.dragOffset = Qt.point(mouse.x, mouse.y);
                                                dragPreview.scheduleUpdate();
                                            }
                                            onPositionChanged: mouse => {
                                                if (!pressed)
                                                    return;
                                                root.pointer = mapToItem(surface, mouse.x, mouse.y);
                                                root.dropWorkspace = 0;
                                                for (let i = 0; i < tiles.count; i++) {
                                                    const target = tiles.itemAt(i);
                                                    const p = target.mapFromItem(surface, root.pointer.x, root.pointer.y);
                                                    if (p.x >= 0 && p.y >= 0 && p.x < target.width && p.y < target.height) {
                                                        root.dropWorkspace = target.modelData.id;
                                                        break;
                                                    }
                                                }
                                                if (Math.abs(root.pointer.x - startPoint.x) + Math.abs(root.pointer.y - startPoint.y) > 8)
                                                    root.dragging = true;
                                            }
                                            onReleased: mouse => {
                                                const end = mapToItem(surface, mouse.x, mouse.y);
                                                if (Math.abs(end.x - startPoint.x) + Math.abs(end.y - startPoint.y) > 8)
                                                    root.dragging = true;
                                                root.release(end, root.draggedAddress);
                                            }
                                            onCanceled: {
                                                root.dragging = false;
                                                root.pointerHeld = false;
                                                root.draggedItem = null;
                                                root.dropWorkspace = 0;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        ShaderEffectSource {
            id: dragPreview
            z: 100
            visible: root.dragging
            x: root.pointer.x - root.dragOffset.x
            y: root.pointer.y - root.dragOffset.y
            width: root.draggedSize.width
            height: root.draggedSize.height
            sourceItem: root.draggedItem
            hideSource: root.dragging
            live: false
            recursive: false
            smooth: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            text: action.error || snapshot.error
            color: Style.foreground
        }
    }
}
