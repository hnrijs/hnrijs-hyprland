import json
import os
from pathlib import Path
import re
try:
    settings=json.loads((Path(os.environ.get('XDG_STATE_HOME') or str(Path.home()/'.local/state'))/'hshell/preferences.json').read_text())
except (OSError,ValueError):
    settings={}
print('[General]')
print('Background=/var/lib/hshell/backgrounds/'+str(os.getuid())+'/wallpaper.png')
for key,name in [('foregroundColor','Foreground'),('accentColor','Accent')]:
    value=settings.get(key,'#ffffff')
    if not isinstance(value,str) or not re.fullmatch(r'#[0-9a-fA-F]{6}',value):value='#ffffff'
    print(name+'='+value)
