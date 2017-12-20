#import "Spotify.h"
#import "SPTHistoryViewController.h"
#import "SPTEmptyHistoryViewController.h"

static SPTGLUEImageLoader *imageLoader;
static SPTStatefulPlayer *statefulPlayer;
static SPTModalPresentationControllerImplementation *modalPresentationController;
static SPTImageLoaderImplementation *contextImageLoader;
static PlaylistFeatureImplementation *playlistFeature;
static SPTCollectionPlatformImplementation *collectionPlatform;
static SPTScannablesTestManagerImplementation *scannablesTestManager;
static SPTRadioManager *radioManager;


// Help methods to create a context actions
%hook SPTContextMenuTaskAction

%new
+ (id)actionWithAction:(SPAction *)action {
    SPTContextMenuTaskAction *contextAction = [[%c(SPTContextMenuTaskAction) alloc] init];
    contextAction.action = action;
    return contextAction;
}

%new
+ (NSArray *)actionsWithActions:(NSArray<SPAction *> *)actions {
    NSMutableArray *contextActions = [NSMutableArray new];
    for (SPAction *action in actions) {
        [contextActions addObject:[%c(SPTContextMenuTaskAction) actionWithAction:action]];
    }
    return contextActions;
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

    SPTCollectionOverviewNavigationModelEntryImplementation *historyNavEntry = [[%c(SPTCollectionOverviewNavigationModelEntryImplementation) alloc] initWithDictionary:HISTORY_ENTRY_DICT];
    [self.navigationItems addObject:historyNavEntry];
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

%hook SPTCollectionOverviewViewController

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [table numberOfRowsInSection:indexPath.section] - 1) {
        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefPath];

        UIViewController *vc;
        if (!prefs[kTracks] || ((NSArray *)prefs[kTracks]).count == 0) {
            // No previous history
            vc = [[SPTEmptyHistoryViewController alloc] init];
        } else {
            vc = [[SPTHistoryViewController alloc] initWithPreferences:prefs
                                                   nowPlayingBarHeight:npBarHeight
                                                           imageLoader:imageLoader
                                                        statefulPlayer:statefulPlayer
                                           modalPresentationController:modalPresentationController
                                                    contextImageLoader:contextImageLoader
                                                       playlistFeature:playlistFeature
                                                    collectionPlatform:collectionPlatform
                                                        linkDispatcher:self.linkDispatcher
                                                 scannablesTestManager:scannablesTestManager
                                                          radioManager:radioManager];
        }

        [self.navigationController pushViewControllerOnTopOfTheNavigationStack:vc animated:YES];
        [table deselectRowAtIndexPath:indexPath animated:NO];
        return;
    }

    %orig;
}

%end


// Used to get images
%hook SPTGLUEImageLoader

- (id)initWithImageLoader:(id)arg sourceIdentifier:(id)arg2 {
    return imageLoader ? %orig : imageLoader = %orig;
}

%end


// Add previous track to history
%hook SPTNowPlayingBarContainerViewController

- (void)setCurrentTrack:(SPTPlayerTrack *)track {
    // This has to be static on method level, simply adding
    // a property or declaring a static varible in the global
    // scope results in some memory shenanigans and will crash
    static double timestampLastTrackChange;

    if (self.currentTrack && ![statefulPlayer.queue isTrack:self.currentTrack equalToTrack:track] &&
        timestampLastTrackChange) {
        double current = [[NSDate date] timeIntervalSince1970];
        HBLogDebug(@"diff: %f", current - timestampLastTrackChange);
        if (current - timestampLastTrackChange > 10) {
            // Save previously track to history
            NSMutableDictionary *tr = [NSMutableDictionary new];
            tr[@"imageURL"] = self.currentTrack.imageURL.absoluteString;
            tr[@"URI"] = self.currentTrack.URI.absoluteString;
            tr[@"name"] = self.currentTrack.trackTitle;
            tr[@"artist"] = self.currentTrack.artistTitle;
            tr[@"artistURI"] = self.currentTrack.artistURI.absoluteString;
            tr[@"album"] = self.currentTrack.albumTitle;
            tr[@"albumURI"] = self.currentTrack.albumURI.absoluteString;

            NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefPath];
            if (!prefs) {
                prefs = [[NSMutableDictionary alloc] init];
            }

            NSArray *tracks;
            if (!prefs[kTracks]) {
                tracks = [[NSArray alloc] initWithObjects:tr, nil];
            } else {
                tracks = prefs[kTracks];
                // Duplicate?
                if ([((NSDictionary *)[tracks firstObject])[@"imageURL"] isEqualToString:tr[@"imageURL"]]) {
                    goto updateTimer; // "break" from if statement - do not add track
                }
                NSMutableArray *newTracks = [tracks mutableCopy];
                [newTracks insertObject:tr atIndex:0];
                tracks = newTracks;
            }

            prefs[kTracks] = tracks;
            if (![prefs writeToFile:prefPath atomically:YES]) {
                HBLogError(@"Could not save %@ to path %@", prefs, prefPath);
            }
        }
    }

    updateTimer:
    // Save timestamp when changing to this track
    timestampLastTrackChange = [[NSDate date] timeIntervalSince1970];

    %orig;
}

%end


// Even though only the SPTPlayerImpl is needed, I'm hooking
// this since this init method seems far less likely to change.
%hook SPTStatefulPlayer

- (id)initWithPlayer:(id)player {
    return statefulPlayer = %orig;
}

%end


// Used to present a context menu
%hook SPTModalPresentationControllerImplementation

- (id)initWithPresenterProvider:(id)arg1
       modalPresentationMonitor:(id)arg2 {
    return modalPresentationController = %orig;
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


// Used to add to/remove from collection with context action
%hook SPTCollectionPlatformImplementation

- (id)initWithCosmosDataLoader:(id)arg1
              collectionLogger:(id)arg2
         collectionTestManager:(id)arg3
            metaViewController:(id)arg4
               alertController:(id)arg5 {
    return collectionPlatform ? %orig : collectionPlatform = %orig;
}

%end


// Used to load the header view of the context menu
%hook SPTScannablesTestManagerImplementation

- (id)initWithFeatureFlags:(id)arg1 featureSettingsItemFactory:(id)arg2 localSettings:(id)arg3 alertController:(id)arg4 {
    return scannablesTestManager = %orig;
}

%end


// Used to start radio from track
%hook SPTRadioManager

- (id)initWithLocalSettings:(id)arg1 abba:(id)arg2 productState:(id)arg3 {
    return radioManager = %orig;
}

%end

