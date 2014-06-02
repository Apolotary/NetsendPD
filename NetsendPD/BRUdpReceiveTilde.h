//
//  BRUdpReceiveTilde.h
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 5/30/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

// obj-c workaround for [udpreceive~] object
// due to the problems with libpd not calling
// update cycle on udp objects when needed
//
// more info here: http://goo.gl/C6Xjbx

#import <Foundation/Foundation.h>

@interface BRUdpReceiveTilde : NSObject

- (void) connectToPort: (uint16_t) portNum;

@end
