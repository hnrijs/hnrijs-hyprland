#!/usr/bin/env python3
import configparser,json,os,shlex,shutil,subprocess,sys
from pathlib import Path
CONFIG=Path(os.environ.get('XDG_CONFIG_HOME',str(Path.home()/'.config')))
DATA=Path(os.environ.get('XDG_DATA_HOME',str(Path.home()/'.local/share')))
FILE=CONFIG/'applications/defaults.json'
GROUPS={
'pdf':['application/pdf'],
'browser':['x-scheme-handler/http','x-scheme-handler/https','text/html'],
'video':['video/mp4','video/x-matroska','video/webm','video/quicktime','video/avi','audio/mpeg','audio/flac','audio/ogg'],
'image':['image/png','image/jpeg','image/webp','image/gif','image/bmp','image/tiff','image/avif'],
'files':['inode/directory'],
 'text':['text/plain','text/x-python','text/x-c','text/x-c++','application/json','application/x-shellscript','text/markdown','text/x-lua','application/x-yaml']}
TERMINALS={'alacritty':['-e'],'kitty':['--'],'foot':['--'],'footclient':['--'],'wezterm':['start','--'],'konsole':['-e'],'gnome-terminal':['--'],'xfce4-terminal':['-x'],'xterm':['-e'],'ghostty':['-e']}
def defaults():
    try:return json.loads(FILE.read_text())
    except (OSError,ValueError):return {'browser':'','terminal':'Alacritty.desktop','text':'nvim.desktop','image':'imv.desktop','video':'mpv.desktop','files':'thunar.desktop','pdf':'libreoffice-draw.desktop'}
def entries():
    roots=[DATA/'applications']+[Path(x)/'applications' for x in os.environ.get('XDG_DATA_DIRS','/usr/local/share:/usr/share').split(':') if x]
    result={}
    for root in roots:
        if not root.is_dir():continue
        for path in root.rglob('*.desktop'):
            name=str(path.relative_to(root)).replace('/','-')
            if name in result or name.startswith('hshell-'):continue
            try:
                parser=configparser.ConfigParser(interpolation=None,strict=False);parser.read(path)
                section=parser['Desktop Entry']
                if section.get('Type')!='Application' or section.get('Hidden','false')=='true':continue
                command=shlex.split(section.get('Exec',''))
                if not command:continue
                executable=Path(command[0]).name
                tryexec=section.get('TryExec','')
                if tryexec and not shutil.which(tryexec):continue
                if executable!='env' and not shutil.which(command[0]):continue
                result[name]={'id':name,'name':section.get('Name',path.stem),'icon':section.get('Icon','application-x-executable'),'categories':section.get('Categories',''),'mimes':section.get('MimeType',''),'exec':command,'terminal':section.get('Terminal','false')=='true','binary':executable,'path':str(path)}
            except (OSError,ValueError,configparser.Error,KeyError):continue
    if 'nvim.desktop' in result and 'open-default.py' in ' '.join(result['nvim.desktop']['exec']):
        result['nvim.desktop'].update(binary='nvim',terminal=True,exec=['nvim','%F'])
    return result

def candidates(role,allapps):
    values=list(allapps.values())
    if role=='terminal':return [v for v in values if v['binary'] in TERMINALS and ('TerminalEmulator' in v['categories'].split(';') or v['id'].lower() in [name+'.desktop' for name in TERMINALS])]
    category={'browser':'WebBrowser','text':'TextEditor','image':'Viewer','video':'Player','files':'FileManager','pdf':'Viewer'}[role]
    return [v for v in values if category in v['categories'].split(';') or any(m in v['mimes'].split(';') for m in GROUPS[role]) or role=='text' and v['binary'] in ['nvim','vim','nano','micro','emacs']]

def terminal_argv(command):
    allapps=entries();entry=allapps.get(defaults().get('terminal',''))
    binary=entry['binary'] if entry else 'alacritty'
    if binary not in TERMINALS or not shutil.which(binary):raise ValueError('Select an installed terminal in Default Apps')
    return [binary]+(TERMINALS[binary]+command if command else [])

