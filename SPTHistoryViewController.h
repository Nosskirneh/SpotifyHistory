#import "Spotify.h"

@interface SPTHistoryViewController : UITableViewController
@property (nonatomic, strong) SPTTableView *view;
@property (nonatomic, strong) NSDictionary *prefs;
@property (nonatomic, assign) SPTGLUEImageLoader *imageLoader;
@property (nonatomic, assign) SPTStatefulPlayer *statefulPlayer;
@property (nonatomic) CGFloat nowPlayingBarHeight;
@property (nonatomic, assign) SPTModalPresentationControllerImplementation *modalPresentationController;
@property (nonatomic, assign) SPTImageLoaderImplementation *contextImageLoader;
@property (nonatomic, assign) PlaylistFeatureImplementation *playlistFeature;
@property (nonatomic, assign) SPTCollectionPlatformImplementation *collectionPlatform;
@property (nonatomic, assign) SPTLinkDispatcherImplementation *linkDispatcher;
@property (nonatomic, assign) SPTScannablesTestManagerImplementation *scannablesTestManager;
@property (nonatomic, assign) SPTRadioManager *radioManager;
@property (nonatomic, assign) SPSession *session;
@property (nonatomic, assign) SPTDataLoaderFactory *dataLoaderFactory;
@property (nonatomic, assign) SPTShareFeatureImplementation *shareFeature;
@property (nonatomic, assign) UINavigationItem *navigationItem;
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
                  session:(SPSession *)session
        dataLoaderFactory:(SPTDataLoaderFactory *)dataLoaderFactory
             shareFeature:(SPTShareFeatureImplementation *)shareFeature;
- (void)updateListWithPreferences:(NSDictionary *)prefs;
@end
