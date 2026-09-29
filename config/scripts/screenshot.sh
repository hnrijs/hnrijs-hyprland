#!/usr/bin/env bash
set -euo pipefail
folder=$(python3 - <<'PYTHON'
import json,os
from pathlib import Path
fallback=Path.home()/'Pictures/Screenshots'
try:
    prefs=json.loads((Path(os.environ.get('XDG_STATE_HOME') or str(Path.home()/'.local/state'))/'hshell/preferences.json').read_text())
    folder=Path(prefs.get('options',{}).get('screenshotFolder',str(fallback))).expanduser()
    if not folder.is_absolute():folder=fallback
except (OSError,ValueError,TypeError):folder=fallback
print(folder)
PYTHON
)
mkdir -p "$folder"
file=$(mktemp "$folder/screenshot-$(date +%Y%m%d-%H%M%S)-XXXXXX.png")
trap 'rm -f -- "$file"' ERR
case ${1:-full} in
    full) grim "$file" ;;
    region)
        if ! geometry=$(slurp); then rm -f -- "$file"; exit 0; fi
        grim -g "$geometry" "$file"
        ;;
    *) rm -f -- "$file"; exit 2 ;;
esac
wl-copy --type image/png < "$file"

python3 "${XDG_CONFIG_HOME:-$HOME/.config}/scripts/shell-notice.py" screenshot "Screenshot Saved"
