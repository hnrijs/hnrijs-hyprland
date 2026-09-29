#!/usr/bin/env bash
set -euo pipefail
if command -v pacman >/dev/null; then
    if command -v yay >/dev/null; then yay -Syu;else sudo pacman -Syu;fi
elif command -v apt-get >/dev/null; then
    sudo apt-get update
    sudo apt-get upgrade
elif command -v dnf >/dev/null; then
    sudo dnf upgrade --refresh
else
    printf 'No supported package manager found.\n' >&2
    exit 1
fi
