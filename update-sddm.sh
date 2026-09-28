#!/usr/bin/env bash
set -euo pipefail
source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
backup="/usr/share/sddm/themes/hshell.backup.$(date +%Y%m%d-%H%M%S)"
if [[ -d /usr/share/sddm/themes/hshell ]]; then
    sudo cp -a /usr/share/sddm/themes/hshell "$backup"
fi
sudo install -d -m 755 /usr/share/sddm/themes/hshell
sudo install -m 644 "$source_dir/sddm/hshell/Main.qml" /usr/share/sddm/themes/hshell/Main.qml
sudo install -d -m 755 /var/lib/hshell /var/lib/hshell/backgrounds
sudo install -d -m 755 -o "$(id -un)" -g "$(id -gn)" "/var/lib/hshell/backgrounds/$(id -u)"
python3 "$source_dir/config/scripts/wallpaper.py" sync-login
theme_config=$(mktemp)
trap 'rm -f -- "$theme_config"' EXIT
python3 "$source_dir/installer/sddm-colors.py" > "$theme_config"
sudo install -m 644 "$theme_config" /usr/share/sddm/themes/hshell/theme.conf
printf 'SDDM theme updated. Your current session was not restarted.\n'
