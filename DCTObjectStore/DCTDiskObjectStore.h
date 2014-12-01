//
//  DCTDiskObjectStore.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
@protocol DCTObjectStoreCoding;

@interface DCTDiskObjectStore : NSObject

- (instancetype)initWithURL:(NSURL *)URL;
@property (nonatomic, readonly) NSURL *URL;

- (void)saveObject:(id<DCTObjectStoreCoding>)object;
- (void)deleteObject:(id<DCTObjectStoreCoding>)object;
- (id<DCTObjectStoreCoding>)objectForIdentifier:(NSString *)identifier;

- (NSSet *)objects;

- (void)destroy;

@end
