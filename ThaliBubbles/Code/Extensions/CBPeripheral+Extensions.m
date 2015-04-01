//
//  CBPeripheral+Extensions.m
//  ThaliBubbles
//
//  Created by Brian Lambert on 3/31/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "CBPeripheral+Extensions.h"

// CBPeripheral (Extensions) implementation.
@implementation CBPeripheral (Extensions)

// Gets the identifier as a string.
- (NSString *)identifierString
{
    return [[self identifier] UUIDString];
}

@end
