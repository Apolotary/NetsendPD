//
//  BRUdpReceiveTilde.m
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 5/30/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import "BRUdpReceiveTilde.h"

#import "GCDAsyncUdpSocket.h"

@interface BRUdpReceiveTilde ()<GCDAsyncUdpSocketDelegate>
{
    GCDAsyncUdpSocket *_mainSocket;
}

@end

@implementation BRUdpReceiveTilde

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mainSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

#pragma mark - Connection methods

- (void) connectToPort: (uint16_t) portNum
{
    NSError *error;
    [_mainSocket bindToPort:portNum error:&error];
    
    if (error != nil)
    {
        DDLogVerbose(@"Error connecting to port: %@", error.description);
    }
    else
    {
        DDLogVerbose(@"Connected to port: %i", portNum);
        [_mainSocket beginReceiving:&error];
        
        if (error != nil)
        {
            DDLogVerbose(@"Can't receive from port %i, error: %@", portNum, error.description);
        }
    }
}

#pragma mark - GCDAsyncUdpSocketDelegate


/**
 * Called when the datagram with the given tag has been sent.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    
}

/**
 * Called if an error occurs while trying to send a datagram.
 * This could be due to a timeout, or something more serious such as the data being too large to fit in a sigle packet.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    
}

/**
 * Called when the socket has received the requested datagram.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    DDLogVerbose(@"Received data: %@ \n"
                  "From address: %@ \n"
                  "with context: %@",
                 data, address, filterContext);
}

/**
 * Called when the socket is closed.
 **/
- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{
    
}

@end
