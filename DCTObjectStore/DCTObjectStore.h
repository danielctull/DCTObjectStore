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
#import "DCTObjectStoreController.h"
#import "DCTObjectStoreControllerDelegate.h"



@interface DCTObjectStore : NSObject

+ (instancetype)objectStoreWithName:(NSString *)name;
+ (instancetype)objectStoreWithName:(NSString *)name groupIdentifier:(NSString *)groupIdentifier synchonizable:(BOOL)synchonizable;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *groupIdentifier;
@property (nonatomic, readonly) BOOL synchonizable;

@property (nonatomic, readonly) NSSet *objects;

- (void)saveObject:(id<NSSecureCoding>)object;
- (void)deleteObject:(id<NSSecureCoding>)object;

+ (void)deleteStore:(DCTObjectStore *)store;

@end
