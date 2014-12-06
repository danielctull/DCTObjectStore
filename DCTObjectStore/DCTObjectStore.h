//
//  DCTObjectStore.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 13.01.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;

//! Project version number and string for DCTObjectStore.
FOUNDATION_EXPORT double DCTObjectStoreVersionNumber;
FOUNDATION_EXPORT const unsigned char DCTObjectStoreVersionString[];

#import "DCTObjectStoreCoding.h"
#import "DCTObjectStoreQuery.h"
#import "DCTObjectStoreQueryDelegate.h"


extern NSString *const DCTObjectStoreDidInsertObjectNotification;
extern NSString *const DCTObjectStoreDidChangeObjectNotification;
extern NSString *const DCTObjectStoreDidRemoveObjectNotification;
extern NSString *const DCTObjectStoreObjectKey;


@interface DCTObjectStore : NSObject

+ (instancetype)objectStoreWithName:(NSString *)name;

+ (instancetype)objectStoreWithName:(NSString *)name
					groupIdentifier:(NSString *)groupIdentifier
					cloudIdentifier:(NSString *)cloudIdentifier;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *groupIdentifier;
@property (nonatomic, readonly) NSString *cloudIdentifier;
@property (nonatomic, readonly) NSString *storeIdentifier;

@property (nonatomic, readonly) NSSet *objects;

- (void)saveObject:(id<DCTObjectStoreCoding>)object;
- (void)deleteObject:(id<DCTObjectStoreCoding>)object;

- (void)destroy;

+ (void)handleRemoteNotification:(NSDictionary *)notification;

@end
