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

@interface BRViewController () <UIAlertViewDelegate, BonjourOSCReceiverDelegate>
{
    BRBonjourOSCClient *_bonjourOSCClient;
}

- (void) setConnectionStatus;
- (void) setupLabels;

@end

@implementation BRViewController

#pragma mark - UIButton Methods

-(IBAction)advertiseButtonPressed:(id)sender
{
    UIAlertView *serviceNameAlertView = [[UIAlertView alloc] initWithTitle:@"Bonjour service" message:@"Please input client number" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [serviceNameAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    
    UITextField *alertViewTextField = [serviceNameAlertView textFieldAtIndex:0];
    
    [alertViewTextField setKeyboardType:UIKeyboardTypeDecimalPad];
    [alertViewTextField setText:@"1"];
    [serviceNameAlertView show];
}

-(IBAction)connectButtonPressed:(id)sender
{
    [_bonjourOSCClient connectToStreamingServer];
}

-(IBAction)disconnectButtonPressed:(id)sender
{
    [_bonjourOSCClient disconnectFromStreamingServer];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *serviceName = [[alertView textFieldAtIndex:0] text];

    _bonjourOSCClient = [[BRBonjourOSCClient alloc] initWithServiceName:[NSString stringWithFormat:@"%@%@", kBonjourServiceNameTemplate, serviceName]];
    [_bonjourOSCClient setOscDelegate:self];
    [self setupLabels];
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
        [self setupLabels];
    }
    
    [_logTextView setText:[NSString stringWithFormat:@"%@ \n %@", _logTextView.text, message]];
    [_logTextView scrollRangeToVisible:NSMakeRange([_logTextView.text length], 0)];
}

#pragma mark - Setting up labels and statuses

- (void) setConnectionStatus
{
    if (_bonjourOSCClient.connectionStatus == BRConnectionStatusConnected)
    {
        [_labelStatus setText:@"Connection status: Connected"];
    }
    else if (_bonjourOSCClient.connectionStatus == BRConnectionStatusDisconnected)
    {
        [_labelStatus setText:@"Connection status: Disconnected"];
    }
    else if (_bonjourOSCClient.connectionStatus == BRConnectionStatusWaitingForServer)
    {
        [_labelStatus setText:@"Connection status: Waiting for server"];
    }
    else if (_bonjourOSCClient.connectionStatus == BRConnectionStatusPublishing)
    {
        [_labelStatus setText:@"Connection status: Publishing"];
    }
    else if (_bonjourOSCClient.connectionStatus == BRConnectionStatusBonjourFailure)
    {
        [_labelStatus setText:@"Connection status: Bonjour failure"];
    }
    else if (_bonjourOSCClient.connectionStatus == BRConnectionStatusServerFound)
    {
        [_labelStatus setText:@"Connection status: Found streaming server"];
    }
}

- (void) setupLabels
{
    [_labelLocalIP setText:[NSString stringWithFormat:@"Local IP: %@", _bonjourOSCClient.localIP]];
    [_labelServiceName setText:[NSString stringWithFormat:@"Bonjour name: %@", _bonjourOSCClient.service.name]];
    [self setConnectionStatus];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self advertiseButtonPressed:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
