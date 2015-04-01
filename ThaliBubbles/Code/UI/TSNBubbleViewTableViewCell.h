//
//  TSNBubbleViewTableViewCell.h
//  ThaliBubbles
//
//  Created by Brian Lambert on 3/25/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSNBubbleViewTableViewCellDelegate.h"

// TSNBubbleViewTableViewCell interface.
@interface TSNBubbleViewTableViewCell : UITableViewCell

// Properties.
@property (nonatomic, weak) id<TSNBubbleViewTableViewCellDelegate> delegate;
@property (nonatomic, readonly) CGFloat height;

// Class initializer.
- (instancetype)init;

@end
