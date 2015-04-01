//
//  CBPeripheral+Extensions.h
//  ThaliBubbles
//
//  Created by Brian Lambert on 3/31/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

// CBPeripheral (Extensions) interface.
@interface CBPeripheral (Extensions)

// Gets the identifier as a string.
- (NSString *)identifierString;

@end
