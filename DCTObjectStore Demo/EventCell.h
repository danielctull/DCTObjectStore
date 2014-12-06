//
//  EventCell.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 06.12.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import UIKit;

@interface EventCell : UITableViewCell

@property (nonatomic) NSString *name;

@property (nonatomic, copy) void (^nameDidChangeBlock)(NSString *name);

@end
