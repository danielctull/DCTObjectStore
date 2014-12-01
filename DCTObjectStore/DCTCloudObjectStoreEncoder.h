//
//  DCTCloudObjectStoreEncoder.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 11.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
@import CloudKit;


@interface DCTCloudObjectStoreEncoder : NSCoder

- (instancetype)initWithRecord:(CKRecord *)record;
@property (nonatomic, readonly) CKRecord *record;

@end
