import QtQuick
import qs
import qs.components

Column {
    id: root
    property string page: ""
    spacing: 10
    Flow {
        width: parent.width
        spacing: 8
        visible: !root.page
        Repeater {
            model: [["Appearance", "󰏘"], ["Notifications", "󰂚"], ["Folders", "󰉋"]]
            ControlTile {
                required property var modelData
                width: (parent.width - 8) / 2
                implicitHeight: 56
                symbol: modelData[1]
                text: modelData[0]
                onClicked: root.page = modelData[0]
            }
        }
    }
    Row {
        visible: !!root.page
        width: parent.width
        spacing: 10
        ActionIcon {
            text: "‹"
            hint: "Back"
            onClicked: root.page = ""
        }
        BodyText {
            height: 36
            verticalAlignment: Text.AlignVCenter
            text: root.page
            font.pixelSize: 18
        }
    }
    Loader {
        width: parent.width
        height: item ? item.implicitHeight : 0
        active: !!root.page
        sourceComponent: root.page === "Appearance" ? appearance : preferences
    }
    Component {
        id: appearance
        AppearancePanel {}
    }
    Component {
        id: preferences
        PreferencesPanel {
            embedded: true
            category: root.page
        }
    }
}
