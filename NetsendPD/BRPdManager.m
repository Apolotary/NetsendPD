//
//  BRPdManager.m
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 5/23/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import "BRPdManager.h"
#import "PdAudioController.h"
#import "PdBase.h"

extern void udpsend_tilde_setup(void);
extern void udpreceive_tilde_setup(void);

@interface BRPdManager () <PdReceiverDelegate>
{
    PdAudioController *_pdAudioController;
}

- (instancetype) init;

@end

@implementation BRPdManager

#pragma mark - Initialization

+ (instancetype)sharedInstance {
    static BRPdManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[BRPdManager alloc] init];
    });
    
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [PdBase initialize];
        [PdBase setDelegate:self];
        [PdBase computeAudio:YES];
        
        _pdAudioController = [[PdAudioController alloc] init];
        [_pdAudioController configurePlaybackWithSampleRate:44100
                                            numberChannels:2
                                              inputEnabled:YES
                                             mixingEnabled:NO];
        udpreceive_tilde_setup();
    }
    return self;
}

#pragma mark - Additional Pd setup methods

- (void) openPatch: (NSString *) patchName
          withPath: (NSString *) patchPath
{
    [PdBase openFile:patchName path:patchPath];
    [_pdAudioController setActive:YES];
}

- (void) setSoundActive: (BOOL) isActive
{
    [_pdAudioController setActive:isActive];
}

#pragma mark - Sending methods

- (void) sendBufferSize: (int) buffer
{
    [PdBase sendMessage:[NSString stringWithFormat:@"%i", buffer] withArguments:nil toReceiver:@"udpreceive_buffer"];
}

- (void) sendPortNumber: (int) portNumber
{
    [PdBase sendMessage:[NSString stringWithFormat:@"%i", portNumber] withArguments:nil toReceiver:@"udpreceive_port"];
}

#pragma mark - PDReceiverDelegate

- (void)receivePrint:(NSString *)message
{
    DDLogVerbose(@"Pd print: %@", message);
    
    
}

@end
