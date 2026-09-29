import json,os,re,subprocess
from pathlib import Path
ROOT=Path(os.environ.get('XDG_CONFIG_HOME',str(Path.home()/'.config')))/'hypr/hyprland'
def status():
    defaults=json.loads((ROOT/'keybind-defaults.json').read_text())
    try:saved=json.loads((ROOT/'keybind-overrides.json').read_text())
    except FileNotFoundError:saved=[]
    overrides={x['id']:x for x in saved}
    result=[dict(x,**{k:v for k,v in overrides.get(x['id'],{}).items() if k!='label'}) for x in defaults]
    result += [x for x in saved if x['id'].startswith('custom:')]
    return {'bindings':result}
def canonical(key):
    pieces=[x.strip() for x in key.split('+')]
    if not pieces or not all(pieces):raise ValueError('Enter a key combination')
    mods=[x.upper() for x in pieces[:-1]]
    if any(x not in ['SUPER','SHIFT','CTRL','ALT','MOD2','MOD3','MOD5'] for x in mods):raise ValueError('Unknown modifier')
    if len(mods)!=len(set(mods)):raise ValueError('Repeated modifier')
    last=pieces[-1]
    if not re.fullmatch(r'[A-Za-z0-9_:.-]{1,64}',last):raise ValueError('Invalid key')
    return ' + '.join(sorted(mods)+[last.upper()])
def save(data):
    entries=data['bindings'];defaults={x['id']:x for x in json.loads((ROOT/'keybind-defaults.json').read_text())}
    if not isinstance(entries,list) or len(entries)>512:raise ValueError('Invalid bindings')
    seen=set();ids=set();clean=[]
    for item in entries:
        identity=str(item['id']);key=str(item['key']).strip();command=str(item.get('command','')).strip();disabled=bool(item.get('disabled',False))
        if identity in ids:raise ValueError('Repeated binding')
        ids.add(identity)
        if identity not in defaults and not re.fullmatch(r'custom:[A-Za-z0-9_-]+',identity):raise ValueError('Unknown binding')
        combo=canonical(key)
        if not disabled:
            if combo in seen:raise ValueError('Already assigned: '+key)
            seen.add(combo)
        if len(command)>4096 or any(c in command for c in '\x00\r\n'):raise ValueError('Invalid command')
        if identity.startswith('custom:') and not command:raise ValueError('Enter a command for the new binding')
        clean.append(dict(id=identity,key=key,command=command,disabled=disabled,label=str(item.get('label','Custom Command'))[:200]))
    if not set(defaults).issubset(ids):raise ValueError('Missing default bindings; disable instead of removing')
    def quote(value):return json.dumps(value,ensure_ascii=False)
    mappings=[];extra=[]
    for item in clean:
        fields='{ key = '+quote(item['key'])+', command = '+quote(item['command'])+', disabled = '+str(item['disabled']).lower()+' }'
        if item['id'] in defaults:mappings.append('['+quote(item['id'])+'] = '+fields)
        elif not item['disabled']:extra.append(fields)
    lua='return { bindings = {\n'+',\n'.join(mappings)+'\n}, extra = {\n'+',\n'.join(extra)+'\n} }\n'
    for name,contents in [('keybind-overrides.json',json.dumps(clean,indent=2)),('keybind-overrides.lua',lua)]:
        path=ROOT/name
        if path.exists():path.with_suffix(path.suffix+'.bak').write_text(path.read_text())
        temp=path.with_suffix('.tmp');temp.write_text(contents);temp.replace(path)
    subprocess.run(['hyprctl','reload'],check=True,capture_output=True,text=True)
    return status()
