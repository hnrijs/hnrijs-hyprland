import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import qs
import qs.components

Column {
    id: root
    spacing: 12
    property string generatedText: ""
    property string pendingText: ""
    Task {
        id: generator
        onFinished: success => {
            if (success)
                root.generatedText = root.pendingText;
        }
    }
    Task {
        id: exporter
    }
    ScrollView {
        width: parent.width
        height: 110
        TextArea {
            id: input
            objectName: "qrText"
            placeholderText: "Text or Link"
            wrapMode: TextEdit.Wrap
            color: Style.foreground
            placeholderTextColor: Style.muted
            selectionColor: Style.primary
            selectedTextColor: Style.activeText
            font.family: Style.fontFamily
            font.pixelSize: 14
            padding: 14
            background: Rectangle {
                color: Style.bg1
                radius: 18
            }
        }
    }
    PillButton {
        width: parent.width
        text: "Generate QR Code"
        objectName: "generateQr"
        enabled: input.text.trim() !== "" && !generator.running && !exporter.running
        onClicked: {
            root.pendingText = input.text;
            exporter.result = ({});
            exporter.error = "";
            generator.start(["qr", "generate", input.text]);
        }
    }
    Image {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !!generator.result.url
        width: Math.min(300, root.width)
        height: visible ? width : 0
        source: generator.result.url || ""
        fillMode: Image.PreserveAspectFit
        smooth: false
    }
    Row {
        visible: root.generatedText !== ""
        width: parent.width
        spacing: 8
        PillButton {
            width: (parent.width - 8) / 2
            text: "Copy Image"
            enabled: !generator.running && !exporter.running
            onClicked: exporter.start(["qr", "copy", root.generatedText])
        }
        PillButton {
            width: (parent.width - 8) / 2
            text: "Save PNG"
            enabled: !generator.running && !exporter.running
            onClicked: {
                ShellState.externalDialog = true;
                saveDialog.open();
            }
        }
    }
    FileDialog {
        id: saveDialog
        title: "Save QR Code"
        fileMode: FileDialog.SaveFile
        nameFilters: ["PNG Image (*.png)"]
        defaultSuffix: "png"
        onAccepted: {
            ShellState.externalDialog = false;
            exporter.start(["qr", "save", root.generatedText, selectedFile.toString()]);
        }
        onRejected: ShellState.externalDialog = false
    }
    Component.onDestruction: ShellState.externalDialog = false
    TaskStatus {
        width: parent.width
        task: generator
        showCancel: false
    }
    TaskStatus {
        width: parent.width
        task: exporter
        showCancel: false
    }
}
