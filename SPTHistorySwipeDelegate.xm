#import "SPTHistorySwipeDelegate.h"

@implementation SPTHistorySwipeDelegate

- (id)initWithTableView:(UITableView *)tableView player:(SPTPlayerImpl *)player {
    if (self = [super init]) {
        self.tableView = tableView;
        self.player = player;
    }

    return self;
}

- (void)swipeableTableViewCell:(SPTTrackTableViewCell *)cell
            didCompleteGesture:(NSInteger)gesture
        withHorizontalVelocity:(CGFloat)velocity
                 triggerOffset:(CGFloat)offset {

    if (gesture == LEFT_SWIPE) {
        // Add to queue
        SPTCosmosPlayerQueue *queue = [[%c(SPTCosmosPlayerQueue) alloc] initWithPlayer:self.player];
        [queue queueTrack:[%c(SPTPlayerTrack) trackWithURI:cell.trackURI]];
    } else {
        // Remove cell
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefPath];
        NSMutableArray *tracks = [((NSArray *)prefs[kTracks]) mutableCopy];
        [tracks removeObjectAtIndex:indexPath.row];

        prefs[kTracks] = tracks;
        if (![prefs writeToFile:prefPath atomically:YES]) {
            HBLogError(@"Could not save %@ to path %@", prefs, prefPath);
        }

        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
