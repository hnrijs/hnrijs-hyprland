import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#080808"
    readonly property color foreground: config.stringValue("Foreground") || "#ffffff"
    readonly property color accent: config.stringValue("Accent") || "#ffffff"
    property date now: new Date()
    property bool waiting: false
    property string error: ""
    component FrostedField: Item {
        ShaderEffectSource {
            id: glassSource
            sourceItem: wallpaper
            sourceRect: Qt.rect(inputColumn.x, inputColumn.y + parent.parent.y, parent.width, parent.height)
            textureSize: Qt.size(parent.width, parent.height)
            live: true
            visible: false
        }
        Rectangle {
            id: glassMask
            anchors.fill: parent
            radius: height / 2
            color: "white"
            layer.enabled: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: glassSource
            blurEnabled: true
            blur: 0.65
            blurMax: 24
            autoPaddingEnabled: false
            maskEnabled: true
            maskSource: glassMask
        }
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: "#22000000"
            border.width: 1
            border.color: root.accent
        }
    }
    function login() {
        if (waiting || !username.text.trim() || !password.text)
            return;
        waiting = true;
        error = "";
        sddm.login(username.text, password.text, sessions.currentIndex);
    }
    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }
    Image {
        id: wallpaper
        cache: false
        anchors.fill: parent
        source: config.stringValue("Background")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    Rectangle {
        anchors.fill: parent
        color: "#55000000"
    }
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.12
        spacing: 8
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(root.now, "dddd, MMMM d")
            color: root.foreground
            font.family: "Inter"
            font.pixelSize: 24
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "HH:mm")
            color: root.foreground
            font.family: "Inter"
            font.pixelSize: 100
            font.weight: Font.DemiBold
        }
    }
    Column {
        id: inputColumn
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.min(parent.height * 0.65, parent.height - height - 30)
        width: 300
        spacing: 12
        TextField {
            id: username
            width: parent.width
            height: 44
            text: userModel.lastUser
            placeholderText: "Username"
            color: root.foreground
            horizontalAlignment: TextInput.AlignHCenter
            font.family: "Inter"
            background: FrostedField {}
            onAccepted: password.forceActiveFocus()
        }
        TextField {
            id: password
            width: parent.width
            height: 44
            focus: true
            echoMode: TextInput.Password
            placeholderText: "Password"
            color: root.foreground
            horizontalAlignment: TextInput.AlignHCenter
            enabled: !root.waiting
            background: FrostedField {}
            onAccepted: root.login()
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: keyboard.capsLock
            text: "Caps Lock"
            color: root.foreground
            font.pixelSize: 12
        }
        ComboBox {
            id: sessions
            width: parent.width
            height: 40
            model: sessionModel
            textRole: "name"
            currentIndex: sessionModel.lastIndex
            contentItem: Text {
                text: sessions.displayText
                color: root.foreground
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: FrostedField {}
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.waiting
            text: "Signing In…"
            color: root.foreground
            font.pixelSize: 12
        }
        Text {
            width: parent.width
            text: root.error
            color: "#ff9d9d"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            root.waiting = false;
            root.error = "Sign-in failed";
            password.clear();
            password.forceActiveFocus();
        }
        function onLoginSucceeded() {
            password.clear();
        }
    }
}
