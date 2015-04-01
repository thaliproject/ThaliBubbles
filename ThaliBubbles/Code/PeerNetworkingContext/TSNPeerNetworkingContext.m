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
//  TSNPeerNetworkingContext.m
//

#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "TSNPeerNetworkingContext.h"
#import "TSNLogger.h"
#import "TSNThreading.h"

// Logging.
static inline void Log(NSString * format, ...)
{
    // Format the log entry.
    va_list args;
    va_start(args, format);
    NSString * formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    // Append the log entry.
    TSNLog([NSString stringWithFormat:@"TSNPeerNetworkingContext: %@", formattedString]);
}

// Static declarations.
static NSString * const PEER_ID_KEY = @"PeerIDKey";

// TSNPeerNetworkingContext (MCNearbyServiceAdvertiserDelegate) interface.
@interface TSNPeerNetworkingContext (MCNearbyServiceAdvertiserDelegate) <MCNearbyServiceAdvertiserDelegate>
@end

// TSNPeerNetworkingContext (MCNearbyServiceBrowserDelegate) interface.
@interface TSNPeerNetworkingContext (MCNearbyServiceBrowserDelegate) <MCNearbyServiceBrowserDelegate>
@end


// TSNPeerNetworkingContext (MCSessionDelegate) interface.
@interface TSNPeerNetworkingContext (MCSessionDelegate) <MCSessionDelegate>
@end

// TSNPeerNetworkingContext (Internal) interface.
@interface TSNPeerNetworkingContext (Internal)
@end

// TSNPeerNetworkingContext implementation.
@implementation TSNPeerNetworkingContext
{
@private
    // The service type.
    NSString * _serviceType;
    
    // The peer name.
    NSString * _peerName;
    
    // The peer ID.
    MCPeerID * _peerID;

    // The session.
    MCSession * _session;
    
    // The nearby service advertiser.
    MCNearbyServiceAdvertiser * _nearbyServiceAdvertiser;
    
    // The nearby service browser.
    MCNearbyServiceBrowser * _nearbyServiceBrowser;
}

// Class initializer.
- (instancetype)initWithServiceType:(NSString *)serviceType
                           peerName:(NSString *)peerName
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    _serviceType = serviceType;
    _peerName = peerName;
    
    // Done.
    return self;
}

// Returns a value which indicates whether peers are connected.
- (BOOL)peersAreConnected
{
    return [[_session connectedPeers] count];
}

// Starts the peer networking context.
- (void)start
{
    // Obtain user defaults and see if we have a serialized peer ID. If we do, deserialize it. If not, make one
    // and serialize it for later use. If we don't serialize and reuse the peer ID, we'll see duplicates
    // of this peer in sessions.
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSData * data = [userDefaults dataForKey:PEER_ID_KEY];
    if ([data length])
    {
        // Deserialize the peer ID.
        _peerID = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    else
    {
        // Allocate and initialize a new peer ID.
        _peerID = [[MCPeerID alloc] initWithDisplayName:_peerName];

        // Serialize and save the peer ID in user defaults.
        data = [NSKeyedArchiver archivedDataWithRootObject:_peerID];
        [userDefaults setValue:data
                        forKey:PEER_ID_KEY];
        [userDefaults synchronize];
    }
    
    // Allocate and initialize the session.
    _session = [[MCSession alloc] initWithPeer:_peerID
                              securityIdentity:nil
                          encryptionPreference:MCEncryptionRequired];
    [_session setDelegate:(id<MCSessionDelegate>)self];
    
    // Allocate and initialize the nearby service advertizer.
    _nearbyServiceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_peerID
                                                                 discoveryInfo:nil
                                                                   serviceType:_serviceType];
    [_nearbyServiceAdvertiser setDelegate:(id<MCNearbyServiceAdvertiserDelegate>)self];

    // Allocate and initialize the nearby service browser.
    _nearbyServiceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:_peerID
                                                             serviceType:_serviceType];
    [_nearbyServiceBrowser setDelegate:(id<MCNearbyServiceBrowserDelegate>)self];

    // Start advertising this peer and browsing for peers.
    [_nearbyServiceAdvertiser startAdvertisingPeer];
    [_nearbyServiceBrowser startBrowsingForPeers];
    
    // Log.
    Log(@"Initialized peer %@", [_peerID displayName]);
}

// Stops the peer networking context.
- (void)stop
{
    // Stop advertising this peer and browsing for peers.
    [_nearbyServiceAdvertiser stopAdvertisingPeer];
    [_nearbyServiceBrowser stopBrowsingForPeers];
    
    // Disconnect from the session.
    [_session disconnect];
    
    // Clean up.
    _nearbyServiceAdvertiser = nil;
    _nearbyServiceBrowser = nil;
    _session = nil;
    _peerID = nil;
}

// Sends data.
- (void)sendData:(NSData *)data
{
    NSArray * connectedPeers = [_session connectedPeers];
    if ([connectedPeers count])
    {
        NSError * error;
        
        Log(@"%@ sending %lu bytes", [_peerID displayName], [data length]);
        for (MCPeerID * peerID in connectedPeers)
        {
            Log(@"    %@ has peer %@", [_peerID displayName], [peerID displayName]);
        }
        
        if (![_session sendData:data
                        toPeers:connectedPeers
                       withMode:MCSessionSendDataReliable
                          error:&error])
        {
            Log(@"%@ sending %lu bytes failed: %@", [_peerID displayName], [data length], [error localizedDescription]);
        }
        else
        {
            Log(@"%@ sending %lu bytes succeeded", [_peerID displayName], [data length]);
        }
    }
}

@end

