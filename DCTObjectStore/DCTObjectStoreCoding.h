//
//  DCTObjectStoreCoding.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 28.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;

@protocol DCTObjectStoreCoding <NSSecureCoding>
- (NSString *)identifier;
@end
