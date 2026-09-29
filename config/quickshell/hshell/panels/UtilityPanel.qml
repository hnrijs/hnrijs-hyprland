import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import qs
import qs.components

Column {
    id: root
    objectName: "utilityPanel"
    required property string kind
    spacing: 10
    readonly property var task: ({
            translate: Tasks.translate,
            words: Tasks.words,
            server: Tasks.server,
            iso: Tasks.flash,
            ocr: Tasks.ocr,
            phone: Tasks.phone
        })[kind] || Tasks.ocr
    property var ocrLanguages: ["eng"]
    Connections {
        target: root.task
        function onResultChanged() {
            if (root.kind === "ocr" && root.task.result.languages)
                root.ocrLanguages = root.task.result.languages;
        }
    }
    readonly property string home: Quickshell.env("HOME")
    function start(args) {
        task.start(args);
    }
    function copyText(text) {
        Tasks.textCopy.startText(["utilities", "copy-text", "--stdin"], text);
    }
    function clearTask() {
        task.cancel();
        task.result = ({});
        task.error = "";
        task.progress = ({});
    }
    function terminal(script, args) {
        ShellState.close();
        Quickshell.execDetached(["python3", ShellState.scripts + "open-default.py", "terminal", "python3", ShellState.scripts + script].concat(args));
    }
    function refresh() {
        if (task.running)
            return;
        task.error = "";
        const commands = {
            server: ["local-server", "status"],
            iso: ["iso-flash", "list"],
            ocr: ["utilities", "ocr-languages"],
            phone: ["utilities", "phone-devices"]
        };
        if (commands[kind])
            start(commands[kind]);
    }
    Component.onCompleted: refresh()
    onKindChanged: Qt.callLater(refresh)
    Component.onDestruction: {
        ShellState.externalDialog = false;
    }
    Loader {
        width: parent.width
        height: item ? item.implicitHeight : 0
        sourceComponent: ({
                translate: translate,
                server: server,
                words: words,
                ocr: ocr,
                phone: phone,
                iso: iso
            })[root.kind]
    }
    TaskStatus {
        width: parent.width
        task: root.task
        showCancel: false
    }

    Component {
        id: translate
        Column {
            spacing: 10
            Row {
                width: parent.width
                spacing: 8
                Field {
                    id: from
                    width: (parent.width - 52) / 2
                    text: Tasks.translate.sourceCode
                    onTextChanged: Tasks.translate.sourceCode = text
                    placeholderText: "From · auto"
                }
                PillButton {
                    width: 36
                    text: "⇄"
                    enabled: from.text !== "auto"
                    onClicked: {
                        let value = from.text;
                        from.text = to.text;
                        to.text = value;
                    }
                }
                Field {
                    id: to
                    width: (parent.width - 52) / 2
                    text: Tasks.translate.targetCode
                    onTextChanged: Tasks.translate.targetCode = text
                    placeholderText: "To · en, lv, de"
                }
            }
            TextBox {
                id: input
                objectName: "translateInput"
                width: parent.width
                text: Tasks.translate.inputText
                onTextChanged: Tasks.translate.inputText = text
                placeholderText: "Text"
            }
            PillButton {
                width: parent.width
                text: "Translate"
                enabled: !root.task.running && input.text.trim() !== ""
                onClicked: root.task.startText(["utilities", "translate", from.text.trim(), to.text.trim(), "--stdin"], input.text)
            }
            TextBox {
                width: parent.width
                text: root.task.result.text || ""
                readOnly: true
            }
            Row {
                width: parent.width
                spacing: 8
                PillButton {
                    width: 44
                    text: "󰆏"
                    Accessible.name: "Copy Translation"
                    onClicked: root.copyText(root.task.result.text || "")
                }
                BodyText {
                    width: parent.width - 104
                    height: 44
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: root.task.result.sourceLanguage ? root.task.result.sourceLanguage + " → " + root.task.result.targetLanguage + " · " + root.task.result.words + " Words" : ""
                    font.pixelSize: 12
                }
                PillButton {
                    width: 44
                    text: "󰃢"
                    Accessible.name: "Clear Translation"
                    enabled: !root.task.running
                    onClicked: {
                        input.text = "";
                        root.clearTask();
                    }
                }
            }
        }
    }
    Component {
        id: server
        Column {
            spacing: 10
            property var servers: root.task.result.servers || []
            Choice {
                id: mode
                width: parent.width
                model: ["Single", "Multiple"]
            }
            Field {
                id: folder
                width: parent.width
                text: Preferences.folder("serverFolder", "~/Server")
                placeholderText: "Folder"
            }
            PillButton {
                width: parent.width
                text: "Choose Folder"
                onClicked: {
                    ShellState.externalDialog = true;
                    folderDialog.open();
                }
            }
            FolderDialog {
                id: folderDialog
                currentFolder: "file://" + Preferences.folder("serverFolder", "~/Server")
                onAccepted: {
                    folder.text = selectedFolder.toString();
                    ShellState.externalDialog = false;
                }
                onRejected: ShellState.externalDialog = false
            }
            Field {
                id: port
                width: parent.width
                text: "8000"
                placeholderText: "Port · 1024–65535"
            }

            PillButton {
                width: parent.width
                text: "Start"
                enabled: !root.task.running
                onClicked: root.start(["local-server", "start", folder.text, port.text, mode.currentIndex === 0 ? "single" : "multiple"])
            }
            Repeater {
                model: parent.servers
                Column {
                    required property var modelData
                    width: parent.width
                    spacing: 6
                    BodyText {
                        width: parent.width
                        text: modelData.folder + "\n" + modelData.url
                    }
                    Row {
                        width: parent.width
                        spacing: 8
                        PillButton {
                            width: (parent.width - 8) / 2
                            text: "Copy URL"
                            onClicked: root.copyText(modelData.url)
                        }
                        PillButton {
                            width: (parent.width - 8) / 2
                            text: "Stop"
                            enabled: !root.task.running
                            onClicked: root.start(["local-server", "stop", modelData.token])
                        }
                    }
                }
            }
        }
    }
    Component {
        id: words
        Column {
            spacing: 10
            TextBox {
                id: wordsInput
                width: parent.width
                implicitHeight: 240
                placeholderText: "Paste Text"
                text: Tasks.words.inputText
                onTextChanged: {
                    Tasks.words.inputText = text;
                    analysisDelay.restart();
                }
            }
            Timer {
                id: analysisDelay
                interval: 500
                onTriggered: {
                    if (root.task.running)
                        restart();
                    else if (wordsInput.text.trim())
                        root.task.startText(["utilities", "analyze", "--stdin"], wordsInput.text);
                    else
                        root.task.result = ({});
                }
            }
            BodyText {
                width: parent.width
                text: (root.task.result.words || 0) + " Words"
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 30
            }
            Row {
                width: parent.width
                spacing: 8
                PillButton {
                    width: 44
                    text: "󰆏"
                    Accessible.name: "Copy Text"
                    onClicked: root.copyText(wordsInput.text)
                }
                BodyText {
                    width: parent.width - 104
                    height: 44
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: (root.task.result.language || "Unknown") + " · " + (root.task.result.characters || 0) + " Characters"
                    font.pixelSize: 12
                }
                PillButton {
                    width: 44
                    text: "󰃢"
                    Accessible.name: "Clear Text"
                    enabled: !root.task.running
                    onClicked: {
                        wordsInput.text = "";
                        root.clearTask();
                    }
                }
            }
        }
    }

    Component {
        id: ocr
        Column {
            spacing: 10
            property var languages: root.ocrLanguages
            Choice {
                id: language
                width: parent.width
                model: parent.languages
                currentIndex: Math.max(0, parent.languages.indexOf("eng"))
            }
            FileField {
                id: imageFile
                width: parent.width
            }
            Row {
                width: parent.width
                spacing: 8
                PillButton {
                    width: (parent.width - 8) / 2
                    text: "Image to Text"
                    enabled: !root.task.running && imageFile.path !== ""
                    onClicked: root.start(["utilities", "ocr-file", imageFile.path, language.currentText || "eng"])
                }
                PillButton {
                    width: (parent.width - 8) / 2
                    text: "Select Region"
                    enabled: !root.task.running
                    onClicked: {
                        let lang = language.currentText || "eng";
                        ShellState.close();
                        Quickshell.execDetached(["bash", ShellState.scripts + "screen-ocr.sh", lang]);
                    }
                }
            }
            TextBox {
                width: parent.width
                text: root.task.result.text || ""
                readOnly: true
            }
            Row {
                width: parent.width
                PillButton {
                    width: 44
                    text: "󰆏"
                    objectName: "ocrCopy"
                    Accessible.name: "Copy Recognized Text"
                    enabled: !!root.task.result.text
                    onClicked: root.copyText(root.task.result.text || "")
                }
                Item {
                    width: parent.width - 88
                    height: 44
                }
                PillButton {
                    width: 44
                    text: "󰃢"
                    objectName: "ocrClear"
                    Accessible.name: "Clear Recognized Text"
                    enabled: !root.task.running
                    onClicked: {
                        imageFile.path = "";
                        root.clearTask();
                    }
                }
            }
            Row {
                width: parent.width
                spacing: 8
                Field {
                    id: code
                    width: parent.width - 220
                    placeholderText: "Language · eng, lav, deu"
                }
                PillButton {
                    width: 100
                    text: "Install"
                    onClicked: {
                        let value = code.text.trim();
                        ShellState.close();
                        Quickshell.execDetached(["python3", ShellState.scripts + "open-default.py", "terminal", "bash", ShellState.scripts + "ocr-language.sh", "install", value]);
                    }
                }
                PillButton {
                    width: 104
                    text: "Remove"
                    onClicked: {
                        let value = code.text.trim();
                        ShellState.close();
                        Quickshell.execDetached(["python3", ShellState.scripts + "open-default.py", "terminal", "bash", ShellState.scripts + "ocr-language.sh", "remove", value]);
                    }
                }
            }
        }
    }
    Component {
        id: phone
        Column {
            spacing: 10
            PillButton {
                width: parent.width
                text: "Refresh Devices"
                enabled: !root.task.running
                onClicked: root.start(["utilities", "phone-devices"])
            }
            Repeater {
                model: root.task.result.devices || []
                PillButton {
                    required property var modelData
                    width: parent.width
                    text: modelData.serial
                    detail: modelData.state
                    enabled: modelData.state === "device"
                    onClicked: {
                        const serial = modelData.serial;
                        ShellState.close();
                        Tasks.phone.start(["utilities", "phone-start", serial]);
                    }
                }
            }
            BodyText {
                width: parent.width
                visible: !(root.task.result.devices || []).length
                text: "Connect via USB and authorize USB debugging on the phone."
                color: Style.muted
            }
        }
    }
    Component {
        id: iso
        Column {
            spacing: 10
            readonly property var drives: Tasks.flash.drives
            property bool confirming: false
            readonly property string selectedDrive: Tasks.flash.selectedDrive
            FileField {
                id: isoFile
                width: parent.width
                onPathChanged: parent.confirming = false
                startFolder: "file://" + Preferences.folder("isoFolder", "~/Iso")
                enabled: !root.task.running
            }
            Choice {
                id: drive
                objectName: "isoDriveChoice"
                width: parent.width
                model: parent.drives.map(d => d.name + " · " + d.model + " · " + (d.size / 1e9).toFixed(1) + " GB")
                enabled: !root.task.running
                currentIndex: Math.max(0, parent.drives.findIndex(d => d.name === Tasks.flash.selectedDrive))
                onActivated: index => {
                    parent.confirming = false;
                    if (parent.drives[index])
                        Tasks.flash.selectedDrive = parent.drives[index].name;
                    currentIndex = Qt.binding(() => Math.max(0, Tasks.flash.drives.findIndex(d => d.name === Tasks.flash.selectedDrive)));
                }
            }
            PillButton {
                width: parent.width
                text: "Refresh Drives"
                enabled: !root.task.running
                onClicked: root.start(["iso-flash", "list"])
            }
            BodyText {
                width: parent.width
                visible: parent.confirming
                text: "Erase all data on " + parent.selectedDrive + " and flash this image?"
            }
            PillButton {
                width: parent.width
                visible: parent.confirming
                text: "Cancel"
                onClicked: parent.confirming = false
            }
            PillButton {
                width: parent.width
                text: parent.confirming ? "Confirm Flash" : "Flash"
                enabled: !root.task.running && isoFile.path !== "" && parent.drives.length > 0
                onClicked: {
                    if (!parent.confirming) {
                        parent.confirming = true;
                        return;
                    }
                    let d = parent.drives.find(d => d.name === parent.selectedDrive);
                    if (!d)
                        return;
                    root.start(["iso-flash", "write", isoFile.path, JSON.stringify({
                            name: d.name,
                            size: d.size,
                            serial: d.serial,
                            "maj:min": d["maj:min"]
                        })]);
                    parent.confirming = false;
                }
            }
        }
    }
}
