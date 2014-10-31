//
//  BRErrorTracker.h
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 10/28/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BRErrorTracker : NSObject

// set this property to enable/disable error tracking
@property BOOL isTrackingErrors;
@property NSTimeInterval startTime;
@property NSTimeInterval endTime;
@property NSString *clientName;

+ (instancetype)sharedInstance;

- (void)addErrorWithTimeStamp:(NSTimeInterval) errorTimeStamp;
- (void)writeAndUploadErrorReports;

@end
