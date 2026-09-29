#!/usr/bin/env bash
set -euo pipefail
if command -v apt-get >/dev/null; then
    sudo apt-get autoremove
    sudo apt-get autoclean
    exit 0
elif command -v dnf >/dev/null; then
    sudo dnf autoremove
    sudo dnf clean packages
    exit 0
fi
command -v pacman >/dev/null || { printf 'No supported package manager found.\n' >&2;exit 1; }
printf 'Packages no longer required by another package:\n'
mapfile -t orphans < <(pacman -Qtdq || true)
if ((${#orphans[@]})); then
    printf '  %s\n' "${orphans[@]}"
    read -r -p 'Remove these packages and their unused dependencies? [y/N] ' answer
    if [[ $answer == [yY] ]]; then sudo pacman -Rns -- "${orphans[@]}"; fi
else
    printf 'None.\n'
fi
printf '\nPackage cache: keep the newest three versions of each package.\n'
read -r -p 'Prune older cached packages? [y/N] ' answer
if [[ $answer == [yY] ]]; then sudo paccache -rk3; fi

if command -v yay >/dev/null; then
    printf '\nReview AUR build-cache cleanup.\n'
    yay -Sc
fi
