import QtQuick
import Quickshell
import QtQuick.Controls
import QtQuick.Dialogs
import qs
import qs.components

Column {
    id: root
    objectName: "interfacePanel"
    property int section: 0
    spacing: 14
    Row {
        width: parent.width
        spacing: 8
        Repeater {
            model: ["Colors", "Wallpaper", "Weather"]
            PillButton {
                required property int index
                required property string modelData
                width: (root.width - 16) / 3
                text: modelData
                selected: root.section === index
                onClicked: root.section = index
            }
        }
    }
    Repeater {
        model: [["overviewTransparent", "Transparent Overview", false], ["overviewBlur", "Blur Behind Overview", true], ["overviewNumbers", "Workspace Numbers", true]]
        Item {
            required property var modelData
            width: parent.width
            height: 40
            visible: root.section === 0
            BodyText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: modelData[1]
            }
            Toggle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: Preferences.option(modelData[0], modelData[2])
                onToggled: Preferences.setOptions(Object.assign({}, Preferences.options, {
                    [modelData[0]]: checked
                }))
            }
        }
    }
    BodyText {
        visible: root.section === 0
        text: "Colors"
    }
    Repeater {
        model: [["backgroundColor", "Background"], ["surfaceColor", "Surfaces"], ["foregroundColor", "Text"], ["accentColor", "Accent"]]
        delegate: Row {
            id: colorRow
            visible: root.section === 0
            required property var modelData
            width: parent.width
            spacing: 10
            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: Preferences[modelData[0]]
                border.width: 1
                border.color: Style.muted
            }
            BodyText {
                width: 110
                height: 44
                verticalAlignment: Text.AlignVCenter
                text: modelData[1]
            }
            Field {
                id: colorInput
                width: parent.width - 166
                objectName: "color-" + colorRow.modelData[0]
                text: Preferences[colorRow.modelData[0]]
                maximumLength: 7
                onTextEdited: if (/^#[0-9a-fA-F]{6}$/.test(text))
                    Preferences.save(colorRow.modelData[0], text)
                Connections {
                    target: Preferences
                    function onColorsReset() {
                        colorInput.text = Preferences[colorRow.modelData[0]];
                    }
                }
            }
        }
    }
    PillButton {
        visible: root.section === 0
        text: "Reset Colors"
        objectName: "resetColors"
        onClicked: Preferences.resetColors()
    }
    BodyText {
        visible: root.section === 0 && (Preferences.saving || Preferences.saveError !== "")
        width: parent.width
        text: Preferences.saveError || "Saving…"
        color: Style.muted
    }
    PillButton {
        visible: root.section === 0 && Preferences.saveError !== ""
        text: "Retry Save"
        onClicked: Preferences.retry()
    }
    BodyText {
        visible: root.section === 1
        text: "Wallpaper Folder"
    }
    Field {
        width: parent.width
        visible: root.section === 1
        text: Preferences.wallpaperFolder
        onEditingFinished: Preferences.save("wallpaperFolder", text)
    }
    Row {
        visible: root.section === 1
        width: parent.width
        spacing: 8
        PillButton {
            width: (parent.width - 8) / 2
            text: "Open Folder"
            onClicked: {
                ShellState.close();
                WallpaperState.openWallpaperFolder();
            }
        }
        PillButton {
            width: (parent.width - 8) / 2
            text: "Choose Wallpaper"
            onClicked: {
                ShellState.navigation = ShellState.navigation.concat([
                    {
                        panel: "tool",
                        tool: "interface",
                        detail: ""
                    }
                ]);
                ShellState.setPanel("wallpaper");
            }
        }
    }
    Item {
        width: parent.width
        height: 44
        visible: root.section === 2
        BodyText {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Detailed Weather"
        }
        Toggle {
            anchors.right: parent.right
            checked: Preferences.option("detailedWeather", true)
            onToggled: Preferences.setOptions(Object.assign({}, Preferences.options, {
                detailedWeather: checked
            }))
        }
    }
    BodyText {
        visible: root.section === 2
        text: "Weather Cities"
    }
    Repeater {
        model: Preferences.cities
        delegate: Row {
            required property string modelData
            required property int index
            visible: root.section === 2
            width: parent.width
            spacing: 8
            Field {
                width: parent.width - 52
                text: modelData
                onEditingFinished: {
                    const cities = Preferences.cities.slice();
                    cities[index] = text.trim() || modelData;
                    Preferences.save("cities", JSON.stringify(cities));
                }
            }
            PillButton {
                width: 44
                text: "−"
                enabled: Preferences.cities.length > 1
                onClicked: Preferences.save("cities", JSON.stringify(Preferences.cities.filter((c, i) => i !== index)))
            }
        }
    }
    Row {
        visible: root.section === 2
        width: parent.width
        spacing: 8
        Field {
            id: newCity
            width: parent.width - 52
            placeholderText: "Add City"
        }
        PillButton {
            width: 44
            text: "+"
            enabled: newCity.text.trim() !== "" && Preferences.cities.length < 8
            onClicked: {
                Preferences.save("cities", JSON.stringify(Preferences.cities.concat([newCity.text.trim()])));
                newCity.text = "";
            }
        }
    }
}
