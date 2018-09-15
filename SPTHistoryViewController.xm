#import "SPTHistoryViewController.h"
#import "SPTTrackTableViewCell.h"
#import "SPTHistorySwipeDelegate.h"
#import "SPTHistorySettingsViewController.h"

@interface SPTTrackContextButton : UIButton
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) SPTTrackTableViewCell *cell;
@end

@implementation SPTTrackContextButton
@end


@implementation SPTHistoryViewController
@dynamic view;

- (id)initWithTracks:(NSArray *)tracks
 nowPlayingBarHeight:(CGFloat)height
         imageLoader:(SPTGLUEImageLoader *)imageLoader
              player:(SPTPlayerImpl *)player
  contextImageLoader:(SPTImageLoaderImplementation *)contextImageLoader
     playlistFeature:(PlaylistFeatureImplementation *)playlistFeature
             session:(SPSession *)session
  contextMenuFeature:(SPContextMenuFeatureImplementation *)contextMenuFeature {
    if (self = [super init]) {
        self.tracks = tracks;
        self.nowPlayingBarHeight = height;
        self.sourceURL = [NSURL URLWithString:@"spotify:collection:history"];
        self.imageLoader = imageLoader;
        self.player = player;
        self.modalPresentationController = contextMenuFeature.UIPresentationService.modalPresentationController;
        self.contextImageLoader = contextImageLoader;
        self.playlistFeature = playlistFeature;
        self.session = session;
        self.contextMenuFeature = contextMenuFeature;

        // Navigation items
        self.navigationItem = [[UINavigationItem alloc] initWithTitle:@"History"];
        UIImage *settingsIcon = [UIImage imageForSPTIcon:11 size:CGSizeMake(24, 24)];
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithImage:settingsIcon
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(presentSettings:)];
        [self.navigationItem setRightBarButtonItem:rightItem];

        [self.session.offlineNotifier addOfflineModeObserver:self];
    }

    return self;
}

- (void)presentSettings:(UIBarButtonItem *)sender {
    SPTHistorySettingsViewController *vc = [[SPTHistorySettingsViewController alloc] initWithNowPlayingBarHeight:self.nowPlayingBarHeight
                                                                                           historyViewController:self
                                                                                                 playlistFeature:self.playlistFeature];
    [self.navigationController pushViewControllerOnTopOfTheNavigationStack:vc animated:YES];
}

- (void)dealloc {
    [self.session.offlineNotifier removeOfflineModeObserver:self];
}

