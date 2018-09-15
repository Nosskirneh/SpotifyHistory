#import "Spotify.h"
#import "SPTHistoryViewController.h"

#define prefPath @"/var/mobile/Library/Preferences/se.nosskirneh.spotifyhistory.plist"
#define prefPathSandboxed [NSString stringWithFormat:@"%@/Library/Preferences/se.nosskirneh.spotifyhistory.plist", NSHomeDirectory()]


SpotifyApplication *getSpotifyApplication() {
    return (SpotifyApplication *)[UIApplication sharedApplication];
}

NowPlayingFeatureImplementation *getRemoteDelegate() {
    return getSpotifyApplication().remoteControlDelegate;
}

PlaylistFeatureImplementation *getPlaylistFeature() {
    return getRemoteDelegate().playlistFeature;
}

SPTStatefulPlayer *getStatefulPlayer() {
    return getRemoteDelegate().statefulPlayer;
}

SPSession *getSession() {
    return getRemoteDelegate().coreService.core.session;
}

SPContextMenuFeatureImplementation *getContextMenuFeature() {
    return getRemoteDelegate().contextMenu;
}

SPTGLUEImageLoader *getImageLoader() {
    static SPTGLUEImageLoader *imageLoader;
    if (!imageLoader)
        imageLoader = [getRemoteDelegate().queueService.glueImageLoaderFactory createImageLoaderForSourceIdentifier:@"se.nosskirneh.spotifyhistory"];
    return imageLoader;
}

SPTImageLoaderImplementation *getContextImageLoader() {
    static SPTImageLoaderImplementation *imageLoader;
    if (!imageLoader)
        imageLoader = [getRemoteDelegate().queueService.imageLoaderFactory createImageLoader];
    return imageLoader;
}

UIViewController *getNowPlayingBarViewController() {
    return getRemoteDelegate().nowPlayingBarViewController;
}


// Help method to create a checkmark in settings
%hook SettingsMultipleChoiceTableViewCell

%new
- (void)setCheckmarkAccessory {
    UIImage *img = [UIImage imageForSPTIcon:6
                                       size:CGSizeMake(13, 13)
                                      color:[UIColor colorWithRed:0.11 green:0.73 blue:0.33 alpha:1.0]];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:img];
    [self setAccessoryView:imageView];
}

%end


// Highest order is 100 as of currently, but I'm setting
// this to 200 to make sure it's the last item.
#define HISTORY_ENTRY_DICT @{ \
    @"URL": @"spotify:collection:tracks:history", \
    @"icon": @53, \
    @"order": @200, \
    @"title": @"History" \
}

// Inject the history entry
%hook SPTCollectionOverviewNavigationModel

- (void)setupNavigationItems {
    %orig;

    if ([%c(SPTCollectionOverviewNavigationModelEntryImplementation) instancesRespondToSelector:@selector(initWithDictionary:)])
        [self.navigationItems addObject:[[%c(SPTCollectionOverviewNavigationModelEntryImplementation) alloc] initWithDictionary:HISTORY_ENTRY_DICT]];
}

%end

/*
 * Presenting the history view:
 * There is probably a better way to do this, with register URI schemas within Spotify.
 * However, after several hours of scratching my head, I cannot seem to understand how.
 * If you're a bored developer, look into the `linkDispatcher` object of
 * `SPTCollectionOverviewViewController` – it exists several schemas handlers as properties.
 */

static SPTHistoryViewController *historyVC;

%hook SPTCollectionOverviewViewController

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [table numberOfRowsInSection:indexPath.section] - 1) {
        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];

        historyVC = [[SPTHistoryViewController alloc] initWithTracks:prefs[kTracks]
                                                 nowPlayingBarHeight:getNowPlayingBarViewController().view.frame.size.height
                                                         imageLoader:getImageLoader()
                                                              player:getStatefulPlayer().player
                                                  contextImageLoader:getContextImageLoader()
                                                     playlistFeature:getPlaylistFeature()
                                                             session:getSession()
                                                  contextMenuFeature:getContextMenuFeature()];

        [self.navigationController pushViewControllerOnTopOfTheNavigationStack:historyVC animated:YES];
        [table deselectRowAtIndexPath:indexPath animated:NO];

        return;
    }

    %orig;
}

%end


// Add previous track to history
%hook SPTNowPlayingBarContainerViewController

%new
- (NSDictionary *)exportTrack {
    NSMutableDictionary *tr = [NSMutableDictionary new];
    tr[@"imageURL"] = self.currentTrack.imageURL.absoluteString;
    tr[@"URI"] = self.currentTrack.URI.absoluteString;
    tr[@"name"] = self.currentTrack.trackTitle;
    tr[@"artist"] = self.currentTrack.artistTitle;
    tr[@"artistURI"] = self.currentTrack.artistURI.absoluteString;
    tr[@"album"] = self.currentTrack.albumTitle;
    tr[@"albumURI"] = self.currentTrack.albumURI.absoluteString;
    return tr;
}

- (void)setCurrentTrack:(SPTPlayerTrack *)track {
    // This has to be static on method level, simply adding
    // a property or declaring a static varible in the global
    // scope results in some memory shenanigans and will crash
    static double timestampLastTrackChange;

    // Prevent timer from resetting when saving to/removing from collection
    if ([getStatefulPlayer().queue isTrack:self.currentTrack equalToTrack:track])
        return %orig;

    if (self.currentTrack && timestampLastTrackChange) {
        double current = [[NSDate date] timeIntervalSince1970];
        if (current - timestampLastTrackChange > 10) {
            // Save previously track to history
            NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
            if (!prefs)
                prefs = [[NSMutableDictionary alloc] init];

            NSDictionary *tr = [self exportTrack];

            NSArray<NSDictionary *> *tracks;
            if (prefs[kTracks]) {
                tracks = prefs[kTracks];
                // Compare last history item to now playing - are they the same?
                if ([[tracks firstObject][@"URI"] isEqualToString:tr[@"URI"]])
                    goto updateTimer; // "break" from if statement - do not add track

                NSMutableArray *newTracks = [tracks mutableCopy];
                [newTracks insertObject:tr atIndex:0];
                int maxSize = prefs[kMaxSize] ? [prefs[kMaxSize] intValue] : 100;
                if (newTracks.count > maxSize && maxSize != 0)
                    [newTracks removeLastObject];
                tracks = newTracks;
            } else {
                tracks = [[NSArray alloc] initWithObjects:tr, nil];
            }


            prefs[kTracks] = tracks;
            if (![prefs writeToFile:kPrefPath atomically:NO])
                HBLogError(@"Could not save %@ to path %@", prefs, kPrefPath);

            if (historyVC)
                [historyVC updateListWithTracks:tracks];
        }
    }

    // Save timestamp when changing to this track
    updateTimer:
    timestampLastTrackChange = [[NSDate date] timeIntervalSince1970];

    %orig;
}

%end


%hook SpotifyAppDelegate

// Different path for settings file (sandbox issues on iOS 11)
%property (nonatomic, retain) NSString *historyPrefPath;

- (BOOL)application:(id)arg1 didFinishLaunchingWithOptions:(id)arg2 {
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 11)
        self.historyPrefPath = prefPathSandboxed;
    else
        self.historyPrefPath = prefPath;

    return %orig;
}

// Clear data on change of user
- (void)userWillLogOut {
    %orig;

    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
    if (!prefs)
        return;
    prefs[kTracks] = @[];

    if (![prefs writeToFile:kPrefPath atomically:NO])
        HBLogError(@"Could not save %@ to path %@", prefs, kPrefPath);
}

%end
