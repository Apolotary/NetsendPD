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

@interface BRViewController () <UIAlertViewDelegate, BonjourOSCReceiverDelegate>
{
    BRBonjourOSCClient *_bonjourOSCClient;
    BRLogViewController *_logViewController;
    NSString *_channelString;
}

- (void) addObservers;
- (void) removeObservers;

- (void) dropBoxLinkedSuccessfully;
- (void) dropBoxUnlinkedSuccessfully;

@end

@implementation BRViewController

//-(IBAction)advertiseButtonPressed:(id)sender
//{
//    UIAlertView *serviceNameAlertView = [[UIAlertView alloc] initWithTitle:@"Bonjour service" message:@"Please input client number" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//    [serviceNameAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
//    
//    UITextField *alertViewTextField = [serviceNameAlertView textFieldAtIndex:0];
//    
//    [alertViewTextField setKeyboardType:UIKeyboardTypeDecimalPad];
//    [alertViewTextField setText:@"1"];
//    [serviceNameAlertView show];
//}
//
//-(IBAction)connectButtonPressed:(id)sender
//{
//    [_bonjourOSCClient connectToStreamingServer];
//}
//
//-(IBAction)disconnectButtonPressed:(id)sender
//{
//    [_bonjourOSCClient disconnectFromStreamingServer];
//}
//
//#pragma mark - UIAlertViewDelegate
//
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    NSString *serviceName = [[alertView textFieldAtIndex:0] text];
//
//    _bonjourOSCClient = [[BRBonjourOSCClient alloc] initWithServiceName:[NSString stringWithFormat:@"%@%@", kBonjourServiceNameTemplate, serviceName]];
//    [_bonjourOSCClient setOscDelegate:self];
//    [self setupLabels];
//}
//
//#pragma mark - OSCDelegate
//
//- (void)receiveOSCMessage: (F53OSCMessage *) message
//{
//    NSString *oscMessage = [NSString stringWithFormat:@"OSC message: %@ %@", message.addressPattern, message.arguments.description];
//    [self updateLogWithMessage:oscMessage updateConnectionStatus:YES];
//}
//
//- (void)updateLogWithMessage: (NSString *) message
//      updateConnectionStatus: (BOOL) shouldUpdate
//{
//    if (shouldUpdate)
//    {
//        [self setupLabels];
//    }
//    
//    [_logTextView setText:[NSString stringWithFormat:@"%@ \n %@", _logTextView.text, message]];
//    [_logTextView scrollRangeToVisible:NSMakeRange([_logTextView.text length], 0)];
//}
//
//#pragma mark - Setting up labels and statuses
//
//- (void) setupLabels
//{
//    [_labelLocalIP setText:[NSString stringWithFormat:@"Local IP: %@", _bonjourOSCClient.localIP]];
//    [_labelServiceName setText:[NSString stringWithFormat:@"Bonjour name: %@", _bonjourOSCClient.service.name]];
//    [self setConnectionStatus];
//}
//

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
    
}

- (void) dropBoxUnlinkedSuccessfully
{
    
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

#pragma mark - IBActions

-(IBAction)channelButtonPressed:(id)sender
{
    
}

-(IBAction)advertiseButtonPressed:(id)sender
{
    
}

-(IBAction)connectButtonPressed:(id)sender
{
    
}

-(IBAction)disconnectButtonPressed:(id)sender
{
    
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

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
