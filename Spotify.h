#define prefPath @"/var/mobile/Library/Preferences/se.nosskirneh.spotifyhistory.plist"
#define kTracks @"tracks"
#define kMaxSize @"maxSize"

enum {
    inCollectionEnum = 0,
    notInCollectionEnum = 2
};

enum {
    isAvailableOffline = 3,
    isNotAvailableOffline = 0
};

enum {
    LEFT_SWIPE = 1,
    RIGHT_SWIPE = 2
};

// Data objects
@interface SPTPlayerTrack : NSObject
@property (nonatomic, readwrite, assign) NSURL *imageURL;
@property (nonatomic, readwrite, assign) NSURL *URI;
@property (nonatomic, readwrite, assign) NSURL *artistURI;
@property (nonatomic, readwrite, assign) NSURL *albumURI;
+ (id)trackWithURI:(NSURL *)URI;
- (NSString *)trackTitle;
- (NSString *)artistTitle;
- (NSString *)albumTitle;
@end

@interface SPTPlayerContext : NSObject
+ (id)contextForURI:(NSURL *)URI;
@end

@interface SPTPlayerImpl : NSObject
- (id)playContext:(id)arg1 options:(id)arg2;
@end

@interface SPTStatefulPlayerQueue : NSObject
- (BOOL)isTrack:(SPTPlayerTrack *)track1 equalToTrack:(SPTPlayerTrack *)track2;
@end

@interface SPTStatefulPlayer : NSObject
@property (nonatomic, readwrite, assign) SPTPlayerImpl *player;
@property (nonatomic, readwrite, assign) SPTStatefulPlayerQueue *queue;
@end

@interface SPTCosmosPlayerQueue : NSObject
- (id)initWithPlayer:(SPTPlayerImpl *)player;
- (void)queueTrack:(SPTPlayerTrack *)track;
@end

@interface SPTRadioManager : NSObject
@end

@interface SPTOfflineManager : NSObject
- (NSInteger)stateForTrackWithURL:(NSURL *)URL;
@end

@interface SPTOfflineModeNotifier : NSObject
- (void)addOfflineModeObserver:(id)arg;
- (void)removeOfflineModeObserver:(id)arg;
@end

@interface SPSession : NSObject
@property(nonatomic, readwrite, assign) SPTOfflineManager *offlineManager;
@property(nonatomic, readwrite, assign) SPTOfflineModeNotifier *offlineNotifier;
@property(nonatomic, readwrite, assign) BOOL *isOffline;
@end

@interface SPTDataLoaderFactory : NSObject
@end

@interface SPTDataLoader : NSObject
+ (id)dataLoaderWithRequestResponseHandlerDelegate:(id)arg1 cancellationTokenFactory:(id)arg2;
@end

@interface SPTScannablesRemoteDataSource : NSObject
- (id)initWithDataLoader:(id)arg;
@end



// Images
@interface UIImage (spt)
+ (id)imageForSPTIcon:(NSInteger)icon size:(CGSize)size;
+ (id)imageForSPTIcon:(NSInteger)icon size:(CGSize)size color:(UIColor *)color;
+ (id)trackSPTPlaceholderWithSize:(NSInteger)size;
+ (id)spt_infoViewErrorIcon;
@end

@interface SPTGLUEImageLoader : NSObject
- (id)loadImageForURL:(NSURL *)url imageSize:(CGSize)size completion:(id)completiton;
@end

// Themes
@interface SPTTheme : NSObject
+ (id)catTheme;
@end

@interface GLUETheme : NSObject
+ (id)themeWithSPTTheme:(SPTTheme *)theme;
@end


// Implementations (used to create actions with)
@interface SPTModalPresentationControllerImplementation : NSObject
- (void)presentViewController:(UIViewController *)vc animated:(BOOL)animate completion:(id)block;
@end

@interface SPTImageLoaderImplementation : NSObject
@end

