//
//  TSNNearbyPeerEnteredTableViewCell.h
//  ThaliBubbles
//
//  Created by Brian Lambert on 4/13/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "TSNNearbyPeerTableViewCell.h"
#import "TSNPeer.h"

// TSNNearbyPeerEnteredTableViewCell interface.
@interface TSNNearbyPeerEnteredTableViewCell : TSNNearbyPeerTableViewCell

// Class initializer.
- (instancetype)initWithPeer:(TSNPeer *)peer;

@end
