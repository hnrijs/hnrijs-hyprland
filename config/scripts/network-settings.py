#!/usr/bin/env python3
import ipaddress,json,re,subprocess,sys
from pathlib import Path
DNS={'dhcp':('',''),'cloudflare':('1.1.1.1,1.0.0.1','2606:4700:4700::1111,2606:4700:4700::1001'),'google':('8.8.8.8,8.8.4.4','2001:4860:4860::8888,2001:4860:4860::8844')}
def run(args):return subprocess.check_output(args,text=True,stderr=subprocess.PIPE).strip()
def profiles():
    rows=[]
    for line in run(['nmcli','-t','-f','UUID,TYPE,DEVICE','connection','show','--active']).splitlines():
        uuid,kind,device=line.split(':',2)
        if kind not in ['802-3-ethernet','802-11-wireless','ethernet','wifi']:continue
        name=run(['nmcli','-g','connection.id','connection','show','uuid',uuid])
        dns=run(['nmcli','-g','ipv4.dns','connection','show','uuid',uuid])
        ignore=run(['nmcli','-g','ipv4.ignore-auto-dns','connection','show','uuid',uuid])
        preset='dhcp' if ignore=='no' and not dns else 'custom'
        for key,value in DNS.items():
            if key!='dhcp' and ignore=='yes' and dns.replace(' ','')==value[0]:preset=key
        rows.append(dict(uuid=uuid,device=device,name=name,preset=preset,dns=dns))
    return rows

def firewall_status():
    try: enabled=bool(re.search(r'^ENABLED=yes\s*$',Path('/etc/ufw/ufw.conf').read_text(),re.M))
    except OSError: enabled=False
    try: defaults=Path('/etc/default/ufw').read_text()
    except OSError: defaults=''
    def policy(name):
        match=re.search(r'^'+name+r'="?([A-Z]+)',defaults,re.M)
        return match[1].title() if match else 'Unknown'
    return {'firewall':enabled,'incoming':policy('DEFAULT_INPUT_POLICY'),'outgoing':policy('DEFAULT_OUTPUT_POLICY')}

def main(action,*args):
    message=''
    if action=='firewall-status':return firewall_status()
    if action=='firewall-rules':return dict(firewall_status(),rules=run(['pkexec','/usr/bin/ufw','status','verbose']))
    if action=='dns':
        uuid,preset=args[:2]
        if preset not in [*DNS,"custom"] or not re.fullmatch(r'[0-9a-fA-F-]{36}',uuid):raise ValueError('Invalid DNS choice')
        row=next((r for r in profiles() if r['uuid']==uuid),None)
        if not row:raise ValueError('Connection is no longer active')
        if preset=='custom':
            addresses=[ipaddress.ip_address(a) for a in re.split(r'[,\s]+',args[2].strip()) if a]
            if not addresses or len(addresses)>8:raise ValueError('Enter one to eight DNS addresses')
            v4=','.join(str(a) for a in addresses if a.version==4);v6=','.join(str(a) for a in addresses if a.version==6)
        else:v4,v6=DNS[preset]
        ignore='no' if preset=='dhcp' else 'yes' 
        run(['nmcli','connection','modify','uuid',uuid,'ipv4.ignore-auto-dns',ignore,'ipv4.dns',v4,'ipv6.ignore-auto-dns',ignore,'ipv6.dns',v6])
        result=subprocess.run(['nmcli','device','reapply',row['device']],capture_output=True,text=True)
        message='DNS Applied' if result.returncode==0 else 'DNS Saved. Reconnect this connection to apply.'
    elif action=='ping':
        row=next((r for r in profiles() if r['uuid']==args[0]),None)
        if not row:raise ValueError('Connection is no longer active')
        target=next((a.strip() for a in row['dns'].split(',') if a.strip()),'1.1.1.1')
        target=str(ipaddress.ip_address(target))
        result=subprocess.run(['ping','-n','-c','3','-W','2','-I',row['device'],target],capture_output=True,text=True,timeout=12)
        message=result.stdout.strip() or result.stderr.strip()
    elif action=='firewall': 
        if args[0] not in ['on','off']:raise ValueError('Invalid firewall state')
        run(['pkexec','/usr/bin/ufw','--force','enable' if args[0]=='on' else 'disable'])
        return dict(firewall_status(),message='Firewall Enabled' if args[0]=='on' else 'Firewall Disabled')
    elif action!='status':raise ValueError('Unknown network setting')
    try: enabled=bool(re.search(r'^ENABLED=yes\s*$',Path('/etc/ufw/ufw.conf').read_text(),re.M))
    except OSError: enabled=False
    return {'connections':profiles(),'firewall':enabled,'message':message}
if __name__=='__main__':
    try:print(json.dumps({'type':'result','data':main(*sys.argv[1:])}),flush=True)
    except Exception as e:print(json.dumps({'type':'error','data':str(e)}),flush=True);sys.exit(1)
