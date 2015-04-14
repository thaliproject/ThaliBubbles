//
//  TSNLocalPeerEnteredTableViewCell.m
//  ThaliBubbles
//
//  Created by Brian Lambert on 4/13/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "TSNLocalPeerEnteredTableViewCell.h"

// TSNLocalPeerEnteredTableViewCell (Internal) interface.
@interface TSNLocalPeerEnteredTableViewCell (Internal)
@end

// TSNLocalPeerEnteredTableViewCell implementation.
@implementation TSNLocalPeerEnteredTableViewCell
{
@private
}

// Class initializer.
- (instancetype)init
{
    // Initialize superclass.
    self = [super initWithMessage:@"Entered the Bubble"];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Done.
    return self;
}

@end

// TSNLocalPeerEnteredTableViewCell (Internal) implementation.
@implementation TSNLocalPeerEnteredTableViewCell (Internal)
@end
