//
//  TSNLocalPeerTableViewCell.h
//  ThaliBubbles
//
//  Created by Brian Lambert on 4/13/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

// TSNLocalPeerTableViewCell interface.
@interface TSNLocalPeerTableViewCell : UITableViewCell

// Class initializer.
- (instancetype)initWithMessage:(NSString *)message;

// Returns the height.
- (CGFloat)height;

@end