// TSNPeerNetworkingContext (MCNearbyServiceAdvertiserDelegate) implementation.
@implementation TSNPeerNetworkingContext (MCNearbyServiceAdvertiserDelegate)

// Notifies the delegate that an invitation to join a session was received from a nearby peer.
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser
didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context
 invitationHandler:(void (^)(BOOL accept, MCSession * session))invitationHandler
{
    // Log.
    Log(@"%@ sent invitation", [peerID displayName]);
    
    // Accept the invitation.
    invitationHandler(YES, _session);
    
    // Log.
    Log(@"%@ invitation accepted", [peerID displayName]);
}

// Notifies the delegate that advertisement failed.
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser
didNotStartAdvertisingPeer:(NSError *)error
{
    Log(@"%@ did not start advertising: %@", [_peerID displayName], [error localizedDescription]);
}

@end

// TSNPeerNetworkingContext (MCNearbyServiceBrowserDelegate) implementation.
@implementation TSNPeerNetworkingContext (MCNearbyServiceBrowserDelegate)

// Notifies the delegate that a peer was found.
- (void)browser:(MCNearbyServiceBrowser *)browser
      foundPeer:(MCPeerID *)peerID
withDiscoveryInfo:(NSDictionary *)info
{
    // If it's not this local peer, invite the peer to the session.
    if (![[_peerID displayName] isEqualToString:[peerID displayName]])
    {
        // Log.
        Log(@"%@ was found", [peerID displayName]);
        
        // Invite the peer to the session.
        [_nearbyServiceBrowser invitePeer:peerID
                                toSession:_session
                              withContext:nil
                                  timeout:30];

        // Log.
        Log(@"%@ invited", [peerID displayName]);
    }

}

// Notifies the delegate that a peer was lost.
- (void)browser:(MCNearbyServiceBrowser *)browser
       lostPeer:(MCPeerID *)peerID
{
    if (![[_peerID displayName] isEqualToString:[peerID displayName]])
    {
        Log(@"%@ was lost", [peerID displayName]);
    }
}

// Notifies the delegate that the browser failed to start browsing for peers.
- (void)browser:(MCNearbyServiceBrowser *)browser
didNotStartBrowsingForPeers:(NSError *)error
{
    Log(@"%@ did not start browsing for peers: %@", [_peerID displayName], [error localizedDescription]);
}

@end

// TSNPeerNetworkingContext (MCSessionDelegate) implementation.
@implementation TSNPeerNetworkingContext (MCSessionDelegate)

// Notifies the delegate that the local peer receieved data from a nearby peer.
- (void)session:(MCSession *)session
 didReceiveData:(NSData *)data
       fromPeer:(MCPeerID *)peerID
{
    // Log.
    Log(@"Received %lu bytes from %@", [data length], [peerID displayName]);

    // Notify.
    if ([[self delegate] respondsToSelector:@selector(peerNetworking:didReceiveData:)])
    {
        [[self delegate] peerNetworking:self didReceiveData:data];
    }
}

// Notifies the delegate that the local peer started receiving a resource from a nearby peer.
- (void)session:(MCSession *)session
didStartReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
   withProgress:(NSProgress *)progress
{
    Log(@"%@ started sending %@", [peerID displayName], resourceName);
}

// Notifies the delegate that the local peer finished receiving a resource from a nearby peer.
- (void)session:(MCSession *)session
didFinishReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
          atURL:(NSURL *)localURL
      withError:(NSError *)error
{
    Log(@"%@ finished sending %@ [%@]", [peerID displayName], resourceName, localURL);
}

// Notifies the delegate that the local peer received a stream from a nearby peer.
- (void)session:(MCSession *)session
didReceiveStream:(NSInputStream *)stream
       withName:(NSString *)streamName
       fromPeer:(MCPeerID *)peerID
{
    Log(@"%@ sent stream %@", [peerID displayName], streamName);
}

// Notifies the delegate that the state of a nearby peer changed.
- (void)session:(MCSession *)session
           peer:(MCPeerID *)peerID
 didChangeState:(MCSessionState)state
{
    // Log.
    NSString * stateValue;
    switch (state)
    {
        case MCSessionStateNotConnected:
            stateValue = @"not connected";
            break;
        
        case MCSessionStateConnecting:
            stateValue = @"connecting";
            break;
        
        case MCSessionStateConnected:
            stateValue = @"connected";
            break;
    }
    Log(@"%@ %@", [peerID displayName], stateValue);
    NSArray * connectedPeers = [_session connectedPeers];
    Log(@"------------ %lu Connected Peers ------------", [connectedPeers count]);
    for (MCPeerID * connectedPeerID in [_session connectedPeers])
    {
        if (![[connectedPeerID displayName] isEqualToString:[_peerID displayName]])
        {
            Log(@"    %@ connected", [connectedPeerID displayName]);
        }
        else
        {
            Log(@"**********************************************************");
            Log(@"**********************************************************");
            Log(@"**********************************************************");
            Log(@"**********************************************************");
            Log(@"**********************************************************");
            Log(@"**********************************************************");
            Log(@"**********************************************************");
            Log(@"**********************************************************");
            Log(@"**********************************************************");
        }
    }
}

// Notifies the delegate to validate the client certificate provided by a nearby peer when a connection is first established.
- (void)session:(MCSession *)session
didReceiveCertificate:(NSArray *)certificate
       fromPeer:(MCPeerID *)peerID
certificateHandler:(void (^)(BOOL accept))certificateHandler
{
    Log(@"%@ sent certificate",  [peerID displayName]);
    
    certificateHandler(YES);

    Log(@"%@ certificate accepted",  [peerID displayName]);
}

@end

// TSNPeerNetworkingContext (Internal) implementation.
@implementation TSNPeerNetworkingContext (Internal)
@end
