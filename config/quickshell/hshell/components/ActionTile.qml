import QtQuick
import qs

FocusScope {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool expandable: false
    property bool expanded: false
    property string detailAccessibleName: "Show " + title + " options"

    signal clicked
    signal detailClicked

    implicitHeight: 58
    activeFocusOnTab: true
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()
    Accessible.role: Accessible.Button
    Accessible.name: title + (subtitle ? ", " + subtitle : "")

    Rectangle {
        anchors.fill: parent
        radius: Style.radius
        color: root.active ? Style.primary : Style.bg0
        border.width: root.activeFocus || detailButton.activeFocus ? 2 : 0
        border.color: Style.primary

        Behavior on color {
            ColorAnimation {
                duration: Style.animationFast
            }
        }
    }

    Row {
        anchors.left: parent.left
        anchors.right: detailButton.visible ? detailButton.left : parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 9
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
            radius: 15
            color: root.active ? Qt.rgba(0, 0, 0, 0.14) : Style.bg1

            ShellText {
                anchors.centerIn: parent
                text: root.icon
                color: root.active ? Style.bgDim : Style.muted
                font.pixelSize: 16
                font.weight: Font.Bold
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 38
            spacing: 2

            ShellText {
                width: parent.width
                text: root.title
                color: root.active ? Style.bgDim : Style.foreground
                elide: Text.ElideRight
                font.pixelSize: 14
                font.weight: Font.Bold
            }

            ShellText {
                width: parent.width
                text: root.subtitle
                color: root.active ? Qt.rgba(0, 0, 0, 0.68) : Style.muted
                elide: Text.ElideRight
                font.pixelSize: 11
            }
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: detailButton.visible ? detailButton.left : parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    FocusScope {
        id: detailButton

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.expandable ? 31 : 0
        visible: root.expandable
        activeFocusOnTab: visible
        Keys.onReturnPressed: root.detailClicked()
        Keys.onEnterPressed: root.detailClicked()
        Keys.onSpacePressed: root.detailClicked()
        Accessible.role: Accessible.Button
        Accessible.name: root.detailAccessibleName

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: parent.height - 18
            color: root.active ? Qt.rgba(0, 0, 0, 0.18) : Style.bg2
        }

        ShellText {
            anchors.centerIn: parent
            text: root.expanded ? "󰅃" : "󰅀"
            color: root.active ? Qt.rgba(0, 0, 0, 0.62) : Style.mutedDark
            font.pixelSize: 13
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.detailClicked()
        }
    }
}
