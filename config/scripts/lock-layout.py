#!/usr/bin/env python3
import json
import os
from pathlib import Path
import re
import shlex

CONFIG=Path(os.environ.get('XDG_CONFIG_HOME',str(Path.home()/'.config')))
STATE=Path(os.environ.get('XDG_STATE_HOME',str(Path.home()/'.local/state')))/'hshell'
RUNTIME=Path(os.environ.get('XDG_RUNTIME_DIR') or '/run/user/'+str(os.getuid()))
def generate():
    try:preferences=json.loads((STATE/'preferences.json').read_text())
    except (OSError,ValueError):preferences={}
    options=preferences.get('options',{})
    source=(CONFIG/'hypr/hyprlock.conf').read_text()
    source=re.sub(r'^label\s*\{.*?^\}',lambda match:'' if 'lock-status.py' in match.group(0) else match.group(0),source,flags=re.M|re.S)
    source=source.replace('$HOME/.local/state/hshell',str(STATE))
    font=options.get('fontFamily','Inter')
    if re.fullmatch(r'[A-Za-z0-9 _-]{1,80}',font):source=source.replace('font_family = Inter','font_family = '+font)
    for key,old in [('foregroundColor','ffffffff'),('backgroundColor','080808ff')]:
        value=preferences.get(key,'')
        if re.fullmatch(r'#[0-9a-fA-F]{6}',value):source=source.replace('rgba('+old+')','rgba('+value[1:]+'ff)')
    accent=preferences.get('accentColor','#ffffff')
    if not re.fullmatch(r'#[0-9a-fA-F]{6}',accent):accent='#ffffff'
    source=re.sub(r'(^\s*outer_color\s*=).*$',r'\1 rgba('+accent[1:]+'ff)',source,flags=re.M)
    source=re.sub(r'(^\s*inner_color\s*=).*$',r'\1 rgba(00000000)',source,flags=re.M)
    target=RUNTIME/('hshell-lock-'+str(os.getuid())+'.conf')
    fd=os.open(target,os.O_WRONLY|os.O_CREAT|os.O_TRUNC|os.O_NOFOLLOW,0o600)
    with os.fdopen(fd,'w') as stream:stream.write(source)
    print(target)
if __name__=='__main__':generate()
