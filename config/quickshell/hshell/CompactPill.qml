import QtQuick
import Quickshell
import qs
import qs.components

Item {
    id: root
    required property string screenName
    property bool hovered: false
    property bool externalHover: false
    readonly property bool showCapsLock: false
    readonly property bool playing: !!Media.player && Media.player.isPlaying
    readonly property bool showBars: playing && hovered
    readonly property var hoverIndicators: [
        {
            icon: Controls.wifiIcon,
            enabled: !!Controls.connectedWifi
        },
        {
            icon: Controls.adapter && Controls.adapter.enabled ? "󰂯" : "󰂲",
            enabled: !!Controls.adapter && Controls.adapter.enabled
        },
        {
            icon: Controls.hasBattery ? Controls.batteryIcon + " " + Math.round(Controls.batteryLevel * 100) + "%" : "",
            enabled: true
        },
        {
            icon: Controls.powerIcon,
            enabled: true
        },
        {
            icon: Tasks.caffeine.result.enabled ? "󰅶" : "󰒲",
            enabled: true
        },
        {
            icon: "󰖔",
            enabled: Backend.nightLightStatus === "on"
        }
    ].filter(v => v.icon !== "")
    readonly property bool notice: ShellState.workspaceNotice && !hovered
    readonly property bool hardwareOsd: ShellState.osd !== "" && !notice
    readonly property real desiredWidth: notice ? (ShellState.noticeDetail ? 400 : 218) : hardwareOsd ? 260 : hovered ? 620 : 110
    readonly property real desiredHeight: notice && ShellState.noticeDetail ? 78 : hovered && !notice && !hardwareOsd ? 86 : 42
    height: desiredHeight
    onVisibleChanged: if (!visible && !externalHover) {
        leave.stop();
        hovered = false;
    }
    HoverHandler {
        enabled: !root.externalHover
        onHoveredChanged: {
            if (hovered) {
                leave.stop();
                root.hovered = Preferences.hoverExpand;
            } else
                leave.restart();
        }
    }
    Timer {
        id: leave
        interval: 200
        onTriggered: root.hovered = false
    }
    Text {
        anchors.centerIn: parent
        visible: root.notice && !ShellState.noticeDetail
        text: ShellState.workspaceText
        color: Style.foreground
        font.family: Style.iconFontFamily
        font.pixelSize: 16
    }
    Column {
        anchors.centerIn: parent
        width: parent.width - 40
        spacing: 6
        visible: root.notice && !!ShellState.noticeDetail
        Text {
            width: parent.width
            text: ShellState.statusNotice
            color: Style.foreground
            font.family: Style.fontFamily
            font.pixelSize: 18
            font.bold: true
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: ShellState.noticeDetail
            color: Style.muted
            font.family: Style.fontFamily
            font.pixelSize: 14
            elide: Text.ElideRight
        }
    }
    Item {
        anchors.fill: parent
        visible: !root.notice && !root.hardwareOsd
        Item {
            x: (parent.width - width) / 2
            width: root.hovered ? 158 : 96
            height: parent.height
            Column {
                anchors.centerIn: parent
                spacing: 3
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5
                    Text {
                        text: Clock.timeText
                        font.family: Style.iconFontFamily
                        font.pixelSize: root.hovered ? 24 : 18
                        font.bold: true
                        color: Style.foreground
                    }
                    Text {
                        objectName: "capsLockIndicator"
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.showCapsLock
                        text: "󰌎"
                        font.family: Style.iconFontFamily
                        font.pixelSize: 18
                        color: Style.foreground
                        Accessible.name: "Caps Lock On"
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.hovered
                    text: Clock.dateText
                    font.family: Style.iconFontFamily
                    font.pixelSize: 12
                    color: Style.muted
                }
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: event => ShellState.showOnScreen(event.button === Qt.RightButton ? "menu" : event.button === Qt.MiddleButton ? "calendar" : "control", root.screenName)
            }
        }
        Item {
            x: 16
            y: 16
            width: 210
            height: 54
            visible: root.hovered
            Rectangle {
                width: 54
                height: 54
                radius: 16
                color: Style.bg1
                clip: true
                Image {
                    anchors.fill: parent
                    source: Media.player ? Media.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: !Media.player || !Media.player.trackArtUrl
                    text: "󰎈"
                    color: Style.foreground
                    font.family: Style.iconFontFamily
                    font.pixelSize: 22
                }
            }
            AudioSpectrum {
                visible: root.showBars
                x: 64
                y: 4
                width: 24
                height: 14
                active: root.visible && root.showBars && root.hovered
            }
            Text {
                x: root.showBars ? 98 : 64
                y: 1
                width: root.showBars ? 112 : 146
                height: 22
                text: Controls.hasBattery ? Math.round(Controls.batteryLevel * 100) + "% Battery" : Media.player ? Media.player.trackTitle || "Audio" : "Audio"
                color: Style.foreground
                font.family: Style.iconFontFamily
                font.pixelSize: 13
                elide: Text.ElideRight
            }
            Text {
                x: 64
                y: 30
                width: 146
                text: Controls.hasBattery ? (Controls.batteryCharging ? "Charging" : "On Battery") : Media.player ? Media.player.trackArtist : "No player"
                color: Style.muted
                font.family: Style.iconFontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.showOnScreen("control", root.screenName)
            }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(112, indicators.implicitWidth + 24)
            height: 54
            radius: 20
            color: Style.bg1
            visible: root.hovered
            Row {
                id: indicators
                anchors.centerIn: parent
                spacing: 9
                Repeater {
                    model: root.hoverIndicators
                    Text {
                        required property var modelData
                        height: 24
                        verticalAlignment: Text.AlignVCenter
                        text: modelData.icon
                        color: modelData.enabled ? Style.foreground : Style.muted
                        font.family: Style.iconFontFamily
                        font.pixelSize: 14
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.showOnScreen("control", root.screenName)
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        visible: root.notice || root.hardwareOsd
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => ShellState.showOnScreen(event.button === Qt.RightButton ? "menu" : event.button === Qt.MiddleButton ? "calendar" : "control", root.screenName)
    }
    ThinSlider {
        x: 10
        y: 7
        width: parent.width - 20
        compact: true
        visible: root.hardwareOsd
        property string kind: ShellState.osd
        enabled: kind === "volume" ? !!Controls.sink : Backend.brightnessAvailable
        icon: kind === "volume" ? "󰕾" : "󰃠"
        caption: kind
        value: kind === "volume" ? (Controls.sink ? Controls.sink.audio.volume : 0) : Backend.brightness / 100
        displayValue: !enabled ? "N/A" : kind === "volume" && Controls.sink.audio.muted ? "Mute" : Math.round(value * 100) + "%"
        onMoved: {
            if (kind === "volume")
                Controls.volume(value);
            else
                Backend.setBrightness(value * 100);
        }
    }
}
