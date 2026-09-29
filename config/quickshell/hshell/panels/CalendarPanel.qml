import QtQuick
import QtQuick.Controls
import qs
import qs.components

Column {
    id: root
    property date month: new Date(Clock.year, Clock.month - 1, 1)
    property date today: new Date(Clock.year, Clock.month - 1, Clock.day)
    property bool detailed: false
    property string selectedDate: Qt.formatDate(today, "yyyy-MM-dd")
    spacing: 6
    Row {
        width: parent.width
        ActionIcon {
            width: 44
            height: 44
            text: "‹"
            onClicked: root.month = new Date(root.month.getFullYear(), root.month.getMonth() - 1, 1)
        }
        BodyText {
            width: parent.width - 88
            height: 44
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDate(root.month, "MMMM yyyy")
            font.pixelSize: 16
        }
        ActionIcon {
            width: 44
            height: 44
            text: "›"
            onClicked: root.month = new Date(root.month.getFullYear(), root.month.getMonth() + 1, 1)
        }
    }
    Grid {
        width: parent.width
        columns: 7
        spacing: 4
        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            delegate: BodyText {
                required property string modelData
                width: (parent.width - 24) / 7
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: ["Sa", "Su"].includes(modelData) ? "#ba4a50" : Style.muted
            }
        }
        Repeater {
            model: 42
            delegate: Rectangle {
                required property int index
                readonly property int day: index - ((root.month.getDay() + 6) % 7) + 1
                readonly property bool valid: day > 0 && day <= new Date(root.month.getFullYear(), root.month.getMonth() + 1, 0).getDate()
                readonly property bool isToday: valid && day === root.today.getDate() && root.month.getMonth() === root.today.getMonth() && root.month.getFullYear() === root.today.getFullYear()
                objectName: "calendarDay-" + day
                readonly property bool isSelected: valid && Qt.formatDate(new Date(root.month.getFullYear(), root.month.getMonth(), day), "yyyy-MM-dd") === root.selectedDate
                width: (parent.width - 24) / 7
                height: root.detailed ? 40 : 32
                radius: 21
                color: "transparent"
                MouseArea {
                    anchors.fill: parent
                    enabled: parent.valid
                    onClicked: root.selectedDate = Qt.formatDate(new Date(root.month.getFullYear(), root.month.getMonth(), parent.day), "yyyy-MM-dd")
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: 18
                    color: parent.isSelected ? Style.foreground : "transparent"
                    border.width: parent.isToday && !parent.isSelected ? 1 : 0
                    border.color: Style.muted
                }
                BodyText {
                    anchors.centerIn: parent
                    text: new Date(root.month.getFullYear(), root.month.getMonth(), parent.day).getDate()
                    color: parent.isSelected ? Style.bg0 : parent.valid ? (index % 7 >= 5 ? "#ba4a50" : Style.foreground) : Style.bg3
                }
            }
        }
    }
    Rectangle {
        width: parent.width
        height: 1
        color: Style.bg3
    }
    WeatherDashboard {
        width: parent.width
    }
}
