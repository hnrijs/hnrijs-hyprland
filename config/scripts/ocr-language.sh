#!/usr/bin/env bash
set -euo pipefail
action=${1:-}
lang=${2:-}
[[ $lang =~ ^[a-z][a-z0-9_]{1,30}$ ]] || { echo 'Invalid language code'; exit 2; }
case $action in
  install) sudo pacman -S --needed -- "tesseract-data-$lang" ;;
  remove) sudo pacman -R -- "tesseract-data-$lang" ;;
  *) exit 2 ;;
esac
read -r -p 'Press Enter to close.' _ || true
