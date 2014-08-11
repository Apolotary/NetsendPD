//
//  MetatoneNetworkManager.m
//  Metatone
//
//  Created by Charles Martin on 10/04/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//  Modified January 2014 to work with F53OSC
//

#import "MetatoneNetworkManager.h"
#define DEFAULT_PORT 51200
#define DEFAULT_ADDRESS @"10.0.1.2"
#define METATONE_SERVICE_TYPE @"_metatoneapp._udp."
#define OSCLOGGER_SERVICE_TYPE @"_osclogger._udp."

@implementation MetatoneNetworkManager
// Designated Initialiser
-(MetatoneNetworkManager *) initWithDelegate: (id<MetatoneNetworkManagerDelegate>) delegate shouldOscLog: (bool) osclogging {
    self = [super init];
    
    self.delegate = delegate;
    self.deviceID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    self.appID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    self.oscLogging = osclogging;
    self.loggingIPAddress = DEFAULT_ADDRESS;
    self.loggingPort = DEFAULT_PORT;
    self.localIPAddress = [MetatoneNetworkManager getIPAddress];

    
    // Setup OSC Client
    self.oscClient = [[F53OSCClient alloc] init];
    [self.oscClient setHost:self.loggingIPAddress];
    [self.oscClient setPort:self.loggingPort];
    [self.oscClient connect];
    
    // Setup OSC Server
    self.oscServer = [[F53OSCServer alloc] init];
    [self.oscServer setDelegate:self];
    [self.oscServer setPort:DEFAULT_PORT];
    [self.oscServer startListening];
    
    // register with Bonjour
    self.metatoneNetService = [[NSNetService alloc]
                               initWithDomain:@""
                               type:METATONE_SERVICE_TYPE
                               name:[UIDevice currentDevice].name
                               port:DEFAULT_PORT];
    if (self.metatoneNetService != nil) {
        [self.metatoneNetService setDelegate: self];
        [self.metatoneNetService publishWithOptions:0];
        NSLog(@"NETWORK MANAGER: Metatone NetService Published - name: %@", [UIDevice currentDevice].name);
        
    }
    
    
    if (self.oscLogging) {
        // try to find an OSC Logger to connect to (but only if "oscLogging" is set).
        NSLog(@"NETWORK MANAGER: Browsing for OSC Logger Services...");
        self.oscLoggerServiceBrowser  = [[NSNetServiceBrowser alloc] init];
        [self.oscLoggerServiceBrowser setDelegate:self];
        [self.oscLoggerServiceBrowser searchForServicesOfType:OSCLOGGER_SERVICE_TYPE
                                                     inDomain:@"local."];
    }
    
    // try to find Metatone Apps to connect to (always do this)
    NSLog(@"NETWORK MANAGER: Browsing for Metatone App Services...");
    self.metatoneServiceBrowser  = [[NSNetServiceBrowser alloc] init];
    [self.metatoneServiceBrowser setDelegate:self];
    [self.metatoneServiceBrowser searchForServicesOfType:METATONE_SERVICE_TYPE
                                                inDomain:@"local."];
    return self;
}

-(void) stopSearches
{
    [self.metatoneServiceBrowser stop];
    [self.oscLoggerServiceBrowser stop];
    [self.remoteMetatoneIPAddresses removeAllObjects];
    [self.remoteMetatoneNetServices removeAllObjects];
    //[self.connection disconnect];
    [self.oscClient disconnect];
}

#pragma mark Instantiation
-(NSMutableArray *) remoteMetatoneNetServices {
    if (!_remoteMetatoneNetServices) _remoteMetatoneNetServices = [[NSMutableArray alloc] init];
    return _remoteMetatoneNetServices;
}

-(NSMutableArray *) remoteMetatoneIPAddresses {
    if (!_remoteMetatoneIPAddresses) _remoteMetatoneIPAddresses = [[NSMutableArray alloc] init];
    return _remoteMetatoneIPAddresses;
}

