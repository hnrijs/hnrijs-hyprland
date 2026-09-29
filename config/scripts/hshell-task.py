#!/usr/bin/env python3

import ipaddress
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import urllib.parse
import urllib.request

_state_home = Path(os.environ.get('XDG_STATE_HOME') or str(Path.home()/'.local/state'))
STATE = (_state_home if _state_home.is_absolute() else Path.home()/'.local/state') / 'hshell'
SCRIPTS = Path(__file__).resolve().parent
PREFS = STATE/'preferences.json'
BOOL_PREFS = ['visualizer','hoverExpand','mediaCard','tray','notifications','weather','hideFullscreen','workspaceOsd','volumeOsd','showPower','showMic','showCapsLock','showIdle','showNightlight','showBluetooth','showWifi']


def emit(kind, data):
    print(json.dumps({'type': kind, 'data': data}, ensure_ascii=False), flush=True)


def prefs():
    try:
        value=json.loads(PREFS.read_text())
        if not isinstance(value,dict): value={}
    except (OSError, ValueError): value={}
    defaults=json.loads((SCRIPTS/'v9-defaults.json').read_text())
    saved=value.get('options',{})
    if not isinstance(saved,dict): saved={}
    for key,item in saved.items():
        if key not in defaults: continue
        if isinstance(item,dict) and isinstance(defaults.get(key),dict):
            defaults[key].update({k:v for k,v in item.items() if k in defaults[key]})
        else: defaults[key]=item
    defaults['minimalVersion']=1
    for key in BOOL_PREFS:
        value[key]=key not in ['showCapsLock','visualizer']
    value['options']=defaults
    return value


def save_pref(key, value):
    if key=='options':
        data=json.loads(value)
        if not isinstance(data,dict) or len(value)>200000: raise ValueError('Invalid settings')
        for key in ['nightlightStart','nightlightEnd','dndStart','dndEnd','shutdownTime','rebootTime']:
            if key in data and not re.fullmatch(r'(?:[01][0-9]|2[0-3]):[0-5][0-9]',str(data[key])):raise ValueError('Use HH:MM for '+key)
        if data.get('autoshutdown') and data.get('autoreboot') and data.get('shutdownTime')==data.get('rebootTime'):raise ValueError('Shutdown and restart need different times')
        limits={'pillWidth':(100,600),'pillHeight':(32,100),'pillExpandedWidth':(540,1200),'pillExpandedHeight':(86,240),'pillTopGap':(0,100),'pillRadius':(0,100),'capsGap':(0,40),'cavaGap':(0,40)}
        for name,(minimum,maximum) in limits.items():
            if name in data and not minimum<=float(data[name])<=maximum:raise ValueError(name+' must be '+str(minimum)+'–'+str(maximum))
        if 'fontSize' in data and not 8<=float(data['fontSize'])<=72:raise ValueError('Font size must be 8–72')
        for key in ['breakEvery','breakMinutes']:
            if key in data and not 1<=float(data[key])<=1440:raise ValueError('Use 1–1440 minutes')
        if 'batteryThresholds' in data:
            if not isinstance(data['batteryThresholds'],list) or any(type(v) not in [int,float] or not 1<=v<=99 for v in data['batteryThresholds']):raise ValueError('Battery thresholds must be 1–99 percent')
            data['batteryThresholds']=sorted(set(map(int,data['batteryThresholds'])),reverse=True)
        allowed=json.loads((SCRIPTS/'v9-defaults.json').read_text())
        data={k:v for k,v in data.items() if k in allowed}
        for key in ['serverFolder','isoFolder','downloadFolder','screenshotFolder']:
            if key in data:
                folder=Path(data[key]).expanduser()
                if not folder.is_absolute(): raise ValueError('Use an absolute folder path')
                folder.mkdir(parents=True,exist_ok=True)
                data[key]=str(folder)
        return write_preferences({'options':data})
    if key not in BOOL_PREFS + ['cities','city','notificationSeconds','wallpaperFolder','backgroundColor','surfaceColor','foregroundColor','accentColor']: raise ValueError('Unknown preference')
    if key in BOOL_PREFS and value not in ['true', 'false']: raise ValueError('Expected true or false')
    if key == 'city' and (not value.strip() or len(value) > 120): raise ValueError('Invalid city')
    if key == 'notificationSeconds' and not 0.1 <= float(value) <= 10: raise ValueError('Duration must be 0.1–10 seconds')
    if key.endswith('Color') and not re.fullmatch(r'#[0-9a-fA-F]{6}',value): raise ValueError('Use a six-digit hex color')
    if key == 'wallpaperFolder':
        value=str(Path(value).expanduser())
        if not Path(value).is_absolute(): raise ValueError('Use an absolute folder path')
        Path(value).mkdir(parents=True,exist_ok=True)
    if key == 'cities':
        value=json.loads(value)
        if not isinstance(value,list) or not 1<=len(value)<=8 or any(not isinstance(c,str) or not c.strip() or len(c)>120 for c in value): raise ValueError('Choose 1–8 cities')
        value=list(dict.fromkeys(c.strip() for c in value))
    return write_preferences({key:value})


