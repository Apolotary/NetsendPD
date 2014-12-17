//
//  BRViewController.m
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 5/18/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import "BRViewController.h"
#import "BRBonjourOSCClient.h"
#import "BRPdManager.h"
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
    
    NSTimer *_errorTimer;
    
    UIColor *_blueTextColor;
    NSTimeInterval _currentTime;
}

- (void)addObservers;
- (void)removeObservers;

- (void) updateStatuses;
- (void) updateTrackingProgress:(id) sender;
- (void) startErrorTracking;

@end

@implementation BRViewController

#pragma mark - Updating statuses 

- (void) updateStatuses
{
    _stringIP = _bonjourOSCClient.localIP;
    _stringName = _bonjourOSCClient.service.name;
    _status = _bonjourOSCClient.connectionStatus;
}

- (void)printErrorInfo:(NSNotification *)notification
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Test Results" message:[NSString stringWithFormat:@"%@ : %@ \n %@ : %@ \n %@ : %@ \n %@ : %@", kErrorDictKeyOverflow, notification.userInfo[kErrorDictKeyOverflow], kErrorDictKeyUnderflow, notification.userInfo[kErrorDictKeyUnderflow], kErrorDictKeyTagError, notification.userInfo[kErrorDictKeyTagError], kErrorDictKeyPackets, notification.userInfo[kErrorDictKeyPackets]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

#pragma mark - Timer and Slider methods

- (void) updateTrackingProgress:(id) sender
{
    _currentTime += 1.0;
    [_progressTimeSlider setValue:_currentTime animated:YES];
    [_progressTimeLabel setText:[NSString stringWithFormat:@"%1.0fs", _currentTime]];
    
    if (_currentTime == ERROR_TRACKING_TIME)
    {
        [_errorTimer invalidate];
        
        [_progressTimeSlider setValue:0.0 animated:YES];
        [_progressTimeLabel setText:@"0.0"];
        
        [[BRPdManager sharedInstance] getErrorInfo];
    }
}

- (void) startErrorTracking
{
    [_progressTimeSlider setMinimumValue:0.0];
    [_progressTimeSlider setMaximumValue:ERROR_TRACKING_TIME];
    
    _currentTime = 0.0;
    _errorTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTrackingProgress:) userInfo:nil repeats:YES];
    [_errorTimer fire];
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
    NSString *clientName = [NSString stringWithFormat:@"%@%@", kBonjourServiceNameTemplate, _stringChannel];
    _bonjourOSCClient = [[BRBonjourOSCClient alloc] initWithServiceName:clientName];
    [_bonjourOSCClient setOscDelegate:self];
    [self startErrorTracking];
}

-(IBAction)connectButtonPressed:(id)sender
{
    [_bonjourOSCClient connectToStreamingServer];
}

-(IBAction)disconnectButtonPressed:(id)sender
{
    [_bonjourOSCClient disconnectFromStreamingServer];
}

-(IBAction)logButtonPressed:(id)sender
{
    if (!_logViewController)
    {
        _logViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"BRLogViewController"];
    }
    
    [_logViewController setupWithIP:_stringIP bonjourName:_stringName status:_status log:_stringLog andDelegate:self];
    [self presentViewController:_logViewController animated:YES completion:nil];
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

#pragma mark - Adding / Removing observers

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(printErrorInfo:) name:kNotificationInfoReceived object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationInfoReceived object:nil];
}

#pragma mark - BRLogViewControllerDelegate

- (void) dismissLogButtonPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _stringChannel = @"1";
    _stringLog = @"";
    _blueTextColor = [UIColor colorWithRed:33.0/256.0 green:121.0/256.0 blue:250.0/256.0 alpha:1.0];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self addObservers];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
