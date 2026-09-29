#!/usr/bin/env bash
set -euo pipefail
timeout 1 qs -c hshell ipc call hshell close >/dev/null 2>&1 || true
sleep 0.15
region=$(slurp) || exit 0
[[ -n $region ]] || exit 0
grim -g "$region" - | wl-copy --type image/png
xdg-open 'https://lens.google.com/'
python3 "$(dirname -- "${BASH_SOURCE[0]}")/shell-notice.py" search 'Image Copied · Paste into Google Lens'
