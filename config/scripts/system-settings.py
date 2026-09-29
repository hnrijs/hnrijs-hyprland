#!/usr/bin/env python3
import fcntl,json,math,os,pwd,re,subprocess,sys,time,uuid
from pathlib import Path
CONFIG=Path(os.environ.get('XDG_CONFIG_HOME',str(Path.home()/'.config')))/'hypr/hyprland'
STATE=Path(os.environ.get('XDG_STATE_HOME',str(Path.home()/'.local/state')))/'hshell'
PENDING=STATE/'monitor-pending.json'
def run(args):return subprocess.check_output(args,text=True,stderr=subprocess.PIPE).strip()
def atomic(path,text):
    path.parent.mkdir(parents=True,exist_ok=True)
    tmp=path.with_suffix('.tmp');tmp.write_text(text);tmp.replace(path)
def lua(v):
    if isinstance(v,bool):return 'true' if v else 'false'
    if isinstance(v,(float,int)):
        if not math.isfinite(v):raise ValueError('Invalid number')
        return str(v)
    if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
    return '{ '+', '.join(k+' = '+lua(x) for k,x in v.items())+' }'
def number(value,low,high):
    value=float(value)
    if not math.isfinite(value) or not low<=value<=high:raise ValueError(f'Value must be {low}–{high}')
    return value

def replace_block(path,name,body):
    start='_hshell_'+name+'_begin = true';end='_hshell_'+name+'_end = true'
    original=path.read_text()
    for edge in ['begin','end']:
        original=original.replace('-- hshell '+name+' '+edge,'_hshell_'+name+'_'+edge+' = true')
    if start not in original or end not in original:raise ValueError('Managed section is missing from '+str(path))
    text=original[:original.index(start)]+start+'\n'+body+'\n'+original[original.index(end):]
    atomic(path.with_suffix('.lua.bak'),original)
    atomic(path,text)
    return original

def option(key,default):
    try:
        data=json.loads(run(['hyprctl','-j','getoption',key]))
        for k in ['str','float','int']:
            if k in data:return data[k]
    except (ValueError,subprocess.CalledProcessError):pass
    return default

def input_status():
    return dict(sensitivity=option('input:sensitivity',0),accel=option('input:accel_profile','flat'),layouts=option('input:kb_layout','lv'),variants=option('input:kb_variant',''),options=option('input:kb_options',''),natural=bool(option('input:touchpad:natural_scroll',0)),follow=int(option('input:follow_mouse',1)))

def save_input(data):
    layouts=str(data.get('layouts','lv')).replace(' ','').split(',')
    if not 1<=len(layouts)<=4 or any(not re.fullmatch('[a-zA-Z0-9_-]{1,24}',x) for x in layouts):raise ValueError('Choose 1–4 XKB layouts, for example lv,us,de')
    database=Path('/usr/share/X11/xkb/rules/evdev.xml')
    if database.is_file():
        import xml.etree.ElementTree as ET
        available={e.text for e in ET.parse(database).findall('./layoutList/layout/configItem/name')}
        if any(x not in available for x in layouts):raise ValueError('Unknown keyboard layout')
    variants=str(data.get('variants',''));options=str(data.get('options',''))
    if not re.fullmatch(r'[a-zA-Z0-9_+,;:.-]{0,240}',variants+options):raise ValueError('Invalid XKB options')
    accel=data.get('accel','flat')
    if accel not in ['flat','adaptive']:raise ValueError('Choose Flat or Adaptive acceleration')
    sensitivity=number(data.get('sensitivity',0),-1,1)
    follow=int(number(data.get('follow',1),0,3))
    config=dict(kb_layout=','.join(layouts),kb_variant=variants,kb_options=options,follow_mouse=follow,sensitivity=sensitivity,accel_profile=accel,touchpad={'natural_scroll':bool(data.get('natural',False))})
    replace_block(CONFIG/'input.lua','input','hl.config('+lua({'input':config})+')')
    run(['hyprctl','reload'])
    return input_status()

