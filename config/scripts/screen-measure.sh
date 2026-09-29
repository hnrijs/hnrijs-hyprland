#!/usr/bin/env bash
set -euo pipefail
timeout 1 qs -c hshell ipc call hshell close >/dev/null 2>&1 || true
sleep 0.15
selection=$(timeout 30 slurp -f '%wx%h') || exit 0
[[ -n "$selection" ]] || exit 0
printf '%s' "$selection" | timeout 5 wl-copy
python3 "${XDG_CONFIG_HOME:-$HOME/.config}/scripts/shell-notice.py" measure "$selection px"
