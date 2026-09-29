pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    property int selected: 0
    readonly property var players: Mpris.players.values
    readonly property var player: {
        const preferred = players.length ? players[Math.min(selected, players.length - 1)] : null;
        return preferred && preferred.isPlaying ? preferred : players.find(p => p.isPlaying) || preferred;
    }
    function nextPlayer() {
        if (players.length)
            selected = (selected + 1) % players.length;
    }
}
