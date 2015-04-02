//
//  TSNAppContext.m
//  ThaliBubbles
//
//  Created by Brian Lambert on 3/25/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <pthread.h>
#import <TSNLogger.h>
#import <TSNAtomicFlag.h>
#import "TSNAppContext.h"
#import "TSNPeerBluetoothContext.h"
#import "TSNPeerNetworkingContext.h"
#import "TSNLocationContext.h"

// Logging.
static inline void Log(NSString * format, ...)
{
    // Format the log entry.
    va_list args;
    va_start(args, format);
    NSString * formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    // Append the log entry.
    TSNLog([NSString stringWithFormat:@"           TSNAppContext: %@", formattedString]);
}

// External definitions.
NSString * const TSNLocationUpdatedNotification = @"TSNLocationUpdated";
NSString * const TSNPeersUpdatedNotification    = @"TSNPeersUpdated";

// TSNAppContext (TSNPeerBluetoothContextDelegate) interface.
@interface TSNAppContext (TSNPeerBluetoothContextDelegate) <TSNPeerBluetoothContextDelegate>
@end

// TSNAppContext (TSNPeerNetworkingContextDelegate) interface.
@interface TSNAppContext (TSNPeerNetworkingContextDelegate) <TSNPeerNetworkingContextDelegate>
@end

// TSNAppContext (TSNLocationContextDelegate) interface.
@interface TSNAppContext (TSNLocationContextDelegate) <TSNLocationContextDelegate>
@end

// TSNAppContext (Internal) interface.
@interface TSNAppContext (Internal)

// Class initializer.
- (instancetype)init;

// The updater thread entry point.
- (void)threadUpdaterEntryPointWithObject:(id)object;

@end

// TSNAppContext implementation.
@implementation TSNAppContext
{
@private
    // The enabled atomic flag.
    TSNAtomicFlag * _atomicFlagEnabled;

    // The peer Bluetooth context.
    TSNPeerBluetoothContext * _peerBluetoothContext;
    
    // The peer networking context.
    TSNPeerNetworkingContext * _peerNetworkingContext;
    
    // The location context.
    TSNLocationContext * _locationContext;
    
    // The mutex used to protect access to things below.
    pthread_mutex_t _mutex;

    // The location.
    CLLocation * _location;
    
    // The peers dictionary.
    NSMutableDictionary * _peers;
    
    // The updater thread.
    NSThread * _threadUpdater;
}

// Singleton.
+ (instancetype)singleton
{
    // Singleton instance.
    static TSNAppContext * appContext = nil;
    
    // If unallocated, allocate.
    if (!appContext)
    {
        // Allocator.
        void (^allocator)() = ^
        {
            appContext = [[TSNAppContext alloc] init];
        };
        
        // Dispatch allocator once.
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, allocator);
    }
    
    // Done.
    return appContext;
}

// Starts communications.
- (void)startCommunications
{
    if ([_atomicFlagEnabled trySet])
    {
        [_peerBluetoothContext start];
        //    [_peerNetworkingContext start];
        [_locationContext start];
        
        _threadUpdater = [[NSThread alloc] initWithTarget:self
                                                 selector:@selector(threadUpdaterEntryPointWithObject:)
                                                   object:nil];
        [_threadUpdater setQualityOfService:NSQualityOfServiceBackground];
        [_threadUpdater setName:@"org.thaliproject.thalibubblesaa"];
//        [_threadUpdater setThreadPriority:0.75];
        [_threadUpdater start];
    }
}

// Stops communications.
- (void)stopCommunications
{
    if ([_atomicFlagEnabled tryClear])
    {
        [_peerBluetoothContext stop];
//        [_peerNetworkingContext stop];
        [_locationContext stop];
    }
}

- (NSArray *)peers
{
    // Lock.
    pthread_mutex_lock(&_mutex);
    
    NSArray * peers = [_peers allValues];
    
    // Unlock.
    pthread_mutex_unlock(&_mutex);

    // Return the peers.
    return peers;
}

@end

// TSNAppContext (TSNPeerBluetoothContextDelegate) implementation.
@implementation TSNAppContext (TSNPeerBluetoothContextDelegate)

