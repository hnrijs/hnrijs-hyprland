#!/usr/bin/env bash
set -euo pipefail
runtime=${XDG_RUNTIME_DIR:?Run this inside your desktop session}
state=$runtime/hshell-caffeine
if [[ -f $state ]]; then
    rm -f -- "$state"
    notify-send 'Idle timers enabled' 'Automatic locking and suspend are enabled.'
else
    touch "$state"
    notify-send 'Stay awake enabled' 'Automatic locking and suspend are paused; manual locking still works.'
fi
