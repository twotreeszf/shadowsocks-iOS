//
//  SWBAppDelegate.m
//  ShadowWeb
//
//  Created by clowwindy on 2/16/13.
//  Copyright (c) 2013 clowwindy. All rights reserved.
//
#import "SWBAppDelegate.h"

#import "ShadowsocksRunner.h"
#import "ProxySettingsTableViewController.h"

#define kProxyModeKey @"proxy mode"

@implementation SWBAppDelegate {
    BOOL polipoRunning;
    BOOL polipoEnabled;
    NSURL *ssURL;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{

    }];
    polipoEnabled = YES;
    dispatch_queue_t proxy = dispatch_queue_create("proxy", NULL);
    dispatch_async(proxy, ^{
        [self runProxy];
    });

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    ProxySettingsTableViewController *settingsController = [[ProxySettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsController];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];

    /*
    QRCodeViewController *qrCodeViewController = [[QRCodeViewController alloc] initWithReturnBlock:^(NSString *code) {
        if (code) {
            NSURL *URL = [NSURL URLWithString:code];
            if (URL) {
                [[UIApplication sharedApplication] openURL:URL];
            }
        }
    }];
    */
    
    return YES;
}


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [self application:application openURL:url sourceApplication:nil annotation:nil];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    ssURL = url;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:_L(Use this server?) message:[url absoluteString] delegate:self cancelButtonTitle:_L(Cancel) otherButtonTitles:_L(OK), nil];
    [alertView show];
    return YES;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [ShadowsocksRunner openSSURL:ssURL];
    } else {
        // Do nothing
    }
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Run proxy

- (void)runProxy {
    [ShadowsocksRunner reloadConfig];
    for (; ;) {
        if ([ShadowsocksRunner runProxy]) {
            sleep(1);
        } else {
            sleep(2);
        }
    }
}

#pragma mark polipo

@end