// Notifies the delegate that a peer was connected.
- (void)peerBluetoothContext:(TSNPeerBluetoothContext *)peerBluetoothContext
        didConnectToPeerName:(NSString *)peerName
{
    // Allocate and initialize the peer.
    TSNPeer * peer = [[TSNPeer alloc] initWithPeerName:peerName
                                              location:nil
                                              distance:0];
    
    // Lock.
    pthread_mutex_lock(&_mutex);

    // Set the peer in the peers dictionary.
    [_peers setObject:peer
               forKey:peerName];
    
    // Unlock.
    pthread_mutex_unlock(&_mutex);
    
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
    {
        UILocalNotification * localNotification = [[UILocalNotification alloc] init];
        [localNotification setFireDate:[[NSDate alloc] init]];
        [localNotification setAlertTitle:@"New Peer Connected"];
        [localNotification setAlertBody:[NSString stringWithFormat:@"%@ connected to you.", peerName]];
        [localNotification setSoundName:UILocalNotificationDefaultSoundName];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
}

// Notifies the delegate that a peer was disconnected.
- (void)peerBluetoothContext:(TSNPeerBluetoothContext *)peerBluetoothContext
   didDisconnectFromPeerName:(NSString *)peerName
{
    // Lock.
    pthread_mutex_lock(&_mutex);
    
    // Set the peer in the peers dictionary.
    [_peers removeObjectForKey:peerName];
    
    // Unlock.
    pthread_mutex_unlock(&_mutex);
    
    // Post the TSNPeersUpdatedNotification so the rest of the app knows about the update.
    [[NSNotificationCenter defaultCenter] postNotificationName:TSNPeersUpdatedNotification
                                                        object:nil];

    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
    {
        UILocalNotification * localNotification = [[UILocalNotification alloc] init];
        [localNotification setFireDate:[[NSDate alloc] init]];
        [localNotification setAlertTitle:@"Peer Disconnected"];
        [localNotification setAlertBody:[NSString stringWithFormat:@"%@ has disconnected.", peerName]];
        [localNotification setSoundName:UILocalNotificationDefaultSoundName];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
}

// Notifies the delegate that a peer updated its location.
- (void)peerBluetoothContext:(TSNPeerBluetoothContext *)peerBluetoothContext
          didReceiveLocation:(CLLocation *)location
                 forPeerName:(NSString *)peerName
{
    // Lock.
    pthread_mutex_lock(&_mutex);
    
    // Get the peer. If we don't have it yet, ignore the location update.
    TSNPeer * peer = [_peers objectForKey:peerName];
    if (!peer)
    {
        pthread_mutex_unlock(&_mutex);
        return;
    }
    
    // Update the peer's location and distance.
    [peer setLocation:location];
    [peer setDisance:[location distanceFromLocation:_location]];
    [peer setLastUpdated:[[NSDate alloc] init]];
    
    // Unlock.
    pthread_mutex_unlock(&_mutex);
    
    Log(@"Peer %@ updated location.", peerName);
    
    // Post the TSNPeersUpdatedNotification so the rest of the app knows about the update.
    [[NSNotificationCenter defaultCenter] postNotificationName:TSNPeersUpdatedNotification
                                                        object:nil];
}

@end

// TSNAppContext (TSNPeerNetworkingContextDelegate) implementation.
@implementation TSNAppContext (TSNPeerNetworkingContextDelegate)

// Notifies the delegate that data was received.
- (void)peerNetworking:(TSNPeerNetworkingContext *)peerNetworking
        didReceiveData:(NSData *)data
{
    Log(@"We got some data! %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

@end

// TSNAppContext (TSNLocationContextDelegate) implementation.
@implementation TSNAppContext (TSNLocationContextDelegate)

// Notifies the delegate that the location was updated.
- (void)locationContext:(TSNLocationContext *)locationContext
      didUpdateLocation:(CLLocation *)location
{
    // Lock.
    pthread_mutex_lock(&_mutex);
    
    // Update the location.
    _location = location;
    
    // Unlock.
    pthread_mutex_unlock(&_mutex);
    
    // Update our location in the peer Bluetooth context to share it with peers.
    [_peerBluetoothContext updateLocation:location];

    // Post the TSNLocationUpdatedNotification so the rest of the app knows about the location update.
    [[NSNotificationCenter defaultCenter] postNotificationName:TSNLocationUpdatedNotification
                                                        object:location];
}

@end

// TSNAppContext (Internal) implementation.
@implementation TSNAppContext (Internal)

// Class initializer.
- (instancetype)init
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Intialize.
    _atomicFlagEnabled = [[TSNAtomicFlag alloc] init];
    pthread_mutex_init(&_mutex, NULL);
    _peers = [[NSMutableDictionary alloc] init];
    
    // Get the peer name.
    NSString * peerName = [[UIDevice currentDevice] name];
    
    // Allocate and initialize the peer Bluetooth context.
    _peerBluetoothContext = [[TSNPeerBluetoothContext alloc] initWithPeerName:peerName];
    [_peerBluetoothContext setDelegate:(id<TSNPeerBluetoothContextDelegate>)self];

    // Allocate and initialize the peer networking context.
    _peerNetworkingContext = [[TSNPeerNetworkingContext alloc] initWithServiceType:@"ThaliBubbles"
                                                                          peerName:peerName];
    [_peerNetworkingContext setDelegate:(id<TSNPeerNetworkingContextDelegate>)self];
    
    // Allocate and initialize the location context.
    _locationContext = [[TSNLocationContext alloc] init];
    [_locationContext setDelegate:(id<TSNLocationContextDelegate>)self];

    // Done.
    return self;
}

// The updater thread entry point.
- (void)threadUpdaterEntryPointWithObject:(id)object
{
    // Run while we're connected.
    while ([_atomicFlagEnabled isSet])
    {
        [NSThread sleepForTimeInterval:5.0];
        
        // Lock.
        pthread_mutex_lock(&_mutex);
        
        // Update the location.
        CLLocation * location = _location;
        
        // Unlock.
        pthread_mutex_unlock(&_mutex);

        if (location)
        {
            Log(@"Update!! location");

            // Update our location in the peer Bluetooth context to share it with peers.
            [_peerBluetoothContext updateLocation:location];
        }
    }
}

@end
