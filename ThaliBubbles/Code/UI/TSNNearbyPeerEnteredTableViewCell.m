//
//  TSNNearbyPeerEnteredTableViewCell.m
//  ThaliBubbles
//
//  Created by Brian Lambert on 4/13/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIColor+Extensions.h>
#import <UIView+Extensions.h>
#import "TSNNearbyPeerEnteredTableViewCell.h"

// TSNNearbyPeerEnteredTableViewCell (Internal) interface.
@interface TSNNearbyPeerEnteredTableViewCell (Internal)
@end

// TSNNearbyPeerEnteredTableViewCell implementation.
@implementation TSNNearbyPeerEnteredTableViewCell

// Class initializer.
- (instancetype)initWithPeer:(TSNPeer *)peer
{
    // Initialize superclass.
    self = [super initWithPeer:peer message:@"Entered the Bubble"];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Done.
    return self;
}

@end

// TSNNearbyPeerEnteredTableViewCell (Internal) implementation.
@implementation TSNNearbyPeerEnteredTableViewCell (Internal)
@end
