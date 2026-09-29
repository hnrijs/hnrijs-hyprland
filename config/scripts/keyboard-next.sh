#!/usr/bin/env bash
set -euo pipefail
hyprctl switchxkblayout all next >/dev/null
name=$(hyprctl -j devices | python3 -c 'import json,sys; k=json.load(sys.stdin).get("keyboards",[]); d=next((x for x in k if x.get("main")),k[0] if k else {}); print(d.get("active_keymap","Keyboard").split("(")[0].strip())')
python3 "$(dirname "$0")/shell-notice.py" keyboard "$name"
