//
//  DCTObjectStoreReachability.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 01.12.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;

extern NSString *const DCTObjectStoreReachabilityDidChangeNotification;

typedef NS_ENUM(NSInteger, DCTObjectStoreReachabilityStatus) {
	DCTObjectStoreReachabilityStatusUnknown,
	DCTObjectStoreReachabilityStatusConnected,
	DCTObjectStoreReachabilityStatusNotConnected
};

@interface DCTObjectStoreReachability : NSObject
@property (nonatomic, readonly) DCTObjectStoreReachabilityStatus status;
@end
