#import "Spotify.h"
#import "SPTHistoryViewController.h"

@interface SPTHistorySwipeDelegate : NSObject
@property (nonatomic, readwrite, assign) UITableView *tableView;
@property (nonatomic, readwrite, assign) SPTPlayerImpl *player;
@property (nonatomic, assign) SPTHistoryViewController *historyViewController;
- (id)initWithTableView:(UITableView *)tableView
                 player:(SPTPlayerImpl *)player
  historyViewController:(SPTHistoryViewController *)historyViewController;
@end
