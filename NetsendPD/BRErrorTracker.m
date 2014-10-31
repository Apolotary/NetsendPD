//
//  BRErrorTracker.m
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 10/28/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import "BRErrorTracker.h"
#import <CHCSVParser.h>

@interface BRErrorTracker () <DBRestClientDelegate>
{
    NSMutableArray *_errorTimeStampArray;
    DBRestClient *_restClient;
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
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
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

- (void)writeCSVAtPath: (NSString *)filePath
{
    CHCSVWriter * csvWriter = [[CHCSVWriter alloc] initForWritingToCSVFile:filePath];
    
    NSMutableArray *timeArray = [NSMutableArray arrayWithObject:@"0"];
    NSMutableArray *errorArray = [NSMutableArray arrayWithObject:@"0"];
    
    NSTimeInterval timeDifference = _endTime - _startTime;
    
    for (int i = 0; i <= timeDifference; i++)
    {
        [timeArray addObject:[NSString stringWithFormat:@"%i", i]];
        
        NSNumber *adjustedTime = [NSNumber numberWithDouble:(_startTime + (double)i)];
        
        if ([_errorTimeStampArray containsObject:adjustedTime])
        {
            [errorArray addObject:@"1"];
        }
        else
        {
            [errorArray addObject:@"0"];
        }
    }
    
    for (NSInteger i = 0; i < timeArray.count; i++)
    {
        [csvWriter writeField:[timeArray objectAtIndex:i]];
        [csvWriter writeField:[errorArray objectAtIndex:i]];
        [csvWriter finishLine];
    }
}

- (void)writeAndUploadErrorReports
{
    NSString *filename = [NSString stringWithFormat:@"%@_%f_%f", _clientName, _startTime, _endTime];
    NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *localPath = [localDir stringByAppendingPathComponent:filename];
    [self writeCSVAtPath:localPath];
    
    // Upload file to Dropbox
    NSString *destDir = @"/";
    [_restClient uploadFile:filename toPath:destDir withParentRev:nil fromPath:localPath];
}

#pragma mark - Dropbox callbacks

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata
{
    DDLogVerbose(@"File uploaded successfully to path: %@", metadata.path);
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    DDLogError(@"File upload failed with error: %@", error);
}


@end
