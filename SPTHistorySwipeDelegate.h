#import "Spotify.h"

@interface SPTHistorySwipeDelegate : NSObject
@property (nonatomic, readwrite, assign) UITableView *tableView;
@property (nonatomic, readwrite, assign) SPTPlayerImpl *player;
- (id)initWithTableView:(UITableView *)tableView player:(SPTPlayerImpl *)player;
@end
