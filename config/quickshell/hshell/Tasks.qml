pragma Singleton
import QtQuick
import Quickshell
import qs

Singleton {
    property alias textCopy: textCopyTask
    Task {
        id: textCopyTask
    }
    property alias translate: translateTask
    property alias words: wordsTask
    property alias ocr: ocrTask
    property alias phone: phoneTask
    property alias server: serverTask
    property alias flash: flashTask
    Task {
        id: translateTask
        property string inputText: ""
        property string sourceCode: "auto"
        property string targetCode: "en"
    }
    Task {
        id: wordsTask
        property string inputText: ""
    }
    Task {
        id: ocrTask
        onFinished: success => {
            if (success && result.text)
                ShellState.notice("ocr", "Text Copied");
        }
    }
    Task {
        id: phoneTask
    }
    Task {
        id: serverTask
    }
    Task {
        id: flashTask
        property var drives: []
        property string selectedDrive: ""
        onResultChanged: {
            if (!result.drives)
                return;
            drives = result.drives;
            if (!drives.some(d => d.name === selectedDrive))
                selectedDrive = drives.length ? drives[0].name : "";
        }
    }
    property alias device: deviceTask
    Task {
        id: deviceTask
    }
    property alias network: networkTask
    Task {
        id: networkTask
    }
    property alias exif: exifTask
    Task {
        id: exifTask
    }
    property alias color: colorTask
    Task {
        id: colorTask
        onFinished: success => {
            if (success && result.color) {
                ShellState.notice("color", result.color);
            }
        }
    }
    property alias weather: weatherTask
    property alias speed: speedTask
    property alias disks: diskTask
    property alias download: downloadTask
    property alias media: mediaTask
    property alias ip: ipTask
    property alias windows: windowsTask
    property alias windowAction: windowActionTask
    property alias clipboard: clipboardTask
    property alias caffeine: caffeineTask
    Task {
        id: weatherTask
    }
    Task {
        id: speedTask
    }
    Task {
        id: diskTask
    }
    Task {
        id: downloadTask
        onFinished: success => {
            if (success) {
                ShellState.notice("download", "Download Complete");
            }
        }
    }
    Task {
        id: mediaTask
    }
    Task {
        id: ipTask
    }
    Task {
        id: windowsTask
    }
    Task {
        id: windowActionTask
        onFinished: success => {
            if (success)
                windowsTask.start(["windows"]);
        }
    }
    Task {
        id: clipboardTask
        onFinished: success => {
            if (success) {
                Backend.clipboardContents = "";
                Backend.clipboardImageSource = "";
                Backend.refreshClipboard();
            }
        }
    }
    Task {
        id: caffeineTask
        property bool initialized: false
        onFinished: success => {
            if (success && initialized)
                ShellState.notice("idle", result.enabled ? "Awake" : "Idle");
            if (success)
                initialized = true;
        }
    }
    Component.onCompleted: caffeineTask.start(["caffeine"])
}
