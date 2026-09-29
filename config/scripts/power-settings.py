import os,re,subprocess
from pathlib import Path
PATH=Path(os.environ.get('XDG_CONFIG_HOME',str(Path.home()/'.config')))/'hypr/hypridle.conf'
def listeners(text):
    return list(re.finditer(r'(?ms)^listener\s*\{\s*\n.*?^\}',text))
def status():
    result={'lock':60,'suspend':300}
    for block in listeners(PATH.read_text()):
        for name in result:
            if re.search(r'idle-action\.sh.*\b'+name+r"['\"]?\s*$",block[0],re.M):
                result[name]=int(re.search(r'timeout\s*=\s*(\d+)',block[0])[1])
    return result
def save(data):
    values={name:int(data[name]) for name in ['lock','suspend']}
    if any(not 10<=x<=86400 for x in values.values()):raise ValueError('Choose 10–86400 seconds')
    if values['suspend']<=values['lock']:raise ValueError('Suspend must be later than Lock')
    old=PATH.read_text();text=old;found=set()
    for block in reversed(listeners(old)):
        for name,value in values.items():
            if re.search(r'idle-action\.sh.*\b'+name+r"['\"]?\s*$",block[0],re.M):
                new=re.sub(r'(timeout\s*=\s*)\d+',lambda m:m[1]+str(value),block[0],count=1)
                text=text[:block.start()]+new+text[block.end():];found.add(name)
    if found!=set(values):raise ValueError('Managed idle listeners are missing')
    PATH.with_suffix('.conf.bak').write_text(old)
    temp=PATH.with_suffix('.tmp');temp.write_text(text);temp.replace(PATH)
    
    active=subprocess.run(['systemctl','--user','is-active','--quiet','hypridle.service']).returncode==0
    if active:subprocess.run(['systemctl','--user','restart','hypridle.service'],check=True)
    else:
        subprocess.run(['pkill','-u',str(os.getuid()),'-x','hypridle'],check=False)
        subprocess.Popen(['hypridle','-c',str(PATH)],start_new_session=True,stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    return status()
