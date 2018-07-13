#define kPrefPath ((SpotifyAppDelegate *)[[UIApplication sharedApplication] delegate]).historyPrefPath
#define kTracks @"tracks"
#define kMaxSize @"maxSize"

typedef enum {
    isAvailableOffline = 3,
    isNotAvailableOffline = 0
} OfflineStates;

typedef enum {
    leftSwipe = 1,
    rightSwipe = 2
} SwipeDirections;

@interface SpotifyAppDelegate : NSObject
@property (nonatomic, retain) NSString *historyPrefPath;
@end

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
@property(nonatomic, readwrite, assign) BOOL isOffline;
@end


// Images
@interface UIImage (SPT)
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

// Context menu
@interface SPTContextMenuViewController : UIViewController
- (id)initWithHeaderImageURL:(id)arg1
                       tasks:(id)arg2
                   entityURL:(id)arg3
                 imageLoader:(id)arg4
                  headerView:(id)arg5
 modalPresentationController:(id)arg6
                     options:(id)arg7
                       theme:(id)arg8
          notificationCenter:(id)arg9;

- (id)initWithHeaderImageURL:(id)arg1
                       tasks:(id)arg2
                   entityURL:(id)arg3
                 imageLoader:(id)arg4
                  headerView:(id)arg5
 modalPresentationController:(id)arg6
                       model:(id)arg7
                       theme:(id)arg8
          notificationCenter:(id)arg9;

- (id)initWithHeaderImageURL:(id)arg1
                       tasks:(id)arg2
                   entityURL:(id)arg3
                 imageLoader:(id)arg4
                  headerView:(id)arg5
 modalPresentationController:(id)arg6
                      logger:(id)arg7
                       model:(id)arg8
                       theme:(id)arg9
          notificationCenter:(id)arg10;
@end

@interface SPTPopoverController : NSObject
- (id)initWithContentViewController:(id)arg1;
@end

@interface SPTContextMenuIpadPresenterImplementation : NSObject
- (id)initWithPopoverController:(SPTPopoverController *)popoverController;
- (void)presentWithSenderView:(UIView *)sender permittedArrowDirections:(NSUInteger)directions animated:(BOOL)animate;
@end

@interface SPTask : NSObject
@end

@interface SPContextMenuActionsFactoryImplementation : NSObject
- (id)actionForURIs:(id)arg1 logContext:(id)arg2 sourceURL:(id)arg3 containerURL:(id)arg4 playlistName:(id)arg5 actionIdentifier:(id)arg6 contextSourceURL:(id)arg7;
- (id)actionForURI:(id)arg1 logContext:(id)arg2 sourceURL:(id)arg3 tracks:(id)arg4 actionIdentifier:(id)arg5;
- (id)actionForURI:(id)arg1 logContext:(id)arg2 sourceURL:(id)arg3 itemName:(id)arg4 creatorName:(id)arg5 sourceName:(id)arg6 imageURL:(id)arg7 clipboardLinkTitle:(id)arg8 actionIdentifier:(id)arg9;
- (id)actionForURI:(id)arg1 logContext:(id)arg2 sourceURL:(id)arg3 actionIdentifier:(id)arg4;
- (id)actionForURIs:(id)arg1 logContext:(id)arg2 sourceURL:(id)arg3 actionIdentifier:(id)arg4 title:(id)arg5 albumTitle:(id)arg6 artistTitle:(id)arg7 imageURL:(id)arg8 clipboardLinkTitle:(id)arg9 tracks:(id)arg10 containerEntityURL:(id)arg11;
- (id)viewAlbumWithAlbumURL:(id)arg1 logContext:(id)arg2;
- (id)viewArtistWithURL:(id)arg1 logContext:(id)arg2;
@end

@interface SPTScannablesServiceImplementation : NSObject
@property(retain, nonatomic) id authorizationRequester;
@property(retain, nonatomic) id dependencies; // < 8.4.39
@property(retain, nonatomic) id scannableDependencies; // >= 8.4.39
@property(retain, nonatomic) id onboardingPresenter;
@property(retain, nonatomic) id scannablesDataSource;
@end

@interface SPTUIPresentationServiceImplementation : NSObject
@property(retain, nonatomic) SPTModalPresentationControllerImplementation *modalPresentationController;
@end

@interface SPTContextMenuOptionsImplementation : NSObject
@end

@interface SPTContextMenuOptionsFactoryImplementation : NSObject
- (id)contextMenuOptionsWithScannableEnabled:(BOOL)enabled;
@end

@interface SPContextMenuFeatureImplementation : NSObject
@property(retain, nonatomic) SPContextMenuActionsFactoryImplementation *actionsFactory;
@property(retain, nonatomic) SPTContextMenuOptionsFactoryImplementation *contextMenuOptionsFactory;
@property(nonatomic, assign) SPTScannablesServiceImplementation *scannablesService;
@property(nonatomic, assign) SPTUIPresentationServiceImplementation *UIPresentationService;
@end

@interface SPTContextMenuViewControllerIPad : UIViewController
@property (nonatomic, readwrite, assign) SPTPopoverController *currentPopoverController;
- (id)initWithHeaderImageURL:(id)arg1
      headerImagePlaceholder:(id)arg2
                       title:(id)arg3
                    subtitle:(id)arg4
               metadataTitle:(id)arg5
                       tasks:(id)arg6
                   entityURL:(id)arg7
                    trackURL:(id)arg8
                 imageLoader:(id)arg9
                  senderView:(id)arg10;
@end

@interface SPTContextMenuModel : NSObject
- (id)initWithOptions:(id)options player:(id)player;
@end

@interface SPTAlertPresenter : NSObject
+ (id)sharedInstance;
+ (id)defaultPresenterWithWindow:(id)arg;
- (UIAlertController *)alertControllerWithTitle:(NSString *)title message:(NSString *)msg actions:(NSArray *)actions;
- (void)queueAlertController:(UIAlertController *)alert;
- (void)showNextAlert;
@end

@interface SPTScannablesContextMenuHeaderView : UIView
- (id)initWithTitle:(NSString *)title
           subtitle:(NSString *)subtitle
          entityURL:(NSURL *)URL
         dataSource:(id)dataSource
onboardingPresenter:(id)arg1
authorizationRequester:(id)arg2
       dependencies:(id)dep
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
@property (nonatomic, readwrite, assign) id linkDispatcher;
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

@interface GLUEButtonStyle : NSObject
@property (nonatomic, readwrite, assign) UIColor *normalBackgroundColor;
@property (nonatomic, readwrite, assign) UIColor *highlightedBackgroundColor;
@end

@interface GLUEButton : UIButton
@property (nonatomic, readwrite, assign) GLUEButtonStyle *glueStyle;
@end

@interface SPTSettingsButtonTableViewCell : UITableViewCell
@property (nonatomic, readwrite, assign) GLUEButton *button;
@end


/*
 * SPTProgressView modes:
 * 0: three dots
 * 1: checkmark
 * 2: cross
 */
enum {
    threeDotsMode,
    checkmarkMode,
    crossMode
};

@interface SPTProgressView : UIView
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, assign, readwrite) NSInteger mode;
+ (id)progressView;
- (void)animateShowing;
- (void)animateHiding;
@end
