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

extern const struct DCTObjectStoreAttributes {
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *objects;
	__unsafe_unretained NSString *sortDescriptors;
} DCTObjectStoreAttributes;

extern NSString *const DCTObjectStoreDidChangeNotification;

@protocol DCTObjectStoreCoding <NSSecureCoding>
- (NSString *)identifier;
@end

@interface DCTObjectStore : NSObject

+ (instancetype)objectStoreWithName:(NSString *)name;
+ (instancetype)objectStoreWithName:(NSString *)name sortDescriptors:(NSArray *)sortDescriptors;
+ (instancetype)objectStoreWithName:(NSString *)name sortDescriptors:(NSArray *)sortDescriptors groupIdentifier:(NSString *)groupIdentifier;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSArray *objects;
@property (nonatomic, readonly) NSArray *sortDescriptors;
@property (nonatomic, readonly) NSString *groupIdentifier;

@property (nonatomic) NSPredicate *objectPredicate;

- (void)reload;
- (void)saveObject:(id<DCTObjectStoreCoding>)object;
- (void)deleteObject:(id<DCTObjectStoreCoding>)object;

@end
