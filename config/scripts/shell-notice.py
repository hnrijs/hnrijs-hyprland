#!/usr/bin/env python3
import subprocess
import sys
if len(sys.argv)==3:
    try:subprocess.run(['qs','-c','hshell','ipc','call','hshell','notice',sys.argv[1],sys.argv[2][:500]],capture_output=True,timeout=2)
    except (OSError,subprocess.SubprocessError):pass
