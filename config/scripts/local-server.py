#!/usr/bin/env python3
import functools,http.server,json,os,secrets,signal,subprocess,sys,time,urllib.parse,fcntl
from pathlib import Path
ROOT=Path(os.environ.get('XDG_RUNTIME_DIR') or (Path.home()/'.cache'))/'hshell-server'
ROOT.mkdir(parents=True,exist_ok=True,mode=0o700)

def current():
    servers=[]
    for file in ROOT.glob('*.json'):
        try:
            data=json.loads(file.read_text());command=Path(f'/proc/{data["pid"]}/cmdline').read_bytes().split(b'\0')
            if data['token'].encode() in command and str(Path(__file__).resolve()).encode() in command:servers.append(data)
            else:file.unlink(missing_ok=True)
        except (OSError,ValueError,KeyError):continue
    return sorted(servers,key=lambda d:d['port'])

def main(action,*args):
    with (ROOT/'control.lock').open('a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        return operate(action,*args)

def operate(action,*args):
    servers=current()
    if action=='status':return {'servers':servers}
    if action=='stop':
        token=args[0] if args else ''
        selected=next((d for d in servers if d['token']==token),None)
        if not selected:raise ValueError('Server is no longer running')
        os.kill(selected['pid'],signal.SIGTERM)
        for file in ROOT.glob('*.json'):
            try:
                if json.loads(file.read_text()).get('token')==token:file.unlink()
            except (ValueError,OSError):pass
        return {'servers':[d for d in servers if d['token']!=token]}
    if action!='start':raise ValueError('Unknown server action')
    mode=args[2] if len(args)>2 else 'single'
    if mode not in ['single','multiple']:raise ValueError('Invalid server mode')
    if servers and mode=='single':raise ValueError('Stop existing servers or choose Multiple')
    value=args[0];value=urllib.parse.unquote(urllib.parse.urlsplit(value).path) if value.startswith('file:') else value
    folder=Path(value).expanduser().resolve(strict=True);port=int(args[1])
    if not folder.is_dir() or not 1024<=port<=65535:raise ValueError('Select a folder and port 1024–65535')
    if any(d['port']==port for d in servers):raise ValueError('This port is already in use')
    token=secrets.token_hex(16);log=ROOT/(token+'.log')
    with log.open('wb') as output:
        process=subprocess.Popen([sys.executable,str(Path(__file__).resolve()),'serve',str(folder),str(port),token],stdin=subprocess.DEVNULL,stdout=output,stderr=output,start_new_session=True)
    ready=ROOT/(token+'.ready')
    for _ in range(40):
        if ready.exists():break
        if process.poll() is not None:raise ValueError(log.read_text()[-1500:])
        time.sleep(.05)
    if not ready.exists():process.terminate();raise ValueError('Server did not start')
    ready.unlink()
    route=subprocess.run(['ip','-j','route','get','1.1.1.1'],capture_output=True,text=True,timeout=5)
    try:ip=json.loads(route.stdout)[0].get('prefsrc','127.0.0.1')
    except (ValueError,IndexError):ip='127.0.0.1'
    data=dict(pid=process.pid,token=token,folder=str(folder),port=port,url=f'http://{ip}:{port}')
    (ROOT/(token+'.json')).write_text(json.dumps(data))
    try:subprocess.run(['wl-copy'],input=data['url'],text=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=5)
    except (OSError,subprocess.TimeoutExpired):pass
    return {'servers':servers+[data]}

class Handler(http.server.SimpleHTTPRequestHandler):
    def translate_path(self,path):
        candidate=Path(super().translate_path(path)).resolve()
        if not candidate.is_relative_to(Path(self.directory).resolve()):return '/dev/null'
        return str(candidate)
if __name__=='__main__' and sys.argv[1]=='serve':
    folder,port,token=sys.argv[2:]
    server=http.server.ThreadingHTTPServer(('0.0.0.0',int(port)),functools.partial(Handler,directory=folder))
    (ROOT/(token+'.ready')).touch();server.serve_forever()
