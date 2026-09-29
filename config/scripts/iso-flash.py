#!/usr/bin/env python3

import json,os,stat,subprocess,sys,time,urllib.parse
from pathlib import Path


def disks():
    result=json.loads(subprocess.check_output(['lsblk','--json','--bytes','--paths','-o','NAME,TYPE,SIZE,MODEL,SERIAL,TRAN,RM,RO,MOUNTPOINTS,MAJ:MIN'],text=True))
    return result['blockdevices']

def descendants(disk):
    yield disk
    for child in disk.get('children',[]):yield from descendants(child)

def identity(disk):return {key:disk.get(key) for key in ['name','size','serial','maj:min']}

def validate(disk,expected):
    if disk['type']!='disk' or not (disk.get('tran')=='usb' or disk.get('rm')) or disk.get('ro') or not disk.get('size'):raise ValueError('Select a writable removable or USB disk')
    if identity(disk)!=expected:raise ValueError('Drive changed. Refresh and confirm the target again.')
    mounts=[m for node in descendants(disk) for m in node.get('mountpoints',[]) if m]
    if any(not m.startswith(('/run/media/','/media/')) for m in mounts):raise ValueError('System or manually mounted drive is protected. Unmount it first.')
    swaps=subprocess.check_output(['swapon','--show=NAME','--noheadings'],text=True).splitlines()
    if any(node['name'] in swaps for node in descendants(disk)):raise ValueError('Drive contains active swap')
    return mounts

def list_drives():
    return {'drives':[dict(identity(d),model=(d.get('model') or 'USB Drive').strip(),mounted=any(m for n in descendants(d) for m in n.get('mountpoints',[]) if m)) for d in disks() if d['type']=='disk' and (d.get('tran')=='usb' or d.get('rm')) and not d.get('ro')]}

def emit(kind,data):print(json.dumps({'type':kind,'data':data}),flush=True)

def write_image(filename,expected):
    if os.geteuid()!=0:raise ValueError('Administrator authentication is required')
    image=Path(filename).resolve(strict=True)
    if not image.is_file() or image.suffix.lower() not in ['.iso','.img']:raise ValueError('Choose an ISO or raw IMG file')
    disk=next((d for d in disks() if d['name']==expected['name']),None)
    if not disk:raise ValueError('Drive was disconnected')
    mounts=validate(disk,expected)
    if image.stat().st_size<=0 or image.stat().st_size>disk['size']:raise ValueError('Image is empty or larger than the drive')
    for node in descendants(disk):
        for mount in node.get('mountpoints',[]):
            if mount and image.is_relative_to(Path(mount).resolve()):raise ValueError('Image is stored on the target drive')
    for mount in sorted(set(mounts),key=len,reverse=True):subprocess.run(['umount','--',mount],check=True,capture_output=True)
    disk=next((d for d in disks() if d['name']==expected['name']),None)
    if not disk:raise ValueError('Drive was disconnected')
    if validate(disk,expected):raise ValueError('Drive is still mounted')
    major,minor=map(int,expected['maj:min'].split(':'))
    flags=os.O_WRONLY|os.O_EXCL|os.O_NOFOLLOW|os.O_DSYNC
    descriptor=os.open(expected['name'],flags)
    try:
        info=os.fstat(descriptor)
        if not stat.S_ISBLK(info.st_mode) or info.st_rdev!=os.makedev(major,minor):raise ValueError('Target device changed')
        total=image.stat().st_size;copied=0;last=0;started=time.monotonic()
        emit('progress',{'message':'Writing · 0%','percent':0})
        with image.open('rb') as source:
            while True:
                data=source.read(4*1024*1024)
                if not data:break
                view=memoryview(data)
                while view:
                    count=os.write(descriptor,view);view=view[count:];copied+=count
                if time.monotonic()-last>.2:
                    elapsed=max(.001,time.monotonic()-started);rate=copied/elapsed;remaining=max(0,int((total-copied)/rate))
                    emit('progress',{'message':f'Writing · {copied/total*100:.1f}% · {copied/1e6:.0f} / {total/1e6:.0f} MB · {rate/1e6:.1f} MB/s · ~{remaining}s','percent':copied/total*100});last=time.monotonic()
        emit('progress',{'message':'Finalizing · 100% written to drive','percent':100});os.fsync(descriptor)
    finally:os.close(descriptor)
    subprocess.run(['blockdev','--rereadpt',expected['name']],capture_output=True)
    return {'message':'Flash Complete · Safe to Remove','bytes':copied}

def main(action,*args):
    if action=='list':return list_drives()
    if action=='write':
        file=args[0];file=urllib.parse.unquote(urllib.parse.urlsplit(file).path) if file.startswith('file:') else file
        expected=json.loads(args[1])
        if os.geteuid()==0:return write_image(file,expected)
        process=subprocess.Popen(['pkexec','/usr/bin/python3',str(Path(__file__).resolve()),'write',str(Path(file).expanduser().resolve()),json.dumps(expected)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        result=None
        for line in process.stdout:
            event=json.loads(line)
            if event['type']=='progress':emit('progress',event['data'])
            elif event['type']=='result':result=event['data']
        error=process.stderr.read();code=process.wait()
        if code:raise ValueError(error.strip() or 'Flash cancelled or failed')
        if result is None:raise ValueError('No completion result from writer')
        return result
    raise ValueError('Unknown flash action')
if __name__=='__main__':
    try:emit('result',main(*sys.argv[1:]))
    except Exception as error:print(str(error),file=sys.stderr);sys.exit(1)
