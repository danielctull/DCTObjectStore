//
//  DCTObjectStoreReachability.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 01.12.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;

extern NSString *const DCTObjectStoreReachabilityDidChangeNotification;

@interface DCTObjectStoreReachability : NSObject
@property (nonatomic, readonly, getter=isReachable) BOOL reachable;
@end
