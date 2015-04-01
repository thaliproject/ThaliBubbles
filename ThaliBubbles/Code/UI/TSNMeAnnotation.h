//
//  TSNMeAnnotation.h
//  ThaliBubbles
//
//  Created by Brian Lambert on 3/28/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

// TSNMeAnnotation interface.
@interface TSNMeAnnotation : NSObject <MKAnnotation>

// Properties.
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString * title;
@property (nonatomic, readonly, copy) NSString * subtitle;

// Class initializer.
- (instancetype)init;

@end