def write_preferences(updates):
    import fcntl
    STATE.mkdir(parents=True, exist_ok=True)
    with (STATE/'preferences.lock').open('a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        data=prefs(); data.update(updates)
        tmp=PREFS.with_suffix('.tmp')
        with tmp.open('w') as stream:
            json.dump(data,stream);stream.flush();os.fsync(stream.fileno())
        tmp.replace(PREFS)
    return data


def web_json(url):
    req=urllib.request.Request(url, headers={'User-Agent':'hshell/2.0'})
    with urllib.request.urlopen(req, timeout=20) as response:
        return json.loads(response.read(2_000_000))


def checked_url(value, magnet=False):
    scheme=urllib.parse.urlsplit(value).scheme.lower()
    if scheme not in (['magnet'] if magnet else ['http','https']):
        raise ValueError('Enter a valid '+('magnet' if magnet else 'HTTP(S)')+' URL')
    return value


def path_arg(value):
    if value.startswith('file://'):
        value=urllib.parse.unquote(urllib.parse.urlsplit(value).path)
    path=Path(value).expanduser().absolute()
    if not path.is_file(): raise ValueError('Choose an existing file')
    return path


def run_job(command, label):
    if not shutil.which(command[0]): raise RuntimeError('Required program is missing: '+command[0])
    emit('progress', {'message':label})
    process=subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, errors='replace', start_new_session=True)
    
    import signal
    def stop(signum, frame):
        os.killpg(process.pid,signal.SIGTERM)
        try: process.wait(timeout=5)
        except subprocess.TimeoutExpired: os.killpg(process.pid,signal.SIGKILL)
        raise SystemExit(130)
    signal.signal(signal.SIGTERM, stop)
    last=0
    for line in process.stdout:
        if time.monotonic()-last<0.2:continue
        last=time.monotonic();progress={'message':line.strip()[-500:]}
        match=re.search(r'(\d+(?:\.\d+)?)%',line)
        if match:progress['percent']=min(100,float(match[1]))
        emit('progress',progress)
    code=process.wait()
    if code: raise RuntimeError(f'{command[0]} exited with code {code}')
    return {'message':label+' completed'}


def download(mode, raw_url, destination, playlist='false'):
    url=str(path_arg(raw_url)) if mode=='torrent' else checked_url(raw_url, mode=='magnet')
    if mode=='torrent' and Path(url).suffix.lower()!='.torrent':raise ValueError('Choose a .torrent file')
    folder=Path(destination or str(Path.home()/'Downloads')).expanduser().absolute()
    folder.mkdir(parents=True, exist_ok=True)
    stamp=time.strftime('%Y%m%d-%H%M%S')
    commands={
        'mp3':['yt-dlp','--newline','--no-overwrites','-P',str(folder),'-x','--audio-format','mp3'],
        'mp4':['yt-dlp','--newline','--no-overwrites','-P',str(folder),'-S','ext:mp4:m4a','--merge-output-format','mp4'],
        'file':['wget','--no-clobber','--directory-prefix',str(folder),'--content-disposition'],
        'magnet':['aria2c','--summary-interval=1','--enable-color=false','--seed-time=0','--allow-overwrite=false','--dir',str(folder)],
        'html':['monolith','-o',str(folder/f'page-{stamp}.html')],
        'git':['git','clone',url,str(folder/f'repository-{stamp}')],
    }
    commands['torrent']=commands['magnet'][:]
    if mode not in commands: raise ValueError('Unknown download type')
    command=commands[mode]
    if mode in ['mp3','mp4']: command += ['--yes-playlist' if playlist=='true' else '--no-playlist']
    if mode!='git': command += ['--',url]
    return dict(run_job(command, 'Download'),source=url,folder=str(folder),format=mode)


