#!/usr/bin/env python3

from pathlib import Path
import time


def enabled(directory=Path('/sys/class/leds')):
    for path in directory.glob('*::capslock/brightness'):
        try:
            if int(path.read_text().strip()) > 0:
                return True
        except (OSError, ValueError):
            pass  
    return False


if __name__ == '__main__':
    previous = None
    try:
        while True:
            current = enabled()
            if current != previous:
                print('on' if current else 'off', flush=True)
                previous = current
            time.sleep(0.15)
    except (BrokenPipeError, KeyboardInterrupt):
        pass
