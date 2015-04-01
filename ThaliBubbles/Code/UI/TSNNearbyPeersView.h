//
//  TSNNearbyPeersView.h
//  ThaliBubbles
//
//  Created by Brian Lambert on 3/28/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSNNearbyPeersViewDelegate.h"

// TSNNearbyPeersView interface.
@interface TSNNearbyPeersView : UIView

// Properties.
@property (nonatomic, weak) id<TSNNearbyPeersViewDelegate> delegate;

// Class initializer.
- (instancetype)initWithFrame:(CGRect)frame;

@end
