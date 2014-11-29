//
//  DCTDiskObjectStore.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;

@interface DCTDiskObjectStore : NSObject

- (instancetype)initWithStoreIdentifier:(NSString *)storeIdentifier groupIdentifier:(NSString *)groupIdentifier;
@property (nonatomic, readonly) NSString *storeIdentifier;
@property (nonatomic, readonly) NSString *groupIdentifier;
@property (nonatomic, readonly) NSURL *URL;

- (void)saveObject:(id<NSSecureCoding>)object;
- (void)deleteObject:(id<NSSecureCoding>)object;

- (NSSet *)objects;

- (void)destroy;

@end