@interface PlaylistFeatureImplementation : NSObject

- (void)presentAddToPlaylistViewControllerWithTrackURLs:(NSArray<NSURL *> *)trackURLs
                                           addEntityURL:(NSURL *)entityURL
                                    defaultPlaylistName:(NSString *)playlistName
                                             senderView:(UIView *)view
                                             logContext:(id)log
                                              sourceURL:(NSURL *)sourceURL
                                       contextSourceURL:(NSURL *)contextSourceURL;
@end

@interface SPTShareFeatureImplementation : NSObject
@end

@interface SPTCollectionPlatformTestManagerImplementation : NSObject
@end

@interface SPTCollectionPlatformImplementation : NSObject
@property (nonatomic, readwrite, assign) SPTCollectionPlatformTestManagerImplementation *collectionTestManager;
- (void)collectionStateForURL:(NSURL *)URL completion:(id)block;
@end

@interface SPTScannablesTestManagerImplementation : NSObject
@end

@interface SPTLinkDispatcherImplementation : NSObject
@end

@interface SPTScannablesDependencies : NSObject
- (id)initWithSpotifyApplication:(UIApplication *)app
                  linkDispatcher:(SPTLinkDispatcherImplementation *)linkDispatcher
                          device:(UIDevice *)device
                           theme:(SPTTheme *)theme
                     testManager:(SPTScannablesTestManagerImplementation *)scannablesTestManager
                          logger:(id)logger;
@end

// Actions
@interface SPAction : NSObject
@end

@interface SPTAddToPlaylistAction : SPAction
- (id)initWithTrackURLs:(NSArray *)tracks
           addEntityURL:(NSURL *)entityURL
    defaultPlaylistName:(NSString *)name
        playlistFeature:(id)playlistFeature
             logContext:(id)log
              sourceURL:(NSURL *)sourceURL
       contextSourceURL:(NSURL *)contextSourceURL;
@end

@interface SPTCollectionPlatformAddRemoveFromCollectionAction : SPAction
- (id)initWithLink:(NSURL *)link
collectionPlatform:(id)colPlatform
collectionTestManager:(id)colTestManager
   wasInCollection:(BOOL)inCollection
        logContext:(id)log
         sourceURL:(NSURL *)sourceURL;
@end

@interface SPTQueueTrackAction : SPAction
- (id)initWithTrack:(SPTPlayerTrack *)track
             player:(SPTPlayerImpl *)player
        playerQueue:(SPTCosmosPlayerQueue *)queue
      upsellManager:(id)arg1
         logContext:(id)log
    alertController:(id)alert;
@end

@interface SPTShareAction : SPAction
- (id)initWithItemURL:(NSURL *)itemURL
             itemName:(NSString *)name
          creatorName:(NSString *)artist
           sourceName:(NSString *)album
             imageURL:(NSURL *)imageURL
            sourceUrl:(NSURL *)sourceUrl
            shareType:(NSUInteger)type
   clipboardLinkTitle:(NSString *)text
              session:(SPSession *)session
         shareFeature:(SPTShareFeatureImplementation *)shareFeature
           logContext:(id)log;
@end

@interface SPTStartRadioAction : SPAction
- (id)initWithSeedURL:(NSURL *)URL
            session:(id)session
       radioManager:(id)radioManager
         logContext:(id)log;
@end

@interface SPTGoToURLAction : SPAction
- (id)initWithURL:(NSURL *)URL
            title:(NSString *)title
     logEventName:(NSString *)logName
            order:(NSInteger *)order
       logContext:(id)log;
@end

// Context menu
@interface SPTContextMenuViewController : UIViewController
- (id)initWithHeaderImageURL:(id)arg1
                     actions:(id)arg2
                   entityURL:(id)arg3
                 imageLoader:(id)arg4
                  headerView:(id)arg5
 modalPresentationController:(id)arg6
                      logger:(id)arg7
                       model:(id)arg8
                       theme:(id)arg9
          notificationCenter:(id)arg10;
