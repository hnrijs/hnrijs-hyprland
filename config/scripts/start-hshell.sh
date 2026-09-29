#!/usr/bin/env bash
set -euo pipefail
qs -c hshell ipc call hshell ping >/dev/null 2>&1 && exit 0
export QSG_RENDER_LOOP=${QSG_RENDER_LOOP:-threaded}
exec flock -n "${XDG_RUNTIME_DIR:-/run/user/$UID}/hshell-session.lock" qs -c hshell
