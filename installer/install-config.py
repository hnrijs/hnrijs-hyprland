#!/usr/bin/env python3

import argparse
from datetime import datetime
from pathlib import Path
import shutil


def deploy(source, home, config, state, no_backups=False):
    stamp = datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup = state / 'hshell' / 'backups' / stamp
    copied = []
    def copy_file(src, dst, label):
        if dst.exists() or dst.is_symlink():
            old = backup / label
            if not no_backups:
                old.parent.mkdir(parents=True, exist_ok=True)
            if dst.is_dir():
                raise RuntimeError(f'Expected a file, found directory: {dst}')
            if not no_backups:
                shutil.copy2(dst, old, follow_symlinks=False)
            
            if dst.is_symlink():
                dst.unlink()
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        copied.append(dst)
    for folder in ['Desktop', 'Documents', 'Music', 'Downloads', 'Pictures/Wallpapers', 'Pictures/Screenshots', 'Videos', 'Server', 'Iso']:
        (home / folder).mkdir(parents=True, exist_ok=True)
    
    old_entry = config / 'quickshell' / 'shell.qml'
    if old_entry.exists():
        saved = backup / 'config/quickshell/shell.qml'
        if no_backups:
            if old_entry.is_dir() and not old_entry.is_symlink():
                shutil.rmtree(old_entry)
            else:
                old_entry.unlink()
        else:
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(old_entry), saved)
    old_shell = config / 'quickshell/hshell'
    if old_shell.exists() or old_shell.is_symlink():
        saved = backup / 'config/quickshell/hshell'
        if no_backups:
            if old_shell.is_dir() and not old_shell.is_symlink():
                shutil.rmtree(old_shell)
            else:
                old_shell.unlink()
        else:
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(old_shell), saved)
    for name in ['game-mode.py', 'pgp-tool.py', 'lock-widgets.py', 'snapshots.py', 'apply-gtk-theme.py', 'wifi-secrets.py', 'v9-data.py', 'system-files.py']:
        obsolete = config / 'scripts' / name
        if obsolete.exists() or obsolete.is_symlink():
            saved = backup / 'config/scripts' / name
            if no_backups:
                if obsolete.is_dir() and not obsolete.is_symlink():
                    shutil.rmtree(obsolete)
                else:
                    obsolete.unlink()
            else:
                saved.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(obsolete), saved)
    incoming = source / 'config' 
    for item in sorted(incoming.rglob('*')):
        if item.is_file():
            relative = item.relative_to(incoming)
            if "__pycache__" in relative.parts or item.suffix == ".pyc": continue
            if relative.parts[0] == 'quickshell' and relative.parts[1] != 'hshell':
                continue
            if relative == Path('applications/defaults.json') and (config / relative).exists(): continue
            if relative in [Path('hypr/hyprland/devices.lua'),Path('hypr/hyprland/input.lua')] and (config/relative).is_file():
                target=config/relative;old=target.read_text();updated=old
                for section in ['monitors','input']:
                    for edge in ['begin','end']:updated=updated.replace('-- hshell '+section+' '+edge,'_hshell_'+section+'_'+edge+' = true')
                if updated!=old:
                    if not no_backups:
                        saved=backup/'config'/relative;saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(target,saved)
                    target.write_text(updated)
                continue
            copy_file(item, config / relative, Path('config') / relative)
    main = source / 'main.png'
    if main.is_file():
        copy_file(main, home / 'Pictures/Wallpapers/main.png', Path('wallpapers/main.png'))
    walls = source / 'Wallpapers'
    if walls.is_dir():
        for item in sorted(walls.rglob('*')):
            if item.is_file():
                relative = item.relative_to(walls)
                copy_file(item, home / 'Pictures/Wallpapers' / relative, Path('wallpapers') / relative)
    for item in (config / 'scripts').glob('*'):
        if item.is_file() and item.suffix in {'.sh', '.py'}:
            item.chmod(item.stat().st_mode | 0o111)
    print(f'Installed {len(copied)} files into {config}')
    if backup.exists():
        print(f'Backups: {backup}')
    return copied, backup


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--home', type=Path, required=True)
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--state', type=Path, required=True)
    parser.add_argument("--no-backups", action="store_true")
    args = parser.parse_args()
    deploy(args.source, args.home, args.config, args.state, args.no_backups)
