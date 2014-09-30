"""
This is a simple server implementation, which looks for clients through Bonjour protocol,
and communicates with clients / Pd patch via OSC protocol.
"""

import socket
import threading

from netifaces import interfaces, ifaddresses, AF_INET
from zeroconf import raw_input, ServiceBrowser, Zeroconf
from pythonosc import osc_message_builder
from pythonosc import udp_client
from pythonosc import dispatcher
from pythonosc import osc_server


"""
Global list for connected / disconnected clients
"""
connected_clients = list()

def get_channel_number(fullname):
    string_index = fullname.index('._netsendpd._udp.local.')
    fullname = fullname[:string_index]
    fullname = fullname.replace('streamingChannel_', '')
    return fullname

"""
A class that describes mobile clients when they are found via Bonjour protocol.
"""
class BonjourClient:
    def __init__(self, name, host_ip, channel_num):
        self.name = name
        self.host_ip = host_ip
        self.channel_num = channel_num

"""
OSC class that handles client/server communication via OSC protocol between mobile clients and a Pd patch
"""
class OSCClientServer:
    def __init__(self):
        self.osc_path_stream = "/stream"
        self.osc_path_server_ip = "/serverIP"
        self.osc_path_connect = "/connect"
        self.osc_path_disconnect = "/disconnect"
        self.osc_path_volume = "/volume"
        self.osc_port_patch = 3002
        self.osc_port_server = 3003
        self.osc_port_mobile = 6001
        self.osc_port_udpreceive = 1349
        self.dispatcher = None
        self.server = None
        self.client = None

    def get_local_ip(self):
        for ifaceName in interfaces():
            if ifaceName == 'en0':
                address = [i['addr'] for i in ifaddresses(ifaceName).setdefault(AF_INET, [{'addr':'No IP addr'}] )]
                return address[0]

    """
    Sends a generic OSC message, it's important to note that osc_args is supposed to be a list,
    so arguments should be ordered if it matters for the recipient.
    """
    def osc_client_send_message(self, receiver_ip, receiver_port, osc_path, osc_args):
        self.client = udp_client.UDPClient(receiver_ip, receiver_port)

        osc_builder = osc_message_builder.OscMessageBuilder(address=osc_path)

        for argument in osc_args:
            osc_builder.add_arg(argument)

        message_to_send = osc_builder.build()
        self.client.send(message_to_send)

    """
    Connect / disconnect messages which notify mobile client if it's connected to Pd patch.
    """
    def osc_client_send_connect(self, receiver_ip):
        local_ip = self.get_local_ip()
        osc_args = [local_ip]
        self.osc_client_send_message(receiver_ip, self.osc_port_mobile, self.osc_path_connect, osc_args)

    def osc_client_send_disconnect(self, receiver_ip):
        local_ip = self.get_local_ip()
        osc_args = [local_ip]
        self.osc_client_send_message(receiver_ip, self.osc_port_mobile, self.osc_path_disconnect, osc_args)

    """
    A message which notifies mobile client about OSC server's host IP
    """
    def osc_client_send_host_ip(self, receiver_ip):
        local_ip = self.get_local_ip()
        osc_args = [local_ip]
        self.osc_client_send_message(receiver_ip, self.osc_port_mobile, self.osc_path_disconnect, osc_args)

    """
    Volume level message for mobile client
`
    Volume - should be in 0.0f-1.0f range
    """
    def osc_client_send_volume(self, receiver_ip, volume):
        osc_args = [volume]
        self.osc_client_send_message(receiver_ip, self.osc_port_mobile, self.osc_path_volume, osc_args)

    """
    A new Bonjour client was found, thus we're sending message to Pd patch, so that
    it would connect to the mobile client.

    bonjour_client - mobile client itself
    client_udpreceive_port - port used in subpatch within iOS application
    patch_host_ip - IP of a host where Pd patch is running (in most cases - 127.0.0.1)
    patch_host_osc_port - OSC receiving port of the same patch
    """
    def osc_client_send_bonjour_connect(self, bonjour_client, client_udpreceive_port, patch_host_ip, patch_osc_port):
        print("calling connect function")
        osc_args = ['connect', client_udpreceive_port, bonjour_client.host_ip]
        self.osc_client_send_message(patch_host_ip, patch_osc_port, self.osc_path_stream + bonjour_client.channel_num, osc_args)

    """
    Bonjour client is lost/disconnected, send a disconnect message to Pd patch

    bonjour_client - mobile client itself
    patch_host_ip - IP of a host where Pd patch is running (in most cases - 127.0.0.1)
    patch_host_osc_port - OSC receiving port of the same patch
    """
    def osc_client_send_bonjour_disconnect(self, bonjour_client, patch_host_ip, patch_osc_port):
        print("calling disconnect function")
        osc_args = ['disconnect']
        self.osc_client_send_message(patch_host_ip, patch_osc_port, self.osc_path_stream + bonjour_client.channel_num, osc_args)

    def osc_server_handler_connect(self, args):
        print(args)

    def osc_server_handler_disconnect(self, args):
        print(args)

    def osc_server_handler_stream(self, args):
        print(args)

    def osc_server_start_server(self):
        self.dispatcher = dispatcher.Dispatcher()
        self.dispatcher.map(self.osc_path_stream, self.osc_server_handler_stream)
        self.dispatcher.map(self.osc_path_connect, self.osc_server_handler_connect)
        self.dispatcher.map(self.osc_path_disconnect, self.osc_server_handler_disconnect)
        self.server = osc_server.ForkingOSCUDPServer(("127.0.0.1", self.osc_port_server), dispatcher)
        server_thread = threading.Thread(target=self.server.serve_forever)
        server_thread.start()

    def osc_server_stop(self):
        self.server.shutdown()



    """
    Function that is passed to listener to message OSC client when a bonjour client connected/disconnected
    """
    def bonjour_connect_function(self, name, address):
        # notify patch
        bonjour_client = BonjourClient(name, address, get_channel_number(name))
        connected_clients.append(bonjour_client)
        self.osc_client_send_bonjour_connect(bonjour_client, self.osc_port_udpreceive, "127.0.0.1", self.osc_port_patch)

        #notify client
        self.osc_client_send_connect(address)
        print("Bonjour connected %s %s" % (name, address))

    def bonjour_disconnect_function(self, name):
        bonjour_client = BonjourClient(name, "0.0.0.0", get_channel_number(name))

        for client in connected_clients:
            if client.name == name:
                bonjour_client = client
                break

        # notify patch
        self.osc_client_send_bonjour_disconnect(bonjour_client, "127.0.0.1", self.osc_port_patch)

        #notify client
        self.osc_client_send_disconnect(bonjour_client.host_ip)
        print("Bonjour disconnected %s", name)

"""
Bonjour class that helps in monitoring connected/disconnected mobile clients
"""
class BonjourListener(object):
    """
    Connect function is called when a new Bonjour client was found
    Disconnect is called when Bonjour client is lost/removed
    """
    def __init__(self, osc_client):
        self.osc_client = osc_client

    def removeService(self, zeroconf, type, name):
        self.osc_client.bonjour_disconnect_function(name)
        print("Service %s removed" % (name,))

    def addService(self, zeroconf, type, name):
        info = zeroconf.getServiceInfo(type, name)
        self.osc_client.bonjour_connect_function(info.name, socket.inet_ntoa(info.address))
        print("Service %s added, service info: %s %s" % (name, info.name, socket.inet_ntoa(info.address)))

# --------- MAIN -------------

zeroconf = Zeroconf("bridge100")
oscClientServer = OSCClientServer()
oscClientServer.osc_server_start_server()
listener = BonjourListener(oscClientServer)
browser = ServiceBrowser(zeroconf, "_netsendpd._udp.local.", listener)
try:
    raw_input("Press enter to exit...\n\n")
finally:
    oscClientServer.osc_server_stop()
    zeroconf.close()



