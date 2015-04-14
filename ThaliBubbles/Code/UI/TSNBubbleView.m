//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Microsoft
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  ThaliBubbles
//  TSNBubbleView.m
//

#import <UIColor+Extensions.h>
#import <UIView+Extensions.h>
#import <TSNThreading.h>
#import "TSNAppContext.h"
#import "TSNBubbleView.h"
#import "TSNLocalPeerEnteredTableViewCell.h"
#import "TSNNearbyPeerEnteredTableViewCell.h"
#import "TSNNearbyPeerExitedTableViewCell.h"

// Centers one thing (a) within another (b).
CG_INLINE CGFloat Center(CGFloat a, CGFloat b)
{
    return ((b - a) / 2.0);
}

// TSNBubbleView (UITableViewDataSource) interface.
@interface TSNBubbleView (UITableViewDataSource) <UITableViewDataSource>
@end

// TSNBubbleView (UITableViewDelegate) interface.
@interface TSNBubbleView (UITableViewDelegate) <UITableViewDelegate>
@end

// TSNBubbleView (Internal) interface.
@interface TSNBubbleView (Internal)

// buttonSendMessageTouchUpInside action.
- (void)buttonSendMessageTouchUpInsideAction:(UIButton *)sender;

// TSNPeerEnteredNotification callback.
- (void)peerEnteredNotificationCallback:(NSNotification *)notification;

// TSNPeerExitedNotification callback.
- (void)peerExitedNotificationCallback:(NSNotification *)notification;

// UIKeyboardWillShowNotification callback.
- (void)keyboardWillShowNotificationCallback:(NSNotification *)notification;

// UIKeyboardWillHideNotification callback.
- (void)keyboardWillHideNotificationCallback:(NSNotification *)notification;

@end

// TSNBubbleView implementation.
@implementation TSNBubbleView
{
@private
    // The container view.
    UIView * _viewContainer;
    
    // The table view.
    UITableView * _tableView;
    
    // The text field.
    UITextField * _textField;
    
    // The send button.
    UIButton * _buttonSend;
    
    // The bubble table view cells array.
    NSMutableArray * _bubbleTableViewCells;
}

// Class initializer.
- (instancetype)initWithFrame:(CGRect)frame
{
    // Initialize superclass.
    self = [super initWithFrame:frame];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    [self setOpaque:YES];
    [self setBackgroundColor:[UIColor colorWithRGB:0xecf0f1]];
    
    // Allocate and initialize the text field font. Calculate the text field height.
    UIFont * textFieldFont = [UIFont boldSystemFontOfSize:16.0];
    CGFloat textFieldHeight = [textFieldFont lineHeight] + 10.0;
    
    // Allocate, initialize, and add the container view. This view contains the table view,
    // text field, and send button and is resized in response to the keyboard.
    _viewContainer = [[UIView alloc] initWithFrame:[self bounds]];
    [_viewContainer setOpaque:YES];
    [_viewContainer setAutoresizesSubviews:YES];
    [_viewContainer setBackgroundColor:[UIColor colorWithRGB:0xecf0f1]];
    [self addSubview:_viewContainer];

    // Calculate the text are height and Y. This is the area below the table view that contains
    // the text field and the send button.
    CGFloat textAreaHeight = textFieldHeight + 16.0;
    CGFloat textAreaY = [_viewContainer height] - textAreaHeight;

    // Allocate, initialize, and add the table view.
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, [_viewContainer width], textAreaY)
                                              style:UITableViewStylePlain];
    [_tableView setBackgroundColor:[UIColor colorWithRGB:0xe1e5e5]];
    [_tableView setShowsVerticalScrollIndicator:NO];
    [_tableView setShowsHorizontalScrollIndicator:NO];
    [_tableView setContentInset:UIEdgeInsetsZero];
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [_tableView setDataSource:(id<UITableViewDataSource>)self];
    [_tableView setDelegate:(id<UITableViewDelegate>)self];
    [_tableView setAutoresizingMask: UIViewAutoresizingFlexibleHeight];
    [_tableView setKeyboardDismissMode:UIScrollViewKeyboardDismissModeOnDrag];
    [_viewContainer addSubview:_tableView];
    
    // Allocate, initialize, and add the text field.
    _textField = [[UITextField alloc] initWithFrame:CGRectMake(8.0, textAreaY + Center(textFieldHeight, textAreaHeight), [_viewContainer width] - 56.0, textFieldHeight)];
    [_textField setBorderStyle:UITextBorderStyleRoundedRect];
    [_textField setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [_textField setFont:textFieldFont];
    [_textField setBackgroundColor:[UIColor whiteColor]];
    [_viewContainer addSubview:_textField];
    
    _buttonSend = [UIButton buttonWithType:UIButtonTypeCustom];
    [_buttonSend setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [_buttonSend setFrame:CGRectMake([self width] - 50.0, textAreaY + Center(50.0, textAreaHeight), 50.0, 50.0)];
    [_buttonSend setImage:[UIImage imageNamed:@"Send"]
                 forState:UIControlStateNormal];
    [_buttonSend setAdjustsImageWhenHighlighted:YES];
    [_buttonSend addTarget:self action:@selector(buttonSendMessageTouchUpInsideAction:)
          forControlEvents:UIControlEventTouchUpInside];
    [_viewContainer addSubview:_buttonSend];
    
    _bubbleTableViewCells = [[NSMutableArray alloc] init];
    
    TSNLocalPeerEnteredTableViewCell * localPeerEnteredTableViewCell = [[TSNLocalPeerEnteredTableViewCell alloc] init];
    [_bubbleTableViewCells addObject:localPeerEnteredTableViewCell];
    
    // Add our observers.
    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(peerEnteredNotificationCallback:)
                               name:TSNPeerEnteredNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(peerExitedNotificationCallback:)
                               name:TSNPeerExitedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(keyboardWillShowNotificationCallback:)
                               name:UIKeyboardWillShowNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(keyboardWillHideNotificationCallback:)
                               name:UIKeyboardWillHideNotification
                             object:nil];

    // Done.
    return self;
}

