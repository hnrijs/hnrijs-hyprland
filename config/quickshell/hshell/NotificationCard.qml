import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs
import qs.components

Rectangle {
    id: root
    required property var notification
    property bool expanded: false
    implicitHeight: Math.max(78, content.implicitHeight + 30)
    radius: 25
    color: Style.bg0
    Rectangle {
        x: 16
        y: 24
        width: 38
        height: 38
        radius: 19
        color: Style.bg1
        Text {
            anchors.centerIn: parent
            text: "󰂚"
            color: Style.foreground
            font.family: Style.iconFontFamily
            font.pixelSize: 20
        }
        IconImage {
            anchors.fill: parent
            anchors.margins: 7
            source: root.notification ? (root.notification.image || (root.notification.appIcon ? Quickshell.iconPath(root.notification.appIcon) : "")) : ""
        }
    }
    Column {
        id: content
        x: 68
        y: 15
        width: parent.width - 86
        spacing: 5
        BodyText {
            width: parent.width
            text: root.notification ? root.notification.appName || root.notification.app || "Notification" : ""
            color: Style.muted
            font.pixelSize: 12
            textFormat: Text.PlainText
        }
        BodyText {
            width: parent.width
            text: root.notification ? root.notification.summary : ""
            font.pixelSize: 16
            font.bold: true
            maximumLineCount: 2
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
        BodyText {
            width: parent.width
            visible: text !== ""
            text: root.notification ? root.notification.body : ""
            color: Style.muted
            maximumLineCount: root.expanded ? 999 : 3
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }
    HoverHandler {
        id: hover
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: NotificationCenter.dismissCurrent()
    }
}
