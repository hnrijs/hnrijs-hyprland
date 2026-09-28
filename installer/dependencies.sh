#!/usr/bin/env bash
set -euo pipefail
if command -v apt-get >/dev/null; then
    manager=apt
    packages=(alacritty aria2 bluez brightnessctl cliphist curl dbus desktop-file-utils fd-find ffmpeg fontconfig fzf gawk git gnome-keyring grim libgtk-3-0 gvfs gvfs-backends hypridle hyprland hyprlock hyprpicker hyprsunset imagemagick imv jq less libnotify-bin libpulse0 mpv network-manager neovim fonts-noto fonts-noto-color-emoji fonts-inter cava pipewire pipewire-alsa pipewire-pulse playerctl policykit-1 power-profiles-daemon python3 python3-dbus-next python3-qrcode python3-pil qt6-declarative-dev qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts qml6-module-qtquick-window qml6-module-qtquick-effects qt6-wayland quickshell ripgrep slurp speedtest-cli thunar thunar-volman thunar-archive-plugin file-roller tumbler udisks2 upower util-linux wget wireplumber wl-clipboard xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-user-dirs xdg-utils yt-dlp pavucontrol openssh-client smartmontools zip unzip p7zip-full  ffmpegthumbnailer fonts-dejavu fonts-font-awesome fonts-noto-cjk ncdu qalc ufw translate-shell tesseract-ocr tesseract-ocr-eng scrcpy adb iproute2 libreoffice-draw libimage-exiftool-perl )
    [[ ${1:-} == sddm ]] && packages+=(sddm xserver-xorg)
    sudo apt-get update
    exists(){ apt-cache show "$1" 2>/dev/null | grep -q '^Package:'; }
elif command -v dnf >/dev/null; then
    manager=dnf
    packages=(alacritty aria2 bluez brightnessctl cliphist curl dbus desktop-file-utils fd-find ffmpeg fontconfig fzf gawk git gnome-keyring grim gtk3 gvfs gvfs-mtp hypridle hyprland hyprlock hyprpicker hyprsunset ImageMagick imv jq less libnotify pulseaudio-utils mpv NetworkManager neovim google-noto-sans-fonts google-noto-color-emoji-fonts rsms-inter-fonts cava pipewire pipewire-alsa pipewire-pulseaudio playerctl polkit power-profiles-daemon python3 python3-dbus-next python3-qrcode python3-pillow qt6-qtdeclarative qt6-qtimageformats qt6-qtmultimedia qt6-qtwayland quickshell ripgrep slurp speedtest-cli Thunar thunar-volman thunar-archive-plugin file-roller tumbler udisks2 upower util-linux wget wireplumber wl-clipboard xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-user-dirs xdg-utils yt-dlp pavucontrol openssh-clients smartmontools zip unzip 7zip  ffmpegthumbnailer dejavu-sans-fonts fontawesome-fonts ncdu qalculate ufw translate-shell tesseract tesseract-langpack-eng scrcpy android-tools iproute libreoffice-draw perl-Image-ExifTool )
    [[ ${1:-} == sddm ]] && packages+=(sddm xorg-x11-server-Xorg)
    exists(){ dnf -q repoquery --available "$1" 2>/dev/null | grep -q .; }
else
    printf 'Supported package managers: pacman, apt-get, dnf. Use --config-only for manual dependencies.\n' >&2
    exit 1
fi
for package in hyprland quickshell; do
    binary=Hyprland
    [[ $package == quickshell ]] && binary=qs
    if ! command -v "$binary" >/dev/null && ! exists "$package"; then
        printf '%s is unavailable in enabled repositories. Install a compatible version first; no repositories will be added automatically.\n' "$package" >&2
        exit 1
    fi
done
available=()
missing=()
for package in "${packages[@]}"; do
    if exists "$package"; then available+=("$package");else missing+=("$package");fi
done
if ((${#missing[@]})); then printf 'Packages unavailable in enabled repositories:\n';printf '  %s\n' "${missing[@]}";fi
if [[ $manager == apt ]]; then sudo apt-get install "${available[@]}";else sudo dnf install "${available[@]}";fi