def monitor_status():
    monitors=json.loads(run(['hyprctl','-j','monitors','all']))
    source=(CONFIG/'devices.lua').read_text()
    workspaces={m.group(2):m.group(1) for m in re.finditer(r'workspace\s*=\s*"([0-9]+)"\s*,\s*monitor\s*=\s*"([^"]+)"',source)}
    for m in monitors:
        m['workspace']=workspaces.get(m['name'],str(m.get('activeWorkspace',{}).get('id',1)))
    return {'monitors':monitors,'vrr':int(option('misc:vrr',0)),'pending':PENDING.exists()}

def apply_monitor(data):
    if PENDING.exists():raise ValueError('Keep or revert the previous display change first')
    monitors=monitor_status()['monitors'];target=next((x for x in monitors if x['name']==data['name']),None)
    if not target:raise ValueError('Display is no longer connected')
    mode=str(data['mode'])
    if mode!='preferred' and not re.fullmatch(r'[0-9]{3,5}x[0-9]{3,5}(@[0-9]{1,4}(\.[0-9]+)?(Hz)?)?',mode):raise ValueError('Use widthxheight@Hz')
    position=str(data['position'])
    if position!='auto' and not re.fullmatch(r'-?[0-9]{1,6}x-?[0-9]{1,6}',position):raise ValueError('Use XxY, for example 1080x0')
    scale=number(data['scale'],0.5,4);transform=int(number(data['transform'],0,7));workspace=int(number(data['workspace'],1,100));vrr=int(number(data.get('vrr',0),0,2))
    path=CONFIG/'devices.lua';old=path.read_text()
    line='hl.monitor('+lua(dict(output=target['name'],mode=mode.replace('Hz',''),position=position,scale=scale,transform=transform))+')'
    pattern=r'hl\.monitor\(\s*\{[^{}]*output\s*=\s*'+re.escape(json.dumps(target['name']))+r'[^{}]*\}\s*\)'
    text,n=re.subn(pattern,lambda _:line,old)
    if not n:text+='\n'+line+'\n'
    for output,coordinates in data.get('positions',{}).items():
        if output == target['name']:continue
        if output not in {m['name'] for m in monitors}:raise ValueError('Unknown display')
        if not isinstance(coordinates,list) or len(coordinates)!=2:raise ValueError('Invalid display position')
        coords=[int(number(v,-999999,999999)) for v in coordinates]
        pattern=r'hl\.monitor\(\s*\{[^{}]*output\s*=\s*'+re.escape(json.dumps(output))+r'[^{}]*\}\s*\)'
        def relocate(match):
            return re.sub(r'position\s*=\s*"[^"]*"','position = "'+str(coords[0])+'x'+str(coords[1])+'"',match[0])
        text,count=re.subn(pattern,relocate,text)
        if not count:
            text+='\nhl.monitor('+lua(dict(output=output,mode='preferred',position=str(coords[0])+'x'+str(coords[1]),scale=next(m.get('scale',1) for m in monitors if m['name']==output),transform=next(m.get('transform',0) for m in monitors if m['name']==output)))+')\n'
    text=re.sub(r'vrr\s*=\s*[012]',f'vrr = {vrr}',text)
    pattern=r'hl\.workspace_rule\(\s*\{[^{}]*monitor\s*=\s*'+re.escape(json.dumps(target['name']))+r'[^{}]*\}\s*\)'
    line='hl.workspace_rule('+lua(dict(workspace=str(workspace),monitor=target['name'],default=True))+')'
    text,n=re.subn(pattern,lambda _:line,text)
    if not n:text+='\n'+line+'\n'
    STATE.mkdir(parents=True,exist_ok=True)
    token=uuid.uuid4().hex
    atomic(PENDING,json.dumps({'token':token,'old':old,'deadline':time.time()+20}))
    subprocess.Popen([sys.executable,__file__,'rollback',token],start_new_session=True,stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    atomic(path.with_suffix('.lua.bak'),old);atomic(path,text)
    run(['hyprctl','reload'])
    return monitor_status()

def revert(token=None):
    try:data=json.loads(PENDING.read_text())
    except FileNotFoundError:return
    if token and data['token']!=token:return
    atomic(CONFIG/'devices.lua',data['old']);PENDING.unlink(missing_ok=True)
    run(['hyprctl','reload'])

def users():
    return {'current':pwd.getpwuid(os.getuid()).pw_name,'users':[{'name':x.pw_name,'uid':x.pw_uid,'home':x.pw_dir} for x in pwd.getpwall() if 1000<=x.pw_uid<65534]}

def dispatch(action,*args):
    if action=='rollback':
        revert(args[0]);return {}
    if action in ['power','save-power','keybinds','save-keybinds']:
        import importlib.util
        name='power-settings' if action in ['power','save-power'] else 'keybind-settings'
        spec=importlib.util.spec_from_file_location(name,Path(__file__).with_name(name+'.py'))
        module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        return module.save(json.loads(args[0])) if action.startswith('save-') else module.status()
    if action=='input':return input_status()
    if action=='save-input':return save_input(json.loads(args[0]))
    if action=='monitors':return monitor_status()
    if action=='apply-monitor':return apply_monitor(json.loads(args[0]))
    if action=='keep-monitor':PENDING.unlink(missing_ok=True);return monitor_status()
    if action=='revert-monitor':revert();return monitor_status()
    if action=='timezone':
        import importlib.util
        spec=importlib.util.spec_from_file_location('clock_state',Path(__file__).with_name('clock-state.py'))
        module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        return {'current':run(['timedatectl','show','-p','Timezone','--value']),'zones':run(['timedatectl','list-timezones']).splitlines(),'clock':module.snapshot()}
    if action=='set-timezone':
        zone=args[0]
        if zone not in run(['timedatectl','list-timezones']).splitlines():raise ValueError('Unknown timezone')
        run(['timedatectl','set-timezone',zone]);return main('timezone')
    if action=='users':return users()
    if action in ['add-user','delete-user','delete-user-home']:
        name=args[0]
        if not re.fullmatch(r'[a-z_][a-z0-9_-]{0,30}',name):raise ValueError('Use a lowercase username')
        if action=='add-user':run(['pkexec','/usr/bin/useradd','--create-home','--shell','/bin/bash','--',name])
        else:
            account=pwd.getpwnam(name)
            if account.pw_uid<1000 or account.pw_uid>=65534 or account.pw_uid==os.getuid():raise ValueError('Cannot remove the current or a system account')
            flags=[]
            if action=='delete-user-home':
                home=Path(account.pw_dir)
                if len(args)<2 or args[1]!=str(home) or home!=Path('/home')/name or home.is_symlink() or os.path.ismount(home):raise ValueError('Home removal requires an ordinary /home/username directory and an exact path confirmation')
                if any(u.pw_name!=name and u.pw_dir==str(home) for u in pwd.getpwall()):raise ValueError('Home directory is shared with another account')
                flags=['--remove']
            run(['pkexec','/usr/bin/userdel',*flags,'--',name])
        return users()
    raise ValueError('Unknown setting')
def main(action,*args):
    if action == 'rollback': time.sleep(20)
    if action in ['apply-monitor','keep-monitor','revert-monitor','rollback']:
        STATE.mkdir(parents=True,exist_ok=True)
        with (STATE/'monitor-settings.lock').open('a') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX)
            return dispatch(action,*args)
    return dispatch(action,*args)

if __name__=='__main__':
    try:print(json.dumps({'type':'result','data':main(*sys.argv[1:])}),flush=True)
    except Exception as e:
        error=e.stderr if isinstance(e,subprocess.CalledProcessError) and e.stderr else str(e)
        print(json.dumps({'type':'error','data':error}),flush=True);sys.exit(1)
