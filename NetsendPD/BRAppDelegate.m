//
//  BRAppDelegate.m
//  NetsendPD
//
//  Created by Bektur Ryskeldiev on 5/18/14.
//  Copyright (c) 2014 Bektur Ryskeldiev. All rights reserved.
//

#import "BRAppDelegate.h"

#import "DDASLLogger.h"
#import "DDTTYLogger.h"

#import "BRPdManager.h"

#import "BRConstants.h"

@interface BRAppDelegate ()

- (void) setupLogger;

@end

@implementation BRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupLogger];
    
    // initializing pure data
    BRPdManager *pdManager = [BRPdManager sharedInstance];
    [pdManager openPatch:@"receive_pd.pd" withPath:[[NSBundle mainBundle] bundlePath]];
    
    NSString* appKey = @"0nvhp9ngucy4tgc";
    NSString* appSecret = @"q7ojpf5qzj7d3fl";
    NSString *root = kDBRootAppFolder;
    
    DBSession* session =
    [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
    [DBSession setSharedSession:session];
    
    return YES;
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
  sourceApplication:(NSString *)source
         annotation:(id)annotation
{
    if ([[DBSession sharedSession] handleOpenURL:url])
    {
        if ([[DBSession sharedSession] isLinked])
        {
            DDLogVerbose(@"Linked successfully");
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDropboxLinked object:nil];
        }
        else
        {
            DDLogVerbose(@"Unlinked successfully");
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDropboxUnLinked object:nil];
        }
        return YES;
    }
    DDLogError(@"Can't link the app");
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - DDLog setup

- (void) setupLogger
{
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
}

@end
