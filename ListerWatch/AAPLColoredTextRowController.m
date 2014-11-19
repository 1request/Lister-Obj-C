/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The \c AAPLColoredTextRowController class defines a simple interface that the \c AAPLWatchListsInterfaceController uses to represent an \c AAPLList object in the table.
            
*/

#import "AAPLColoredTextRowController.h"
@import WatchKit;

@interface AAPLColoredTextRowController ()

@property (nonatomic, weak) IBOutlet WKInterfaceGroup *listColorGroup;
@property (nonatomic, weak) IBOutlet WKInterfaceLabel *textLabel;

@end

@implementation AAPLColoredTextRowController

- (void)setText:(NSString *)text {
    [self.textLabel setText:text];
}

- (void)setColor:(UIColor *)color {
    [self.listColorGroup setBackgroundColor:color];
}

@end
