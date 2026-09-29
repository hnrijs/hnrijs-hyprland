import QtQuick
import QtQuick.Effects
import QtQuick.Window
import qs

Rectangle {
    id: root
    property var player: Media.player
    implicitHeight: player ? 160 : 0
    visible: !!player
    radius: 24
    color: Style.bg1
    clip: true
    readonly property bool effects: GraphicsInfo.api !== GraphicsInfo.Software
    layer.enabled: effects
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: roundedMask
    }
    Item {
        id: roundedMask
        anchors.fill: parent
        layer.enabled: true
        visible: false
        Rectangle {
            anchors.fill: parent
            radius: 24
            color: "white"
        }
    }
    Image {
        id: artwork
        anchors.fill: parent
        source: root.player ? root.player.trackArtUrl : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: !root.effects
    }
    MultiEffect {
        anchors.fill: parent
        source: artwork
        brightness: -0.35
        saturation: -0.15
        visible: root.effects && artwork.status === Image.Ready
    }
    Rectangle {
        x: 12
        y: 12
        width: parent.width - 24
        height: 24
        radius: 12
        color: "transparent"
        Text {
            anchors.fill: parent
            anchors.leftMargin: 10
            text: root.player ? root.player.identity : ""
            font.family: Style.fontFamily
            font.pixelSize: 11
            color: Style.foreground
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        MouseArea {
            anchors.fill: parent
            onClicked: Media.nextPlayer()
        }
    }
    Rectangle {
        x: 12
        y: 46
        width: parent.width - 96
        height: 58
        radius: 16
        color: "transparent"
        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 3
            Text {
                width: parent.width
                text: root.player ? root.player.trackTitle || "No title" : ""
                color: Style.foreground
                font.family: Style.fontFamily
                font.pixelSize: 15
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.player ? root.player.trackArtist : ""
                color: Style.muted
                font.family: Style.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }
    PillButton {
        anchors.right: parent.right
        anchors.rightMargin: 16
        y: 48
        width: 56
        height: 56
        selected: true
        text: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
        enabled: root.player && root.player.canTogglePlaying
        onClicked: root.player.togglePlaying()
    }
    Row {
        x: 12
        y: 116
        width: parent.width - 24
        spacing: 8
        PillButton {
            width: 32
            height: 28
            text: "󰒮"
            enabled: root.player && root.player.canGoPrevious
            onClicked: root.player.previous()
        }
        ThinSlider {
            width: parent.width - 80
            compact: true
            caption: "Seek"
            from: 0
            to: root.player && root.player.lengthSupported ? Math.max(1, root.player.length) : 1
            value: root.player ? root.player.position : 0
            displayValue: ""
            enabled: root.player && root.player.canSeek && root.player.positionSupported
            onMoved: root.player.position = value
        }
        PillButton {
            width: 32
            height: 28
            text: "󰒭"
            enabled: root.player && root.player.canGoNext
            onClicked: root.player.next()
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.visible && root.player && root.player.isPlaying
        onTriggered: root.player.positionChanged()
    }
}
