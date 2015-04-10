//
//  TSNAppContext.h
//  ThaliBubbles
//
//  Created by Brian Lambert on 3/25/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSNPeer.h"

// External declarations.
extern NSString * const TSNLocationUpdatedNotification;
extern NSString * const TSNPeersUpdatedNotification;

// TSNAppContext interface.
@interface TSNAppContext : NSObject

// Class singleton.
+ (instancetype)singleton;

// Starts communications.
- (void)startCommunications;

// Stops communications.
- (void)stopCommunications;

// Gets the peers.
- (NSArray *)peers;

// Sends a message.
- (void)sendMessage:(NSString *)message;

@end
