//
//  AppDelegate.m
//  DCTObjectStore Demo
//
//  Created by Daniel Tull on 28.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import DCTObjectStore;
#import "AppDelegate.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[application registerForRemoteNotifications];
	return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
	[DCTObjectStore handleRemoteNotification:userInfo];
	completionHandler(UIBackgroundFetchResultNoData);
}

@end
