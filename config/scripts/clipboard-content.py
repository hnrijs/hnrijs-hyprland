import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

def main():
    ident=sys.argv[1]
    if not ident.isdigit():raise ValueError('Invalid clipboard item')
    data=subprocess.run(['cliphist','decode',ident],capture_output=True,check=True,timeout=8).stdout
    types=[(b'\x89PNG','png'),(b'\xff\xd8\xff','jpg'),(b'GIF8','gif'),(b'BM','bmp')]
    extension=next((ext for signature,ext in types if data.startswith(signature)),None)
    if data[:4]==b'RIFF' and data[8:12]==b'WEBP':extension='webp'
    if extension:
        folder=Path(os.environ.get('XDG_RUNTIME_DIR') or '/run/user/'+str(os.getuid()))/'hshell-clipboard'
        folder.mkdir(mode=0o700,exist_ok=True)
        target=folder/(ident+'.'+extension)
        fd,name=tempfile.mkstemp(dir=folder)
        with os.fdopen(fd,'wb') as stream:stream.write(data)
        os.replace(name,target)
        return {'image':target.as_uri(),'text':''}
    return {'text':data.decode('utf-8',errors='replace')[:1000000],'image':''}
try:print(json.dumps(main()))
except Exception:print(json.dumps({'text':'Preview unavailable','image':''}))
