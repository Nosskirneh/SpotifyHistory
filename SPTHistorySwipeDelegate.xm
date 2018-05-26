#import "SPTHistorySwipeDelegate.h"
#import "SPTTrackTableViewCell.h"

@implementation SPTHistorySwipeDelegate

- (id)initWithTableView:(UITableView *)tableView
                 player:(SPTPlayerImpl *)player
  historyViewController:(SPTHistoryViewController *)historyViewController {
    if (self = [super init]) {
        self.tableView = tableView;
        self.player = player;
        self.historyViewController = historyViewController;
    }

    return self;
}

- (void)swipeableTableViewCell:(SPTTrackTableViewCell *)cell
            didCompleteGesture:(NSInteger)gesture
        withHorizontalVelocity:(CGFloat)velocity
                 triggerOffset:(CGFloat)offset {
    if (gesture == leftSwipe) {
        // Add to queue
        if (self.player &&
            [%c(SPTCosmosPlayerQueue) instancesRespondToSelector:@selector(initWithPlayer:)]) {
            SPTCosmosPlayerQueue *queue = [[%c(SPTCosmosPlayerQueue) alloc] initWithPlayer:self.player];
            [queue queueTrack:[%c(SPTPlayerTrack) trackWithURI:cell.trackURI]];
        }
    } else {
        // Remove cell
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
        NSMutableArray *tracks = [prefs[kTracks] mutableCopy];
        [tracks removeObjectAtIndex:indexPath.row];

        prefs[kTracks] = tracks;
        if (![prefs writeToFile:kPrefPath atomically:NO])
            HBLogError(@"Could not save %@ to path %@", prefs, kPrefPath);

        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.historyViewController checkEmptyTracks:tracks];
    }
}

@end
