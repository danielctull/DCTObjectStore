//
//  DCTObjectStore.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 13.01.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;

extern const struct DCTObjectStoreAttributes {
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *objects;
	__unsafe_unretained NSString *sortDescriptors;
} DCTObjectStoreAttributes;

@protocol DCTObjectStoreCoding <NSSecureCoding>
- (NSString *)identifier;
@end

@interface DCTObjectStore : NSObject

+ (instancetype)objectStoreWithName:(NSString *)name;
+ (instancetype)objectStoreWithName:(NSString *)name sortDescriptors:(NSArray *)sortDescriptors;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSArray *objects;
@property (nonatomic, readonly) NSArray *sortDescriptors;

@property (nonatomic) NSPredicate *objectPredicate;

- (void)addObject:(id<DCTObjectStoreCoding>)object;
- (void)removeObject:(id<DCTObjectStoreCoding>)object;
- (void)updateObject:(id<DCTObjectStoreCoding>)object;

- (BOOL)save:(NSError *__autoreleasing*)error;

@end
