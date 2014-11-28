//
//  DCTObjectStoreCloudEncoder.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 11.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
@import CloudKit;

@interface DCTObjectStoreCloudEncoder : NSCoder

+ (NSArray *)archivedRecordsWithRootObject:(id)rootObject;

@end
