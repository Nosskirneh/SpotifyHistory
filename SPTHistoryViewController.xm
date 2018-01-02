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
      statefulPlayer:(SPTStatefulPlayer *)statefulPlayer
modalPresentationController:(SPTModalPresentationControllerImplementation *)modalPresentationController
  contextImageLoader:(SPTImageLoaderImplementation *)contextImageLoader
     playlistFeature:(PlaylistFeatureImplementation *)playlistFeature
  collectionPlatform:(SPTCollectionPlatformImplementation *)collectionPlatform
      linkDispatcher:(SPTLinkDispatcherImplementation *)linkDispatcher
scannablesTestManager:(SPTScannablesTestManagerImplementation *)scannablesTestManager
        radioManager:(SPTRadioManager *)radioManager
             session:(SPSession *)session
   dataLoaderFactory:(SPTDataLoaderFactory *)dataLoaderFactory
        shareFeature:(SPTShareFeatureImplementation *)shareFeature {
    if (self = [super init]) {
        self.tracks = tracks;
        self.nowPlayingBarHeight = height;
        self.imageLoader = imageLoader;
        self.statefulPlayer = statefulPlayer;
        self.modalPresentationController = modalPresentationController;
        self.contextImageLoader = contextImageLoader;
        self.playlistFeature = playlistFeature;
        self.collectionPlatform = collectionPlatform;
        self.linkDispatcher = linkDispatcher;
        self.scannablesTestManager = scannablesTestManager;
        self.radioManager = radioManager;
        self.session = session;
        self.dataLoaderFactory = dataLoaderFactory;
        self.shareFeature = shareFeature;

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
    [super dealloc];
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
                                              self.view.contentInset.left - 4,
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
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:prefPath];
    self.tracks = prefs[kTracks];
    return [self.tracks count];
}

