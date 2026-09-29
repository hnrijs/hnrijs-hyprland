#!/usr/bin/env python3
import html
import hashlib
import io
import urllib.parse
import urllib.request
import json
import os
from pathlib import Path
import subprocess
import sys

def settings():
    try:return json.loads((Path(os.environ.get('XDG_STATE_HOME',str(Path.home()/'.local/state')))/'hshell/preferences.json').read_text()).get('options',{})
    except (OSError,ValueError):return {}

def battery():
    if not settings().get('lockBattery',True):return ''
    capacities=[]
    for p in Path('/sys/class/power_supply').glob('*'):
        try:
            if (p/'type').read_text().strip()!='Battery' or ((p/'scope').exists() and (p/'scope').read_text().strip()=='Device'):continue
            if (p/'present').exists() and (p/'present').read_text().strip()=='0':continue
            capacities.append(float((p/'capacity').read_text()))
        except (OSError,ValueError):pass
    return str(round(sum(capacities)/len(capacities)))+'%' if capacities else ''

def run(args):
    return subprocess.run(args,text=True,capture_output=True,timeout=2).stdout.strip()

def shell_state():
    try:return json.loads(run(['qs','-c','hshell','ipc','call','hshell','lockstate']))
    except (ValueError,OSError,subprocess.SubprocessError):return {}

def media_art():
    if not settings().get('lockMedia',False):return ''
    url=run(['playerctl','metadata','mpris:artUrl'])
    if not url:return ''
    parsed=urllib.parse.urlsplit(url)
    if parsed.username or parsed.password:return ''
    runtime=os.environ.get('XDG_RUNTIME_DIR')
    if not runtime:return ''
    directory=Path(runtime)/'hshell-lock-art'
    directory.mkdir(exist_ok=True,mode=0o700)
    if directory.is_symlink() or directory.stat().st_uid!=os.getuid():return ''
    os.chmod(directory,0o700)
    target=directory/(hashlib.sha256(url.encode()).hexdigest()+'.png')
    if target.is_file():return str(target)
    if parsed.scheme=='file':
        with Path(urllib.parse.unquote(parsed.path)).open('rb') as stream:data=stream.read(5000001)
    elif parsed.scheme=='https':
        with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'hshell-lock-art/9'}),timeout=3) as response:data=response.read(5000001)
    else:return ''
    if len(data)>5000000:return ''
    from PIL import Image,ImageOps
    with Image.open(io.BytesIO(data)) as image:
        if image.width*image.height>30000000:return ''
        image=ImageOps.fit(image.convert('RGB'),(360,360));image.save(target)
    for old in directory.glob('*.png'):
        if old!=target:old.unlink(missing_ok=True)
    return str(target)

def main():
    mode=sys.argv[1] if len(sys.argv)>1 else 'battery'
    if mode=='battery':print(battery())
    elif mode=='art':print(media_art())
    elif mode in ['previous','play-pause','next']:
        if settings().get('lockMedia',False):subprocess.run(['playerctl',mode],capture_output=True,timeout=2)
    elif mode.startswith('icon-'):
        if settings().get('lockMedia',False) and run(['playerctl','status']):print({'icon-previous':'󰒮','icon-next':'󰒭','icon-play-pause':'󰐎'}.get(mode,''))
    elif mode=='media':
        if settings().get('lockMedia',False):print(html.escape(run(['playerctl','metadata','--format','{{title}} · {{artist}}'])[:100]))
    elif mode=='indicators':
        options=settings();parts=[];state=shell_state() if any(options.get(k) for k in ['lockPower','lockDnd','lockNightlight','lockIdle']) else {}
        if options.get('lockBattery',True):parts.append(battery())
        if options.get('lockWifi',False):
            active=run(['nmcli','-t','-f','ACTIVE,SIGNAL','device','wifi']).splitlines()
            signal=next((int(line.split(':')[1]) for line in active if line.startswith('yes:')),0)
            parts.append('󰤨' if signal>=75 else '󰤥' if signal>=50 else '󰤢' if signal else '󰤭')
        if options.get('lockBluetooth',False):parts.append('󰂯' if 'Powered: yes' in run(['bluetoothctl','show']) else '󰂲')
        if options.get('lockPower',False):parts.append({'power-saver':'󰌪','balanced':'󰾅','performance':'󱐋'}.get(state.get('power'),''))
        if options.get('lockDnd',False) and state.get('dnd'):parts.append('󰂛')
        if options.get('lockNightlight',False) and state.get('nightlight'):parts.append('󰖔')
        if options.get('lockIdle',False):parts.append('󰅶' if state.get('awake') else '󰒲')
        print('  '.join(p for p in parts if p))
    elif mode=='notifications':
        if settings().get('lockNotifications',False):print(html.escape('\n'.join(shell_state().get('notifications',[])[:3])))
    elif mode=='weather':
        if settings().get('lockWeather',False):
            state=Path(os.environ.get('XDG_STATE_HOME',str(Path.home()/'.local/state')))/'hshell'
            files=sorted((state/'Weather').glob('*.json'),key=lambda p:p.stat().st_mtime,reverse=True)
            if files:
                data=json.loads(files[0].read_text());print(html.escape(str(data.get('city',''))+' · '+str(data.get('temperature',''))+' °C · '+str(data.get('description',''))))
    elif mode=='wifi':
        if settings().get('lockWifi',False):
            p=subprocess.run(['nmcli','-t','-f','STATE','general'],text=True,capture_output=True,timeout=3)
            print('󰤨' if p.stdout.strip()=='connected' else '󰤭')
    elif mode=='prepare':
        for key,target in [('lockMuteAudio','sink'),('lockMuteMic','source')]:
            if settings().get(key,False):subprocess.run(['pactl','set-'+target+'-mute','@DEFAULT_'+target.upper()+'@','1'],capture_output=True,timeout=2)
if __name__=='__main__':
    try:main()
    except (OSError,ValueError,subprocess.SubprocessError):pass
