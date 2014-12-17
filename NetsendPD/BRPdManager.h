//
//  BRPdManager.h
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 5/23/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

// Manages all Pd objects within an app

#import <Foundation/Foundation.h>

@interface BRPdManager : NSObject

+ (instancetype) sharedInstance;

- (void) openPatch: (NSString *) patchName
          withPath: (NSString *) patchPath;
- (void) setSoundActive: (BOOL) isActive;

- (void) sendBufferSize: (int) buffer;
- (void) sendPortNumber: (int) portNumber;
- (void) getErrorInfo;

@end
