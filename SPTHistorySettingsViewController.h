#import "Spotify.h"
#import "SPTHistoryViewController.h"

@interface SPTHistorySettingsViewController : UITableViewController
@property (nonatomic, strong) SPTTableView *view;
@property (nonatomic, assign) NSDictionary *prefs;
@property (nonatomic) CGFloat nowPlayingBarHeight;
@property (nonatomic, assign) UINavigationItem *navigationItem;
@property (nonatomic, assign) NSIndexPath *currentIndexPath;
@property (nonatomic, assign) SPTHistoryViewController *historyViewController;
@property (nonatomic, assign) PlaylistFeatureImplementation *playlistFeature;
@property (nonatomic, assign) NSMutableArray *buttons;
@property (nonatomic, assign) UIButton *exportButton;
- (id)initWithNowPlayingBarHeight:(CGFloat)nowPlayingBarHeight
            historyViewController:(SPTHistoryViewController *)historyViewController
                  playlistFeature:(PlaylistFeatureImplementation *)playlistFeature;
@end