def media(mode, raw_file, parameter=''):
    source=path_arg(raw_file)
    stamp=time.strftime('%Y%m%d-%H%M%S')
    output=source.with_name(source.stem+'-'+mode+'-'+stamp+source.suffix)
    command=['ffmpeg','-hide_banner','-nostdin','-n','-i',str(source)]
    if mode=='silent': command+=['-c','copy','-an']
    elif mode=='rotate': command+=['-vf','transpose=1']
    elif mode=='mirror': command+=['-vf','hflip']
    elif mode=='mp3': output=output.with_suffix('.mp3'); command+=['-vn']
    elif mode=='resize':
        size=re.fullmatch(r'\s*([1-9][0-9]{0,4})(?:\s*[xX×]\s*([1-9][0-9]{0,4}))?\s*',parameter)
        if not size: raise ValueError('Enter a width or width × height, e.g. 1280 or 1080x1080')
        width=int(size[1]);height=int(size[2]) if size[2] else -2
        if any(value != -2 and (value < 2 or value > 16384 or value % 2) for value in [width,height]):
            raise ValueError('Use even dimensions from 2 to 16384 pixels')
        output=output.with_suffix('.mp4')
        resize=f'scale={width}:{height}' + (',setsar=1' if height != -2 else '')
        command+=['-vf',resize]
    elif mode=='trim':
        times=parameter.split()
        if len(times)!=2 or not all(re.fullmatch(r'\d{2}:\d{2}:\d{2}',v) for v in times): raise ValueError('Enter start and duration: 00:00:10 00:00:30')
        command+=['-ss',times[0],'-t',times[1],'-c','copy']
    elif mode=='png':
        output=output.with_suffix('.png'); command=['magick',str(source)]
    else: raise ValueError('Unknown media operation')
    result=run_job(command+[str(output)],'Media job');result['path']=str(output);return result


def exif(mode, raw_file, offset=""):
    source=path_arg(raw_file)
    if mode=='view':
        data=subprocess.check_output(['exiftool','-j',str(source)],text=True)
        return {'text':json.dumps(json.loads(data),ensure_ascii=False,indent=2)}
    if mode not in ['remove','timezone']: raise ValueError('Unknown EXIF action')
    if mode=='timezone':
        if not re.fullmatch(r'[+-](?:0[0-9]|1[0-4]):[0-5][0-9]',offset) or offset[1:3]=='14' and offset[4:]!='00':raise ValueError('Use a UTC offset between -14:00 and +14:00')
    import uuid
    output=source.with_name(source.stem+('-clean-' if mode=='remove' else '-timezone-')+uuid.uuid4().hex[:8]+source.suffix)
    shutil.copy2(source, output)
    try:
        tags=['-all='] if mode=='remove' else ['-OffsetTime='+offset,'-OffsetTimeOriginal='+offset,'-OffsetTimeDigitized='+offset]
        subprocess.run(['exiftool',*tags,'-overwrite_original',str(output)],check=True,capture_output=True,text=True)
    except Exception:
        output.unlink(missing_ok=True)
        raise
    return {'path':str(output),'message':'Clean copy saved' if mode=='remove' else 'Timezone offset copy saved; other location metadata is unchanged'}


