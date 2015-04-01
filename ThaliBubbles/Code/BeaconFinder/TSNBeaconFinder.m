//
//  TSNBeaconFinder.m
//  ThaliChat
//
//  Created by Brian Lambert on 3/17/15.
//  Copyright (c) 2015 Thali Project. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "TSNAtomicFlag.h"
#import "TSNLogger.h"
#import "TSNBeaconFinder.h"

// TSNBeaconFinder (CBCentralManagerDelegate) interface.
@interface TSNBeaconFinder (CBCentralManagerDelegate) <CBCentralManagerDelegate>
@end

// TSNBeaconFinder (CBPeripheralDelegate) interface.
@interface TSNBeaconFinder (CBPeripheralDelegate) <CBPeripheralDelegate>
@end

// TSNBeaconFinder (Internal) interface.
@interface TSNBeaconFinder (Internal)

// Starts scanning.
- (void)startScanning;

// Stops scanning.
- (void)stopScanning;

@end

// TSNBeaconFinder implementation.
@implementation TSNBeaconFinder
{
@private
    // The scanning atomic flag.
    TSNAtomicFlag * _atomicFlagScanning;

    // The service UUID.
    CBUUID * _cbuuidService;
    
    // The characteristic UUID.
    CBUUID * _cbuuidCharacteristic;
    
    // The central manager.
    CBCentralManager * _centralManager;
    
    // The connected peripherals.
    NSMutableDictionary * _connectedPeripherals;
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

    // Allocate and initialize the scanning atomic flag.
    _atomicFlagScanning = [[TSNAtomicFlag alloc] init];

    // Allocate and initialize the service UUID.
    _cbuuidService = [CBUUID UUIDWithString:@"B206EE5D-17EE-40C1-92BA-462A038A33D2"];
    
    // Allocate and initialize the characteristic UUID.
    _cbuuidCharacteristic = [CBUUID UUIDWithString:@"B080D422-5B7D-430B-9F75-1D1D7D264197"];

    // Allocate and initialize the central manager.
    _centralManager = [[CBCentralManager alloc] initWithDelegate:(id<CBCentralManagerDelegate>)self
                                                           queue:nil];
    
    // Allopcate and initialzie the connected peripherals dictionary.
    _connectedPeripherals = [[NSMutableDictionary alloc] init];
    
    // Done.
    return self;
}

@end

// TSNBeaconFinder (CBCentralManagerDelegate) implementation.
@implementation TSNBeaconFinder (CBCentralManagerDelegate)

/*!
 *  @method centralManagerDidUpdateState:
 *
 *  @param central  The central manager whose state has changed.
 *
 *  @discussion     Invoked whenever the central manager's state has been updated. Commands should only be issued when the state is
 *                  <code>CBCentralManagerStatePoweredOn</code>. A state below <code>CBCentralManagerStatePoweredOn</code>
 *                  implies that scanning has stopped and any connected peripherals have been disconnected. If the state moves below
 *                  <code>CBCentralManagerStatePoweredOff</code>, all <code>CBPeripheral</code> objects obtained from this central
 *                  manager become invalid and must be retrieved or discovered again.
 *
 *  @see            state
 *
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch ([_centralManager state])
    {
        case CBCentralManagerStateUnknown:
            TSNLog(@"Central manager state is unknown.");
            [self stopScanning];
            break;
            
        case CBCentralManagerStateResetting:
            TSNLog(@"Central manager state is resetting.");
            [self stopScanning];
            break;

        case CBCentralManagerStateUnsupported:
            TSNLog(@"Central manager state is unsupported.");
            [self stopScanning];
            break;

        case CBCentralManagerStateUnauthorized:
            TSNLog(@"Central manager state is unauthorized.");
            [self stopScanning];
            break;

        case CBCentralManagerStatePoweredOff:
            TSNLog(@"Central manager state is powered off.");
            [self stopScanning];
            break;

        case CBCentralManagerStatePoweredOn:
            TSNLog(@"Central manager state is powered on.");
            [self startScanning];
            break;

        default:
            TSNLog(@"Central manager state is %d.");
            [self stopScanning];
            break;
    }
}

/*!
 *  @method centralManager:willRestoreState:
 *
 *  @param central      The central manager providing this information.
 *  @param dict			A dictionary containing information about <i>central</i> that was preserved by the system at the time the app was terminated.
 *
 *  @discussion			For apps that opt-in to state preservation and restoration, this is the first method invoked when your app is relaunched into
 *						the background to complete some Bluetooth-related task. Use this method to synchronize your app's state with the state of the
 *						Bluetooth system.
 *
 *  @seealso            CBCentralManagerRestoredStatePeripheralsKey;
 *  @seealso            CBCentralManagerRestoredStateScanServicesKey;
 *  @seealso            CBCentralManagerRestoredStateScanOptionsKey;
 *
 */
