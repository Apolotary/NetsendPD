//
//  BRViewController.m
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 5/18/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import "BRViewController.h"

#import "BRUdpReceiveTilde.h"
#import "BRNetsendConstants.h"

@interface BRViewController ()
{
    BRUdpReceiveTilde *_udpReceive;
}

@end

@implementation BRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//    _udpReceive = [[BRUdpReceiveTilde alloc] init];
//    [_udpReceive connectToPort:kDefaultUdpPortNumber];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
