//
//  BRConstants.h
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 8/11/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

#define OSC_SEND_PORT 6000
#define OSC_RECEIVE_PORT 6001

#define OSC_PATCH_RECEIVE_PORT 3002
#define OSC_UDPRECEIVE_PORT @"1349"

#define ERROR_TRACKING_TIME 60 // seconds

extern NSString *const kNotificationInfoReceived;

extern NSString *const kBonjourDomain;
extern NSString *const kBonjourServiceType;
extern NSString *const kBonjourServiceNameTemplate;

extern NSString *const kOSCPatternConnect;
extern NSString *const kOSCPatternDisconnect;
extern NSString *const kOSCPatternServerIP;
extern NSString *const kOSCPatternClientStream;

extern NSString *const kOSCMessageConnect;
extern NSString *const kOSCMessageDisconnect;

extern NSString *const kErrorDictKeyOverflow;
extern NSString *const kErrorDictKeyUnderflow;
extern NSString *const kErrorDictKeyTagError;
extern NSString *const kErrorDictKeyPackets;

@interface BRConstants : NSObject

@end