// Dealloc.
- (void)dealloc
{
    // Remove our observers.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

// TSNBubbleView (UITableViewDataSource) implementation.
@implementation TSNBubbleView (UITableViewDataSource)

// Returns the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// Returns the number of rows in a given section of a table view.
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [_bubbleTableViewCells count];
}

// Returns the cell to insert in a particular location of the table view.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _bubbleTableViewCells[[indexPath row]];
}

@end

// TSNBubbleView (UITableViewDelegate) implementation.
@implementation TSNBubbleView (UITableViewDelegate)

// Returns the height to use for a row in a specified location.
- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [_bubbleTableViewCells[[indexPath row]] height];
}

// Called when a row is selected.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Row selected!");
}

@end

// TSNBubbleView (Internal) implementation.
@implementation TSNBubbleView (Internal)

// buttonSendMessageTouchUpInside action.
- (void)buttonSendMessageTouchUpInsideAction:(UIButton *)sender
{
    // Obtain the text from the text field and clear it out.
    NSString * text = [_textField text];
    [_textField setText:nil];
    
    // Update our status.
    [[TSNAppContext singleton] updateStatus:text];
}

// TSNPeerEnteredNotification callback.
- (void)peerEnteredNotificationCallback:(NSNotification *)notification
{
    OnMainThread(^{
        TSNPeer * peer = [notification object];
        
        TSNNearbyPeerEnteredTableViewCell * peerEnteredTableViewCell = [[TSNNearbyPeerEnteredTableViewCell alloc] initWithPeer:peer];
        [_bubbleTableViewCells addObject:peerEnteredTableViewCell];
        
        NSIndexPath * indexPath = [NSIndexPath indexPathForRow:[_bubbleTableViewCells count] - 1
                                                     inSection:0];

        [_tableView insertRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationAutomatic];

        [_tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:YES];
    });
}

// TSNPeerExitedNotification callback.
- (void)peerExitedNotificationCallback:(NSNotification *)notification
{
    OnMainThread(^{
        TSNPeer * peer = [notification object];
        
        TSNNearbyPeerExitedTableViewCell * peerExitedTableViewCell = [[TSNNearbyPeerExitedTableViewCell alloc] initWithPeer:peer];
        [_bubbleTableViewCells addObject:peerExitedTableViewCell];

        NSIndexPath * indexPath = [NSIndexPath indexPathForRow:[_bubbleTableViewCells count] - 1
                                                     inSection:0];

        [_tableView insertRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [_tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:YES];
    });
}

// UIKeyboardWillShowNotification callback.
- (void)keyboardWillShowNotificationCallback:(NSNotification *)notification
{
    NSDictionary * dictionary = [notification userInfo];
    CGRect keyboardFrame = [[dictionary objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect screenBounds = [self convertRect:[self bounds] toView:nil];
    CGFloat containerViewShrinkHeight = (screenBounds.origin.y + screenBounds.size.height) - keyboardFrame.origin.y;
    [UIView beginAnimations:nil
                    context:NULL];
    [UIView setAnimationDuration:[dictionary[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[dictionary[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    [_viewContainer setFrame:CGRectMake(0.0, 0.0, [self width], [self height] - containerViewShrinkHeight)];
    
    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:[_bubbleTableViewCells count] - 1
                                                 inSection:0];
    
    [_tableView scrollToRowAtIndexPath:indexPath
                      atScrollPosition:UITableViewScrollPositionBottom
                              animated:YES];
    
    [UIView commitAnimations];
}

// UIKeyboardWillHideNotification callback.
- (void)keyboardWillHideNotificationCallback:(NSNotification *)notification
{
    NSDictionary * dictionary = [notification userInfo];
    [UIView beginAnimations:nil
                    context:NULL];
    [UIView setAnimationDuration:[dictionary[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[dictionary[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [_viewContainer setFrame:[self bounds]];

    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:[_bubbleTableViewCells count] - 1
                                                 inSection:0];
    
    [_tableView scrollToRowAtIndexPath:indexPath
                      atScrollPosition:UITableViewScrollPositionBottom
                              animated:YES];

    [UIView commitAnimations];
}

@end
