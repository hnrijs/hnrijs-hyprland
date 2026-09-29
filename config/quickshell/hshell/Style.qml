pragma Singleton
import QtQuick
import Quickshell
import qs

Singleton {
    readonly property var palette: [Preferences.backgroundColor, Preferences.surfaceColor, Qt.lighter(Preferences.surfaceColor, 1.4), Preferences.foregroundColor, Qt.darker(Preferences.foregroundColor, 1.5), Preferences.accentColor]
    readonly property color bgDim: palette[0]
    readonly property color bg0: palette[0]
    readonly property color bg1: palette[1]
    readonly property color bg2: palette[1]
    readonly property color bg3: palette[2]
    readonly property color bg4: palette[2]
    readonly property color foreground: palette[3]
    readonly property color muted: palette[4]
    readonly property color mutedDark: palette[4]
    readonly property color primary: palette[5]
    readonly property color activeFill: primary
    readonly property color activeText: (primary.r * 0.299 + primary.g * 0.587 + primary.b * 0.114) > 0.55 ? "#111111" : "#ffffff"
    readonly property color primaryContainer: palette[1]
    readonly property color shellBackground: bg0
    readonly property color shellForeground: foreground
    readonly property color bgGreen: bg1
    readonly property color bgYellow: bg1
    readonly property color red: primary
    readonly property color green: primary
    readonly property color blue: primary
    readonly property color yellow: primary
    readonly property color orange: primary
    readonly property color purple: primary
    readonly property color aqua: primary
    readonly property string fontFamily: "Inter"
    readonly property string iconFontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 14
    readonly property int radius: 28
    readonly property int radiusSmall: 18
    readonly property int animationFast: 160
    readonly property int animationNormal: 260
}
