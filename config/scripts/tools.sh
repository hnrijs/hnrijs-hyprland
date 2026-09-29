#!/usr/bin/env bash
set -euo pipefail
scripts=${XDG_CONFIG_HOME:-$HOME/.config}/scripts
action=${1:-}
if [[ $action == terminal ]]; then
    shift
    status=0
    bash "$0" "$@" || status=$?
    printf '\nFinished with exit code %s. Press Enter to close.\n' "$status"
    read -r _ || true
    exit "$status"
fi
case $action in
    update) bash "$scripts/system-update.sh" ;;
    clean) bash "$scripts/system-clean.sh" ;;
    info) uname -a; lscpu; free -h; lsblk ;;
    monitors) hyprctl monitors ;;
    network) nmtui ;;
    network-info) nmcli device; nmcli connection show --active ;;
    install-app)
        mapfile -t packages < <(pacman -Slq | sort -u | fzf --multi --preview 'pacman -Si {1}')
        ((${#packages[@]} == 0)) || sudo pacman -S --needed -- "${packages[@]}"
        ;;
    remove-app)
        mapfile -t packages < <(pacman -Qq | fzf --multi --preview 'pacman -Qi {1}')
        ((${#packages[@]} == 0)) || sudo pacman -Rns -- "${packages[@]}"
        ;;
    find-file)
        mapfile -d '' -t selected < <(fd --type f --print0 . "$HOME" | fzf --read0 --print0)
        ((${#selected[@]} == 0)) || xdg-open "${selected[0]}"
        ;;
    find-text)
        read -r -p 'Search text: ' term
        [[ -z $term ]] || rg --fixed-strings -- "$term" "$HOME" | less -R
        ;;
    edit-hypr) nvim "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.lua" ;;
    password) passwd ;;
    user-password)
        name=${2:?username required}
        [[ $name =~ ^[a-z_][a-z0-9_-]{0,30}$ ]] || exit 2
        sudo passwd -- "$name"
        ;;
    diagnostics) bash "$scripts/diagnose.sh" ;;
    *) printf 'Unknown tool: %s\n' "$action" >&2; exit 2 ;;
esac