def disks():
    data=json.loads(subprocess.check_output(['lsblk','--json','--bytes','--paths','-o','NAME,LABEL,FSTYPE,SIZE,MOUNTPOINT,TYPE,MODEL'],text=True))
    rows=[]
    def visit(item):
        if item.get('fstype') or item.get('type')=='disk':
            row={k:item.get(k) for k in ['name','label','fstype','size','mountpoint','type','model']}
            if item.get('mountpoint'):
                try:
                    usage=shutil.disk_usage(item['mountpoint']);row.update(total=usage.total,used=usage.used,free=usage.free)
                except OSError: pass
            rows.append(row)
        for child in item.get('children',[]):visit(child)
    for device in data['blockdevices']:visit(device)
    return {'disks':rows}


def speed():
    import speedtest
    emit('progress',{'phase':'Connecting','download':0,'upload':0,'ping':0})
    client=speedtest.Speedtest(secure=True)
    client.get_servers();server=client.get_best_server()
    ping=client.results.ping
    emit('progress',{'phase':'Download','download':0,'upload':0,'ping':ping})
    down=client.download()/1e6
    emit('progress',{'phase':'Upload','download':down,'upload':0,'ping':ping})
    up=client.upload()/1e6
    return {'phase':'Complete','download':down,'upload':up,'ping':ping,'server':server.get('sponsor','')}


def overview(action, *args):
    if action=='windows':
        return {'windows':json.loads(subprocess.check_output(['hyprctl','-j','clients'],text=True))}
    if action=='workspace':
        ws=int(args[0]);assert 1<=ws<=10
        expr=f'hl.dispatch(hl.dsp.focus({{workspace={ws}}}))'
    else:
        address=args[0]
        if not re.fullmatch(r'0x[0-9a-fA-F]+',address):raise ValueError('Invalid window address')
        if action=='move-window':
            ws=int(args[1]);assert 1<=ws<=10
            expr=f'hl.dispatch(hl.dsp.window.move({{workspace={ws},window="address:{address}"}}))'
        elif action=='focus-window':expr=f'hl.dispatch(hl.dsp.focus({{window="address:{address}"}}))'
        else:raise ValueError('Unknown window action')
    subprocess.run(['hyprctl','eval',expr],check=True,stdout=subprocess.DEVNULL)
    return {'message':'Done'}


