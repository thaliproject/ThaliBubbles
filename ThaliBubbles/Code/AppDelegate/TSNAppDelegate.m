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
//  TSNAppDelegate.m
//

#import <TSNLogger.h>
#import <TSNThreading.h>
#import "TSNAppContext.h"
#import "TSNAppDelegate.h"
#import "TSNAppWindow.h"
#import "TSNAppViewController.h"

// Logging.
static inline void Log(NSString * format, ...)
{
    // Format the log entry.
    va_list args;
    va_start(args, format);
    NSString * formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    // Append the log entry.
    TSNLog([NSString stringWithFormat:@"          TSNAppDelegate: %@", formattedString]);
}

// TSNAppDelegate (UIApplicationDelegate) interface.
@interface TSNAppDelegate (UIApplicationDelegate) <UIApplicationDelegate>
@end

// TSNAppDelegate (Internal) interface.
@interface TSNAppDelegate (Internal)
@end

// TSNAppDelegate implementation.
@implementation TSNAppDelegate
{
@private
    // The app window.
    TSNAppWindow * _appWindow;
    
    // The app view controller.
    TSNAppViewController * _appViewController;
    
    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;

}

@end

// TSNAppDelegate (UIApplicationDelegate) implementation.
@implementation TSNAppDelegate (UIApplicationDelegate)

// Tells the delegate when the application has launched and may have additional launch options to handle.
- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _backgroundTaskIdentifier = UIBackgroundTaskInvalid;

    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
 
    // Configure logger.
    TSNLogger * logger = [TSNLogger singleton];
    [logger setMaxLogEntries:500];
    [logger setWriteToAppleSystemLog:YES];
    
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    // On iOS 8, register the user notification settings we use. This will prompt the user once.
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        UIUserNotificationSettings * userNotificationSettings = [UIUserNotificationSettings settingsForTypes:types
                                                                                                  categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:userNotificationSettings];
    }
#endif
    
    // Allocate and initialize the app window.
    _appWindow = [[TSNAppWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Allocate and initialize the app view controller.
    _appViewController = [[TSNAppViewController alloc] init];
    
    // Make the app visible.
    [_appWindow setRootViewController:_appViewController];
    [_appWindow makeKeyAndVisible];
    
    [[TSNAppContext singleton] startCommunications];
    
    // Success.
    return YES;
}

// Tells the delegate that the application is about to become inactive.
- (void)applicationWillResignActive:(UIApplication *)application
{
    Log(@"Application will resign active");
}

// Tells the delegate that the application is now in the background.
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    Log(@"Application did enter background");
}

// Tells the delegate that the application is about to enter the foreground.
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    Log(@"Application will enter foreground");
}

// Tells the delegate that the application has become active.
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    Log(@"Application did become active");
}

// Tells the delegate when the application is about to terminate.
- (void)applicationWillTerminate:(UIApplication *)application
{
    Log(@"Application will terminate");
}

@end

// TSNAppDelegate (Internal) implementation.
@implementation TSNAppDelegate (Internal)
@end
