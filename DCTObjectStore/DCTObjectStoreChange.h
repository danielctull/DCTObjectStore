//
//  DCTObjectStoreChange.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 30.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
#import "DCTObjectStoreCoding.h"

extern const struct DCTObjectStoreChangeAttributes {
	__unsafe_unretained NSString *date;
	__unsafe_unretained NSString *identifier;
	__unsafe_unretained NSString *object;
	__unsafe_unretained NSString *type;
} DCTObjectStoreChangeAttributes;

typedef NS_ENUM(NSInteger, DCTObjectStoreChangeType) {
	DCTObjectStoreChangeTypeSave,
	DCTObjectStoreChangeTypeDelete
};

@interface DCTObjectStoreChange : NSObject <DCTObjectStoreCoding>

- (instancetype)initWithObject:(id<DCTObjectStoreCoding>)object type:(DCTObjectStoreChangeType)type;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) id<DCTObjectStoreCoding> object;
@property (nonatomic, readonly) DCTObjectStoreChangeType type;
@property (nonatomic, readonly) NSDate *date;

@end
