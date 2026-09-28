import json
import subprocess
import sys
from pathlib import Path
import time

def run(args):
    return subprocess.check_output(args,text=True,stderr=subprocess.PIPE).strip()

def main():
    backup=[]
    for line in run(['nmcli','-t','-f','UUID,TYPE','connection','show']).splitlines():
        token,kind=line.split(':',1)
        if kind not in ['802-11-wireless','802-3-ethernet','wifi','ethernet']:continue
        values={field:run(['nmcli','-g',field,'connection','show','uuid',token]) for field in ['ipv4.ignore-auto-dns','ipv4.dns','ipv6.ignore-auto-dns','ipv6.dns']}
        backup.append({'uuid':token,'settings':values})
    if not backup:return
    if '--no-backups' not in sys.argv:
        directory=Path(sys.argv[1]);directory.mkdir(parents=True,exist_ok=True,mode=0o700)
        path=directory/('dns-'+str(time.time_ns())+'.json');path.write_text(json.dumps(backup,indent=2));path.chmod(0o600)
    for row in backup:
        subprocess.run(['sudo','nmcli','connection','modify','uuid',row['uuid'],'ipv4.ignore-auto-dns','yes','ipv4.dns','1.1.1.1 1.0.0.1','ipv6.ignore-auto-dns','yes','ipv6.dns','2606:4700:4700::1111 2606:4700:4700::1001'],check=True)
    print('Cloudflare DNS saved for physical network profiles; applies on reconnect.')

if __name__=='__main__':main()