- (id)initWithHeaderImageURL:(id)arg1
                     actions:(id)arg2
                   entityURL:(id)arg3
                 imageLoader:(id)arg4
                  headerView:(id)arg5
 modalPresentationController:(id)arg6
                       model:(id)arg7
                       theme:(id)arg8
          notificationCenter:(id)arg9;
@end

@interface SPTContextMenuTaskAction : NSObject
@property (nonatomic, readwrite, assign) SPAction *action;
+ (id)actionWithAction:(SPAction *)action;
+ (NSArray *)actionsWithActions:(NSArray<SPAction *> *)actions;
@end

@interface SPTContextMenuModel : NSObject
- (id)initWithOptions:(id)options player:(id)player;
@end

@interface SPTContextMenuOptionsImplementation : NSObject
- (void)setShouldShowScannable:(BOOL)show;
@end

@interface SPTAlertPresenter : NSObject
+ (id)sharedInstance;
@end

@interface SPTScannablesContextMenuHeaderView : UIView
- (id)initWithTitle:(NSString *)title
           subtitle:(NSString *)subtitle
          entityURL:(NSURL *)URL
         dataSource:(id)dataSource
onboardingPresenter:(id)arg1
authorizationRequester:(id)arg2
       dependencies:(SPTScannablesDependencies *)dep
    alertController:(SPTAlertPresenter *)alert;
@end


// Views and view controllers
@interface SPTCollectionOverviewNavigationModelEntryImplementation : NSObject
- (id)initWithDictionary:(NSDictionary *)dict;
@end

@interface SPTCollectionOverviewNavigationModel
@property (nonatomic, readwrite, assign) NSMutableArray *navigationItems;
@end

@interface SPTTableView : UITableView
- (id)dequeueReusableHeaderFooterViewWithIdentifier:(id)identifier;
@end

@interface SPTInfoView : UIView
@property (nonatomic, readwrite, assign) NSString *title;
@property (nonatomic, readwrite, assign) NSString *text;
@property (nonatomic, readwrite, assign) UIImage *image;
@end

@interface UINavigationController (SPT)
- (void)pushViewControllerOnTopOfTheNavigationStack:(UIViewController *)vc animated:(BOOL)animate;
@end

@interface SPTCollectionOverviewViewController : UIViewController
@property (nonatomic, readwrite, assign) SPTLinkDispatcherImplementation *linkDispatcher;
@end

@interface SPTNowPlayingBarContainerViewController : UIViewController
- (SPTPlayerTrack *)currentTrack;
- (NSDictionary *)exportTrack;
@end

@interface SPTSwipeableTableViewCellShelf : UIView
+ (id)queueShelf;
+ (id)removeFromCollectionShelf;
@end

@interface SPTSwipeableTableViewCell : UITableViewCell
- (void)setShelf:(id)shelf forGesture:(NSInteger)gesture;
- (void)setSwipeDelegate:(id)delegate;
@end

@interface SettingsMultipleChoiceTableViewCell : UITableViewCell
- (void)setCheckmarkAccessory;
- (void)setAccessoryView:(UIImageView *)view;
@end

@interface SPTTableViewSectionHeaderView : UIView
@property (nonatomic, readwrite, assign) NSString *title;
@end

@interface SPTableHeaderFooterView : UIView
- (id)initWithStyle:(NSInteger)style maxWidth:(CGFloat)width;
@property (nonatomic, readwrite, assign) NSString *text;
@property (nonatomic, readwrite, assign) BOOL firstSection;
@property (nonatomic, readwrite, assign) BOOL lastSection;
@end

@interface GLUEButton : UIButton
@end

@interface SPTSettingsButtonTableViewCell : UITableViewCell
@property (nonatomic, readwrite, assign) GLUEButton *button;
@end
