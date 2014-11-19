/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

*/

#import "InterfaceController.h"


@interface InterfaceController()

@end


@implementation InterfaceController

- (instancetype)initWithContext:(id)context {
    self = [super initWithContext:context];

    if (self){
    
        // Initialize variables here.
        // Configure interface objects here.
        NSLog(@"initWithContext");
        
    }

    return self;
}

- (void)willActivate {
    NSLog(@"Interface will activate...");
}

- (void)didDeactivate {
    NSLog(@"Interface did deactivate...");
}

@end



