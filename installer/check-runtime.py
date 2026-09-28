import re
import shutil
import subprocess
for binary,minimum,args in [('Hyprland',(0,55,0),['--version']),('qs',(0,3,1),['--version'])]:
    if not shutil.which(binary):raise SystemExit(binary+' is required before deploying hshell')
    result=subprocess.run([binary,*args],capture_output=True,text=True,timeout=10)
    match=re.search(r'\b(\d+)\.(\d+)\.(\d+)\b',result.stdout+' '+result.stderr)
    if not match or tuple(map(int,match.groups()))<minimum:raise SystemExit(binary+' '+'.'.join(map(str,minimum))+' or newer is required')
