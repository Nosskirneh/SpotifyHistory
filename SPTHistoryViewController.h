#import "Spotify.h"

#define prefPath @"/var/mobile/Library/Preferences/se.nosskirneh.spotifyhistory.plist"
#define kTracks @"tracks"

@interface SPTHistoryViewController : UITableViewController
@property (nonatomic, strong) SPTTableView *view;
@property (nonatomic, strong) NSDictionary *prefs;
@property (nonatomic, strong) SPTGLUEImageLoader *imageLoader;
@property (nonatomic, strong) SPTStatefulPlayer *statefulPlayer;
@property (nonatomic) CGFloat nowPlayingBarHeight;
@property (nonatomic, strong) SPTModalPresentationControllerImplementation *modalPresentationController;
@property (nonatomic, strong) SPTImageLoaderImplementation *contextImageLoader;
@property (nonatomic, strong) PlaylistFeatureImplementation *playlistFeature;
@property (nonatomic, strong) SPTCollectionPlatformImplementation *collectionPlatform;
@property (nonatomic, strong) SPTLinkDispatcherImplementation *linkDispatcher;
@property (nonatomic, strong) SPTScannablesTestManagerImplementation *scannablesTestManager;
@property (nonatomic, strong) SPTRadioManager *radioManager;
@property (nonatomic, strong) SPSession *session;
@property (nonatomic, strong) SPTDataLoaderFactory *dataLoaderFactory;
@property (nonatomic, strong) SPTShareFeatureImplementation *shareFeature;
@property (nonatomic, strong) UINavigationItem *navigationItem;
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
@end
