/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The \c AAPLWatchListInterfaceController that presents a single list managed by an \c AAPLListPresenting object.
            
*/

#import "AAPLWatchListInterfaceController.h"
#import "AAPLListItemRowController.h"
#import "AAPLWatchStoryboardConstants.h"
@import ListerKit;

@interface AAPLWatchListInterfaceController () <AAPLListPresenterDelegate>

@property (nonatomic, weak) IBOutlet WKInterfaceTable *interfaceTable;

@property (nonatomic, strong) AAPLListDocument *listDocument;

@property (nonatomic, readonly) AAPLIncompleteListItemsPresenter *listPresenter;

@end

@implementation AAPLWatchListInterfaceController

#pragma mark - Property Overrides

- (AAPLIncompleteListItemsPresenter *)listPresenter {
    return self.listDocument.listPresenter;
}

#pragma mark - Initialization

- (instancetype)initWithContext:(id)context {
    self = [super initWithContext:context];
    
    if (self) {
        NSAssert([context isKindOfClass:[AAPLListInfo class]], @"Expected class of `context` is AAPLListInfo.");

        AAPLListInfo *listInfo = context;
        _listDocument = [[AAPLListDocument alloc] initWithFileURL:listInfo.URL];

        [self setTitle:listInfo.name];
        [self setUpInterfaceTable];
    }
    
    return self;
}

- (void)setUpInterfaceTable {
    self.listDocument.listPresenter = [[AAPLIncompleteListItemsPresenter alloc] init];
    
    self.listPresenter.delegate = self;
    
    [self.listDocument openWithCompletionHandler:^(BOOL success) {
        if (!success) {
            NSLog(@"Couldn't open document: %@.", self.listDocument.fileURL);
        }
    }];
}

#pragma mark - Interface Table Selection

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    AAPLListItem *listItem = self.listPresenter.presentedListItems[rowIndex];

    [self.listPresenter toggleListItem:listItem];
}

#pragma mark - Actions

- (IBAction)markAllListItemsAsComplete {
    [self.listPresenter updatePresentedListItemsToCompletionState:YES];
}

- (IBAction)markAllListItemsAsIncomplete {
    [self.listPresenter updatePresentedListItemsToCompletionState:NO];
}

- (void)refreshAllData {
    NSInteger listItemCount = self.listPresenter.count;

    if (listItemCount > 0) {
        // Update the data to show all of the list items.
        [self.interfaceTable setNumberOfRows:listItemCount withRowType:AAPLWatchListControllerListItemRowType];
        
        for (NSInteger idx = 0; idx < listItemCount; idx++) {
            [self configureRowControllerAtIndex:idx];
        }
    }
    else {
        // Show a "No Items" row.
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];

        [self.interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLWatchListControllerListNoItemsRowType];
    }
}

#pragma mark - ListPresenterDelegate

- (void)listPresenterDidRefreshCompleteLayout:(id<AAPLListPresenting>)listPresenter {
    [self refreshAllData];
}

- (void)listPresenterWillChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    // `WKInterfaceTable` objects do not need to be notified of changes to the table, so this is a no op.
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didInsertListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    
    // The list presenter was previously empty. Remove the "no items" row.
    if (index == 0 && self.listPresenter.count == 1) {
        [self.interfaceTable removeRowsAtIndexes:indexSet];
    }
    
    [self.interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLWatchListControllerListItemRowType];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didRemoveListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    
    [self.interfaceTable removeRowsAtIndexes:indexSet];
    
    // The list presenter is now empty. Add the "no items" row.
    if (index == 0 && self.listPresenter.isEmpty) {
        [self.interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLWatchListControllerListNoItemsRowType];
    }
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    [self configureRowControllerAtIndex:index];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListColorWithColor:(AAPLListColor)color {
    for (NSInteger idx = 0; idx < self.listPresenter.count; idx++) {
        [self configureRowControllerAtIndex:idx];
    }
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didMoveListItem:(AAPLListItem *)listItem fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    // Remove the item from the fromIndex straight away.
    NSIndexSet *fromIndexSet = [[NSIndexSet alloc] initWithIndex:fromIndex];
    [self.interfaceTable removeRowsAtIndexes:fromIndexSet];
    
    /*
        Determine where to insert the moved item. If the `toIndex` was beyond the `fromIndex`, normalize
        its value.
    */
    NSIndexSet *toIndexSet;
    if (toIndex > fromIndex) {
        toIndexSet = [[NSIndexSet alloc] initWithIndex:toIndex - 1];
    }
    else {
        toIndexSet = [[NSIndexSet alloc] initWithIndex:toIndex];
    }
    
    [self.interfaceTable insertRowsAtIndexes:toIndexSet withRowType:AAPLWatchListControllerListItemRowType];
}

- (void)listPresenterDidChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    if (isInitialLayout) {
        // Display all of the list items on the first layout.
        [self refreshAllData];
    }
    else {
        /*
            The underlying document changed because of user interaction (this event only occurs if the list
            presenter's underlying list presentation changes based on user interaction).
         */
        [self.listDocument updateChangeCount:UIDocumentChangeDone];
    }
}

#pragma mark - Convenience

- (void)configureRowControllerAtIndex:(NSInteger)index {
    AAPLListItemRowController *listItemRowController = [self.interfaceTable rowControllerAtIndex:index];
    
    AAPLListItem *listItem = self.listPresenter.presentedListItems[index];
    
    [listItemRowController setText:listItem.text];
    UIColor *textColor = listItem.isComplete ? [UIColor grayColor] : [UIColor whiteColor];
    [listItemRowController setTextColor:textColor];
    
    // Update the checkbox image.
    NSString *state = listItem.isComplete ? @"checked" : @"unchecked";
    
    NSString *colorName = [AAPLNameFromListColor(self.listPresenter.color) lowercaseString];
    
    NSString *imageName = [NSString stringWithFormat:@"checkbox-%@-%@", colorName, state];
    
    [listItemRowController setCheckBoxImageNamed:imageName];
}

#pragma mark - Interface Life Cycle

- (void)didDeactivate {
    [self.listDocument closeWithCompletionHandler:nil];
}

@end