- (SPTTrackTableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";

    SPTTrackTableViewCell *cell = [table dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
        cell = [[%c(SPTTrackTableViewCell) alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Standard"];

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
    SPTTrackContextButton *button = [SPTTrackContextButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self
               action:@selector(showContextMenu:)
     forControlEvents:UIControlEventTouchUpInside];

    UIImage *dots = [UIImage imageForSPTIcon:23 size:CGSizeMake(20.0, 20.0)];
    [button setImage:dots forState:UIControlStateNormal];
    button.frame = CGRectMake(self.view.frame.size.width - 48,
                              [self tableView:table heightForRowAtIndexPath:indexPath] / 2 - 48 / 2,
                              48.0, 48.0);
    button.indexPath = indexPath;
    button.cell = cell;
    [cell addSubview:button];

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

    [self.imageLoader loadImageForURL:cell.imageURL imageSize:imageSize completion:^(UIImage *img) {
        if (img) {
            cell.imageView.image = img;
        }
    }];

    // Left and right swipes
    SPTSwipeableTableViewCellShelf *lShelf = [%c(SPTSwipeableTableViewCellShelf) queueShelf];
    SPTSwipeableTableViewCellShelf *rShelf = [%c(SPTSwipeableTableViewCellShelf) removeFromCollectionShelf];
    [cell setShelf:lShelf forGesture:leftSwipe];
    [cell setShelf:rShelf forGesture:rightSwipe];
    [cell setSwipeDelegate:[[SPTHistorySwipeDelegate alloc] initWithTableView:table
                                                                       player:self.statefulPlayer.player
                                                        historyViewController:self]];

    return cell;
}

- (void)showContextMenu:(SPTTrackContextButton *)sender {
    static NSURL *sourceURL = [NSURL URLWithString:@"spotify:history"];

    SPTTrackTableViewCell *cell = sender.cell;

    /* Create headerView */
    SPTScannablesDependencies *dependencies = nil;
    if ([%c(SPTScannablesDependencies) instancesRespondToSelector:@selector(initWithSpotifyApplication:linkDispatcher:device:theme:testManager:logger:)]) {
        dependencies = [[%c(SPTScannablesDependencies) alloc] initWithSpotifyApplication:[UIApplication sharedApplication]
                                                                          linkDispatcher:self.linkDispatcher
                                                                                  device:[UIDevice currentDevice]
                                                                                   theme:[%c(SPTTheme) catTheme]
                                                                             testManager:self.scannablesTestManager
                                                                                  logger:nil];
    }

    NSString *subtitle = [NSString stringWithFormat:@"%@ • %@", cell.artist, cell.album];
    SPTDataLoaderCancellationTokenFactoryImplementation *cancelFact = [[%c(SPTDataLoaderCancellationTokenFactoryImplementation) alloc] init];
    SPTDataLoader *dataLoader = [%c(SPTDataLoader) dataLoaderWithRequestResponseHandlerDelegate:self.dataLoaderFactory
                                                                       cancellationTokenFactory:cancelFact];
    SPTScannablesRemoteDataSource *dataSource = [[%c(SPTScannablesRemoteDataSource) alloc] initWithDataLoader:dataLoader];
    SPTScannablesContextMenuHeaderView *headerView = nil;
    if ([%c(SPTScannablesContextMenuHeaderView) instancesRespondToSelector:@selector(initWithTitle:subtitle:entityURL:dataSource:onboardingPresenter:authorizationRequester:dependencies:alertController:)]) {
        headerView = [[%c(SPTScannablesContextMenuHeaderView) alloc] initWithTitle:cell.trackName
                                                                          subtitle:subtitle
                                                                         entityURL:cell.trackURI
                                                                        dataSource:dataSource
                                                               onboardingPresenter:nil
                                                            authorizationRequester:nil
                                                                      dependencies:dependencies
                                                                   alertController:[%c(SPTAlertPresenter) sharedInstance]];
    }

    /* Build actions */
    NSMutableArray *_actions = [NSMutableArray new];

    // Add to playlist
    SPTAddToPlaylistAction *toPlaylist = nil;
    if ([%c(SPTAddToPlaylistAction) instancesRespondToSelector:@selector(initWithTrackURLs:addEntityURL:defaultPlaylistName:playlistFeature:logContext:sourceURL:contextSourceURL:)]) {
        toPlaylist = [[%c(SPTAddToPlaylistAction) alloc] initWithTrackURLs:@[cell.trackURI]
                                                              addEntityURL:nil
                                                       defaultPlaylistName:cell.trackName
                                                           playlistFeature:self.playlistFeature
                                                                logContext:nil
                                                                 sourceURL:sourceURL
                                                              contextSourceURL:nil];
        [_actions addObject:toPlaylist];
    }

    // Add to queue
    SPTPlayerTrack *track = [%c(SPTPlayerTrack) trackWithURI:cell.trackURI];
    SPTCosmosPlayerQueue *queue = [[%c(SPTCosmosPlayerQueue) alloc] initWithPlayer:self.statefulPlayer.player];
    SPTQueueTrackAction *toQueue = nil;
    if ([%c(SPTQueueTrackAction) instancesRespondToSelector:@selector(initWithTrack:player:playerQueue:upsellManager:logContext:alertController:)]) {
        toQueue = [[%c(SPTQueueTrackAction) alloc] initWithTrack:track
                                                          player:self.statefulPlayer.player
                                                     playerQueue:queue
                                                   upsellManager:nil
                                                      logContext:nil
                                                 alertController:[%c(SPTAlertPresenter) sharedInstance]];
        [_actions addObject:toQueue];
    }

    // Start radio
    SPTStartRadioAction *toRadio = nil;
    if ([%c(SPTStartRadioAction) instancesRespondToSelector:@selector(initWithSeedURL:session:radioManager:logContext:)]) {
        toRadio = [[%c(SPTStartRadioAction) alloc] initWithSeedURL:cell.trackURI
                                                           session:self.session
                                                      radioManager:self.radioManager
                                                        logContext:nil];
        [_actions addObject:toRadio];
    }

    // Share
    SPTShareAction *toShare = nil;
    if ([%c(SPTShareAction) instancesRespondToSelector:@selector(initWithItemURL:itemName:creatorName:sourceName:imageURL:sourceUrl:shareType:clipboardLinkTitle:session:shareFeature:logContext:)]) {
        toShare = [[%c(SPTShareAction) alloc] initWithItemURL:cell.trackURI
                                                     itemName:cell.trackName
                                                  creatorName:cell.artist
                                                   sourceName:cell.album
                                                     imageURL:cell.imageURL
                                                    sourceUrl:cell.trackURI
                                                    shareType:3
                                           clipboardLinkTitle:nil
                                                      session:self.session
                                                 shareFeature:self.shareFeature
                                                   logContext:nil];
        [_actions addObject:toShare];
    }

    // Go to artist and album
    SPTGoToURLAction *toArtist = nil;
    SPTGoToURLAction *toAlbum  = nil;
    if ([%c(SPTGoToURLAction) instancesRespondToSelector:@selector(initWithURL:title:logEventName:order:logContext:)]) {
        toArtist = [[%c(SPTGoToURLAction) alloc] initWithURL:cell.artistURI
                                                       title:@"View Artist"
                                                logEventName:nil
                                                       order:0
                                                  logContext:nil];
        [_actions addObject:toArtist];

        toAlbum = [[%c(SPTGoToURLAction) alloc] initWithURL:cell.albumURI
                                                      title:@"View Album"
                                               logEventName:nil
                                                      order:0
                                                 logContext:nil];
        [_actions addObject:toAlbum];
    }

    /* Check collection state */
    [self.collectionPlatform collectionStateForURL:cell.trackURI completion:^void(NSInteger value) {
        BOOL inCollection = NO;
        if (value == inCollectionEnum) {
            inCollection = YES;
        }

        SPTCollectionPlatformAddRemoveFromCollectionAction *toCollection = nil;
        if ([%c(SPTCollectionPlatformAddRemoveFromCollectionAction) instancesRespondToSelector:@selector(initWithLink:collectionPlatform:collectionTestManager:wasInCollection:logContext:sourceURL:)]) {
            toCollection = [[%c(SPTCollectionPlatformAddRemoveFromCollectionAction) alloc] initWithLink:cell.trackURI
                                                                                     collectionPlatform:self.collectionPlatform
                                                                                  collectionTestManager:self.collectionPlatform.collectionTestManager
                                                                                        wasInCollection:inCollection
                                                                                             logContext:nil
                                                                                              sourceURL:sourceURL];
            [_actions insertObject:toCollection atIndex:0];
        }


        /* Create view controller */
        NSArray *actions = [%c(SPTContextMenuTaskAction) actionsWithActions:_actions];

        SPTContextMenuOptionsImplementation *options = [[%c(SPTContextMenuOptionsImplementation) alloc] init];
        [options setShouldShowScannable:YES];

        SPTContextMenuModel *model = [[%c(SPTContextMenuModel) alloc] initWithOptions:options player:self.statefulPlayer.player];
        GLUETheme *theme = [%c(GLUETheme) themeWithSPTTheme:[%c(SPTTheme) catTheme]];

        SPTContextMenuViewController *vc = nil;
        if ([%c(SPTContextMenuViewController) instancesRespondToSelector:@selector(initWithHeaderImageURL:actions:entityURL:imageLoader:headerView:modalPresentationController:logger:model:theme:notificationCenter:)]) {
            // Earlier than 8.4.34
            vc = [[%c(SPTContextMenuViewController) alloc] initWithHeaderImageURL:cell.imageURL
                                                                          actions:actions
                                                                        entityURL:cell.trackURI
                                                                      imageLoader:self.contextImageLoader
                                                                       headerView:headerView
                                                      modalPresentationController:self.modalPresentationController
                                                                           logger:nil
                                                                            model:model
                                                                            theme:theme
                                                               notificationCenter:[NSNotificationCenter defaultCenter]];
        } else if ([%c(SPTContextMenuViewController) instancesRespondToSelector:@selector(initWithHeaderImageURL:actions:entityURL:imageLoader:headerView:modalPresentationController:model:theme:notificationCenter:)]) {
            // 8.4.34
            vc = [[%c(SPTContextMenuViewController) alloc] initWithHeaderImageURL:cell.imageURL
                                                                          actions:actions
                                                                        entityURL:cell.trackURI
                                                                      imageLoader:self.contextImageLoader
                                                                       headerView:headerView
                                                      modalPresentationController:self.modalPresentationController
                                                                            model:model
                                                                            theme:theme
                                                               notificationCenter:[NSNotificationCenter defaultCenter]];
        }

        [self.modalPresentationController presentViewController:vc animated:YES completion:nil];
    }];
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *URI = ((SPTTrackTableViewCell *)[table cellForRowAtIndexPath:indexPath]).trackURI;
    SPTPlayerContext *context = [%c(SPTPlayerContext) contextForURI:URI];
    [self.statefulPlayer.player playContext:context options:nil];
    [table deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)table heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

- (void)offlineModeState:(id)arg updated:(BOOL)offline {
    for (SPTTrackTableViewCell *cell in self.view.visibleCells) {
        float alpha = 1;

        NSInteger offlineState = [self.session.offlineManager stateForTrackWithURL:cell.trackURI];
        if (offline && offlineState == isNotAvailableOffline) {
            alpha = 0.4;
        }
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

    self.tracks = newTracks;
}

@end