# pragma mark NetServiceBrowserDelegate Methods

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict {
    NSLog(@"NETWORK MANAGER: ERROR: Did not search for OSC Logger");
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    
    if ([[aNetService type] isEqualToString:METATONE_SERVICE_TYPE]) {
        if ([aNetService isEqual:self.metatoneNetService]) {
            NSLog(@"NETWORK MANAGER: Found own metatone service - ignoring.");
            return;
        }
        [aNetService setDelegate:self];
        [aNetService resolveWithTimeout:5.0];
        [self.remoteMetatoneNetServices addObject:aNetService];
    }
    
    if ([[aNetService type] isEqualToString:OSCLOGGER_SERVICE_TYPE]) {
        self.oscLoggerService = aNetService;
        [self.oscLoggerService setDelegate:self];
        [self.oscLoggerService resolveWithTimeout:5.0];
        //TODO: sort out case of multiple OSC Loggers.
    }
}

-(void)netServiceDidResolveAddress:(NSNetService *)sender {
    NSString* firstAddress;
    int firstPort;
    
    for (NSData* data in [sender addresses]) {
        char addressBuffer[100];
        struct sockaddr_in* socketAddress = (struct sockaddr_in*) [data bytes];
        int sockFamily = socketAddress->sin_family;
        if (sockFamily == AF_INET || sockFamily == AF_INET6) {
            const char* addressStr = inet_ntop(sockFamily,
                                               &(socketAddress->sin_addr), addressBuffer,
                                               sizeof(addressBuffer));
            int port = ntohs(socketAddress->sin_port);
            if (addressStr && port) {
                NSLog(@"NETWORK MANAGER: Resolved service of type %@ at %s:%d - %@",
                      [sender type],
                      addressStr,
                      port,
                      sender.hostName);
                firstAddress = [NSString stringWithFormat:@"%s",addressStr];
                firstPort = port;
                break;
            }
        }
    }
    
    if ([sender.type isEqualToString:OSCLOGGER_SERVICE_TYPE] && firstAddress && firstPort) {
        self.loggingHostname = sender.hostName;
        self.loggingIPAddress = firstAddress;
        self.loggingPort = firstPort;
        
        [self.delegate loggingServerFoundWithAddress:self.loggingIPAddress
                                             andPort:(int)self.loggingPort
                                         andHostname:self.loggingHostname];
        [self sendMessageOnline];
        NSLog(@"NETWORK MANAGER: Resolved and Connected to an OSC Logger Service.");
    }
    
    if ([sender.type isEqualToString:METATONE_SERVICE_TYPE] && firstAddress && firstPort) {
        // Save the found address.
        // Need to also check if address is already in the array.
        if (![firstAddress isEqualToString:self.localIPAddress] && ![firstAddress isEqualToString:@"127.0.0.1"]) {
            [self.remoteMetatoneIPAddresses addObject:@[firstAddress,[NSNumber numberWithInt:firstPort]]];
            [self.delegate metatoneClientFoundWithAddress:firstAddress andPort:firstPort andHostname:sender.hostName];
            NSLog(@"NETWORK MANAGER: Resolved and Connected to a MetatoneApp Service.");
        }
    }
}


-(void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser {
    [self.delegate searchingForLoggingServer];
}

-(void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser {
    NSLog(@"NETWORK MANAGER: NetServiceBrowser stopped searching.");
    [self.delegate stoppedSearchingForLoggingServer];
}

# pragma mark OSC Sending Methods
-(void)sendMessageWithAccelerationX:(double)x Y:(double)y Z:(double)z
{
    NSArray *contents = @[self.deviceID,
                          [NSNumber numberWithFloat:x],
                          [NSNumber numberWithFloat:y],
                          [NSNumber numberWithFloat:z]];
    F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:@"/metatone/acceleration"
                                                        arguments:contents];
    [self.oscClient sendPacket:message toHost:self.loggingIPAddress onPort:self.loggingPort];
}

-(void)sendMessageWithTouch:(CGPoint)point Velocity:(CGFloat)vel
{
    NSArray *contents = @[self.deviceID,
                          [NSNumber numberWithFloat:point.x],
                          [NSNumber numberWithFloat:point.y],
                          [NSNumber numberWithFloat:vel]];
    F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:@"/metatone/touch"
                                                            arguments:contents];
    [self.oscClient sendPacket:message toHost:self.loggingIPAddress onPort:self.loggingPort];
}

