import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import qs

Flow {
    id: root
    required property var shellWindow
    spacing: 8
    visible: SystemTray.items.values.length > 0
    Repeater {
        model: SystemTray.items
        delegate: Rectangle {
            id: entry
            objectName: "tray-icon-" + modelData.id
            required property var modelData
            width: 42
            height: 42
            radius: 17
            color: pointer.containsMouse ? Style.bg3 : Style.bg1
            property bool quitRequested: false
            QsMenuOpener {
                id: menu
                menu: entry.modelData.menu
                onChildrenChanged: if (entry.quitRequested)
                    entry.tryQuit()
            }
            function tryQuit() {
                const action = menu.children.values.find(a => a.enabled && (/^(quit|exit|close|iziet|aizvērt|beenden|schließen)(\b|\s)/i.test(a.text.replace(/&/g, "")) || /application-exit|window-close/.test(a.icon)));
                if (action) {
                    quitRequested = false;
                    action.triggered();
                }
            }
            Timer {
                id: quitTimeout
                interval: 500
                onTriggered: if (entry.quitRequested) {
                    entry.quitRequested = false;
                    Quickshell.execDetached(["notify-send", "hshell", "This app does not expose a Quit action in its tray menu."]);
                }
            }
            Image {
                anchors.centerIn: parent
                width: 24
                height: 24
                source: entry.modelData.icon
                sourceSize.width: 24
                sourceSize.height: 24
            }
            MouseArea {
                id: pointer
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: event => {
                    if (event.button === Qt.RightButton) {
                        entry.quitRequested = true;
                        entry.tryQuit();
                        if (entry.quitRequested)
                            quitTimeout.restart();
                    } else if (entry.modelData.onlyMenu)
                        entry.modelData.display(root.shellWindow, 0, 60);
                    else
                        entry.modelData.activate();
                }
            }
        }
    }
}
