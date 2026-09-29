import QtQuick
import QtQuick.Controls
import qs
import qs.components

Column {
    id: root
    spacing: 10
    Component.onCompleted: Tasks.device.start(["system-settings", "timezone"])
    BodyText {
        width: parent.width
        text: Tasks.device.result.current || ""
        font.pixelSize: 22
    }
    Field {
        id: search
        width: parent.width
        placeholderText: "Search Timezone"
    }
    ListView {
        width: parent.width
        height: 320
        clip: true
        spacing: 6
        model: (Tasks.device.result.zones || []).filter(z => z.toLowerCase().includes(search.text.toLowerCase()))
        ScrollBar.vertical: ScrollBar {}
        delegate: PillButton {
            required property string modelData
            width: ListView.view.width
            text: modelData
            selected: Tasks.device.result.current === modelData
            enabled: !Tasks.device.running
            onClicked: Tasks.device.start(["system-settings", "set-timezone", modelData])
        }
    }
    TaskStatus {
        width: parent.width
        task: Tasks.device
        showCancel: false
    }
}
