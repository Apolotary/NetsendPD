//
//  BRLogViewController.m
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 10/29/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import "BRLogViewController.h"


@implementation BRLogViewController

#pragma mark - Setup

- (void)setupWithIP:(NSString *) ipAddress
        bonjourName:(NSString *) bonjourName
             status:(BRConnectionStatus) status
                log:(NSString *) log
        andDelegate:(id<BRLogViewControllerDelegate>) newDelegate
{
    [self updateIPWithString:ipAddress];
    [self updateBonjourNameWithString:bonjourName];
    [self updateStatusWithStatus:status];
    [self updateLogWithString:log];
    _delegate = newDelegate;
}

#pragma mark - Action methods

- (IBAction)dismissButtonPressed:(id)sender
{
    [_delegate dismissLogButtonPressed];
}

#pragma mark - Update methods

- (void)updateLogWithString:(NSString *) newLogString
{
    [_logTextView setText:newLogString];
    [_logTextView scrollRangeToVisible:NSMakeRange([_logTextView.text length], 0)];
}

- (void)updateIPWithString:(NSString *) newIPString
{
    [_labelIP setText:[NSString stringWithFormat:@"Local IP: %@", newIPString]];
}

- (void)updateBonjourNameWithString:(NSString *) newBonjourString
{
    [_labelName setText:[NSString stringWithFormat:@"Bonjour name: %@", newBonjourString]];
}

- (void)updateStatusWithStatus:(BRConnectionStatus) connectionStatus
{
    if (connectionStatus == BRConnectionStatusConnected)
    {
        [_labelStatus setText:@"Connection status: Connected"];
    }
    else if (connectionStatus == BRConnectionStatusDisconnected)
    {
        [_labelStatus setText:@"Connection status: Disconnected"];
    }
    else if (connectionStatus == BRConnectionStatusWaitingForServer)
    {
        [_labelStatus setText:@"Connection status: Waiting for server"];
    }
    else if (connectionStatus == BRConnectionStatusPublishing)
    {
        [_labelStatus setText:@"Connection status: Publishing"];
    }
    else if (connectionStatus == BRConnectionStatusBonjourFailure)
    {
        [_labelStatus setText:@"Connection status: Bonjour failure"];
    }
    else if (connectionStatus == BRConnectionStatusServerFound)
    {
        [_labelStatus setText:@"Connection status: Found streaming server"];
    }
}

@end
