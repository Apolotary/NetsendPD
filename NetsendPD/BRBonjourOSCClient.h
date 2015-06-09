//
//  BRBonjourOSCClient.h
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 8/9/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

// Class that advertises client via bonjour protocol
// And communicates via OSC protocol

#import <Foundation/Foundation.h>
#import "F53OSC.h"

typedef enum BRConnectionStatus : NSUInteger {
    BRConnectionStatusConnected = 0,        // connected / disconnected to streaming server
    BRConnectionStatusDisconnected = 1,
    
    BRConnectionStatusWaitingForServer = 2, // waiting until server finds this client via bonjour
    BRConnectionStatusServerFound = 3,      // server found the client
    
    BRConnectionStatusPublishing = 4,       // published or
    BRConnectionStatusBonjourFailure = 5    // failed to publish bonjour service
} BRConnectionStatus;

@protocol BonjourOSCReceiverDelegate <NSObject>

- (void)receiveOSCMessage: (F53OSCMessage *) message; // strictly OSC-messages, which are parsed later
- (void)updateLogWithMessage: (NSString *) message
      updateConnectionStatus: (BOOL) shouldUpdate;   // general debug messages

@end

@interface BRBonjourOSCClient : NSObject

@property (strong, nonatomic) NSNetService *service;
@property (strong, nonatomic) GCDAsyncSocket *socket;

@property (strong, nonatomic) NSString *localIP;
@property (strong, nonatomic) NSString *serverIP;

@property int channelNumber;

@property (weak, nonatomic) id<BonjourOSCReceiverDelegate> oscDelegate;
@property BRConnectionStatus connectionStatus;

- (instancetype)initWithServiceName: (NSString *) name;

- (void) advertiseBonjourServiceWithName: (NSString *) serviceName;

// sends OSC message with connect/disconnect to streaming server
- (void) connectToStreamingServer;
- (void) disconnectFromStreamingServer;

- (void) sendOSCMessageWithPattern: (NSString *) pattern
                      andArguments: (NSArray *) arguments;

- (NSString *)getIPAddress:(BOOL)preferIPv4;

@end
