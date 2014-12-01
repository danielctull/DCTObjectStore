//
//  DCTCloudObjectStoreChange.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 30.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
#import "DCTObjectStoreCoding.h"

typedef NS_ENUM(NSInteger, DCTCloudObjectStoreChangeType) {
	DCTCloudObjectStoreChangeTypeSave,
	DCTCloudObjectStoreChangeTypeDelete
};

@interface DCTCloudObjectStoreChange : NSObject <DCTObjectStoreCoding>

- (instancetype)initWithIdentifier:(NSString *)identifier object:(id<DCTObjectStoreCoding>)object type:(DCTCloudObjectStoreChangeType)type;
@property (nonatomic, readonly) NSString *idenitfier;
@property (nonatomic, readonly) id<DCTObjectStoreCoding> object;
@property (nonatomic, readonly) DCTCloudObjectStoreChangeType type;
@property (nonatomic, readonly) NSDate *date;

@end
