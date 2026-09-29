#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import sys


def call(*args):
    return subprocess.check_output(['pactl',*args],text=True,stderr=subprocess.DEVNULL,timeout=1,env={**os.environ,'LC_ALL':'C'}).strip()


def main(mode):
    runtime=Path(os.environ['XDG_RUNTIME_DIR'])
    target=runtime/'hshell-lock-audio.json'
    if mode=='prepare':
        prefs=Path(os.environ.get('XDG_STATE_HOME',str(Path.home()/'.local/state')))/'hshell/preferences.json'
        try:options=json.loads(prefs.read_text()).get('options',{})
        except (OSError,ValueError):options={}
        devices=[]
        for key,kind in [('lockMuteAudio','sink'),('lockMuteMic','source')]:
            if not options.get(key,False):continue
            try:
                name=call('get-default-'+kind)
                muted=call('get-'+kind+'-mute',name).split(':')[-1].strip()
                if muted in ['yes','no']:devices.append({'kind':kind,'name':name,'muted':muted=='yes'})
            except (OSError,subprocess.SubprocessError):pass
        fd=os.open(target,os.O_WRONLY|os.O_CREAT|os.O_TRUNC|os.O_NOFOLLOW,0o600)
        with os.fdopen(fd,'w') as stream:json.dump(devices,stream)
        for device in devices:
            try:call('set-'+device['kind']+'-mute',device['name'],'1')
            except (OSError,subprocess.SubprocessError):pass
    elif mode=='restore':
        try:
            fd=os.open(target,os.O_RDONLY|os.O_NOFOLLOW)
            with os.fdopen(fd) as stream:devices=json.load(stream)
            for device in devices:
                if device.get('kind') not in ['sink','source']:continue
                try:call('set-'+device['kind']+'-mute',device['name'],'1' if device['muted'] else '0')
                except (OSError,subprocess.SubprocessError):pass
            target.unlink(missing_ok=True)
        except (OSError,ValueError):pass


if __name__=='__main__':main(sys.argv[1])
