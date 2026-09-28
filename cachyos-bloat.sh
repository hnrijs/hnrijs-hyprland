#!/usr/bin/env bash
set -euo pipefail
command -v pacman >/dev/null || { printf 'This script is only for Arch-based installations.\n' >&2;exit 1; }
packages=(cachyos-hello cachyos-kernel-manager cachyos-packageinstaller scx-manager plymouth cachyos-wallpapers cachyos-plymouth-theme cachyos-plymouth-bootanimation scx-scheds scx-tools cachyos-micro-settings micro meld shelly)
installed=()
for package in "${packages[@]}"; do
    if pacman -Q "$package" >/dev/null 2>&1; then installed+=("$package");fi
done
if ((${#installed[@]}==0)); then printf 'None of the listed packages are installed.\n';exit 0;fi
printf 'Review the removal transaction and any additional dependencies before accepting.\n'
sudo pacman -Rns -- "${installed[@]}"
if command -v mkinitcpio >/dev/null; then sudo mkinitcpio -P;fi
if command -v sdboot-manage >/dev/null; then sudo sdboot-manage gen;fi
