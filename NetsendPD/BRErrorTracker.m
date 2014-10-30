//
//  BRErrorTracker.m
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 10/28/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import "BRErrorTracker.h"

@interface BRErrorTracker ()
{
    NSMutableArray *_errorTimeStampArray;
}

@end

@implementation BRErrorTracker

#pragma mark - Initialization

+ (instancetype)sharedInstance {
    static BRErrorTracker *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[BRErrorTracker alloc] init];
    });
    
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _errorTimeStampArray = [NSMutableArray array];
        _isTrackingErrors = NO;
    }
    return self;
}

- (void)addErrorWithTimeStamp:(NSTimeInterval) errorTimeStamp
{
    if (_isTrackingErrors)
    {
        [_errorTimeStampArray addObject:[NSNumber numberWithDouble:errorTimeStamp]];
    }
}

- (void)writeAndUploadErrorReports
{
    
}


@end
