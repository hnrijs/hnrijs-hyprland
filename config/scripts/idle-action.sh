#!/usr/bin/env bash
set -euo pipefail
[[ ! -f ${XDG_RUNTIME_DIR:?}/hshell-caffeine ]] || exit 0
case ${1:-} in
    lock) loginctl lock-session ;;
    suspend) systemctl suspend ;;
    *) exit 2 ;;
esac