def main(action, *args):
    modules={'wifi-connect':'wifi-connect.py','overview':'overview.py','utilities':'utility-tools.py','local-server':'local-server.py','iso-flash':'iso-flash.py'}
    if action in modules:
        import importlib.util
        spec=importlib.util.spec_from_file_location('hshell_tool',SCRIPTS/modules[action])
        module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        return module.main(*args)
    if action in ['network-settings','system-settings','app-defaults','calculate']:
        name={'network-settings':'network-settings.py','system-settings':'system-settings.py','calculate':'calculator.py','app-defaults':'app_defaults.py'}[action]
        code=subprocess.call([sys.executable,str(SCRIPTS/name),*args])
        raise SystemExit(code)
    if action=='exif':return exif(*args)
    if action=='power-profiles':
        output=subprocess.check_output(['powerprofilesctl','list'],text=True)
        return {'profiles':[p for p in ['power-saver','balanced','performance'] if re.search(r'^\s*\*?\s*'+p+r':',output,re.M)]}
    if action=='preferences':return prefs()
    if action=='colors-reset':
        return write_preferences(dict(backgroundColor='#080808',surfaceColor='#202020',foregroundColor='#ffffff',accentColor='#ffffff'))
    if action=='clock':
        import importlib.util
        spec=importlib.util.spec_from_file_location('clock_state',SCRIPTS/'clock-state.py')
        module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        return module.snapshot()
    if action=='qr':
        import importlib.util
        spec=importlib.util.spec_from_file_location('qr_code',SCRIPTS/'qr-code.py')
        module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        return module.main(*args)
    if action=='preference':return save_pref(*args)
    if action=='weather':
        import hashlib
        city=(args[0] if args else 'Riga').strip() or 'Riga'
        cache=STATE/'Weather'/(hashlib.sha256(city.lower().encode()).hexdigest()+'.json')
        try:
            stored=json.loads(cache.read_text())
            if time.time()-stored['fetched']<1800:return stored
        except (OSError,ValueError,KeyError):pass
        data=web_json('https://wttr.in/'+urllib.parse.quote(city,safe='')+'?format=j1')
        now=data['current_condition'][0]
        result={'city':city,'temperature':now['temp_C'],'feels':now['FeelsLikeC'],'humidity':now['humidity'],'wind':now['windspeedKmph'],'description':now['weatherDesc'][0]['value'],'fetched':time.time(),'forecast':[]}
        for day in data.get('weather',[])[:3]:
            result['forecast'].append({'date':day['date'],'min':day['mintempC'],'max':day['maxtempC'],'sunrise':day.get('astronomy',[{}])[0].get('sunrise',''),'sunset':day.get('astronomy',[{}])[0].get('sunset',''),'hours':[{'time':str(h.get('time','0')).zfill(4)[:2]+':00','temperature':h.get('tempC',''),'rain':h.get('chanceofrain',''),'wind':h.get('windspeedKmph',''),'description':h.get('weatherDesc',[{}])[0].get('value','')} for h in day.get('hourly',[])]})
        cache.parent.mkdir(parents=True,exist_ok=True)
        temp=cache.with_suffix('.tmp');temp.write_text(json.dumps(result));temp.replace(cache)
        return result
    if action=='pick-color':
        time.sleep(0.3) 
        proc=subprocess.run(['hyprpicker','--format=hex'],capture_output=True,text=True)
        color=proc.stdout.strip()
        if not color:return {'message':'Selection cancelled'}
        if not re.fullmatch(r'#[0-9a-fA-F]{6}',color):raise ValueError('Picker returned an invalid color')
        subprocess.run(['wl-copy','--',color],check=True)
        return {'color':color.upper()}
    if action=='ip':
        target=args[0].strip() if args else ''
        if target:ipaddress.ip_address(target)
        data=web_json('https://ipwho.is/'+urllib.parse.quote(target,safe=''))
        if data.get('success') is False:raise ValueError(data.get('message','Lookup failed'))
        return {'ip':data.get('ip'),'city':data.get('city'),'region':data.get('region'),'country':data.get('country'),'isp':data.get('connection',{}).get('isp'),'timezone':data.get('timezone',{}).get('id'),'latitude':data.get('latitude'),'longitude':data.get('longitude')}
    if action=='disks':return disks()
    if action in ['mount','unmount']:
        if not re.fullmatch(r'/dev/[A-Za-z0-9_./-]+',args[0]):raise ValueError('Invalid block device')
        run_job(['udisksctl',action,'-b',args[0]],'Disk '+action);return disks()
    if action=='speed':return speed()
    if action=='download':return download(*args)
    if action=='media-edit':
        import runpy
        command, output = runpy.run_path(str(Path(__file__).with_name('media-edit.py')))['command'](path_arg(args[0]), json.loads(args[1]))
        result = run_job(command, 'Media job'); result['path'] = str(output); return result
    if action=='media':return media(*args)
    if action in ['windows','workspace','move-window','focus-window']:return overview(action,*args)
    if action=='clipboard-clear':
        subprocess.run(['cliphist','wipe'],check=True)
        subprocess.run(['wl-copy','--clear'],check=True)
        cache=Path(os.environ['XDG_RUNTIME_DIR'])/'hshell-clipboard'
        if cache.is_dir() and not cache.is_symlink(): shutil.rmtree(cache)
        return {'message':'Clipboard history cleared'}
    if action=='caffeine':
        runtime=Path(os.environ['XDG_RUNTIME_DIR'])/'hshell-caffeine'
        if args and args[0]=='toggle':
            if runtime.exists():runtime.unlink()
            else:runtime.touch()
        elif args and args[0]=='on':runtime.touch()
        elif args and args[0]=='off':runtime.unlink(missing_ok=True)
        return {'enabled':runtime.exists()}
    raise ValueError('Unknown task')

if __name__=='__main__':
    try:emit('result',main(*sys.argv[1:]))
    except Exception as error:
        emit('error',str(error))
        sys.exit(1)
