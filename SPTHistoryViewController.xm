#import "SPTHistoryViewController.h"
#import "SPTTrackTableViewCell.h"
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
    [cell setSwipeDelegate:self];

    return cell;
}

- (void)swipeableTableViewCell:(SPTTrackTableViewCell *)cell
            didCompleteGesture:(long long)gesture {
    if (gesture == leftSwipe) {
        // Add to queue
        if (self.player &&
            [%c(SPTCosmosPlayerQueue) instancesRespondToSelector:@selector(initWithPlayer:)]) {
            SPTCosmosPlayerQueue *queue = [[%c(SPTCosmosPlayerQueue) alloc] initWithPlayer:self.player];
            [queue queueTrack:[%c(SPTPlayerTrack) trackWithURI:cell.trackURI]];

            // Show alert
            if (%c(SPTProgressView) && [%c(SPTProgressView) respondsToSelector:@selector(progressView)]) {
                SPTProgressView *view = [%c(SPTProgressView) progressView];
                view.frame = self.view.frame;
                view.title = @"Added to Queue";
                view.mode = SPTProgressViewCheckmarkMode;
                [[[UIApplication sharedApplication] keyWindow] addSubview:view];
                [view animateShowing];
                [view performSelector:@selector(animateHiding) withObject:nil afterDelay:2];
            }
        }
    } else {
        // Remove cell
        UITableView *tableView = self.view;
        NSIndexPath *indexPath = [tableView indexPathForCell:cell];

        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
        NSMutableArray *tracks = [prefs[kTracks] mutableCopy];
        [tracks removeObjectAtIndex:indexPath.row];

        prefs[kTracks] = tracks;
        if (![prefs writeToFile:kPrefPath atomically:NO])
            HBLogError(@"Could not save %@ to path %@", prefs, kPrefPath);

        self.tracks = tracks;
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self checkEmptyTracks:tracks];
    }
}

- (void)showContextMenu:(SPTTrackContextButton *)sender {
    SPTTrackTableViewCell *cell = sender.cell;

    SPTArtistEntityImpl *artist = [%c(SPTArtistEntityFactory) artistEntityForName:cell.artist uri:cell.artistURI imageURL:nil];
    SPTContextMenuOptionsImplementation *options = [self.contextMenuFeature.contextMenuOptionsFactory contextMenuOptionsWithScannableEnabled:YES];
    if (![self.contextMenuFeature.contextMenuPresenterFactory respondsToSelector:@selector(contextMenuPresenterForTrackWithTrackURL:trackName:trackMetadata:playable:imageURL:artists:albumName:albumURL:viewURL:contextSourceURL:metadataTitle:logContextIphone:logContextIpad:senderView:options:)])
        return;
    id<SPTContextMenuPresenter> presenter = [self.contextMenuFeature.contextMenuPresenterFactory contextMenuPresenterForTrackWithTrackURL:cell.trackURI
                                                                                                                                trackName:cell.textLabel.text
                                                                                                                            trackMetadata:nil
                                                                                                                                 playable:YES
                                                                                                                                 imageURL:cell.imageURL
                                                                                                                                  artists:@[artist]
                                                                                                                                albumName:cell.album
                                                                                                                                 albumURL:cell.albumURI
                                                                                                                                  viewURL:self.sourceURL
                                                                                                                         contextSourceURL:nil
                                                                                                                            metadataTitle:nil
                                                                                                                         logContextIphone:nil
                                                                                                                           logContextIpad:nil
                                                                                                                               senderView:sender
                                                                                                                                  options:options];
    if (![presenter respondsToSelector:@selector(presentWithSenderView:permittedArrowDirections:animated:)])
        return;
    [presenter presentWithSenderView:sender permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
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
