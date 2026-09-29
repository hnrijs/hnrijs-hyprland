import QtQuick
import Quickshell
import qs
import qs.components

Column {
    spacing: 12
    FileField {
        id: source
        width: parent.width
        caption: "Choose File"
    }
    Row {
        width: parent.width
        spacing: 8
        PillButton {
            width: (parent.width - 8) / 2
            text: "View Metadata"
            enabled: !Tasks.exif.running
            onClicked: Tasks.exif.start(["exif", "view", source.path])
        }
        PillButton {
            width: (parent.width - 8) / 2
            text: "Remove Metadata"
            enabled: !Tasks.exif.running
            onClicked: Tasks.exif.start(["exif", "remove", source.path])
        }
    }
    Row {
        width: parent.width
        spacing: 8
        Field {
            id: offset
            width: parent.width - 184
            placeholderText: "UTC offset, e.g. +03:00"
        }
        PillButton {
            width: 176
            text: "Set Timezone"
            enabled: !Tasks.exif.running
            onClicked: Tasks.exif.start(["exif", "timezone", source.path, offset.text])
        }
    }

    Row {
        width: parent.width
        PillButton {
            width: 44
            text: "󰆏"
            Accessible.name: "Copy Metadata"
            onClicked: Quickshell.execDetached(["wl-copy", "--", Tasks.exif.result.text || Tasks.exif.result.path || ""])
        }
        Item {
            width: parent.width - 88
            height: 44
        }
        PillButton {
            width: 44
            text: "󰃢"
            Accessible.name: "Clear Metadata Output"
            enabled: !Tasks.exif.running
            onClicked: {
                Tasks.exif.result = ({});
                Tasks.exif.error = "";
            }
        }
    }
    TaskStatus {
        width: parent.width
        task: Tasks.exif
    }
    BodyText {
        width: parent.width
        text: Tasks.exif.result.text || Tasks.exif.result.path || ""
        textFormat: Text.PlainText
    }
}
