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
@property (nonatomic, readwrite, assign) SPTOfflineManager *offlineManager;
@property (nonatomic, readwrite, assign) SPTOfflineModeNotifier *offlineNotifier;
@property (nonatomic, readwrite, assign) BOOL isOffline;
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

@protocol SPTContextMenuPresenter <NSObject>
@property (readonly, nonatomic, getter=isPresenting) BOOL presenting;
@property (nonatomic) __weak id delegate;
- (void)presentInViewController:(UIViewController *)arg1 senderView:(UIView *)arg2 permittedArrowDirections:(unsigned long long)arg3 animated:(BOOL)arg4;
- (void)presentWithSenderView:(UIView *)arg1 permittedArrowDirections:(unsigned long long)arg2 animated:(BOOL)arg3;
@end

@interface SPTContextMenuOptionsImplementation : NSObject
@end

@interface SPTContextMenuOptionsFactoryImplementation : NSObject
- (id)contextMenuOptionsWithScannableEnabled:(BOOL)enabled;
@end

@interface SPTArtistEntityImpl : NSObject
@end

@interface SPTArtistEntityFactory : NSObject
+ (id)artistEntityForName:(id)arg1 uri:(id)arg2 imageURL:(id)arg3;
@end

@interface SPTContextMenuPresenterFactoryImplementation : NSObject
- (id<SPTContextMenuPresenter>)contextMenuPresenterForTrackWithTrackURL:(id)arg1 trackName:(id)arg2 trackMetadata:(id)arg3 playable:(BOOL)arg4 imageURL:(id)arg5 artists:(id)arg6 albumName:(id)arg7 albumURL:(id)arg8 viewURL:(id)arg9 contextSourceURL:(id)arg10 metadataTitle:(id)arg11 logContextIphone:(id)arg12 logContextIpad:(id)arg13 senderView:(id)arg14 options:(id)arg15;
@end

@interface SPContextMenuFeatureImplementation : NSObject
@property (retain, nonatomic) SPTContextMenuOptionsFactoryImplementation *contextMenuOptionsFactory;
@property (retain, nonatomic) SPTContextMenuPresenterFactoryImplementation *contextMenuPresenterFactory;
@end


@interface SPTAlertPresenter : NSObject
+ (id)sharedInstance;
+ (id)defaultPresenterWithWindow:(id)arg;
- (UIAlertController *)alertControllerWithTitle:(NSString *)title message:(NSString *)msg actions:(NSArray *)actions;
- (void)queueAlertController:(UIAlertController *)alert;
- (void)showNextAlert;
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

@protocol SPTSwipeableTableViewCellDelegate <NSObject>
@optional
- (void)swipeableTableViewCell:(id)arg1 didCompleteGesture:(long long)arg2;
@end

@interface SPTSwipeableTableViewCell : UITableViewCell
@property(nonatomic) __weak id <SPTSwipeableTableViewCellDelegate> swipeDelegate;
- (void)setShelf:(id)shelf forGesture:(NSInteger)gesture;
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


// Get Spotify objects
@interface SPTGLUEImageLoaderFactoryImplementation : NSObject
- (id)createImageLoaderForSourceIdentifier:(NSString *)sourceIdentifier;
@end

@interface SPTImageLoaderFactoryImplementation : NSObject
- (id)createImageLoader;
@end

@interface SPTQueueServiceImplementation : NSObject
@property (retain, nonatomic) SPTGLUEImageLoaderFactoryImplementation *glueImageLoaderFactory;
@property (retain, nonatomic) SPTImageLoaderFactoryImplementation *imageLoaderFactory;
@end

@interface SPCore : NSObject
- (SPSession *)session;
@end

@interface SPTCoreServiceImplementation : NSObject
@property (retain, nonatomic) SPCore *core;
@end

@interface NowPlayingFeatureImplementation : NSObject
@property (nonatomic) __weak PlaylistFeatureImplementation *playlistFeature;
@property (nonatomic) __weak SPTCoreServiceImplementation *coreService;
@property (retain, nonatomic) SPTStatefulPlayer *statefulPlayer;
@property (nonatomic) __weak SPTQueueServiceImplementation *queueService;
@property (nonatomic) __weak SPContextMenuFeatureImplementation *contextMenu;
@property (retain, nonatomic) UIViewController *nowPlayingBarViewController;
@end

@interface SpotifyApplication : UIApplication
@property (nonatomic) __weak NowPlayingFeatureImplementation *remoteControlDelegate;
@end
// ---



/*
 * SPTProgressView modes:
 * 0: three dots
 * 1: checkmark
 * 2: cross
 */
typedef enum {
    SPTProgressViewDotsMode,
    SPTProgressViewCheckmarkMode,
    SPTProgressViewCrossMode
} SPTProgressViewMode;

@interface SPTProgressView : UIView
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, assign, readwrite) NSInteger mode;
+ (id)progressView;
- (void)animateShowing;
- (void)animateHiding;
@end
