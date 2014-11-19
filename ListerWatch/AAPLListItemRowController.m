/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Defines the row controllers used in the \c AAPLWatchListInterfaceController class.
            
*/

#import "AAPLListItemRowController.h"

@implementation AAPLNoItemsRowController
@end

@interface AAPLListItemRowController ()

@property (nonatomic, weak) IBOutlet WKInterfaceLabel *textLabel;

@property (nonatomic, weak) IBOutlet WKInterfaceImage *checkBox;

@end

@implementation AAPLListItemRowController

- (void)setText:(NSString *)text {
    [self.textLabel setText:text];
}

- (void)setTextColor:(UIColor *)color {
    [self.textLabel setTextColor:color];
}

- (void)setCheckBoxImageNamed:(NSString *)imageName {
    [self.checkBox setImageNamed:imageName];
}

@end
