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

#define OSC_SEND_PORT 3000
#define OSC_RECEIVE_PORT 3001

extern NSString *const kBonjourDomain;
extern NSString *const kBonjourServiceType;

extern NSString *const kOSCPatternConnect;
extern NSString *const kOSCPatternDisconnect;
extern NSString *const kOSCPatternServerIP;

@interface BRConstants : NSObject

@end
