#!/usr/bin/env python3
import asyncio
import json
import re
import sys
from dbus_next.aio import MessageBus
from dbus_next import BusType, DBusError
from dbus_next.service import ServiceInterface, method


def emit(event_type, **data):
    print(json.dumps(dict(type=event_type, **data)), flush=True)


class Agent(ServiceInterface):
    def __init__(self):
        super().__init__('org.bluez.Agent1')
        self.pending = None
        self.serial = 0

    async def ask(self, kind, value=''):
        if self.pending and not self.pending.done():
            raise DBusError('org.bluez.Error.Rejected', 'Another pairing request is active')
        self.serial += 1
        self.pending = asyncio.get_running_loop().create_future()
        emit('request', id=self.serial, kind=kind, value=value)
        try:
            answer = await asyncio.wait_for(self.pending, 90)
            if not answer.get('accept'):
                raise DBusError('org.bluez.Error.Rejected', 'Pairing cancelled')
            return answer.get('value', '')
        except asyncio.TimeoutError:
            raise DBusError('org.bluez.Error.Canceled', 'Pairing timed out')
        finally:
            self.pending = None
            emit('clear')

    @method()
    def Release(self):
        self.Cancel()

    @method()
    def Cancel(self):
        if self.pending and not self.pending.done():
            self.pending.set_result({'accept': False})
        emit('clear')

    @method()
    async def RequestPinCode(self, device: 'o') -> 's':
        value = await self.ask('pin')
        if not value or len(value) > 16:
            raise DBusError('org.bluez.Error.Rejected', 'Invalid PIN')
        return value

    @method()
    async def RequestPasskey(self, device: 'o') -> 'u':
        value = await self.ask('passkey')
        if not re.fullmatch(r'\d{1,6}', value):
            raise DBusError('org.bluez.Error.Rejected', 'Enter up to six digits')
        return int(value)

    @method()
    async def RequestConfirmation(self, device: 'o', passkey: 'u'):
        await self.ask('confirm', f'{passkey:06d}')

    @method()
    async def RequestAuthorization(self, device: 'o'):
        await self.ask('authorize')

    @method()
    async def AuthorizeService(self, device: 'o', uuid: 's'):
        await self.ask('authorize', uuid)

    @method()
    def DisplayPinCode(self, device: 'o', pincode: 's'):
        emit('request', id=0, kind='display', value=pincode)

    @method()
    def DisplayPasskey(self, device: 'o', passkey: 'u', entered: 'q'):
        emit('request', id=0, kind='display', value=f'{passkey:06d}')


async def run(address):
    if not re.fullmatch(r'(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}', address):
        raise ValueError('Invalid Bluetooth address')
    bus = await MessageBus(bus_type=BusType.SYSTEM).connect()
    agent = Agent()
    path = '/org/hshell/PairingAgent'
    bus.export(path, agent)
    manager = bus.get_proxy_object('org.bluez', '/org/bluez', await bus.introspect('org.bluez', '/org/bluez')).get_interface('org.bluez.AgentManager1')
    await manager.call_register_agent(path, 'KeyboardDisplay')
    stream = asyncio.StreamReader()
    await asyncio.get_running_loop().connect_read_pipe(lambda: asyncio.StreamReaderProtocol(stream), sys.stdin)

    async def answers():
        while line := await stream.readline():
            try:
                answer = json.loads(line)
                if answer.get('id') == agent.serial and agent.pending and not agent.pending.done():
                    agent.pending.set_result(answer)
            except (ValueError, AttributeError):
                pass
        agent.Cancel()

    reader = asyncio.create_task(answers())
    try:
        objects = bus.get_proxy_object('org.bluez', '/', await bus.introspect('org.bluez', '/')).get_interface('org.freedesktop.DBus.ObjectManager')
        managed = await objects.call_get_managed_objects()
        device_path = next((p for p, interfaces in managed.items() if 'org.bluez.Device1' in interfaces and interfaces['org.bluez.Device1']['Address'].value.lower() == address.lower()), None)
        if not device_path:
            raise ValueError('Device is no longer available; scan again')
        device = bus.get_proxy_object('org.bluez', device_path, await bus.introspect('org.bluez', device_path)).get_interface('org.bluez.Device1')
        await asyncio.wait_for(device.call_pair(), 120)
        await device.call_connect()
        emit('result', message='Connected')
    finally:
        reader.cancel()
        await manager.call_unregister_agent(path)
        bus.disconnect()


if __name__ == '__main__':
    try:
        asyncio.run(run(sys.argv[1]))
    except Exception as error:
        emit('error', message=str(error))
        sys.exit(1)