-(void)sendMesssageSwitch:(NSString *)name On:(BOOL)on
{
    NSString *switchState = on ? @"T" : @"F";
    NSArray *contents = @[self.deviceID,
                          name,
                          switchState];
    F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:@"/metatone/switch" arguments:contents];
    [self.oscClient sendPacket:message toHost:self.loggingIPAddress onPort:self.loggingPort];
}

-(void)sendMessageTouchEnded
{
    NSArray *contents = @[self.deviceID];
    F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:@"/metatone/touch/ended" arguments:contents];
    [self.oscClient sendPacket:message toHost:self.loggingIPAddress onPort:self.loggingPort];
}

-(void)sendMessageOnline
{
    NSArray *contents = @[self.deviceID,self.appID];
    F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:@"/metatone/online" arguments:contents];
    [self.oscClient sendPacket:message toHost:self.loggingIPAddress onPort:self.loggingPort];
}

-(void)sendMessageOffline
{
    NSArray *contents = @[self.deviceID,self.appID];
    F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:@"/metatone/offline"
                                                            arguments:contents];
    [self.oscClient sendPacket:message toHost:self.loggingIPAddress onPort:self.loggingPort];
}


-(void)sendMetatoneMessage:(NSString *)name withState:(NSString *)state {
    NSArray *contents = @[self.deviceID,
                          name,
                          state];
    F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:@"/metatone/app"
                                                            arguments:contents];

    // Log the metatone messages as well.
    [self.oscClient sendPacket:message toHost:self.loggingIPAddress onPort:self.loggingPort];
    
    // Send to each metatone app on the network.
    for (NSArray *address in self.remoteMetatoneIPAddresses) {
        [self.oscClient sendPacket:message
                            toHost:(NSString *)address[0]
                              onPort:[((NSNumber *)address[1]) integerValue]];
    }
}

#pragma mark OSC Receiving Methods
-(void)takeMessage:(F53OSCMessage *)message {
    // Received an OSC message
    if ([message.addressPattern isEqualToString:@"/metatone/app"]) {
        // InterAppmessage
        if ([message.arguments count] == 3) {
            if ([message.arguments[0] isKindOfClass:[NSString class]] &&
                [message.arguments[1] isKindOfClass:[NSString class]] &&
                [message.arguments[2] isKindOfClass:[NSString class]])
            {
                [self.delegate didReceiveMetatoneMessageFrom:message.arguments[0] withName:message.arguments[1] andState:message.arguments[2]];
            }
        }
    } else if ([message.addressPattern isEqualToString:@"/metatone/classifier/gesture"]) {
        // Gesture Message
        [self.delegate didReceiveGestureMessageFor:message.arguments[0] withClass:message.arguments[1]];
    } else if ([message.addressPattern isEqualToString:@"/metatone/classifier/ensemble/state"]) {
        //Ensemble State
        [self.delegate didReceiveEnsembleState:message.arguments[0] withSpread:message.arguments[1] withRatio:message.arguments[2]];
    } else if ([message.addressPattern isEqualToString:@"/metatone/classifier/ensemble/event/new_idea"]) {
        [self.delegate didReceiveEnsembleEvent:@"new_idea" forDevice:message.arguments[0] withMeasure:message.arguments[1]];
    } else if ([message.addressPattern isEqualToString:@"/metatone/classifier/ensemble/event/solo"]) {
        [self.delegate didReceiveEnsembleEvent:@"solo" forDevice:message.arguments[0] withMeasure:message.arguments[1]];
    } else if ([message.addressPattern isEqualToString:@"/metatone/classifier/ensemble/event/parts"]) {
        [self.delegate didReceiveEnsembleEvent:@"parts" forDevice:message.arguments[0] withMeasure:message.arguments[1]];
    }

}

#pragma mark IP Address Methods
// Get IP Address
+ (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

+ (NSString *)getLocalBroadcastAddress {
    NSArray *addressComponents = [[MetatoneNetworkManager getIPAddress] componentsSeparatedByString:@"."];
    NSString *address = nil;
    if ([addressComponents count] == 4)
    {
        address = @"";
        for (int i = 0; i<([addressComponents count] - 1); i++) {
            address = [address stringByAppendingString:addressComponents[i]];
            address = [address stringByAppendingString:@"."];
        }
        address = [address stringByAppendingString:@"255"];
    }
    return address;
}

@end