- (void)loadView {
    self.view = [[%c(SPTTableView) alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];

    // Check for empty history
    if (!self.tracks || self.tracks.count == 0) {
        [self createInfoViewIfNeeded];
        self.view.scrollEnabled = NO;
        [self.view addSubview:self.infoView];
    }

    self.view.dataSource = self;
    self.view.delegate = self;
    self.view.contentInset = UIEdgeInsetsMake(self.view.contentInset.top,
                                              self.view.contentInset.left,
                                              self.view.contentInset.bottom + self.nowPlayingBarHeight,
                                              self.view.contentInset.right);
}

- (void)createInfoViewIfNeeded {
    if (!_infoView) {
        self.infoView = [[%c(SPTInfoView) alloc] initWithFrame:self.view.frame];
        self.infoView.title = @"Ohoh, empty history!";
        self.infoView.text = @"Go and play some music and watch it appear here afterwards.";
        self.infoView.image = [UIImage spt_infoViewErrorIcon];
    }
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return [self.tracks count];
}

- (SPTTrackTableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";

    SPTTrackTableViewCell *cell = [table dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
        cell = [[%c(SPTTrackTableViewCell) alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];

    cell.session = self.session;

    NSDictionary *track = self.tracks[indexPath.row];

    cell.trackName = track[@"name"];
    cell.artist = track[@"artist"];
    cell.artistURI = [NSURL URLWithString:track[@"artistURI"]];
    cell.album = track[@"album"];
    cell.albumURI = [NSURL URLWithString:track[@"albumURI"]];
    cell.trackURI = [NSURL URLWithString:track[@"URI"]];
    cell.imageURL = [NSURL URLWithString:track[@"imageURL"]];

    // Colors
    cell.backgroundColor = UIColor.clearColor;
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = UIColor.blackColor;
    [cell setSelectedBackgroundView:bgColorView];

    // Accessory button
    CGRect frame = CGRectMake(self.view.frame.size.width - 48,
                              [self tableView:table heightForRowAtIndexPath:indexPath] / 2 - 48 / 2,
                              48.0, 48.0);

    SPTTrackContextButton *button = [SPTTrackContextButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self
               action:@selector(showContextMenu:)
     forControlEvents:UIControlEventTouchUpInside];

    UIImage *dots = [UIImage imageForSPTIcon:23 size:CGSizeMake(20.0, 20.0)];
    [button setImage:dots forState:UIControlStateNormal];
    button.frame = frame;
    button.indexPath = indexPath;
    button.cell = cell;
    cell.accessoryView = button;
    [cell.contentView addSubview:button];

    // Texts
    UIFont *font = [UIFont fontWithName:@"CircularSpUI-Book" size:16];
    cell.textLabel.font = font;
    cell.textLabel.textColor = UIColor.whiteColor;
    cell.textLabel.text = track[@"name"];

    font = [UIFont fontWithName:@"CircularSpUI-Book" size:13];
    cell.detailTextLabel.font = font;
    cell.detailTextLabel.textColor = [UIColor colorWithRed:0.702 green:0.702 blue:0.702 alpha:1.0];
    cell.detailTextLabel.text = cell.artist;
    
    // Load image - Add placeholder image
    CGSize imageSize = CGSizeMake(54, 54);
    UIImage *img = [UIImage trackSPTPlaceholderWithSize:0];
    cell.imageView.image = img;

    if ([self.imageLoader respondsToSelector:@selector(loadImageForURL:imageSize:completion:)]) {
        [self.imageLoader loadImageForURL:cell.imageURL imageSize:imageSize completion:^(UIImage *img) {
            if (img)
                cell.imageView.image = img;
        }];
    }

    // Left and right swipes
    SPTSwipeableTableViewCellShelf *lShelf = [%c(SPTSwipeableTableViewCellShelf) queueShelf];
    SPTSwipeableTableViewCellShelf *rShelf = [%c(SPTSwipeableTableViewCellShelf) removeFromCollectionShelf];
    [cell setShelf:lShelf forGesture:leftSwipe];
    [cell setShelf:rShelf forGesture:rightSwipe];
    [cell setSwipeDelegate:[[SPTHistorySwipeDelegate alloc] initWithTableView:table
                                                                       player:self.player
                                                        historyViewController:self]];

    return cell;
}

- (void)showContextMenu:(SPTTrackContextButton *)sender {
    if (!self.modalPresentationController)
        return;

    SPTTrackTableViewCell *cell = sender.cell;

    /* Build actions */
    NSMutableArray *tasks = [NSMutableArray new];

    // Add to playlist
    if ([self.contextMenuFeature.actionsFactory respondsToSelector:@selector(actionForURIs:logContext:sourceURL:containerURL:playlistName:actionIdentifier:contextSourceURL:)]) {
        SPTask *playlist = [self.contextMenuFeature.actionsFactory actionForURIs:@[cell.trackURI]
                                                                      logContext:nil
                                                                       sourceURL:self.sourceURL
                                                                    containerURL:nil
                                                                    playlistName:cell.trackName
                                                                actionIdentifier:@"add-to-playlist"
                                                                contextSourceURL:self.sourceURL];
        [tasks addObject:playlist];
    }

    // Add to queue
    if ([self.contextMenuFeature.actionsFactory respondsToSelector:@selector(actionForURI:logContext:sourceURL:tracks:actionIdentifier:)]) {
        SPTPlayerTrack *track = [%c(SPTPlayerTrack) trackWithURI:cell.trackURI];
        SPTask *queue = [self.contextMenuFeature.actionsFactory actionForURI:nil
                                                                  logContext:nil
                                                                   sourceURL:self.sourceURL
                                                                      tracks:@[track]
                                                            actionIdentifier:@"queue-track"];
        [tasks addObject:queue];
    }

    // Share
    if ([self.contextMenuFeature.actionsFactory respondsToSelector:@selector(actionForURI:logContext:sourceURL:itemName:creatorName:sourceName:imageURL:clipboardLinkTitle:actionIdentifier:)]) {
        SPTask *share = [self.contextMenuFeature.actionsFactory actionForURI:cell.trackURI
                                                                  logContext:nil
                                                                   sourceURL:self.sourceURL
                                                                    itemName:cell.trackName
                                                                 creatorName:cell.artist
                                                                  sourceName:cell.artist
                                                                    imageURL:cell.imageURL
                                                          clipboardLinkTitle:nil
                                                            actionIdentifier:@"share-track"];
        [tasks addObject:share];
    }

    if ([self.contextMenuFeature.actionsFactory respondsToSelector:@selector(actionForURI:logContext:sourceURL:actionIdentifier:)]) {
        // Collection
        SPTask *collection = [self.contextMenuFeature.actionsFactory actionForURI:cell.trackURI
                                                                       logContext:nil
                                                                        sourceURL:self.sourceURL
                                                                 actionIdentifier:@"collection"];
        [tasks insertObject:collection atIndex:0];

        // Start radio
        SPTask *radio = [self.contextMenuFeature.actionsFactory actionForURI:cell.trackURI
                                                                  logContext:nil
                                                                   sourceURL:self.sourceURL
                                                            actionIdentifier:@"start-radio"];
        [tasks addObject:radio];
    }

    // Go to album
    if ([self.contextMenuFeature.actionsFactory respondsToSelector:@selector(viewAlbumWithAlbumURL:logContext:)]) {
        SPTask *album = [self.contextMenuFeature.actionsFactory viewAlbumWithAlbumURL:cell.albumURI logContext:nil];
        [tasks addObject:album];
    }

    // Go to artist
    if ([self.contextMenuFeature.actionsFactory respondsToSelector:@selector(viewArtistWithURL:logContext:)]) {
        SPTask *artist = [self.contextMenuFeature.actionsFactory viewArtistWithURL:cell.artistURI logContext:nil];
        [tasks addObject:artist];
    }

    [self presentContextMenuWithTasks:tasks fromCell:cell fromButton:sender];
}

- (void)presentContextMenuWithTasks:(NSArray *)tasks
                           fromCell:(SPTTrackTableViewCell *)cell
                         fromButton:(SPTTrackContextButton *)sender {
    NSString *subtitle = [NSString stringWithFormat:@"%@ • %@", cell.artist, cell.album];

    // iPad
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        SPTContextMenuViewControllerIPad *vc = nil;
        if ([%c(SPTContextMenuViewControllerIPad) instancesRespondToSelector:@selector(initWithHeaderImageURL:headerImagePlaceholder:title:subtitle:metadataTitle:actions:entityURL:trackURL:imageLoader:senderView:)]) {
            vc = [[%c(SPTContextMenuViewControllerIPad) alloc] initWithHeaderImageURL:cell.imageURL
                                                               headerImagePlaceholder:[UIImage trackSPTPlaceholderWithSize:0]
                                                                                title:cell.trackName
                                                                             subtitle:subtitle
                                                                        metadataTitle:nil
                                                                                tasks:tasks
                                                                            entityURL:self.sourceURL
                                                                             trackURL:cell.trackURI
                                                                          imageLoader:self.contextImageLoader
                                                                           senderView:sender];
            SPNavigationController *navController = [[%c(SPNavigationController) alloc] initWithRootViewController:vc];
            vc.currentPopoverController = [[%c(SPTPopoverController) alloc] initWithContentViewController:navController];
            SPTContextMenuIpadPresenterImplementation *contextPresenter = [[%c(SPTContextMenuIpadPresenterImplementation) alloc] initWithPopoverController:vc.currentPopoverController];
            [contextPresenter presentWithSenderView:sender permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
        }
        return;
    }

    // iPhone
    SPTScannablesContextMenuHeaderView *headerView = nil;
    if ([%c(SPTScannablesContextMenuHeaderView) instancesRespondToSelector:@selector(initWithTitle:subtitle:entityURL:dataSource:onboardingPresenter:authorizationRequester:dependencies:alertController:)]) {
        id dep = nil;
        if ([self.contextMenuFeature.scannablesService respondsToSelector:@selector(scannableDependencies)]) // >= 8.4.39
            dep = self.contextMenuFeature.scannablesService.scannableDependencies;
        else if ([self.contextMenuFeature.scannablesService respondsToSelector:@selector(dependencies)])
            dep = self.contextMenuFeature.scannablesService.dependencies;


        SPTAlertPresenter *presenter = nil;
        if ([%c(SPTAlertPresenter) respondsToSelector:@selector(sharedInstance)])
            presenter = [%c(SPTAlertPresenter) sharedInstance];
        else if ([%c(SPTAlertPresenter) respondsToSelector:@selector(defaultPresenterWithWindow:)])
            presenter = [%c(SPTAlertPresenter) defaultPresenterWithWindow:[UIApplication sharedApplication].keyWindow];

        headerView = [[%c(SPTScannablesContextMenuHeaderView) alloc] initWithTitle:cell.trackName
                                                                          subtitle:subtitle
                                                                         entityURL:cell.trackURI
                                                                        dataSource:self.contextMenuFeature.scannablesService.scannablesDataSource
                                                               onboardingPresenter:self.contextMenuFeature.scannablesService.onboardingPresenter
                                                            authorizationRequester:self.contextMenuFeature.scannablesService.authorizationRequester
                                                                      dependencies:dep
                                                                   alertController:presenter];
    }

    /* Create view controller */
    SPTContextMenuOptionsImplementation *options = [self.contextMenuFeature.contextMenuOptionsFactory contextMenuOptionsWithScannableEnabled:YES];

    id theme = nil;
    if (%c(GLUETheme))
        theme = [%c(GLUETheme) themeWithSPTTheme:[%c(SPTTheme) catTheme]];
    else if (%c(GLUEThemeBase))
        theme = [%c(GLUEThemeBase) themeWithSPTTheme:[%c(SPTTheme) catTheme]];

    SPTContextMenuViewController *vc = nil;
    if ([%c(SPTContextMenuViewController) instancesRespondToSelector:@selector(initWithHeaderImageURL:tasks:entityURL:imageLoader:headerView:modalPresentationController:options:theme:notificationCenter:)]) {
        // 8.4.62
        vc = [[%c(SPTContextMenuViewController) alloc] initWithHeaderImageURL:cell.imageURL
                                                                        tasks:tasks
                                                                    entityURL:cell.trackURI
                                                                  imageLoader:self.contextImageLoader
                                                                   headerView:headerView
                                                  modalPresentationController:self.modalPresentationController
                                                                      options:options
                                                                        theme:theme
                                                           notificationCenter:[NSNotificationCenter defaultCenter]];
    } else {
        SPTContextMenuModel *model = [[%c(SPTContextMenuModel) alloc] initWithOptions:options player:self.player];
        if ([%c(SPTContextMenuViewController) instancesRespondToSelector:@selector(initWithHeaderImageURL:tasks:entityURL:imageLoader:headerView:modalPresentationController:logger:model:theme:notificationCenter:)]) {
            // 8.4.31
            vc = [[%c(SPTContextMenuViewController) alloc] initWithHeaderImageURL:cell.imageURL
                                                                            tasks:tasks
                                                                        entityURL:cell.trackURI
                                                                      imageLoader:self.contextImageLoader
                                                                       headerView:headerView
                                                      modalPresentationController:self.modalPresentationController
                                                                           logger:nil
                                                                            model:model
                                                                            theme:theme
                                                               notificationCenter:[NSNotificationCenter defaultCenter]];
        } else if ([%c(SPTContextMenuViewController) instancesRespondToSelector:@selector(initWithHeaderImageURL:tasks:entityURL:imageLoader:headerView:modalPresentationController:model:theme:notificationCenter:)]) {
            // 8.4.34
            vc = [[%c(SPTContextMenuViewController) alloc] initWithHeaderImageURL:cell.imageURL
                                                                            tasks:tasks
                                                                        entityURL:cell.trackURI
                                                                      imageLoader:self.contextImageLoader
                                                                       headerView:headerView
                                                      modalPresentationController:self.modalPresentationController
                                                                            model:model
                                                                            theme:theme
                                                               notificationCenter:[NSNotificationCenter defaultCenter]];
        }
    }

    if (vc)
        [self.modalPresentationController presentViewController:vc animated:YES completion:nil];
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *URI = ((SPTTrackTableViewCell *)[table cellForRowAtIndexPath:indexPath]).trackURI;
    SPTPlayerContext *context = [%c(SPTPlayerContext) contextForURI:URI];
    [self.player playContext:context options:nil];
    [table deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)table heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

- (void)offlineModeState:(id)arg updated:(BOOL)offline {
    for (SPTTrackTableViewCell *cell in self.view.visibleCells) {
        float alpha = 1;

        NSInteger offlineState = [self.session.offlineManager stateForTrackWithURL:cell.trackURI];
        if (offline && offlineState == isNotAvailableOffline)
            alpha = 0.4;
        cell.alpha = alpha;
    }
}

- (BOOL)checkEmptyTracks:(NSArray *)newTracks {
    if (!newTracks || newTracks.count == 0) {
        [self createInfoViewIfNeeded];
        [self.view addSubview:self.infoView];
        self.view.scrollEnabled = NO;
        [self.view reloadData];
        return YES;
    }
    return NO;
}

- (void)updateListWithTracks:(NSArray *)newTracks {
    // Removed all items?
    if ([self checkEmptyTracks:newTracks])
        return;

    int prevNumberOfTracks = [self.tracks count];

    int diff = newTracks.count - prevNumberOfTracks;

    self.tracks = newTracks;

    NSIndexPath *indexPath = nil;
    if (diff > 0) {
        // Addition
        NSMutableArray *indexPaths = [NSMutableArray new];
        for (int i = 0; i < diff; i++) {
            indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [indexPaths addObject:indexPath];
        }

        if (self.infoView) {
            [self.infoView removeFromSuperview];
            self.view.scrollEnabled = YES;
        }

        [self.view insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (diff < 0) {
        // Removal
        NSMutableArray *indexPaths = [NSMutableArray new];
        for (int i = newTracks.count; i < prevNumberOfTracks; i++) {
            indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [indexPaths addObject:indexPath];
        }
        [self.view deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        // Added one song, removed one
        [self.view beginUpdates];
        indexPath = [NSIndexPath indexPathForRow:prevNumberOfTracks - 1 inSection:0];
        [self.view deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.view insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.view endUpdates];
    }
}

@end
