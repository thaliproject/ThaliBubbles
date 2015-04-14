//
//  TSNNearbyPeerTableViewCell.h
//  ThaliBubbles
//
//  Created by Brian Lambert on 3/25/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSNPeer.h"

// TSNNearbyPeerTableViewCell interface.
@interface TSNNearbyPeerTableViewCell : UITableViewCell

// Class initializer.
- (instancetype)initWithPeer:(TSNPeer *)peer
                     message:(NSString *)message;

// Returns the height.
- (CGFloat)height;

@end
