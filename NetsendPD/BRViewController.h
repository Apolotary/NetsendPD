//
//  BRViewController.h
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 5/18/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BRViewController : UIViewController
{
    IBOutlet UILabel *_progressTimeLabel;
    IBOutlet UISlider *_progressTimeSlider;
    
    IBOutlet UIButton *_buttonAdvertise;
    IBOutlet UIButton *_buttonConnect;
    IBOutlet UIButton *_buttonDisconnect;
    IBOutlet UIButton *_buttonLinkDropBox;
    
    IBOutletCollection(UIButton) NSArray *_channelButtons;
}

-(IBAction)channelButtonPressed:(id)sender;

-(IBAction)advertiseButtonPressed:(id)sender;
-(IBAction)connectButtonPressed:(id)sender;
-(IBAction)disconnectButtonPressed:(id)sender;

-(IBAction)dropBoxButtonPressed:(id)sender;
-(IBAction)logButtonPressed:(id)sender;

@end
