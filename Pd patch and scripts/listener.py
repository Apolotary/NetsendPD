from zeroconf import raw_input, ServiceBrowser, Zeroconf
import socket

class MyListener(object):
    def removeService(self, zeroconf, type, name):
        print("Service %s removed" % (name,))

    def addService(self, zeroconf, type, name):
        info = zeroconf.getServiceInfo(type, name)
        print("Service %s added, service info: %s %s" % (name, info.name, socket.inet_ntoa(info.address)))


zeroconf = Zeroconf()
listener = MyListener()
browser = ServiceBrowser(zeroconf, "_netsendpd._udp.local.", listener)
try:
    raw_input("Press enter to exit...\n\n")
finally:
    zeroconf.close()