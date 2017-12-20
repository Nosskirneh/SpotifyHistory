#define inCollectionEnum 0
#define notInCollectionEnum 2

// Data objects
@interface SPTPlayerTrack : NSObject
@property (nonatomic, readwrite, assign) NSURL *imageURL;
@property (nonatomic, readwrite, assign) NSURL *URI;
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
@end

// Images
@interface UIImage (spt)
+ (id)imageForSPTIcon:(NSInteger)icon size:(CGSize)size;
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
- (id)initWithTrackURLs:(NSArray *)tracks addEntityURL:(NSURL *)entityURL defaultPlaylistName:(NSString *)name playlistFeature:(id)playlistFeature logContext:(id)logContext sourceURL:(NSURL *)sourceURL contextSourceURL:(NSURL *)contextSourceURL;
@end

@interface SPTCollectionPlatformAddRemoveFromCollectionAction : SPAction
- (id)initWithLink:(NSURL *)link collectionPlatform:(id)colPlatform collectionTestManager:(id)colTestManager wasInCollection:(BOOL)inCollection logContext:(id)logContext sourceURL:(NSURL *)sourceURL;
@end

@interface SPTQueueTrackAction : SPAction
- (id)initWithTrack:(SPTPlayerTrack *)track player:(SPTPlayerImpl *)player playerQueue:(SPTCosmosPlayerQueue *)queue upsellManager:(id)arg1 logContext:(id)arg2 alertController:(id)alert;
@end

// Context menu
@interface SPTContextMenuViewController : UIViewController
- (id)initWithHeaderImageURL:(id)arg1 entityURL:(id)arg2 imageLoader:(id)arg3 headerView:(id)arg4 modalPresentationController:(id)arg5 logger:(id)arg6 model:(id)arg7 theme:(id)arg8 notificationCenter:(id)arg9;
- (id)initWithHeaderImageURL:(id)arg1 actions:(id)arg2 entityURL:(id)arg3 imageLoader:(id)arg4 headerView:(id)arg5 modalPresentationController:(id)arg6 logger:(id)arg7 model:(id)arg8 theme:(id)arg9 notificationCenter:(id)arg10;
@end

@interface SPTContextMenuTaskAction : NSObject
@property (nonatomic, readwrite, assign) SPAction *action;
+ (id)actionFromTask:(SPAction *)task;
+ (id)actionsFromTasks:(NSArray *)tasks;
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
@interface SPTCollectionOverviewNavigationModelEntryImplementation
- (id)initWithDictionary:(NSDictionary *)dict;
@end

@interface SPTCollectionOverviewNavigationModel
@property (nonatomic, readwrite, assign) NSMutableArray *navigationItems;
@end

@interface SPTTableView : UITableView
@end

@interface SPTInfoView : UIView
@property (nonatomic, readwrite, assign) NSString *title;
@property (nonatomic, readwrite, assign) NSString *text;
@property (nonatomic, readwrite, assign) UIImage *image;
@end

@interface SPNavigationController : UINavigationController
- (void)pushViewControllerOnTopOfTheNavigationStack:(UIViewController *)vc animated:(BOOL)animate;
@end

@interface SPTCollectionOverviewViewController : UIViewController
@property (nonatomic, readwrite, assign) SPNavigationController *navigationController;
@property (nonatomic, readwrite, assign) SPTLinkDispatcherImplementation *linkDispatcher;
@end

@interface SPTNowPlayingBarContainerViewController : UIViewController
- (SPTPlayerTrack *)currentTrack;
@end
