#!/usr/bin/env python3

import json, subprocess, signal
from pathlib import Path

def consume(event, known):
    if event.get('DEVTYPE') != 'usb_device': return None
    path = event.get('DEVPATH', '')
    name = event.get('ID_MODEL_FROM_DATABASE') or event.get('ID_MODEL') or 'USB device'
    if event.get('ACTION') == 'add' and path not in known:
        known[path] = name.replace('_', ' ')
        return {'summary': 'USB connected', 'body': known[path]}
    if event.get('ACTION') == 'remove' and path in known:
        return {'summary': 'USB disconnected', 'body': known.pop(path)}

def main():
    known = {}
    for device in Path('/sys/bus/usb/devices').glob('*'):
        if not (device / 'busnum').exists(): continue
        path = str(device.resolve())[4:]
        try: known[path] = (device / 'product').read_text().strip()
        except OSError: known[path] = 'USB device'
    child = subprocess.Popen(['udevadm', 'monitor', '--udev', '--property', '--subsystem-match=usb'], stdout=subprocess.PIPE, text=True)
    def stop(*_):
        child.terminate()
        raise SystemExit
    signal.signal(signal.SIGTERM, stop)
    try:
        event = {}
        for line in child.stdout:
            line = line.strip()
            if not line:
                result = consume(event, known)
                if result: print(json.dumps(result), flush=True)
                event = {}
            elif '=' in line:
                key, value = line.split('=', 1)
                event[key] = value
    finally:
        child.terminate()
        child.wait()
if __name__ == '__main__': main()
