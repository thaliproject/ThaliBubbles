//
//  TSNPeer.h
//  ThaliBubbles
//
//  Created by Brian Lambert on 3/30/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

// TSNPeer interface.
@interface TSNPeer : NSObject

// Properties.
@property (nonatomic, readonly) NSString * identifier;
@property (nonatomic, readonly) NSString * name;
@property (atomic) CLLocation * location;
@property (atomic) CLLocationDistance disance;
@property (atomic) NSDate * lastUpdated;

// Class initializer.
- (instancetype)initWithIdentifier:(NSString *)peerIdentifier
                              name:(NSString *)name
                          location:(CLLocation *)location
                          distance:(CLLocationDistance)distance;

@end
