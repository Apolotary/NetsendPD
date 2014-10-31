//
//  BRConstants.m
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 8/11/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import "BRConstants.h"

NSString *const kNotificationDropboxLinked = @"NotificationDropboxLinked";
NSString *const kNotificationDropboxUnLinked = @"NotificationDropboxUnLinked";
NSString *const kNotificationDropboxUploadSuccess = @"NotificationDropboxUploadSuccess";
NSString *const kNotificationDropboxUploadFailure = @"NotificationDropboxUploadFailure";

NSString *const kBonjourDomain = @"local.";
NSString *const kBonjourServiceType = @"_netsendpd._udp.";
NSString *const kBonjourServiceNameTemplate = @"streamingChannel_";

NSString *const kOSCPatternConnect = @"/connect";
NSString *const kOSCPatternDisconnect = @"/disconnect";
NSString *const kOSCPatternServerIP = @"/serverIP";
NSString *const kOSCPatternClientStream = @"/stream";

NSString *const kOSCMessageConnect = @"connect";
NSString *const kOSCMessageDisconnect = @"disconnect";

@implementation BRConstants

@end