- (void)centralManager:(CBCentralManager *)central
      willRestoreState:(NSDictionary *)dict
{
    TSNLog(@"Central manager will restore state.");
}

/*!
 *  @method centralManager:didRetrievePeripherals:
 *
 *  @param central      The central manager providing this information.
 *  @param peripherals  A list of <code>CBPeripheral</code> objects.
 *
 *  @discussion         This method returns the result of a {@link retrievePeripherals} call, with the peripheral(s) that the central manager was
 *                      able to match to the provided UUID(s).
 *
 */
- (void)centralManager:(CBCentralManager *)centralManager
didRetrievePeripherals:(NSArray *)peripherals
{
    TSNLog(@"Central manager did retrieve peripherals.");
}

/*!
 *  @method centralManager:didRetrieveConnectedPeripherals:
 *
 *  @param central      The central manager providing this information.
 *  @param peripherals  A list of <code>CBPeripheral</code> objects representing all peripherals currently connected to the system.
 *
 *  @discussion         This method returns the result of a {@link retrieveConnectedPeripherals} call.
 *
 */
- (void)centralManager:(CBCentralManager *)centralManager
didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
    TSNLog(@"Central manager did retrieve connected peripherals.");
}

/*!
 *  @method centralManager:didDiscoverPeripheral:advertisementData:RSSI:
 *
 *  @param central              The central manager providing this update.
 *  @param peripheral           A <code>CBPeripheral</code> object.
 *  @param advertisementData    A dictionary containing any advertisement and scan response data.
 *  @param RSSI                 The current RSSI of <i>peripheral</i>, in dBm. A value of <code>127</code> is reserved and indicates the RSSI
 *								was not available.
 *
 *  @discussion                 This method is invoked while scanning, upon the discovery of <i>peripheral</i> by <i>central</i>. A discovered peripheral must
 *                              be retained in order to use it; otherwise, it is assumed to not be of interest and will be cleaned up by the central manager. For
 *                              a list of <i>advertisementData</i> keys, see {@link CBAdvertisementDataLocalNameKey} and other similar constants.
 *
 *  @seealso                    CBAdvertisementData.h
 *
 */
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    if (![_connectedPeripherals objectForKey:peripheralIdentifierString])
    {
        TSNLog(@"Central manager discovered peripheral %@ named %@.", peripheralIdentifierString, [peripheral name]);
        [_connectedPeripherals setValue:peripheral
                                 forKey:peripheralIdentifierString];

        [_centralManager connectPeripheral:peripheral
                                   options:nil];
    }
}

/*!
 *  @method centralManager:didConnectPeripheral:
 *
 *  @param central      The central manager providing this information.
 *  @param peripheral   The <code>CBPeripheral</code> that has connected.
 *
 *  @discussion         This method is invoked when a connection initiated by {@link connectPeripheral:options:} has succeeded.
 *
 */
- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    [peripheral setDelegate:(id<CBPeripheralDelegate>)self];

    TSNLog(@"Central manager connected peripheral %@ named %@. Discovering services.", peripheralIdentifierString, [peripheral name]);
    
    // Have the peripheral discover services. This will call us back at peripheral:didDiscoverServices:
    [peripheral discoverServices:@[_cbuuidService]];
}

/*!
 *  @method centralManager:didFailToConnectPeripheral:error:
 *
 *  @param central      The central manager providing this information.
 *  @param peripheral   The <code>CBPeripheral</code> that has failed to connect.
 *  @param error        The cause of the failure.
 *
 *  @discussion         This method is invoked when a connection initiated by {@link connectPeripheral:options:} has failed to complete. As connection attempts do not
 *                      timeout, the failure of a connection is atypical and usually indicative of a transient issue.
 *
 */
- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    [_connectedPeripherals removeObjectForKey:peripheralIdentifierString];
    
    TSNLog(@"Central manager failed to connect peripheral %@ named %@. Error: %@", peripheralIdentifierString, [peripheral name], [error localizedDescription]);
}

/*!
 *  @method centralManager:didDisconnectPeripheral:error:
 *
 *  @param central      The central manager providing this information.
 *  @param peripheral   The <code>CBPeripheral</code> that has disconnected.
 *  @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion         This method is invoked upon the disconnection of a peripheral that was connected by {@link connectPeripheral:options:}. If the disconnection
 *                      was not initiated by {@link cancelPeripheralConnection}, the cause will be detailed in the <i>error</i> parameter. Once this method has been
 *                      called, no more methods will be invoked on <i>peripheral</i>'s <code>CBPeripheralDelegate</code>.
 *
 */
- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];

    [_connectedPeripherals removeObjectForKey:peripheralIdentifierString];
    
    TSNLog(@"Central manager disconnected peripheral %@ named %@. Error: %@", peripheralIdentifierString, [peripheral name], [error localizedDescription]);
}

@end

// TSNBeaconFinder (CBPeripheralDelegate) implementation.
@implementation TSNBeaconFinder (CBPeripheralDelegate)

/*!
 *  @method peripheralDidUpdateName:
 *
 *  @param peripheral	The peripheral providing this update.
 *
 *  @discussion			This method is invoked when the @link name @/link of <i>peripheral</i> changes.
 */
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];

    TSNLog(@"Peripheral %@ changed name to %@", peripheralIdentifierString, [peripheral name]);
}

/*!
 *  @method peripheral:didModifyServices:
 *
 *  @param peripheral			The peripheral providing this update.
 *  @param invalidatedServices	The services that have been invalidated
 *
 *  @discussion			This method is invoked when the @link services @/link of <i>peripheral</i> have been changed.
 *						At this point, the designated <code>CBService</code> objects have been invalidated.
 *						Services can be re-discovered via @link discoverServices: @/link.
 */
- (void)peripheral:(CBPeripheral *)peripheral
 didModifyServices:(NSArray *)invalidatedServices
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    TSNLog(@"Peripheral %@ named %@ modified services.", peripheralIdentifierString, [peripheral name]);
}

/*!
 *  @method peripheralDidUpdateRSSI:error:
 *
 *  @param peripheral	The peripheral providing this update.
 *	@param error		If an error occurred, the cause of the failure.
 *
 *  @discussion			This method returns the result of a @link readRSSI: @/link call.
 */
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral
                          error:(NSError *)error
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    TSNLog(@"Peripheral %@ named %@ updated RSSI.", peripheralIdentifierString, [peripheral name]);
}

/*!
 *  @method peripheral:didDiscoverServices:
 *
 *  @param peripheral	The peripheral providing this information.
 *	@param error		If an error occurred, the cause of the failure.
 *
 *  @discussion			This method returns the result of a @link discoverServices: @/link call. If the service(s) were read successfully, they can be retrieved via
 *						<i>peripheral</i>'s @link services @/link property.
 *
 */
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];

    TSNLog(@"Peripheral %@ discovered services.", peripheralIdentifierString);

    // Process the services.
    for (CBService * service in [peripheral services])
    {
        if ([[service UUID] isEqual:_cbuuidService])
        {
            [peripheral discoverCharacteristics:@[_cbuuidCharacteristic]
                                     forService:service];
        }
    }
}