def desktop_quote(text):return '"'+str(text).replace('\\','\\\\').replace('"','\\"').replace('`','\\`').replace('$','\\$')+'"'
def wrapper(role):
    directory=DATA/'applications';directory.mkdir(parents=True,exist_ok=True)
    path=directory/f'hshell-default-{role}.desktop'
    script=Path(__file__).with_name('open-default.py')
    path.write_text('[Desktop Entry]\nType=Application\nName=hshell '+role.title()+'\nExec=python3 '+desktop_quote(script)+' '+role+' %F\nTerminal=false\nNoDisplay=true\nIcon=accessories-text-editor\n')
    return path.name

def save(role,entryid):
    allapps=entries()
    if role not in ['terminal',*GROUPS] or entryid not in [v['id'] for v in candidates(role,allapps)]:raise ValueError('Select an installed application for this role')
    value=defaults();old=value.copy();value[role]=entryid
    FILE.parent.mkdir(parents=True,exist_ok=True)
    FILE.with_suffix('.json.bak').write_text(json.dumps(old,indent=2))
    tmp=FILE.with_suffix('.tmp');tmp.write_text(json.dumps(value,indent=2));tmp.replace(FILE)
    if role!='terminal':
        entry=allapps[entryid]
        desktop=wrapper(role) if entry['terminal'] or role=='text' and 'nvim' in entryid else entryid
        subprocess.run(['xdg-mime','default',desktop,*GROUPS[role]],check=True)
    
    env=[]
    for key,envkey in [('terminal','TERMINAL'),('browser','BROWSER'),('text','EDITOR')]:
        entry=allapps.get(value.get(key,''))
        if entry:
            binary='nvim' if key=='text' and 'nvim' in entry['id'] else entry['binary']
            env.append('hl.env('+json.dumps(envkey)+', '+json.dumps(binary)+')')
            if key=='text':env.append('hl.env("VISUAL", '+json.dumps(binary)+')')
    target=CONFIG/'hypr/hyprland/app-env.lua';target.parent.mkdir(parents=True,exist_ok=True);target.write_text('\n'.join(env)+'\n')
    if os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'):subprocess.run(['hyprctl','reload'],check=True,stdout=subprocess.DEVNULL)
    return status()

def status():
    allapps=entries();selected=defaults()
    if selected.get('text')=='hshell-nvim.desktop':selected['text']='nvim.desktop'
    return {'selected':selected,'choices':{role:sorted(candidates(role,allapps),key=lambda a:a['name'].casefold()) for role in ['terminal',*GROUPS]}}

def launch(role,args):
    if role=='terminal':
        command=terminal_argv(args);os.execvp(command[0],command)
    if role=='nvim':
        command=terminal_argv(['nvim','--',*args]);os.execvp(command[0],command)
    if role not in GROUPS:raise ValueError('Unknown application role')
    entryid=defaults()[role]
    if role=='text' and 'nvim' in entryid:command=terminal_argv(['nvim','--',*args]);os.execvp(command[0],command)
    entry=entries().get(entryid)
    if not entry:raise ValueError('Default application is no longer installed')
    if entry['terminal']:
        command=[]
        for part in entry['exec']:
            if part in ['%F','%U','%f','%u']:command.extend(args)
            elif part=='%c':command.append(entry['name'])
            elif part=='%k':command.append(entry['path'])
            elif part=='%i':command.extend(['--icon',entry['icon']])
            elif '%' not in part:command.append(part)
            elif '%%' in part:command.append(part.replace('%%','%'))
        if not any(p in entry['exec'] for p in ['%F','%U','%f','%u']):command.extend(args)
        command=terminal_argv(command);os.execvp(command[0],command)
    os.execvp('gtk-launch',['gtk-launch',entryid,*(args or ([str(Path.home())] if role=='files' else []))])

def main(action,*args):
    if action=='status':return status()
    if action=='set':return save(*args)
    raise ValueError('Unknown default application action')
if __name__=='__main__':
    try:print(json.dumps({'type':'result','data':main(*sys.argv[1:])}),flush=True)
    except Exception as e:print(json.dumps({'type':'error','data':str(e)}),flush=True);sys.exit(1)
