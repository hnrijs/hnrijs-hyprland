#!/usr/bin/env bash
set -euo pipefail
exec 9>"${XDG_RUNTIME_DIR:-/run/user/$UID}/hshell-clipboard.lock"
flock -n 9 || exit 0
wl-paste --type text --watch cliphist store &
text_pid=$!
wl-paste --type image --watch cliphist store &
image_pid=$!
trap 'kill "$text_pid" "$image_pid" 2>/dev/null || true' EXIT
trap 'exit 0' TERM INT
wait
