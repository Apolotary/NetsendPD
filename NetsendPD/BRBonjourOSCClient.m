//
//  BRBonjourOSCClient.m
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 8/9/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import "BRBonjourOSCClient.h"
#import "BRConstants.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

@interface BRBonjourOSCClient () <NSNetServiceDelegate, GCDAsyncSocketDelegate, F53OSCClientDelegate, F53OSCPacketDestination>
{
    F53OSCClient *_oscClient;
    F53OSCServer *_oscServer;
}

@end

@implementation BRBonjourOSCClient

- (instancetype)initWithServiceName: (NSString *) name
{
    self = [super init];
    if (self) {
        [self getIPAddress:YES];
        _serverIP = @"n/a";
        _channelNumber = [[name stringByReplacingOccurrencesOfString:kBonjourServiceNameTemplate withString:@""] intValue];
        
        [self advertiseBonjourServiceWithName:name];
        _oscClient = [[F53OSCClient alloc] init];
        _oscServer = [[F53OSCServer alloc] init];
        [_oscServer setPort:OSC_RECEIVE_PORT];
        [_oscServer setDelegate:self];
        [_oscServer startListening];
    }
    return self;
}

#pragma mark - Bonjour methods

- (void) advertiseBonjourServiceWithName: (NSString *) serviceName
{
    if (_service)
    {
        [_service stop];
    }
    
    // Initialize GCDAsyncSocket
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // Start Listening for Incoming Connections
    NSError *error = nil;
    if ([self.socket acceptOnPort:0 error:&error]) {
        // Initialize Service
        self.service = [[NSNetService alloc] initWithDomain:kBonjourDomain
                                                       type:kBonjourServiceType
                                                       name:serviceName
                                                       port:[self.socket localPort]];
        
        // Configure Service
        [self.service setDelegate:self];
        
        // Publish Service
        [self.service publish];
        
        _connectionStatus = BRConnectionStatusPublishing;
        [_oscDelegate updateLogWithMessage:@"Publishing bonjour service" updateConnectionStatus:YES];
        
    } else {
        DDLogVerbose(@"Unable to create socket. Error %@ with user info %@.", error, [error userInfo]);
        
        _connectionStatus = BRConnectionStatusBonjourFailure;
        [_oscDelegate updateLogWithMessage:@"Failed to publish bonjour service" updateConnectionStatus:YES];
    }
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)socket didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    DDLogVerbose(@"Accepted New Socket from %@:%hu", [newSocket connectedHost], [newSocket connectedPort]);
    
    // Socket
    [self setSocket:newSocket];
    
    // Read Data from Socket
    [newSocket readDataToLength:sizeof(uint64_t) withTimeout:-1.0 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)error {
    DDLogVerbose(@"%s", __PRETTY_FUNCTION__);
    
    if (self.socket == socket) {
        [self.socket setDelegate:nil];
        [self setSocket:nil];
    }
}

#pragma mark - Bonjour delegate methods

- (void)netServiceDidPublish:(NSNetService *)service
{
    DDLogVerbose(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)", [service domain], [service type], [service name], (int)[service port]);
    
    _connectionStatus = BRConnectionStatusWaitingForServer;
    
    [_oscDelegate updateLogWithMessage:[NSString stringWithFormat:@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i) \n Waiting for server...", [service domain], [service type], [service name], (int)[service port]] updateConnectionStatus:YES];
}

- (void)netService:(NSNetService *)service didNotPublish:(NSDictionary *)errorDict
{
    DDLogVerbose(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@", [service domain], [service type], [service name], errorDict);
    
    _connectionStatus = BRConnectionStatusBonjourFailure;
    
    [_oscDelegate updateLogWithMessage:[NSString stringWithFormat:@"Failed to Publish Bonjour Service: domain(%@) type(%@) name(%@) - %@", [service domain], [service type], [service name], errorDict] updateConnectionStatus:YES];
}

#pragma mark - OSC methods

- (void) connectToStreamingServer
{
    [self sendOSCMessageWithPattern:[NSString stringWithFormat:@"%@%i", kOSCPatternClientStream, _channelNumber]
                       andArguments:@[kOSCMessageConnect, OSC_UDPRECEIVE_PORT, _localIP]];
}

- (void) disconnectFromStreamingServer
{
    [self sendOSCMessageWithPattern:[NSString stringWithFormat:@"%@%i", kOSCPatternClientStream, _channelNumber]
                       andArguments:@[kOSCMessageDisconnect]];
}

- (void) sendOSCMessageWithPattern: (NSString *) pattern
                      andArguments: (NSArray *) arguments
{
    F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:pattern arguments:arguments];
    [_oscClient sendPacket:message toHost:_serverIP onPort:OSC_PATCH_RECEIVE_PORT];
}

// OSC delegate method

- (void) takeMessage:(F53OSCMessage *)message
{
    // other messages so far are simple connect/disconnect confirmations
    if ([message.addressPattern isEqualToString:kOSCPatternServerIP])
    {
        _serverIP = [message.arguments firstObject];
        _connectionStatus = BRConnectionStatusServerFound;
    }
    else if ([message.addressPattern isEqualToString:kOSCPatternConnect])
    {
        _connectionStatus = BRConnectionStatusConnected;
    }
    else if ([message.addressPattern isEqualToString:kOSCPatternDisconnect])
    {
        _connectionStatus = BRConnectionStatusDisconnected;
    }
    
    [_oscDelegate receiveOSCMessage:message];
}

#pragma mark - Getting IP address

- (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    
    address = [addresses objectForKey:@"en0/ipv4"];
    _localIP = address;
    
    return address ? address : @"0.0.0.0";
}

- (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

@end
