//
//  BRLogViewController.h
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 10/29/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BRBonjourOSCClient.h"
#import "BRConstants.h"

@protocol BRLogViewControllerDelegate <NSObject>

- (void) dismissLogButtonPressed;

@end

@interface BRLogViewController : UIViewController
{
    IBOutlet UILabel *_labelIP;
    IBOutlet UILabel *_labelStatus;
    IBOutlet UILabel *_labelName;
    IBOutlet UITextView *_logTextView;
}

@property (nonatomic, weak) id<BRLogViewControllerDelegate> delegate;

- (void)setupWithIP:(NSString *) ipAddress
        bonjourName:(NSString *) bonjourName
             status:(BRConnectionStatus) status
                log:(NSString *) log
        andDelegate:(id<BRLogViewControllerDelegate>) newDelegate;

- (IBAction)dismissButtonPressed:(id)sender;

- (void)updateLogWithString:(NSString *) newLogString;
- (void)updateIPWithString:(NSString *) newIPString;
- (void)updateBonjourNameWithString:(NSString *) newBonjourString;
- (void)updateStatusWithStatus:(BRConnectionStatus) connectionStatus;

@end
