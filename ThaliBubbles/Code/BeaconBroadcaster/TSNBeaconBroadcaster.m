//
//  TSNBeaconBroadcaster.m
//  ThaliChat
//
//  Created by Brian Lambert on 3/17/15.
//  Copyright (c) 2015 Thali Project. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CBPeripheralManager+Extensions.h"
#import "TSNThreading.h"
#import "TSNAtomicFlag.h"
#import "TSNLogger.h"
#import "TSNBeaconBroadcaster.h"

// TSNBeaconBroadcaster (CBPeripheralManagerDelegate) interface.
@interface TSNBeaconBroadcaster (CBPeripheralManagerDelegate) <CBPeripheralManagerDelegate>
@end

// TSNBeaconBroadcaster (Internal) interface.
@interface TSNBeaconBroadcaster (Internal)

// Starts advertising.
- (void)startAdvertising;

// Stops advertising.
- (void)stopAdvertising;

@end

// TSNBeaconBroadcaster implementation.
@implementation TSNBeaconBroadcaster
{
@private
    // The message number.
    NSUInteger _messageNumber;

    // The advertising atomic flag.
    TSNAtomicFlag * _atomicFlagAdvertising;
    
    // The service UUID.
    CBUUID * _cbuuidService;
    
    // The location characteristic UUID.
    CBUUID * _cbuuidLocationCharacteristic;

    // The service.
    CBMutableService * _service;
    
    // The characteristic.
    CBMutableCharacteristic * _characteristic;
    
    // The advertising data.
    NSDictionary * _advertisingData;
    
    // The peripheral manager.
    CBPeripheralManager * _peripheralManager;
}

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
    
    // Allocate and initialize the advertising atomic flag.
    _atomicFlagAdvertising = [[TSNAtomicFlag alloc] init];
    
    // Allocate and initialize the service UUID.
    _cbuuidService = [CBUUID UUIDWithString:@"B206EE5D-17EE-40C1-92BA-462A038A33D2"];
    
    // Allocate and initialize the characteristic UUID.
    _cbuuidLocationCharacteristic = [CBUUID UUIDWithString:@"B080D422-5B7D-430B-9F75-1D1D7D264197"];
    
    // Allocate and initialize the service.
    _service = [[CBMutableService alloc] initWithType:_cbuuidService
                                              primary:YES];
    
    // Allocate and initialize the characteristic.
    _characteristic = [[CBMutableCharacteristic alloc] initWithType:_cbuuidLocationCharacteristic
                                                          properties:CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead
                                                               value:nil
                                                         permissions:0];
    
    // Set the service characteristics.
    [_service setCharacteristics:@[_characteristic]];
    
    // Allocate and initialize the advertising data.
    _advertisingData = @{CBAdvertisementDataServiceUUIDsKey:    @[_cbuuidService],
                         CBAdvertisementDataLocalNameKey:       [[UIDevice currentDevice] name]};
    
    // Allocate and initialize the peripheral manager.
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                 queue:nil];
    
    [self foo];
    
    // Done.
    return self;
}

- (void)foo
{
    OnMainThreadAfterTimeInterval(1.0, ^{
        UInt8 buffer[20];
        arc4random_buf(buffer, sizeof(buffer));
        NSData * data = [NSData dataWithBytes:buffer length:sizeof(buffer)];

        TSNLog(@">>>>>>>>>>>>> Sending %lu bytes of data", [data length]);

        [_peripheralManager updateValue:data
                      forCharacteristic:_characteristic
                   onSubscribedCentrals:nil];
        [self foo];
    });
}

@end

// TSNBeaconBroadcaster (CBPeripheralManagerDelegate) implementation.
@implementation TSNBeaconBroadcaster (CBPeripheralManagerDelegate)

/*!
 *  @method peripheralManagerDidUpdateState:
 *
 *  @param peripheral   The peripheral manager whose state has changed.
 *
 *  @discussion         Invoked whenever the peripheral manager's state has been updated. Commands should only be issued when the state is
 *                      <code>CBPeripheralManagerStatePoweredOn</code>. A state below <code>CBPeripheralManagerStatePoweredOn</code>
 *                      implies that advertisement has paused and any connected centrals have been disconnected. If the state moves below
 *                      <code>CBPeripheralManagerStatePoweredOff</code>, advertisement is stopped and must be explicitly restarted, and the
 *                      local database is cleared and all services must be re-added.
 *
 *  @see                state
 *
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager
{
    TSNLog(@"Peripheral manager state is %@.", [_peripheralManager stateString]);
    if ([_peripheralManager state] == CBPeripheralManagerStatePoweredOn)
    {
        [self startAdvertising];
    }
    else
    {
        [self stopAdvertising];
    }
}

/*!
 *  @method peripheralManager:willRestoreState:
 *
 *  @param peripheral	The peripheral manager providing this information.
 *  @param dict			A dictionary containing information about <i>peripheral</i> that was preserved by the system at the time the app was terminated.
 *
 *  @discussion			For apps that opt-in to state preservation and restoration, this is the first method invoked when your app is relaunched into
 *						the background to complete some Bluetooth-related task. Use this method to synchronize your app's state with the state of the
 *						Bluetooth system.
 *
 *  @seealso            CBPeripheralManagerRestoredStateServicesKey;
 *  @seealso            CBPeripheralManagerRestoredStateAdvertisementDataKey;
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
         willRestoreState:(NSDictionary *)dict
{
    TSNLog(@"Peripheral manager will restore state.");
}

/*!
 *  @method peripheralManagerDidStartAdvertising:error:
 *
 *  @param peripheral   The peripheral manager providing this information.
 *  @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion         This method returns the result of a @link startAdvertising: @/link call. If advertisement could
 *                      not be started, the cause will be detailed in the <i>error</i> parameter.
 *
 */
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheralManager
                                       error:(NSError *)error
{
    if (!error)
    {
        TSNLog(@"Peripheral manager started advertising.");
    }
    else
    {
        TSNLog(@"Peripheral manager failed to start advertising. Error %@", [error localizedDescription]);
    }
}

