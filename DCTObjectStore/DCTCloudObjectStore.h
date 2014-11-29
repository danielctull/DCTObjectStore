//
//  DCTCloudObjectStore.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
@protocol DCTCloudObjectStoreDelegate;


@interface DCTCloudObjectStore : NSObject

- (instancetype)initWithStoreIdentifier:(NSString *)storeIdentifier
						cloudIdentifier:(NSString *)cloudIdentifier;

@property (nonatomic, readonly) NSString *storeIdentifier;
@property (nonatomic, readonly) NSString *cloudIdentifier;

@property (nonatomic, weak) id<DCTCloudObjectStoreDelegate> delegate;

- (void)saveObject:(id<NSSecureCoding>)object;
- (void)deleteObject:(id<NSSecureCoding>)object;

- (void)destroy;

@end
