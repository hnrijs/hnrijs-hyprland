import QtQuick
import QtQuick.Controls
import qs

Column {
    id: root
    objectName: "inlineChoice"
    property alias background: choiceToggle.background
    property var model: []
    property int currentIndex: 0
    readonly property string currentText: model.length ? String(model[currentIndex]) : ""
    property bool opened: false
    property bool searchable: false
    signal activated(int index)
    spacing: 6
    PillButton {
        id: choiceToggle
        objectName: "choiceToggle"
        width: parent.width
        text: root.currentText + (root.opened ? "  ▴" : "  ▾")
        onClicked: root.opened = !root.opened
    }
    Column {
        width: parent.width
        visible: root.opened && !root.searchable
        spacing: 4
        Repeater {
            model: root.opened && !root.searchable ? root.model : []
            delegate: PillButton {
                objectName: "choiceOption-" + index
                required property int index
                required property var modelData
                width: parent.width
                text: String(modelData)
                selected: root.currentIndex === index
                onClicked: {
                    root.currentIndex = index;
                    root.activated(index);
                    root.opened = false;
                }
            }
        }
    }
    Field {
        id: query
        width: parent.width
        visible: root.opened && root.searchable
        placeholderText: "Search Currency"
    }
    ListView {
        width: parent.width
        visible: root.opened && root.searchable
        height: visible ? Math.min(220, contentHeight) : 0
        clip: true
        spacing: 4
        model: root.opened && root.searchable ? root.model.map((value, index) => ({
                    value: value,
                    index: index
                })).filter(row => String(row.value).toLowerCase().includes(query.text.trim().toLowerCase())) : []
        ScrollBar.vertical: ScrollBar {}
        delegate: PillButton {
            required property var modelData
            width: ListView.view.width
            text: String(modelData.value)
            selected: root.currentIndex === modelData.index
            onClicked: {
                root.currentIndex = modelData.index;
                root.activated(modelData.index);
                root.opened = false;
                query.text = "";
            }
        }
    }
}