/*!
 *  @method peripheralManager:didAddService:error:
 *
 *  @param peripheral   The peripheral manager providing this information.
 *  @param service      The service that was added to the local database.
 *  @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion         This method returns the result of an @link addService: @/link call. If the service could
 *                      not be published to the local database, the cause will be detailed in the <i>error</i> parameter.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error
{
    if (!error)
    {
        TSNLog(@"Peripheral manager did add service.");
    }
    else
    {
        TSNLog(@"Peripheral manager failed to add service. Error %@", [error localizedDescription]);
    }
}

/*!
 *  @method peripheralManager:central:didSubscribeToCharacteristic:
 *
 *  @param peripheral       The peripheral manager providing this update.
 *  @param central          The central that issued the command.
 *  @param characteristic   The characteristic on which notifications or indications were enabled.
 *
 *  @discussion             This method is invoked when a central configures <i>characteristic</i> to notify or indicate.
 *                          It should be used as a cue to start sending updates as the characteristic value changes.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    // Request low latency.
    [_peripheralManager setDesiredConnectionLatency:CBPeripheralManagerConnectionLatencyLow
                                         forCentral:central];
    
    TSNLog(@"--> Peripheral manager did subscribe to characteristic. Maximum update value length %lu", [central maximumUpdateValueLength]);
}

/*!
 *  @method peripheralManager:central:didUnsubscribeFromCharacteristic:
 *
 *  @param peripheral       The peripheral manager providing this update.
 *  @param central          The central that issued the command.
 *  @param characteristic   The characteristic on which notifications or indications were disabled.
 *
 *  @discussion             This method is invoked when a central removes notifications/indications from <i>characteristic</i>.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    TSNLog(@"Peripheral manager did unsubscribe to characteristic.");
}

/*!
 *  @method peripheralManager:didReceiveReadRequest:
 *
 *  @param peripheral   The peripheral manager requesting this information.
 *  @param request      A <code>CBATTRequest</code> object.
 *
 *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request for a characteristic with a dynamic value.
 *                      For every invocation of this method, @link respondToRequest:withResult: @/link must be called.
 *
 *  @see                CBATTRequest
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveReadRequest:(CBATTRequest *)request
{
    TSNLog(@"Peripheral manager did receive read request.");
}

/*!
 *  @method peripheralManager:didReceiveWriteRequests:
 *
 *  @param peripheral   The peripheral manager requesting this information.
 *  @param requests     A list of one or more <code>CBATTRequest</code> objects.
 *
 *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request or command for one or more characteristics with a dynamic value.
 *                      For every invocation of this method, @link respondToRequest:withResult: @/link should be called exactly once. If <i>requests</i> contains
 *                      multiple requests, they must be treated as an atomic unit. If the execution of one of the requests would cause a failure, the request
 *                      and error reason should be provided to <code>respondToRequest:withResult:</code> and none of the requests should be executed.
 *
 *  @see                CBATTRequest
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
  didReceiveWriteRequests:(NSArray *)requests
{
    TSNLog(@"Peripheral manager did receive write request.");
}

/*!
 *  @method peripheralManagerIsReadyToUpdateSubscribers:
 *
 *  @param peripheral   The peripheral manager providing this update.
 *
 *  @discussion         This method is invoked after a failed call to @link updateValue:forCharacteristic:onSubscribedCentrals: @/link, when <i>peripheral</i> is again
 *                      ready to send characteristic value updates.
 *
 */
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    TSNLog(@"Peripheral manager is ready to update subscribers.");
}

@end

// TSNBeaconBroadcaster (Internal) implementation.
@implementation TSNBeaconBroadcaster (Internal)

// Starts advertising.
- (void)startAdvertising
{
    if ([_atomicFlagAdvertising trySet])
    {
        [_peripheralManager addService:_service];
        [_peripheralManager startAdvertising:_advertisingData];
        
        TSNLog(@"Peripheral manager asked to start advertising.");
    }
}

// Stops advertising.
- (void)stopAdvertising
{
    if ([_atomicFlagAdvertising tryClear])
    {
        [_peripheralManager removeAllServices];
        [_peripheralManager stopAdvertising];
        TSNLog(@"Peripheral manager asked to stop advertising.");
    }
}

@end
