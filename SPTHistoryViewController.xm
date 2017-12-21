#import "SPTHistoryViewController.h"

@interface SPTTrackTableViewCell : UITableViewCell
@property (nonatomic, strong) NSURL *trackURI;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) NSString *trackName;
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSString *album;
@property (nonatomic, strong) NSURL *artistURI;
@property (nonatomic, strong) NSURL *albumURI;
@property (nonatomic, strong) SPSession *session;
@end

@interface SPTTrackContextButton : UIButton
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) SPTTrackTableViewCell *cell;
@end

@implementation SPTTrackContextButton
@end


@implementation SPTTrackTableViewCell

- (void)layoutSubviews {
    [super layoutSubviews];

    self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x,
                                      self.textLabel.frame.origin.y,
                                      self.frame.size.width - 140,
                                      self.textLabel.frame.size.height);

    self.detailTextLabel.frame = CGRectMake(self.detailTextLabel.frame.origin.x,
                                            self.detailTextLabel.frame.origin.y,
                                            self.frame.size.width - 140,
                                            self.detailTextLabel.frame.size.height);

    // Set lower alpha on tracks not available offline
    NSInteger offlineState = [self.session.offlineManager stateForTrackWithURL:self.trackURI];
    if ([self.session isOffline] && offlineState == isNotAvailableOffline) {
        self.alpha = 0.4;
    }
}

@end


@implementation SPTHistoryViewController
@dynamic view;

- (id)initWithPreferences:(NSDictionary *)prefs
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
                   session:(SPSession *)session {
    if (self = [super init]) {
        self.prefs = prefs;
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

        self.navigationItem = [[UINavigationItem alloc] initWithTitle:@"History"];
    }

    return self;
}

- (void)loadView {
    self.view = [[%c(SPTTableView) alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.view.dataSource = self;
    self.view.delegate = self;
    self.view.contentInset = UIEdgeInsetsMake(self.view.contentInset.top,
                                              self.view.contentInset.left - 4,
                                              self.view.contentInset.bottom + self.nowPlayingBarHeight,
                                              self.view.contentInset.right);
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return ((NSArray *)self.prefs[kTracks]).count;
}

- (SPTTrackTableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";

    SPTTrackTableViewCell *cell = [table dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[%c(SPTTrackTableViewCell) alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Standard"];
    }

    cell.session = self.session;

    NSArray *tracks = self.prefs[kTracks];
    NSDictionary *track = tracks[indexPath.row];

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

    return cell;
}

- (void)showContextMenu:(SPTTrackContextButton *)sender {
    static NSURL *sourceURL = [NSURL URLWithString:@"spotify:history"];

    SPTTrackTableViewCell *cell = sender.cell;

    SPTContextMenuOptionsImplementation *options = [[%c(SPTContextMenuOptionsImplementation) alloc] init];
    [options setShouldShowScannable:NO];

    SPTContextMenuModel *model = [[%c(SPTContextMenuModel) alloc] initWithOptions:options player:self.statefulPlayer.player];
    GLUETheme *theme = [%c(GLUETheme) themeWithSPTTheme:[%c(SPTTheme) catTheme]];

    /* Create headerView */
    SPTScannablesDependencies *dependencies = [[%c(SPTScannablesDependencies) alloc] initWithSpotifyApplication:[UIApplication sharedApplication]
                                                                                                 linkDispatcher:self.linkDispatcher
                                                                                                         device:[UIDevice currentDevice]
                                                                                                          theme:[%c(SPTTheme) catTheme]
                                                                                                    testManager:self.scannablesTestManager
                                                                                                         logger:nil];

    NSString *subtitle = [NSString stringWithFormat:@"%@ • %@", cell.artist, cell.album];
    SPTScannablesContextMenuHeaderView *headerView = [[%c(SPTScannablesContextMenuHeaderView) alloc] initWithTitle:cell.trackName
                                                                                                          subtitle:subtitle
                                                                                                         entityURL:cell.trackURI
                                                                                                        dataSource:nil
                                                                                               onboardingPresenter:nil
                                                                                            authorizationRequester:nil
                                                                                                      dependencies:dependencies
                                                                                                   alertController:[%c(SPTAlertPresenter) sharedInstance]];

    HBLogDebug(@"headerView: %@", headerView);

    /* Build actions */
    // Add to playlist
    SPTAddToPlaylistAction *toPlaylist = [[%c(SPTAddToPlaylistAction) alloc] initWithTrackURLs:@[cell.trackURI]
                                                                                  addEntityURL:nil
                                                                           defaultPlaylistName:cell.trackName
                                                                               playlistFeature:self.playlistFeature
                                                                                    logContext:nil
                                                                                     sourceURL:sourceURL
                                                                              contextSourceURL:nil];

    // Add to queue
    SPTPlayerTrack *track = [%c(SPTPlayerTrack) trackWithURI:cell.trackURI];
    SPTCosmosPlayerQueue *queue = [[%c(SPTCosmosPlayerQueue) alloc] initWithPlayer:self.statefulPlayer.player];
    SPTQueueTrackAction *toQueue = [[%c(SPTQueueTrackAction) alloc] initWithTrack:track
                                                                           player:self.statefulPlayer.player
                                                                      playerQueue:queue
                                                                    upsellManager:nil
                                                                       logContext:nil
                                                                  alertController:[%c(SPTAlertPresenter) sharedInstance]];
    // Start radio
    SPTStartRadioAction *toRadio = [[%c(SPTStartRadioAction) alloc] initWithSeedURL:cell.trackURI
                                                                            session:self.session
                                                                       radioManager:self.radioManager
                                                                         logContext:nil];

    // Go to artist
    SPTGoToURLAction *toArtist = [[%c(SPTGoToURLAction) alloc] initWithURL:cell.artistURI
                                                                     title:@"View Artist"
                                                              logEventName:nil
                                                                     order:0
                                                                logContext:nil];

    // Go to album
    SPTGoToURLAction *toAlbum = [[%c(SPTGoToURLAction) alloc] initWithURL:cell.albumURI
                                                                    title:@"View Album"
                                                             logEventName:nil
                                                                    order:0
                                                               logContext:nil];

    /* Check collection state */
    [self.collectionPlatform collectionStateForURL:cell.trackURI completion:^void(NSInteger value) {
        BOOL inCollection = NO;
        if (value == inCollectionEnum) {
            inCollection = YES;
        }
        SPTCollectionPlatformAddRemoveFromCollectionAction *toCollection = [[%c(SPTCollectionPlatformAddRemoveFromCollectionAction) alloc] initWithLink:cell.trackURI
                                                                                                                                     collectionPlatform:self.collectionPlatform
                                                                                                                                  collectionTestManager:self.collectionPlatform.collectionTestManager
                                                                                                                                        wasInCollection:inCollection
                                                                                                                                             logContext:nil
                                                                                                                                              sourceURL:sourceURL];


        /* Create view controller */
        NSArray *actions = [%c(SPTContextMenuTaskAction) actionsWithActions:@[toCollection, toPlaylist, toQueue, toRadio, toArtist, toAlbum]];

        SPTContextMenuViewController *vc = [[%c(SPTContextMenuViewController) alloc] initWithHeaderImageURL:cell.imageURL
                                                                                                    actions:actions
                                                                                                  entityURL:cell.trackURI
                                                                                                imageLoader:self.contextImageLoader
                                                                                                 headerView:headerView
                                                                                modalPresentationController:self.modalPresentationController
                                                                                                     logger:nil
                                                                                                      model:model
                                                                                                      theme:theme
                                                                                         notificationCenter:[NSNotificationCenter defaultCenter]];

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

@end
