import QtQuick
import QtQuick.Controls
import qs

Column {
    required property var task
    property bool showCancel: true
    spacing: 8
    Meter {
        width: parent.width
        visible: parent.task.running
        indeterminate: parent.task.progress.percent === undefined
        value: Math.max(0, Math.min(1, Number(parent.task.progress.percent || 0) / 100))
    }
    BodyText {
        width: parent.width
        visible: text !== ""
        text: parent.task.error || parent.task.progress.message || parent.task.result.message || ""
        color: parent.task.error ? Style.primary : Style.muted
        maximumLineCount: 8
        elide: Text.ElideLeft
    }
    PillButton {
        visible: parent.task.running && parent.showCancel
        text: "Cancel"
        onClicked: parent.task.cancel()
    }
}
