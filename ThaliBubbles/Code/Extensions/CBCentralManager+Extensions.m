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
//  CBCentralManager+Extensions.m
//

#import "CBCentralManager+Extensions.h"

// CBCentralManager (Extensions) implementation.
@implementation CBCentralManager (Extensions)

// Returns the central manager state as a string.
- (NSString *)stateString
{
    switch ([self state])
    {
        case CBCentralManagerStateUnknown:
            return @"unknown";
            
        case CBCentralManagerStateResetting:
            return @"resetting";
            
        case CBCentralManagerStateUnsupported:
            return @"unsupported";
            
        case CBCentralManagerStateUnauthorized:
            return @"unauthorized";
            
        case CBCentralManagerStatePoweredOff:
            return @"powered off";
            
        case CBCentralManagerStatePoweredOn:
            return @"powered on";
    }
}

@end
