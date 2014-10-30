//
//  BRViewController.m
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 5/18/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import "BRViewController.h"
#import "BRBonjourOSCClient.h"
#import "BRConstants.h"

#import "BRLogViewController.h"

@interface BRViewController () <UIAlertViewDelegate, BonjourOSCReceiverDelegate, BRLogViewControllerDelegate>
{
    BRBonjourOSCClient *_bonjourOSCClient;
    BRLogViewController *_logViewController;
    NSString *_stringChannel;
    NSString *_stringIP;
    NSString *_stringName;
    NSString *_stringLog;
    BRConnectionStatus _status;
    
    UIColor *_blueTextColor;
}

- (void) addObservers;
- (void) removeObservers;

- (void) dropBoxLinkedSuccessfully;
- (void) dropBoxUnlinkedSuccessfully;

- (void) updateStatuses;
- (void) loadLogViewController;

@end

@implementation BRViewController

#pragma mark - Working with observers

- (void) addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropBoxLinkedSuccessfully) name:kNotificationDropboxLinked object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropBoxUnlinkedSuccessfully) name:kNotificationDropboxUnLinked object:nil];
}

- (void) removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationDropboxLinked object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationDropboxUnLinked object:nil];
}

#pragma mark - Dropbox notifications

- (void) dropBoxLinkedSuccessfully
{
    // dropbox linked, start advertising service
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"Dropbox linked successfully, now pick a channel and press advertise button to start" delegate:nil cancelButtonTitle:@"Got it" otherButtonTitles:nil, nil];
    [alert show];
    [_buttonLinkDropBox setTitle:@"Unlink Dropbox" forState:UIControlStateNormal];
}

- (void) dropBoxUnlinkedSuccessfully
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"Dropbox unlinked successfully, you need to login again to upload data" delegate:nil cancelButtonTitle:@"Got it" otherButtonTitles:nil, nil];
    [alert show];
    [_buttonLinkDropBox setTitle:@"Link Dropbox" forState:UIControlStateNormal];
}

#pragma mark - Showing messages

- (void) showDropboxLinkMessage
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Message" message:@"We will use Dropbox to gather error data, please log into your account" delegate:self cancelButtonTitle:@"Log in" otherButtonTitles:nil, nil];
    alertView.tag = 1;
    [alertView show];
}

- (void) showDropboxUnLinkMessage
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Message" message:@"Do you really want to unlink your Dropbox account?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    alertView.tag = 1;
    [alertView show];
}

#pragma mark - Updating statuses 

- (void) updateStatuses
{
    _stringIP = _bonjourOSCClient.localIP;
    _stringName = _bonjourOSCClient.service.name;
    _status = _bonjourOSCClient.connectionStatus;
}

#pragma mark - OSCDelegate

- (void)receiveOSCMessage: (F53OSCMessage *) message
{
    NSString *oscMessage = [NSString stringWithFormat:@"OSC message: %@ %@", message.addressPattern, message.arguments.description];
    [self updateLogWithMessage:oscMessage updateConnectionStatus:YES];
}

- (void)updateLogWithMessage: (NSString *) message
      updateConnectionStatus: (BOOL) shouldUpdate
{
    if (shouldUpdate)
    {
        [self updateStatuses];
    }
    
    _stringLog = [NSString stringWithFormat:@"%@ \n %@", _stringLog, message];
}


#pragma mark - Button methods

- (void) updateBackgroundForChannelButton: (UIButton *) button
{
    [button setBackgroundColor:_blueTextColor];
    [button setTintColor:[UIColor whiteColor]];
    
    [_buttonAdvertise setEnabled:YES];
    [_buttonConnect setEnabled:YES];
    [_buttonDisconnect setEnabled:YES];
    
    for (UIButton *channelButton in _channelButtons)
    {
        if (![button isEqual:channelButton])
        {
            [channelButton setBackgroundColor:[UIColor clearColor]];
            [channelButton setTintColor:_blueTextColor];
        }
    }
}

-(IBAction)channelButtonPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *senderButton = (UIButton *) sender;
        _stringChannel = senderButton.titleLabel.text;
        [self updateBackgroundForChannelButton:senderButton];
    }
}

-(IBAction)advertiseButtonPressed:(id)sender
{
    _bonjourOSCClient = [[BRBonjourOSCClient alloc] initWithServiceName:[NSString stringWithFormat:@"%@%@", kBonjourServiceNameTemplate, _stringChannel]];
    [_bonjourOSCClient setOscDelegate:self];
}

-(IBAction)connectButtonPressed:(id)sender
{
    [_bonjourOSCClient connectToStreamingServer];
}

-(IBAction)disconnectButtonPressed:(id)sender
{
    [_bonjourOSCClient disconnectFromStreamingServer];
}

-(IBAction)dropBoxButtonPressed:(id)sender
{
    if ([[DBSession sharedSession] isLinked])
    {
        [self showDropboxUnLinkMessage];
    }
    else
    {
        [self showDropboxLinkMessage];
    }
}

-(IBAction)logButtonPressed:(id)sender
{
    
}

#pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Dropbox login
    if (alertView.tag == 1)
    {
        [[DBSession sharedSession] linkFromController:self];
    }
    else if (alertView.tag == 2 && buttonIndex != alertView.cancelButtonIndex)
    {
        [[DBSession sharedSession] unlinkAll];
    }
}

#pragma mark - Logviewcontroller methods and delegate

- (void) loadLogViewController
{
    
}

- (void) dismissLogButtonPressed
{
    
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addObservers];
    _stringChannel = @"1";
    _stringLog = @"";
    _blueTextColor = [UIColor colorWithRed:33.0/256.0 green:121.0/256.0 blue:250.0/256.0 alpha:1.0];
    
    if (![[DBSession sharedSession] isLinked])
    {
        [self showDropboxLinkMessage];
    }
    else
    {
        [_buttonLinkDropBox setTitle:@"Unlink Dropbox" forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [self addObservers];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self removeObservers];
}

@end
