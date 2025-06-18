#!/usr/bin/env python3
try:
  from gi.repository import GObject
except ImportError:
  import gobject as GObject
import sys
import array
from bluez_components import *
import os

class DemoService(Service):
    TEST_SVC_UUID = 'FF00'

    def __init__(self, bus, index):
        Service.__init__(self, bus, index, self.TEST_SVC_UUID, True)
        self.add_characteristic(DemoCharacteristic(bus, 0, self))

class DemoCharacteristic(Characteristic):
    TEST_CHRC_UUID = 'FF01'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.TEST_CHRC_UUID,
                ['read', 'write', 'writable-auxiliaries'],
                service)
        self.value=[0]
        self.add_descriptor(
                CharacteristicUserDescriptionDescriptor(bus, 1, self))

    def ReadValue(self, options):
        print('DemoCharacteristic Read: ' + repr(self.value))
        return self.value

    def WriteValue(self, value, options):
        print('Demo Characteristic WriteValue called')
        self.value = value
        #print("value:%s" % ''.join([str(v) for v in value]))
        lol=''.join([str(v) for v in value])
        print(lol)
        os.system("echo \"" + lol + "\" | socat -U tcp:127.0.0.1:1235 -")

class CharacteristicUserDescriptionDescriptor(Descriptor):
    CUD_UUID = '2901'

    def __init__(self, bus, index, characteristic):
        self.writable = 'writable-auxiliaries' in characteristic.flags
        self.value = array.array('B', b'Demo Characteristic User Description')
        self.value = self.value.tolist()
        Descriptor.__init__(
                self, bus, index,
                self.CUD_UUID,
                ['read', 'write'],
                characteristic)

    def ReadValue(self, options):
        #print(self.value)
        return self.value

    def WriteValue(self, value, options):
        if not self.writable:
            raise NotPermittedException()
        self.value = value

def main():
    global mainloop

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    bus = dbus.SystemBus()

    adapter = find_adapter(bus)
    if not adapter:
        print('GattManager1 interface not found')
        return

    service_manager = dbus.Interface(
            bus.get_object(BLUEZ_SERVICE_NAME, adapter),
            GATT_MANAGER_IFACE)

    app = Application(bus)
    app.add_service(DemoService(bus, 0))
    mainloop = GObject.MainLoop()

    #print('Registering GATT application...')

    service_manager.RegisterApplication(app.get_path(), {},
                                    reply_handler=register_app_cb,
                                    error_handler=register_app_error_cb)

    mainloop.run()

if __name__ == '__main__':
    main()
