import QtQuick
import qs
import qs.components

Column {
    id: root
    spacing: 14
    function takeInitialFocus() {
        response.forceActiveFocus();
    }
    BodyText {
        width: parent.width
        text: "󰌾  Authentication Required"
        font.family: Style.iconFontFamily
        font.pixelSize: 21
    }
    BodyText {
        width: parent.width
        text: Auth.flow ? Auth.flow.message : ""
    }
    BodyText {
        width: parent.width
        text: Auth.flow ? Auth.flow.actionId : ""
        color: Style.muted
        font.pixelSize: 12
    }
    Field {
        id: response
        width: parent.width
        placeholderText: Auth.flow ? Auth.flow.inputPrompt || "Password" : "Password"
        echoMode: Auth.flow && Auth.flow.responseVisible ? TextInput.Normal : TextInput.Password
        enabled: !!Auth.flow && Auth.flow.isResponseRequired
        onAccepted: root.submit()
    }
    function submit() {
        if (Auth.flow && Auth.flow.isResponseRequired) {
            Auth.flow.submit(response.text);
            response.clear();
        }
    }
    BodyText {
        width: parent.width
        text: Auth.flow ? Auth.flow.supplementaryMessage : ""
        visible: text !== ""
        color: Style.muted
    }
    Row {
        width: parent.width
        spacing: 10
        PillButton {
            width: 110
            text: "Cancel"
            onClicked: if (Auth.flow)
                Auth.flow.cancelAuthenticationRequest()
        }
        Item {
            width: Math.max(0, parent.width - 280)
            height: 44
        }
        PillButton {
            width: 150
            text: "Authenticate"
            selected: true
            enabled: !!Auth.flow && Auth.flow.isResponseRequired
            onClicked: root.submit()
        }
    }
    Connections {
        target: Auth
        function onFlowChanged() {
            response.clear();
        }
    }
}
