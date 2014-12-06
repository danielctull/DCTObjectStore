//
//  EventCell.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 06.12.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "EventCell.h"

@interface EventCell () <UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UITextField *textField;
@end

@implementation EventCell

- (void)setName:(NSString *)name {
	self.textField.text = name;
}

- (NSString *)name {
	return self.textField.text;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (self.nameDidChangeBlock) {
		self.nameDidChangeBlock(textField.text);
	}
}


@end
