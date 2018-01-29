#import "Spotify.h"

@interface SPTHistoryViewController : UITableViewController
@property (nonatomic, strong) SPTTableView *view;
@property (nonatomic, strong) SPTInfoView *infoView;
@property (nonatomic, strong) NSArray *tracks;
@property (nonatomic, assign) SPTGLUEImageLoader *imageLoader;
@property (nonatomic, assign) SPTStatefulPlayer *statefulPlayer;
@property (nonatomic) CGFloat nowPlayingBarHeight;
@property (nonatomic, assign) SPTModalPresentationControllerImplementation *modalPresentationController;
@property (nonatomic, assign) SPTImageLoaderImplementation *contextImageLoader;
@property (nonatomic, assign) PlaylistFeatureImplementation *playlistFeature;
@property (nonatomic, assign) SPSession *session;
@property (nonatomic, assign) SPContextMenuFeatureImplementation *contextMenuFeature;
@property (nonatomic, strong) NSURL *sourceURL;
@property (nonatomic, assign) UINavigationItem *navigationItem;
- (id)initWithTracks:(NSArray *)tracks
 nowPlayingBarHeight:(CGFloat)height
         imageLoader:(SPTGLUEImageLoader *)imageLoader
      statefulPlayer:(SPTStatefulPlayer *)statefulPlayer
  contextImageLoader:(SPTImageLoaderImplementation *)contextImageLoader
     playlistFeature:(PlaylistFeatureImplementation *)playlistFeature
             session:(SPSession *)session
  contextMenuFeature:(SPContextMenuFeatureImplementation *)contextMenuFeature;
- (void)updateListWithTracks:(NSArray *)tracks;
- (BOOL)checkEmptyTracks:(NSArray *)newTracks;
@end
