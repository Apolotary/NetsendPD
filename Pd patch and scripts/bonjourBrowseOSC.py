import select
import socket
import pybonjour
import OSC

from netifaces import interfaces, ifaddresses, AF_INET

#----- Global variables -----

regtype  = '_netsendpd._udp.'
udpSendPort = 1349
oscMobileReceivePort = 6001 #port in iOS app
oscLocalReceivePort = 3002  #port in Pd-patch

timeout  = 5
queried  = []
resolved = []
resolvedClients = []

#----- Bonjour client wrapper -----

class BonjourClient:
    name = ''
    hostIP = ''
    channelNum = ''

currentBonjourClient = BonjourClient()

#----- Helper methods -----

def get_server_ip():
    for ifaceName in interfaces():
        if ifaceName == 'en0':
            address = [i['addr'] for i in ifaddresses(ifaceName).setdefault(AF_INET, [{'addr':'No IP addr'}] )]
            return address[0]

def get_channel_number(fullname):
    stringIndex = fullname.index('._netsendpd._udp.local.')
    fullname = fullname[:stringIndex]
    fullname = fullname.replace('streamingChannel_', '')
    return fullname

#----- OSC message handlers -----

# creates message with a single argument
def osc_send_message_with_argument(messagePath, argument, receiverIP, receiverPort):
    oscClient = OSC.OSCClient()
    oscClient.connect((receiverIP, receiverPort))

    oscMessage= OSC.OSCMessage()
    oscMessage.setAddress(messagePath)
    oscMessage.append(argument)
    oscClient.send(oscMessage)
    oscClient.close()

#osc messages which are sent to mobile clients

def osc_send_client_connect_message(bonjourClient):
    oscPath = "/connect"
    oscArgument = get_server_ip()
    osc_send_message_with_argument(oscPath, oscArgument, bonjourClient.hostIP, oscMobileReceivePort)

def osc_send_client_disconnect_message(bonjourClient):
    oscPath = "/disconnect"
    oscArgument = get_server_ip()
    osc_send_message_with_argument(oscPath, oscArgument, bonjourClient.hostIP, oscMobileReceivePort)

def osc_send_client_server_address_message(bonjourClient):
    oscPath = "/serverIP"
    oscArgument = get_server_ip()
    osc_send_message_with_argument(oscPath, oscArgument, bonjourClient.hostIP, oscMobileReceivePort)

# two messages which are sent when bonjour client was found or disappeared, sent to a local patch

def osc_send_bonjour_connect_message(bonjourClient):
    oscPath = "/stream" + bonjourClient.channelNum

    # sending a special message with a complex argument
    oscMessage= OSC.OSCMessage()
    oscMessage.setAddress(oscPath)
    oscMessage.append('connect')
    oscMessage.append(str(udpSendPort))
    oscMessage.append(bonjourClient.hostIP)

    oscClient = OSC.OSCClient()
    oscClient.connect(('127.0.0.1', oscLocalReceivePort))
    oscClient.send(oscMessage)
    oscClient.close()

    osc_send_client_connect_message(bonjourClient)

def osc_send_bonjour_disconnect_message(bonjourClient):
    oscPath = "/stream" + bonjourClient.channelNum
    oscArgument = "disconnect"
    osc_send_message_with_argument(oscPath, oscArgument, '127.0.0.1', oscLocalReceivePort)
    osc_send_client_disconnect_message(bonjourClient)

#----- Bonjour callbacks -----

def query_record_callback(sdRef, flags, interfaceIndex, errorCode, fullname,
                          rrtype, rrclass, rdata, ttl):
    if errorCode == pybonjour.kDNSServiceErr_NoError:
        hostIP = socket.inet_ntoa(rdata)
        print '  IP         =', hostIP
        currentBonjourClient.hostIP = hostIP

        osc_send_client_server_address_message(currentBonjourClient)
        resolvedClients.append(currentBonjourClient)
        osc_send_bonjour_connect_message(currentBonjourClient)

        queried.append(True)


def resolve_callback(sdRef, flags, interfaceIndex, errorCode, fullname,
                     hosttarget, port, txtRecord):
    if errorCode != pybonjour.kDNSServiceErr_NoError:
        return

    print 'Resolved service:'
    print '  fullname   =', fullname
    print '  hosttarget =', hosttarget
    print '  port       =', port

    currentBonjourClient.name = fullname.replace('._netsendpd._udp.local.', '')
    currentBonjourClient.channelNum = get_channel_number(fullname)

    query_sdRef = \
        pybonjour.DNSServiceQueryRecord(interfaceIndex = interfaceIndex,
                                        fullname = hosttarget,
                                        rrtype = pybonjour.kDNSServiceType_A,
                                        callBack = query_record_callback)

    try:
        while not queried:
            ready = select.select([query_sdRef], [], [], timeout)
            if query_sdRef not in ready[0]:
                print 'Query record timed out'
                break
            pybonjour.DNSServiceProcessResult(query_sdRef)
        else:
            queried.pop()
    finally:
        query_sdRef.close()

    resolved.append(True)


def browse_callback(sdRef, flags, interfaceIndex, errorCode, serviceName,
                    regtype, replyDomain):
    if errorCode != pybonjour.kDNSServiceErr_NoError:
        return

    if not (flags & pybonjour.kDNSServiceFlagsAdd):
        print 'Service removed'

        for bonjourClient in resolvedClients:
            if bonjourClient.name == serviceName:
                osc_send_bonjour_disconnect_message(bonjourClient)
                resolvedClients.remove(bonjourClient)

        return

    print 'Service added; resolving'

    resolve_sdRef = pybonjour.DNSServiceResolve(0,
                                                interfaceIndex,
                                                serviceName,
                                                regtype,
                                                replyDomain,
                                                resolve_callback)

    try:
        while not resolved:
            ready = select.select([resolve_sdRef], [], [], timeout)
            if resolve_sdRef not in ready[0]:
                print 'Resolve timed out'
                break
            pybonjour.DNSServiceProcessResult(resolve_sdRef)
        else:
            resolved.pop()
    finally:
        resolve_sdRef.close()

#----- Main -----

browse_sdRef = pybonjour.DNSServiceBrowse(regtype = regtype,
                                          callBack = browse_callback)

try:
    try:
        while True:
            ready = select.select([browse_sdRef], [], [])
            if browse_sdRef in ready[0]:
                pybonjour.DNSServiceProcessResult(browse_sdRef)
    except KeyboardInterrupt:
        pass
finally:
    browse_sdRef.close()
