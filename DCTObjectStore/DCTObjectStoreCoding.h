//
//  DCTObjectStoreCoding.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 30.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;

@protocol DCTObjectStoreCoding <NSSecureCoding, NSObject>

// Enables partial decoding onto an existing object. Note that not all keys may exist in the coder, so only overwrite non-nil values.
- (void)decodeWithCoder:(NSCoder *)coder;

@end
