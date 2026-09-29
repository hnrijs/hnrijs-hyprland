import asyncio
import json
import sys
import uuid

async def connect(data):
    from dbus_next import BusType,Variant
    from dbus_next.aio import MessageBus
    interface=str(data.get('interface',''))
    name=str(data.get('name',''))
    password=str(data.get('password',''))
    if not interface or not 1<=len(name.encode())<=32 or not password:raise ValueError('Enter a network and password')
    bus=await MessageBus(bus_type=BusType.SYSTEM).connect()
    service='org.freedesktop.NetworkManager'
    path='/org/freedesktop/NetworkManager'
    try:
        proxy=bus.get_proxy_object(service,path,await bus.introspect(service,path))
        manager=proxy.get_interface(service)
        device=await manager.call_get_device_by_ip_iface(interface)
        settings={
            'connection':{'id':Variant('s',name),'uuid':Variant('s',str(uuid.uuid4())),'type':Variant('s','802-11-wireless'),'autoconnect':Variant('b',False)},
            '802-11-wireless':{'ssid':Variant('ay',name.encode()),'mode':Variant('s','infrastructure')},
            '802-11-wireless-security':{'key-mgmt':Variant('s','sae' if data.get('sae') else 'wpa-psk'),'psk':Variant('s',password),'psk-flags':Variant('u',2)},
            'ipv4':{'method':Variant('s','auto')},'ipv6':{'method':Variant('s','auto')}
        }
        _,active,_=await manager.call_add_and_activate_connection2(settings,device,'/',{'persist':Variant('s','volatile')})
        active_proxy=bus.get_proxy_object(service,active,await bus.introspect(service,active))
        props=active_proxy.get_interface('org.freedesktop.DBus.Properties')
        for _ in range(90):
            state=(await props.call_get(service+'.Connection.Active','State')).value
            if state==2:return {'message':'Connected for This Session'}
            if state in [3,4]:raise ValueError('Connection failed. Check the password and signal.')
            await asyncio.sleep(0.5)
        raise ValueError('Connection timed out')
    finally:bus.disconnect()

def main():
    data=json.loads(sys.stdin.read(65536))
    try:return asyncio.run(asyncio.wait_for(connect(data),60))
    except ValueError:raise
    except Exception:raise ValueError('Could not create a temporary Wi-Fi connection') from None
