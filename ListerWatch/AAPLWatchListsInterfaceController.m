/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The \c AAPLWatchListInterfaceController that presents a single list managed by a \c AAPLListPresenting instance.
            
*/

#import "AAPLWatchListsInterfaceController.h"
#import "AAPLWatchStoryboardConstants.h"
#import "AAPLColoredTextRowController.h"
@import ListerKit;

@interface AAPLWatchListsInterfaceController () <AAPLListsControllerDelegate>

@property (nonatomic, strong) AAPLListsController *listsController;

@property (nonatomic, weak) IBOutlet WKInterfaceTable *interfaceTable;

@end


@implementation AAPLWatchListsInterfaceController

- (instancetype)initWithContext:(id)context {
    self = [super initWithContext:context];

    if (self) {
        [self initializeListController];
        
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
        [self.interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLWatchListsInterfaceControllerNoListsRowType];
        
        if ([AAPLAppConfiguration sharedAppConfiguration].isFirstLaunch) {
            NSLog(@"Lister does not currently support configuring a storage option before the iOS app is launched. Please launch the iOS app first. See the Release Notes section in README.md for more information.");
        }
    }

    return self;
}

- (void)initializeListController {
    // Determine what kind of storage we should be using (local or iCloud).
    id<AAPLListCoordinator> listCoordinator;

    if ([AAPLAppConfiguration sharedAppConfiguration].storageOption != AAPLAppStorageCloud) {
        listCoordinator = [[AAPLLocalListCoordinator alloc] initWithPathExtension:AAPLAppConfigurationListerFileExtension firstQueryUpdateHandler:nil];
    }
    else {
        listCoordinator = [[AAPLCloudListCoordinator alloc] initWithPathExtension:AAPLAppConfigurationListerFileExtension firstQueryUpdateHandler:nil];
    }

    self.listsController = [[AAPLListsController alloc] initWithListCoordinator:listCoordinator delegateQueue:[NSOperationQueue mainQueue] sortComparator:^NSComparisonResult(AAPLListInfo *lhs, AAPLListInfo *rhs) {
        return [lhs.name localizedCaseInsensitiveCompare:rhs.name];
    }];
}

#pragma mark - Segues

- (id)contextForSegueWithIdentifier:(NSString *)segueIdentifier inTable:(WKInterfaceTable *)table rowIndex:(NSInteger)rowIndex {
    if ([segueIdentifier isEqualToString:AAPLWatchListsInterfaceControllerListSelectionSegue]) {
        AAPLListInfo *listInfo = self.listsController[rowIndex];
        
        return listInfo;
    }
    
    return nil;
}

#pragma mark - AAPLListsControllerDelegate

- (void)listsController:(AAPLListsController *)listsController didInsertListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    NSInteger numberOfLists = self.listsController.count;
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    
    // The lists controller was previously empty. Remove the "no lists" row.
    if (index == 0 && numberOfLists == 1) {
        [self.interfaceTable removeRowsAtIndexes:indexSet];
    }
    
    [self.interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLWatchListsInterfaceControllerListRowType];
    [self configureRowControllerAtIndex:index];
}

- (void)listsController:(AAPLListsController *)listsController didRemoveListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    NSInteger numberOfLists = self.listsController.count;
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    
    [self.interfaceTable removeRowsAtIndexes:indexSet];
    
    // The lists controller is now empty. Add the "no lists" row.
    if (index == 0 && numberOfLists == 0) {
        [self.interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLWatchListsInterfaceControllerNoListsRowType];
    }
}

- (void)listsController:(AAPLListsController *)listsController didUpdateListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    [self configureRowControllerAtIndex:index];
}

#pragma mark - Convenience

- (void)configureRowControllerAtIndex:(NSInteger)index {
    AAPLColoredTextRowController *watchListRowController = [self.interfaceTable rowControllerAtIndex:index];
    
    AAPLListInfo *listInfo = self.listsController[index];
    
    [watchListRowController setText:listInfo.name];
    
    [listInfo fetchInfoWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            AAPLColoredTextRowController *watchListRowController = [self.interfaceTable rowControllerAtIndex:index];
            
            [watchListRowController setColor:AAPLColorFromListColor(listInfo.color)];
        });
    }];
}

#pragma mark - Interface Life Cycle

- (void)willActivate {
    self.listsController.delegate = self;

    [self.listsController startSearching];
}

- (void)didDeactivate {
    [self.listsController stopSearching];
    
    self.listsController.delegate = nil;
}

- (NSString *)actionForUserActivity:(NSDictionary *)userActivity context:(id *)context {
    // The Lister watch app only supports continuing activities where `AAPLListInfoURLStringKey` is provided.
    NSString *listInfoURLPath = userActivity[AAPLListInfoURLPathKey];
    
    if (!listInfoURLPath) {
        return nil;
    }
    
    NSURL *listInfoURL = [NSURL fileURLWithPath:listInfoURLPath];
    AAPLListInfo *listInfo = [[AAPLListInfo alloc] initWithURL:listInfoURL];
    
    // Set the context to the listInfo (following the behavior of the selection segue).
    *context = listInfo;
    
    // Returne the watch list scene's identifier, set in Interface Builder to route the wearer to it.
    return AAPLWatchListInterfaceControllerName;
}

@end
