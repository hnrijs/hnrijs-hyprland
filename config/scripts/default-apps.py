#!/usr/bin/env python3
import json,subprocess,shutil,time
from pathlib import Path
from app_defaults import CONFIG,DATA,FILE,GROUPS,desktop_quote

def main():
    directory=DATA/'applications';directory.mkdir(parents=True,exist_ok=True)
    
    launcher='[Desktop Entry]\nType=Application\nName=Neovim\nExec=python3 '+desktop_quote(Path(__file__).with_name('open-default.py'))+' nvim %F\nTerminal=false\nIcon=nvim\nCategories=Utility;TextEditor;\nMimeType=text/plain;text/x-python;application/json;application/x-shellscript;\n'
    for name in ['hshell-nvim.desktop','nvim.desktop']:
        path=directory/name
        if path.exists():
            old=path.read_text()
            if name=='nvim.desktop' and not ('Exec=alacritty -e nvim -- %F' in old or '/scripts/open-default.py' in old):continue
            backup=CONFIG/'applications/backups'/time.strftime('%Y%m%d-%H%M%S')/name;backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,backup)
        if path.is_symlink():path.unlink()
        path.write_text(launcher+('NoDisplay=true\n' if name.startswith('hshell-') else ''))
    values=json.loads(FILE.read_text());values['text']='nvim.desktop'
    current=subprocess.run(['xdg-settings','get','default-web-browser'],capture_output=True,text=True).stdout.strip()
    roots=[directory,Path('/usr/share/applications'),Path('/usr/local/share/applications')]
    if not values.get('browser') or not any((base/values['browser']).is_file() for base in roots):
        values['browser']=current if current.endswith('.desktop') and '/' not in current and any((base/current).is_file() for base in roots) else ''
    FILE.write_text(json.dumps(values,indent=2))
    for role,mimes in GROUPS.items():
        name=values.get(role, 'libreoffice-draw.desktop' if role=='pdf' else '')
        if role=="browser" and not name:continue
        if not isinstance(name,str) or not name.endswith('.desktop') or '/' in name or name.startswith('-'):raise ValueError('Invalid desktop entry')
        if not any((p/name).is_file() for p in [directory,Path('/usr/share/applications'),Path('/usr/local/share/applications')]):print('Default app is not installed: '+name);continue
        subprocess.run(['xdg-mime','default',name,*mimes],check=True)
    subprocess.run(['update-desktop-database',str(directory)],check=True)
if __name__=='__main__':main()
