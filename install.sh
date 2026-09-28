#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
state_home=${XDG_STATE_HOME:-$HOME/.local/state}
config_only=false
use_sddm=true
network_defaults=true
for arg in "$@"; do
    case $arg in
        --config-only) config_only=true ;;
        --no-sddm) use_sddm=false ;;
        --no-network-defaults) network_defaults=false ;;
        --help) printf 'Run as your normal user: bash install.sh [--config-only] [--no-sddm] [--no-network-defaults]\n'; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$arg" >&2; exit 2 ;;
    esac
done
[[ $EUID -ne 0 ]] || { echo 'Run as your normal desktop user, without sudo.' >&2; exit 1; }
[[ $HOME == /* && $HOME != / && $config_home == /* && $state_home == /* ]] || { echo 'Use absolute HOME/XDG paths.' >&2; exit 1; }
[[ -f $SCRIPT_DIR/config/quickshell/hshell/shell.qml ]] || { echo 'Extract or clone the complete repository.' >&2; exit 1; }
if ! $config_only; then
    command -v sudo >/dev/null || { echo 'Install sudo and grant this user access first.' >&2; exit 1; }
    sudo -v
    if [[ -d "$SCRIPT_DIR/theme" ]]; then
        sudo install -d -m 755 /usr/share/themes
        sudo cp -a "$SCRIPT_DIR/theme/." /usr/share/themes/
    fi
    if command -v pacman >/dev/null; then
    required=(
         alacritty aria2 awww bash bluez bluez-utils brightnessctl
        cliphist curl dbus desktop-file-utils fd ffmpeg fontconfig fzf
        gawk git gnome-keyring grim gtk3 gvfs gvfs-mtp
        hypridle hyprland hyprlock hyprpicker hyprsunset imagemagick imv jq
        less libnotify libpulse monolith mpv networkmanager libreoffice-fresh neovim noto-fonts
        noto-fonts-emoji pacman-contrib perl-image-exiftool inter-font cava pipewire pipewire-alsa pipewire-pulse
        playerctl polkit power-profiles-daemon python python-dbus-next python-qrcode python-pillow qt6-declarative qt6-imageformats qt6-multimedia-ffmpeg
        qt6-wayland quickshell ripgrep slurp speedtest-cli thunar thunar-volman ttf-jetbrains-mono-nerd
        tumbler udisks2 upower util-linux wget wireplumber wl-clipboard xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland xdg-user-dirs xdg-utils yt-dlp base-devel pavucontrol qt5-wayland 
          openssh iwd uwsm smartmontools
              zip unzip
        thunar-archive-plugin file-roller 7zip  ttf-nerd-fonts-symbols android-udev  ffmpegthumbnailer ttf-dejavu otf-font-awesome
        noto-fonts-cjk ncdu libqalculate ufw translate-shell tesseract tesseract-data-eng scrcpy android-tools iproute2
    )
    $use_sddm && required+=(sddm xorg-server)
    if pacman -Si librewolf >/dev/null 2>&1; then required+=(librewolf);else printf 'LibreWolf is not in enabled repositories. Install it from a trusted source to use the preferred browser.\n';fi
    sudo pacman -Syu --needed --noconfirm "${required[@]}"
    [[ $(vercmp "$(pacman -Q quickshell | awk '{print $2}')" 0.3.1) -ge 0 ]] || { echo 'Quickshell 0.3.1+ with Polkit/Networking support is required.' >&2; exit 1; }
    [[ $(vercmp "$(pacman -Q hyprland | awk '{print $2}')" 0.55.0) -ge 0 ]] || { echo 'Hyprland 0.55+ with Lua configuration is required.' >&2; exit 1; }
    else
        if $use_sddm; then bash "$SCRIPT_DIR/installer/dependencies.sh" sddm;else bash "$SCRIPT_DIR/installer/dependencies.sh";fi
        python3 "$SCRIPT_DIR/installer/check-runtime.py"
    fi
fi
command -v python3 >/dev/null || { echo 'Python 3 is required.' >&2; exit 1; }
python3 "$SCRIPT_DIR/installer/install-config.py" --source "$SCRIPT_DIR" --home "$HOME" --config "$config_home" --state "$state_home" --no-backups
python3 - "$config_home/hypr/hyprlock.conf" "$state_home" <<'PY'
from pathlib import Path
import sys
path=Path(sys.argv[1]);path.write_text(path.read_text().replace('$HOME/.local/state',sys.argv[2]))
PY
python3 "$config_home/scripts/default-apps.py"
if ! $config_only; then
    sudo systemctl enable --now NetworkManager.service bluetooth.service power-profiles-daemon.service
    if $network_defaults; then
        python3 "$SCRIPT_DIR/installer/network-defaults.py" "$state_home/hshell/backups" --no-backups
        if systemctl is-active --quiet firewalld.service; then
            printf 'Existing firewalld service retained. UFW was not enabled alongside it.\n'
        elif [[ -n ${SSH_CONNECTION:-} ]]; then
            printf 'Remote session detected. Enable UFW locally after checking SSH rules.\n'
        else
            sudo ufw --force enable
            sudo systemctl enable ufw.service
        fi
    fi
    sudo systemctl --global enable pipewire wireplumber pipewire-pulse 2>/dev/null || true
    systemctl --user start pipewire wireplumber pipewire-pulse 2>/dev/null || true
    if $use_sddm; then
        sudo install -d -m 755 /usr/share/sddm/themes/hshell /etc/sddm.conf.d
        sudo install -m 644 "$SCRIPT_DIR/sddm/hshell/Main.qml" "$SCRIPT_DIR/sddm/hshell/metadata.desktop" "$SCRIPT_DIR/sddm/hshell/theme.conf" /usr/share/sddm/themes/hshell/
        python3 "$SCRIPT_DIR/installer/sddm-colors.py" | sudo tee /usr/share/sddm/themes/hshell/theme.conf >/dev/null
        sudo install -d -m 755 /var/lib/hshell /var/lib/hshell/backgrounds
        sudo install -d -m 755 -o "$(id -un)" -g "$(id -gn)" "/var/lib/hshell/backgrounds/$(id -u)"
        python3 "$config_home/scripts/wallpaper.py" sync-login
        printf '[Theme]\nCurrent=hshell\n' | sudo tee /etc/sddm.conf.d/90-hshell.conf >/dev/null
        sudo systemctl enable --force sddm.service
        sudo systemctl set-default graphical.target
    fi

fi
printf '\nhshell installed.\n'
printf 'Shell only: qs -c hshell\n'
if ! $config_only && $use_sddm; then
    if [[ -z ${WAYLAND_DISPLAY:-} && -z ${DISPLAY:-} ]]; then
        printf 'Starting SDDM. Select Hyprland on the login screen.\n'
        sudo systemctl start sddm.service
    else
        printf 'SDDM is enabled for the next boot. Your current graphical session was not interrupted.\n'
    fi
fi
