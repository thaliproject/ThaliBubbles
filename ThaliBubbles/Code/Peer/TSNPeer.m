//
//  TSNPeer.m
//  ThaliBubbles
//
//  Created by Brian Lambert on 3/30/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "TSNPeer.h"

// TSNPeer (Internal) interface.
@interface TSNPeer (Internal)
@end

// TSNPeer implementation.
@implementation TSNPeer
{
@private
}

// Class initializer.
- (instancetype)initWithPeerName:(NSString *)peerName
                        location:(CLLocation *)location
                        distance:(CLLocationDistance)distance
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    _peerName = peerName;
    _location = location;
    _disance = distance;
    _lastUpdated = [[NSDate alloc] init];
    
    // Done.
    return self;
}

@end

// TSNPeer (Internal) implementation.
@implementation TSNPeer (Internal)
@end
