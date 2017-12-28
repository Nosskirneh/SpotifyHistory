#import "Spotify.h"
#import "SPTHistoryViewController.h"

@interface SPTHistorySettingsViewController : UITableViewController
@property (nonatomic, strong) SPTTableView *view;
@property (nonatomic, assign) NSDictionary *prefs;
@property (nonatomic) CGFloat nowPlayingBarHeight;
@property (nonatomic, assign) UINavigationItem *navigationItem;
@property (nonatomic, assign) NSIndexPath *currentIndexPath;
@property (nonatomic, assign) SPTHistoryViewController *historyViewController;
- (id)initWithPreferences:(NSDictionary *)prefs
      nowPlayingBarHeight:(CGFloat)nowPlayingBarHeight
    historyViewController:(SPTHistoryViewController *)historyViewController;
@end
