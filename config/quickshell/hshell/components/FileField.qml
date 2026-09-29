import QtQuick
import QtQuick.Dialogs
import qs

Column {
    id: root
    property url startFolder: ""
    property string caption: "Choose File"
    property alias path: input.text
    spacing: 8
    Row {
        width: parent.width
        spacing: 8
        Field {
            id: input
            width: parent.width - 132
            placeholderText: "File Path"
            DropArea {
                anchors.fill: parent
                onDropped: drop => {
                    if (drop.hasUrls)
                        input.text = drop.urls[0];
                }
            }
        }
        PillButton {
            width: 124
            text: root.caption
            onClicked: {
                ShellState.externalDialog = true;
                picker.open();
            }
        }
    }
    FileDialog {
        id: picker
        title: root.caption
        currentFolder: root.startFolder
        onAccepted: {
            root.path = selectedFile.toString();
            ShellState.externalDialog = false;
        }
        onRejected: ShellState.externalDialog = false
    }
    Component.onDestruction: ShellState.externalDialog = false
}
