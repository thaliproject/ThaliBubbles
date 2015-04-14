//
//  TSNNearbyPeerExitedTableViewCell.m
//  ThaliBubbles
//
//  Created by Brian Lambert on 4/13/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "TSNNearbyPeerExitedTableViewCell.h"

// TSNNearbyPeerExitedTableViewCell (Internal) interface.
@interface TSNNearbyPeerExitedTableViewCell (Internal)
@end

// TSNNearbyPeerExitedTableViewCell implementation.
@implementation TSNNearbyPeerExitedTableViewCell

// Class initializer.
- (instancetype)initWithPeer:(TSNPeer *)peer
{
    // Initialize superclass.
    self = [super initWithPeer:peer
                       message:@"Exited the Bubble"];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Done.
    return self;
}

@end

// TSNNearbyPeerExitedTableViewCell (Internal) implementation.
@implementation TSNNearbyPeerExitedTableViewCell (Internal)
@end
