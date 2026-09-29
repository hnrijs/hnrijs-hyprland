#!/usr/bin/env python3

import json
import os
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path.home() / "Pictures" / "Wallpapers"
STATE = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "hshell"
try:
    ROOT=Path(json.loads((STATE/'preferences.json').read_text()).get('wallpaperFolder',str(ROOT))).expanduser()
except (OSError,ValueError,TypeError): pass
EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif"}


def wallpapers():
    ROOT.mkdir(parents=True, exist_ok=True)
    return sorted((p for p in ROOT.rglob("*") if p.is_file() and p.suffix.lower() in EXTENSIONS),
                  key=lambda p: str(p.relative_to(ROOT)).casefold())


def check_path(raw):
    path = Path(raw).expanduser().absolute()
    
    if not path.parent.resolve().is_relative_to(ROOT.resolve()):
        raise ValueError("Choose an image inside the selected wallpaper folder")
    if not path.is_file() or path.suffix.lower() not in EXTENSIONS:
        raise ValueError("Wallpaper is missing or has an unsupported extension")
    return path


def ready():
    for _ in range(30):
        result = subprocess.run(["awww", "query"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if result.returncode == 0:
            return
        time.sleep(0.1)
    raise RuntimeError("awww-daemon is not ready; start it before selecting a wallpaper")


def sync_login(path):
    folder=Path('/var/lib/hshell/backgrounds')/str(os.getuid())
    if not folder.is_dir():return
    if folder.is_symlink() or folder.stat().st_uid!=os.getuid():
        raise ValueError('Run apply-update.py --sddm to repair SDDM wallpaper permissions')
    from PIL import Image
    import tempfile
    with Image.open(path) as image:
        image=image.convert('RGB')
        image.thumbnail((3840,2160))
        fd,name=tempfile.mkstemp(prefix='.wallpaper-',suffix='.png',dir=folder)
        try:
            with os.fdopen(fd,'wb') as stream:
                image.save(stream,format='PNG')
                stream.flush()
                os.fsync(stream.fileno())
                os.fchmod(stream.fileno(),0o644)
            os.replace(name,folder/'wallpaper.png')
        finally:
            Path(name).unlink(missing_ok=True)


def apply(path):
    ready()
    subprocess.run(["awww", "img", "--transition-type", "grow", "--transition-pos", "center", "--transition-duration", "0.45", "--transition-fps", str(refresh_rate()), str(path)], check=True)
    STATE.mkdir(parents=True, exist_ok=True)
    temporary = STATE / "current-wallpaper.tmp"
    temporary.write_text(str(path), encoding="utf-8")
    temporary.replace(STATE / "current-wallpaper")
    link=STATE/'wallpaper.png'
    link.unlink(missing_ok=True)
    link.symlink_to(path)
    try:sync_login(path)
    except (OSError,ValueError) as error:print("SDDM wallpaper: "+str(error),file=sys.stderr)


def refresh_rate():
    try:
        monitors=json.loads(subprocess.check_output(['hyprctl','-j','monitors'],text=True))
        return max(30,min(255,round(max(m.get('refreshRate',60) for m in monitors))))
    except (OSError,ValueError,subprocess.SubprocessError):return 60



def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "wallpapers"
    if command == "wallpapers":
        print(json.dumps([{"path": str(p), "name": p.name, "url": p.as_uri()} for p in wallpapers()]))
    elif command == "sync-login":
        path=STATE/'wallpaper.png'
        if path.is_file():sync_login(path)
    elif command == "current":
        try: print((STATE/"current-wallpaper").read_text().strip())
        except OSError: print("")
    elif command == "open-wallpapers":
        ROOT.mkdir(parents=True, exist_ok=True)
        subprocess.run(["xdg-open", str(ROOT)], check=True)
    elif command == "wallpaper" and len(sys.argv) == 3:
        apply(check_path(sys.argv[2]))
    elif command == "restore-wallpaper":
        try:
            selected = check_path((STATE / "current-wallpaper").read_text(encoding="utf-8"))
        except (OSError, ValueError):
            entries = wallpapers()
            selected = ROOT / "main.png" if (ROOT / "main.png").is_file() else (entries[0] if entries else None)
        if selected:
            apply(selected)
        else:
            ready()
            subprocess.run(["awww", "clear", "000000"], check=True)
    else:
        raise ValueError("Unknown wallpaper command")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
