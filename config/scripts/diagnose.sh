#!/usr/bin/env bash
set -u
printf 'Versions\n'
qs --version
hyprctl version
printf '\nRequired desktop helpers\n'
for cmd in qs hyprctl awww awww-daemon alacritty thunar python3 cliphist wl-copy wl-paste hyprlock hypridle; do
    command -v "$cmd" || printf 'MISSING: %s\n' "$cmd"
done
printf '\nSession services\n'
systemctl is-active NetworkManager bluetooth power-profiles-daemon
printf '\nPipeWire\n'
systemctl --user is-active pipewire pipewire-pulse wireplumber
printf '\nShell IPC\n'
qs -c hshell ipc show
printf '\nHyprland configuration errors\n'
hyprctl configerrors
printf '\nSession log: %s/hshell/session.log\n' "${XDG_STATE_HOME:-$HOME/.local/state}"
