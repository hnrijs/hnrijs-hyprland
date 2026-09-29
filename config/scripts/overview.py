#!/usr/bin/env python3
import json,re,subprocess


def query(name):return json.loads(subprocess.check_output(['hyprctl','-j',name],text=True))

def main(action='status',*args):
    clients=query('clients');workspaces=query('workspaces');monitors=query('monitors')
    if action in ['move','focus','workspace']:
        address=args[0] if action!='workspace' else ''
        if action!='workspace' and (not re.fullmatch(r'0x[0-9a-fA-F]+',address) or not any(c['address']==address for c in clients)):
            raise ValueError('Window is no longer available')
        if action=='focus':
            expression='hl.dispatch(hl.dsp.focus({window='+json.dumps('address:'+address)+'}))'
        else:
            destination=args[-1]
            valid={str(i) for i in range(1,11)}|{str(w['id']) for w in workspaces if w['id']>0}|{w['name'] for w in workspaces if w['id']<0}
            if destination not in valid:raise ValueError('Workspace is no longer available')
            value=destination if destination.isdigit() else json.dumps(destination)
            if action=='move':expression='hl.dispatch(hl.dsp.window.move({workspace='+value+',window='+json.dumps('address:'+address)+'}))'
            elif destination.startswith('special:'):expression='hl.dispatch(hl.dsp.workspace.toggle_special('+json.dumps(destination.split(':',1)[1])+'))'
            else:expression='hl.dispatch(hl.dsp.focus({workspace='+value+'}))'
        result=subprocess.run(['hyprctl','eval',expression],capture_output=True,text=True)
        if result.returncode or any(word in result.stdout.lower() for word in ['error','invalid','failed']):
            raise ValueError(result.stderr.strip() or result.stdout.strip() or 'Hyprland rejected the action')
        clients=query('clients');workspaces=query('workspaces')
    elif action!='status':raise ValueError('Unknown overview action')
    active=query('activeworkspace')
    return {'clients':[c for c in clients if c.get('mapped',True) and not c.get('hidden',False)],'workspaces':workspaces,'monitors':monitors,'active':active.get('id',1)}
