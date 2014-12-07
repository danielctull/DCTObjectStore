//
//  DCTCloudObjectStore.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
@protocol DCTCloudObjectStoreDelegate;
@protocol DCTObjectStoreCoding;


@interface DCTCloudObjectStore : NSObject

- (instancetype)initWithName:(NSString *)name
			 storeIdentifier:(NSString *)storeIdentifier
			 cloudIdentifier:(NSString *)cloudIdentifier
						 URL:(NSURL *)URL;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *storeIdentifier;
@property (nonatomic, readonly) NSString *cloudIdentifier;
@property (nonatomic, readonly) NSURL *URL;

@property (nonatomic, weak) id<DCTCloudObjectStoreDelegate> delegate;

- (void)saveObject:(id<DCTObjectStoreCoding>)object;
- (void)deleteObject:(id<DCTObjectStoreCoding>)object;

- (void)destroy;

- (void)handleNotification:(CKRecordZoneNotification *)notification;

@end
