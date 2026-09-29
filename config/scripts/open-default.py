#!/usr/bin/env python3
import sys
from app_defaults import launch
if __name__=='__main__':
    try:launch(sys.argv[1],sys.argv[2:])
    except Exception as error:print(str(error),file=sys.stderr);sys.exit(1)
