#import "Spotify.h"
#import "SPTHistoryViewController.h"

static SPTGLUEImageLoader *imageLoader;
static SPTStatefulPlayer *statefulPlayer;
static SPTImageLoaderImplementation *contextImageLoader;
static PlaylistFeatureImplementation *playlistFeature;
static SPSession *session;
static SPContextMenuFeatureImplementation *contextMenuFeature;


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

    if ([%c(SPTCollectionOverviewNavigationModelEntryImplementation) instancesRespondToSelector:@selector(initWithDictionary:)]) {
        SPTCollectionOverviewNavigationModelEntryImplementation *historyNavEntry = [[%c(SPTCollectionOverviewNavigationModelEntryImplementation) alloc] initWithDictionary:HISTORY_ENTRY_DICT];
        [self.navigationItems addObject:historyNavEntry];
        [historyNavEntry release];
    }
}

%end

static CGFloat npBarHeight;

// Used to get height of now playing bar
%hook SPTBarAttachmentViewControllerData

- (void)setHeight:(CGFloat)height {
    %orig;
    npBarHeight = height;
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
        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefPath];

        historyVC = [[SPTHistoryViewController alloc] initWithTracks:prefs[kTracks]
                                                 nowPlayingBarHeight:npBarHeight
                                                         imageLoader:imageLoader
                                                      statefulPlayer:statefulPlayer
                                                  contextImageLoader:contextImageLoader
                                                     playlistFeature:playlistFeature
                                                             session:session
                                                  contextMenuFeature:contextMenuFeature];

        [self.navigationController pushViewControllerOnTopOfTheNavigationStack:historyVC animated:YES];
        [table deselectRowAtIndexPath:indexPath animated:NO];

        [prefs release];
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
    if ([statefulPlayer.queue isTrack:self.currentTrack equalToTrack:track])
        return %orig;

    if (self.currentTrack && timestampLastTrackChange) {
        double current = [[NSDate date] timeIntervalSince1970];
        if (current - timestampLastTrackChange > 10) {
            // Save previously track to history
            NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefPath];
            if (!prefs)
                prefs = [[NSMutableDictionary alloc] init];

            NSDictionary *tr = [self exportTrack];

            NSArray<NSDictionary *> *tracks;
            if (prefs[kTracks]) {
                tracks = prefs[kTracks];
                // Compare last history item to now playing - are they the same?
                if ([[tracks firstObject][@"URI"] isEqualToString:tr[@"URI"]]) {
                    goto updateTimer; // "break" from if statement - do not add track
                }
                NSMutableArray *newTracks = [tracks mutableCopy];
                [newTracks insertObject:tr atIndex:0];
                int maxSize = prefs[kMaxSize] ? [prefs[kMaxSize] intValue] : 100;
                if (newTracks.count > maxSize) {
                    [newTracks removeLastObject];
                }
                tracks = newTracks;
            } else {
                tracks = [[NSArray alloc] initWithObjects:tr, nil];
            }

            [tr release];

            prefs[kTracks] = tracks;
            [tracks release];
            if (![prefs writeToFile:prefPath atomically:YES])
                HBLogError(@"Could not save %@ to path %@", prefs, prefPath);

            if (historyVC)
                [historyVC updateListWithTracks:tracks];

            [prefs release];
        }
    }

    // Save timestamp when changing to this track
    updateTimer:
    timestampLastTrackChange = [[NSDate date] timeIntervalSince1970];

    %orig;
}

%end


/* Get references to objects */

// Used to fetch images in list
%hook SPTGLUEImageLoader

- (id)initWithImageLoader:(id)arg sourceIdentifier:(id)arg2 {
    return imageLoader ? %orig : imageLoader = %orig;
}

%end


// Even though only the SPTPlayerImpl is needed, I'm hooking
// this since this init method seems far less likely to change.
%hook SPTStatefulPlayer

- (id)initWithPlayer:(id)player {
    return statefulPlayer = %orig;
}

%end


// Load images in context menu
%hook SPTImageLoaderImplementation

- (id)initWithDataLoader:(id)arg1
    offlineEntityTracker:(id)arg2
         persistentCache:(id)arg3
             memoryCache:(id)arg4
     imageLoaderRegistry:(id)arg5
      persistentKeyBlock:(id)arg6
        maximumImageSize:(CGSize)arg7 {
    return contextImageLoader ? %orig : contextImageLoader = %orig;
}

%end


// Used for adding to playlist with context action
%hook PlaylistFeatureImplementation

- (void)load {
    playlistFeature = self;
    %orig;
}

%end


// Used to check offline mode
%group SPSession_8433
// Earlier than 8.4.34
%hook SPSession

- (id)initWithCore:(id)arg1 coreCreateOptions:(id)arg2 isPerfTracingEnabled:(id)arg3 core:(id)arg4 session:(id)arg5 accesspointHandler:(id)arg6 coreTime:(id)arg7 connectivityManager:(id)arg8 scheduler:(id)arg9 clientVersionString:(id)arg10 acceptLanguages:(id)arg11 {
    return session = %orig;
}

%end
%end

// 8.4.34
%group SPSession_8434
%hook SPSession

- (id)initWithCore:(id)arg1 coreCreateOptions:(id)arg2 isPerfTracingEnabled:(id)arg3 core:(id)arg4 session:(id)arg5 accesspointHandler:(id)arg6 serverTime:(id)arg7 connectivityManager:(id)arg8 scheduler:(id)arg9 clientVersionString:(id)arg10 acceptLanguages:(id)arg11 {
    return session = %orig;
}

%end
%end


// Clear data on change of user
%hook SpotifyAppDelegate

- (void)userWillLogOut {
    %orig;

    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefPath];
    if (!prefs)
        return;
    prefs[kTracks] = @[];

    if (![prefs writeToFile:prefPath atomically:YES])
        HBLogError(@"Could not save %@ to path %@", prefs, prefPath);
}

%end


// Holds references to useful implementations
%hook SPContextMenuFeatureImplementation

- (id)init {
    return contextMenuFeature = %orig;
}

%end


%ctor {
    %init();

    if ([%c(SPSession) instancesRespondToSelector:@selector(initWithCore:coreCreateOptions:isPerfTracingEnabled:core:session:accesspointHandler:serverTime:connectivityManager:scheduler:clientVersionString:acceptLanguages:)]) {
        %init(SPSession_8434);
    } else if ([%c(SPSession) instancesRespondToSelector:@selector(initWithCore:coreCreateOptions:isPerfTracingEnabled:core:session:accesspointHandler:coreTime:connectivityManager:scheduler:clientVersionString:acceptLanguages:)]) {
        %init(SPSession_8433);
    }
}
