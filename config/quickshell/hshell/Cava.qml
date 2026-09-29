pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root
    property var levels: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property int consumers: 0
    readonly property bool playing: !!Media.player && Media.player.isPlaying
    Process {
        command: ["cava", "-p", ShellState.scripts + "cava.conf"]
        running: root.playing
        stdout: SplitParser {
            onRead: line => {
                const values = line.split(";").filter(v => v !== "").map(v => Math.max(0, Math.min(100, Number(v) || 0)));
                if (values.length === 10)
                    root.levels = values;
            }
        }
    }
    onPlayingChanged: if (!playing)
        levels = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
}
