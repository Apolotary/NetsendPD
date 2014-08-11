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
    IBOutlet UILabel *_labelStatus;
    IBOutlet UILabel *_labelLocalIP;
    IBOutlet UILabel *_labelServiceName;
    
    IBOutlet UITextView *_logTextView;
}

-(IBAction)advertiseButtonPressed:(id)sender;
-(IBAction)connectButtonPressed:(id)sender;
-(IBAction)disconnectButtonPressed:(id)sender;

@end
