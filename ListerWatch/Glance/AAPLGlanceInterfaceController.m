/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Controls the interface of the Glance. The controller displays statistics about the Today list.
            
*/

#import "AAPLGlanceInterfaceController.h"
#import "AAPLWatchStoryboardConstants.h"
#import "AAPLGlanceBadge.h"
@import ListerKit;

@interface AAPLGlanceInterfaceController () <AAPLListsControllerDelegate, AAPLListPresenterDelegate>

@property (nonatomic, weak) IBOutlet WKInterfaceImage *glanceBadgeImage;
@property (nonatomic, weak) IBOutlet WKInterfaceGroup *glanceBadgeGroup;
@property (nonatomic, weak) IBOutlet WKInterfaceLabel *remainingItemsLabel;

@property (nonatomic, strong) AAPLListsController *listsController;
@property (nonatomic, strong) AAPLListDocument *listDocument;
@property (nonatomic, readonly) AAPLAllListItemsPresenter *listPresenter;

@end

@implementation AAPLGlanceInterfaceController
#pragma mark - Property Overrides

- (AAPLAllListItemsPresenter *)listPresenter {
    return self.listDocument.listPresenter;
}

#pragma mark - Initializers

- (instancetype)initWithContext:(id)context {
    self = [super initWithContext:context];
    
    if (self) {
        [self setUpInterface];
        
        if ([AAPLAppConfiguration sharedAppConfiguration].isFirstLaunch) {
            NSLog(@"Lister does not currently support configuring a storage option before the iOS app is launched. Please launch the iOS app first. See the Release Notes section in README.md for more information.");
        }
    }
    
    return self;
}

#pragma mark - Setup

- (void)setUpInterface {
    [self initializeListController];
    
    // Show the initial data.
    [self.glanceBadgeImage setImage:nil];

    [self.remainingItemsLabel setHidden:YES];
}

- (void)initializeListController {
    NSString *localizedTodayListName = [AAPLAppConfiguration sharedAppConfiguration].localizedTodayDocumentNameAndExtension;
    
    // Determine what kind of storage we should be using (local or iCloud).
    id<AAPLListCoordinator> listCoordinator;
    if ([AAPLAppConfiguration sharedAppConfiguration].storageOption != AAPLAppStorageCloud) {
        listCoordinator = [[AAPLLocalListCoordinator alloc] initWithLastPathComponent:localizedTodayListName firstQueryUpdateHandler:nil];
    }
    else {
        listCoordinator = [[AAPLCloudListCoordinator alloc] initWithLastPathComponent:localizedTodayListName firstQueryUpdateHandler:nil];
    }
    
    self.listsController = [[AAPLListsController alloc] initWithListCoordinator:listCoordinator delegateQueue:[NSOperationQueue mainQueue] sortComparator:^NSComparisonResult(AAPLListInfo *lhs, AAPLListInfo *rhs) {
        return [lhs.name localizedCaseInsensitiveCompare:rhs.name];
    }];
    
    self.listsController.delegate = self;
    
    [self.listsController startSearching];
}

#pragma mark - AAPLListsControllerDelegate

- (void)listsController:(AAPLListsController *)listsController didInsertListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    // Once we've found the Today list, we'll hand off ownership of listening to udpates to the list presenter.
    [self.listsController stopSearching];
    
    self.listsController = nil;
    
    // Update the badge with the Today list info.
    [self processListInfoAsTodayDocument:listInfo];
}

#pragma mark - AAPLListPresenterDelegate

- (void)listPresenterDidRefreshCompleteLayout:(id<AAPLListPresenting>)listPresenter {
    // Since the list changed completely, show present the Glance badge.
    [self presentGlanceBadge];
}

/*!
 * These methods are no ops because all of the data is bulk rendered after the the content changes. This can
 * occur in \c -listPresenterDidRefreshCompleteLayout: or in \c -listPresenterDidChangeListLayout:isInitialLayout:.
 */
- (void)listPresenterWillChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didInsertListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didRemoveListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListColorWithColor:(AAPLListColor)color {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didMoveListItem:(AAPLListItem *)listItem fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {}

- (void)listPresenterDidChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    /*
        The list's layout changed. However, since we don't care that a small detail about the list changed,
        we're going to re-animate the badge.
     */
    [self presentGlanceBadge];
}

#pragma mark - Convenience

- (void)processListInfoAsTodayDocument:(AAPLListInfo *)listInfo {
    NSDictionary *userInfo = @{AAPLListInfoURLPathKey: listInfo.URL.path};
    [self updateUserActivity:AAPLGlanceUserActivityName userInfo:userInfo];
    
    AAPLAllListItemsPresenter *listPresenter = [[AAPLAllListItemsPresenter alloc] init];

    self.listDocument = [[AAPLListDocument alloc] initWithFileURL:listInfo.URL listPresenter:listPresenter];
    
    listPresenter.delegate = self;
    
    [self.listDocument openWithCompletionHandler:^(BOOL success) {
        if (!success) {
            NSLog(@"Couldn't open document: %@.", self.listDocument.fileURL.absoluteString);
        }
    }];
}

- (void)presentGlanceBadge {
    NSInteger totalListItemCount = self.listPresenter.count;

    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"isComplete == YES"];
    NSArray *completeListItems = [self.listPresenter.presentedListItems filteredArrayUsingPredicate:filterPredicate];
    NSInteger completeListItemCount = completeListItems.count;

    AAPLGlanceBadge *glanceBadge = [[AAPLGlanceBadge alloc] initWithTotalItemCount:totalListItemCount completeItemCount:completeListItemCount];

    [self.glanceBadgeGroup setBackgroundImage:glanceBadge.groupBackgroundImage];
    [self.glanceBadgeImage setImageNamed:glanceBadge.imageName];
    [self.glanceBadgeImage startAnimatingWithImagesInRange:glanceBadge.imageRange duration:glanceBadge.animationDuration repeatCount:1];

    /*
        Create a localized string for the # items remaining in the Glance badge. The string is retrieved from
        the Localizable.stringsdict file.
     */
    NSString *itemsRemainingText = [NSString localizedStringWithFormat:NSLocalizedString(@"%d items left", nil), glanceBadge.incompleteItemCount];
    [self.remainingItemsLabel setText:itemsRemainingText];
    [self.remainingItemsLabel setHidden:NO];
}

@end