/*!
 *  @method peripheral:didDiscoverIncludedServicesForService:error:
 *
 *  @param peripheral	The peripheral providing this information.
 *  @param service		The <code>CBService</code> object containing the included services.
 *	@param error		If an error occurred, the cause of the failure.
 *
 *  @discussion			This method returns the result of a @link discoverIncludedServices:forService: @/link call. If the included service(s) were read successfully,
 *						they can be retrieved via <i>service</i>'s <code>includedServices</code> property.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverIncludedServicesForService:(CBService *)service
             error:(NSError *)error
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    TSNLog(@"Peripheral %@ named %@ discovered included services.", peripheralIdentifierString, [peripheral name]);
}

/*!
 *  @method peripheral:didDiscoverCharacteristicsForService:error:
 *
 *  @param peripheral	The peripheral providing this information.
 *  @param service		The <code>CBService</code> object containing the characteristic(s).
 *	@param error		If an error occurred, the cause of the failure.
 *
 *  @discussion			This method returns the result of a @link discoverCharacteristics:forService: @/link call. If the characteristic(s) were read successfully,
 *						they can be retrieved via <i>service</i>'s <code>characteristics</code> property.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    TSNLog(@"Peripheral %@ discovered characteristics for service.", peripheralIdentifierString);

    // If the service is the heart rate service, locate the heart rate measurement characteristic and set-up notifications.
    if ([[service UUID] isEqual:_cbuuidService])
    {
        for (CBCharacteristic * characteristic in [service characteristics])
        {
            if ([[characteristic UUID] isEqual:_cbuuidCharacteristic])
            {
                [peripheral setNotifyValue:YES
                         forCharacteristic:characteristic];
            }
        }
    }
}

/*!
 *  @method peripheral:didUpdateValueForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method is invoked after a @link readValueForCharacteristic: @/link call, or upon receipt of a notification/indication.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
//    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    //TSNLog(@"Peripheral %@ did update value for characteristic.", peripheralIdentifierString);

    // If there is an error, or there's no data, return.
    if (error || ![characteristic value])
    {
        return;
    }
    
    // Process the characteristic.
    if ([[characteristic UUID] isEqual:_cbuuidCharacteristic])
    {
        NSData * data = [characteristic value];
        TSNLog(@"<<<<<<<<<<<<< Received %lu bytes of data", [data length]);
    }
}

/*!
 *  @method peripheral:didWriteValueForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a {@link writeValue:forCharacteristic:type:} call, when the <code>CBCharacteristicWriteWithResponse</code> type is used.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    TSNLog(@"Peripheral %@ did write value for characteristic.", peripheralIdentifierString);
}

/*!
 *  @method peripheral:didUpdateNotificationStateForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link setNotifyValue:forCharacteristic: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    TSNLog(@"Peripheral %@ did update notification state for characteristic.", peripheralIdentifierString);
    
    [peripheral readValueForCharacteristic:characteristic];
}

/*!
 *  @method peripheral:didDiscoverDescriptorsForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link discoverDescriptorsForCharacteristic: @/link call. If the descriptors were read successfully,
 *							they can be retrieved via <i>characteristic</i>'s <code>descriptors</code> property.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    TSNLog(@"Peripheral %@ did discover descriptors for characteristic.", peripheralIdentifierString);
}

/*!
 *  @method peripheral:didUpdateValueForDescriptor:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param descriptor		A <code>CBDescriptor</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link readValueForDescriptor: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForDescriptor:(CBDescriptor *)descriptor
             error:(NSError *)error
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    TSNLog(@"Peripheral %@ did update value for descriptor.", peripheralIdentifierString);
}

/*!
 *  @method peripheral:didWriteValueForDescriptor:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param descriptor		A <code>CBDescriptor</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link writeValue:forDescriptor: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForDescriptor:(CBDescriptor *)descriptor
             error:(NSError *)error
{
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    TSNLog(@"Peripheral %@ did write value for descriptor.", peripheralIdentifierString);
}

@end

// TSNBeaconFinder (Internal) implementation.
@implementation TSNBeaconFinder (Internal)

// Starts scanning.
- (void)startScanning
{
    if ([_atomicFlagScanning trySet])
    {
        [_centralManager scanForPeripheralsWithServices:@[_cbuuidService]
                                                options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @(YES)}];
        TSNLog(@"Central manager asked to start scanning.");
    }
}

// Stops scanning.
- (void)stopScanning
{
    if ([_atomicFlagScanning tryClear])
    {
        [_centralManager stopScan];
        TSNLog(@"Central manager asked to stop scanning.");
    }
}

@end
