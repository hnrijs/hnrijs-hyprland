import QtQuick
import QtQuick.Controls
import qs

ScrollView {
    id: root
    property alias text: editor.text
    property alias placeholderText: editor.placeholderText
    property alias readOnly: editor.readOnly
    implicitHeight: 140
    clip: true
    background: Rectangle {
        color: Style.bg1
        radius: 16
    }
    TextArea {
        id: editor
        wrapMode: TextEdit.Wrap
        selectByMouse: true
        color: Style.foreground
        placeholderTextColor: Style.muted
        selectionColor: Style.primary
        selectedTextColor: Style.activeText
        font.family: Style.fontFamily
        font.pixelSize: 14
        padding: 12
        background: null
    }
}
