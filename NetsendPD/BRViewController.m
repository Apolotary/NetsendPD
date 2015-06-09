//
//  BRViewController.m
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 5/18/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <EstimoteSDK/ESTBeaconManager.h>

#import "BRViewController.h"
#import "BRBonjourOSCClient.h"
#import "BRPdManager.h"
#import "BRConstants.h"

#import "BRLogViewController.h"

#import "APLMonitoringViewController.h"
#import "APLDefaults.h"

@interface BRViewController () <UIAlertViewDelegate, BonjourOSCReceiverDelegate, BRLogViewControllerDelegate, CLLocationManagerDelegate, ESTBeaconManagerDelegate>
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

@property CLBeacon *chosenBeacon;
@property NSMutableDictionary *beacons;
@property CLLocationManager *locationManager;
@property (nonatomic, strong) ESTBeaconManager  *beaconManager;
@property (nonatomic, strong) CLBeaconRegion   *beaconRegion;

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
        _bonjourOSCClient.channelNumber = senderButton.titleLabel.text.intValue;
        [self updateBackgroundForChannelButton:senderButton];
    }
}

-(IBAction)advertiseButtonPressed:(id)sender
{
    NSString *clientName = [NSString stringWithFormat:@"%@%@", kBonjourServiceNameTemplate, _stringChannel];
    
    if (_bonjourOSCClient)
    {
        [_bonjourOSCClient advertiseBonjourServiceWithName:clientName];
    }
    else
    {
        _bonjourOSCClient = [[BRBonjourOSCClient alloc] initWithServiceName:clientName];
        [_bonjourOSCClient setOscDelegate:self];
    }

//    [self startErrorTracking];
    [_channelSelectionLabel setText:@"Channel selection: Manual"];
}

-(IBAction)connectButtonPressed:(id)sender
{
    [_bonjourOSCClient connectToStreamingServer];
    [_channelSelectionLabel setText:@"Channel selection: Manual"];
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

-(IBAction)setupButtonPressed:(id)sender
{
    APLMonitoringViewController *monitoringVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MonitoringVC"];
    UINavigationController *navigationVC = [[UINavigationController alloc] initWithRootViewController:monitoringVC];
    [self presentViewController:navigationVC animated:YES completion:nil];
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

#pragma mark - CLLocationManager callback

- (BOOL)isBeaconEqualToChosenBeacon:(CLBeacon *)newBeacon
{
    if (newBeacon.major.intValue == self.chosenBeacon.major.intValue && newBeacon.minor.intValue == self.chosenBeacon.minor.intValue)
    {
        return YES;
    }
    return NO;
}

- (void)updateChoseBeacon:(CLBeacon *)newBeacon
{
    if (newBeacon.minor.intValue != _bonjourOSCClient.channelNumber)
    {
        [_bonjourOSCClient disconnectFromStreamingServer];
        
        self.chosenBeacon = newBeacon;
        
        [_iBeaconLabel setText:[NSString stringWithFormat:@"iBeacon ch #: %i", self.chosenBeacon.minor.intValue]];
        [_channelSelectionLabel setText:@"Channel selection: Automatic"];
        _stringChannel = [NSString stringWithFormat:@"%i", self.chosenBeacon.minor.intValue];
        [_bonjourOSCClient setChannelNumber:self.chosenBeacon.minor.intValue];
        [_bonjourOSCClient connectToStreamingServer];
    }
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _stringChannel = @"1";
    _stringLog = @"";
    _blueTextColor = [UIColor colorWithRed:33.0/256.0 green:121.0/256.0 blue:250.0/256.0 alpha:1.0];
    
    self.beacons = [[NSMutableDictionary alloc] init];
    
    // This location manager will be used to demonstrate how to range beacons.
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
    {
        [self.locationManager requestAlwaysAuthorization];
        [self.locationManager startUpdatingLocation];
    }
    
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"] identifier:@"RegionIdentifier"];
    
    [self.beaconManager startRangingBeaconsInRegion:self.beaconRegion];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.beaconManager startRangingBeaconsInRegion:self.beaconRegion];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Stop ranging when the view goes away.
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
    
    [self.beaconManager stopRangingBeaconsInRegion:self.beaconRegion];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)beaconManager:(id)manager
      didRangeBeacons:(NSArray *)beacons
             inRegion:(CLBeaconRegion *)region
{
    for (CLBeacon *iBeacon in beacons)
    {
        if (iBeacon.proximity == CLProximityImmediate)
        {
            if (self.chosenBeacon)
            {
                if (![self isBeaconEqualToChosenBeacon:iBeacon])
                {
                    [self updateChoseBeacon:iBeacon];
                    break;
                }
            }
            else
            {
                [self updateChoseBeacon:iBeacon];
                break;
            }
        }
    }
}

@end
