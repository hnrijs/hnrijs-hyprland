#!/usr/bin/env bash
set -euo pipefail
exec 9>"${XDG_RUNTIME_DIR:?}/hshell-lock.lock"
flock -n 9 || exit 0
pgrep -u "$UID" -x hyprlock >/dev/null && exit 0
scripts="${XDG_CONFIG_HOME:-$HOME/.config}/scripts"
cleanup() {
    timeout 5 python3 "$scripts/lock-audio.py" restore >/dev/null 2>&1 || true
    timeout 2 qs -c hshell ipc call hshell lockvisible false >/dev/null 2>&1 || true
}
trap cleanup EXIT
timeout 2 qs -c hshell ipc call hshell close >/dev/null 2>&1 || true
timeout 8 python3 "$scripts/lock-audio.py" prepare >/dev/null 2>&1 || true
generated=$(python3 "$scripts/lock-layout.py")
timeout 2 qs -c hshell ipc call hshell lockvisible true >/dev/null 2>&1 || true
hyprlock --config "$generated"
