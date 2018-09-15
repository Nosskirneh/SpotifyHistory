#import "Spotify.h"

@interface SPTHistoryViewController : UITableViewController
@property (nonatomic, strong) SPTTableView *view;
@property (nonatomic, strong) SPTInfoView *infoView;
@property (nonatomic, strong) NSArray *tracks;
@property (nonatomic, strong) SPTGLUEImageLoader *imageLoader;
@property (nonatomic, strong) SPTPlayerImpl *player;
@property (nonatomic) CGFloat nowPlayingBarHeight;
@property (nonatomic, strong) SPTModalPresentationControllerImplementation *modalPresentationController;
@property (nonatomic, strong) SPTImageLoaderImplementation *contextImageLoader;
@property (nonatomic, strong) PlaylistFeatureImplementation *playlistFeature;
@property (nonatomic, strong) SPSession *session;
@property (nonatomic, strong) SPContextMenuFeatureImplementation *contextMenuFeature;
@property (nonatomic, strong) NSURL *sourceURL;
@property (nonatomic, strong) UINavigationItem *navigationItem;
- (id)initWithTracks:(NSArray *)tracks
 nowPlayingBarHeight:(CGFloat)height
         imageLoader:(SPTGLUEImageLoader *)imageLoader
              player:(SPTPlayerImpl *)player
  contextImageLoader:(SPTImageLoaderImplementation *)contextImageLoader
     playlistFeature:(PlaylistFeatureImplementation *)playlistFeature
             session:(SPSession *)session
  contextMenuFeature:(SPContextMenuFeatureImplementation *)contextMenuFeature;
- (void)updateListWithTracks:(NSArray *)tracks;
- (BOOL)checkEmptyTracks:(NSArray *)newTracks;
@end
