#import "SPTHistorySettingsViewController.h"


@interface SettingsMultipleChoiceIntegerTableViewCell : SettingsMultipleChoiceTableViewCell
@property (nonatomic, assign) NSInteger value;
@end

%subclass SettingsMultipleChoiceIntegerTableViewCell : SettingsMultipleChoiceTableViewCell
%property (nonatomic, assign) NSInteger value;
%end

@implementation SPTHistorySettingsViewController
@dynamic view;

- (id)initWithNowPlayingBarHeight:(CGFloat)nowPlayingBarHeight
            historyViewController:(SPTHistoryViewController *)historyViewController
                  playlistFeature:(PlaylistFeatureImplementation *)playlistFeature {
    if (self == [super init]) {
        self.prefs = [[NSDictionary alloc] initWithContentsOfFile:prefPath];
        self.nowPlayingBarHeight = nowPlayingBarHeight;
        self.historyViewController = historyViewController;
        self.playlistFeature = playlistFeature;

        self.navigationItem = [[UINavigationItem alloc] initWithTitle:@"History Settings"];
    }

    return self;
}

- (void)loadView {
    self.view = [[%c(SPTTableView) alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.view.dataSource = self;
    self.view.delegate = self;
    self.view.contentInset = UIEdgeInsetsMake(self.view.contentInset.top,
                                              self.view.contentInset.left,
                                              self.view.contentInset.bottom + self.nowPlayingBarHeight,
                                              self.view.contentInset.right);
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 4;
    else
        return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";

    if (indexPath.section == 1) {
        SPTSettingsButtonTableViewCell *cell = [table dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil)
            cell = [[%c(SPTSettingsButtonTableViewCell) alloc] initWithStyle:UITableViewCellStyleDefault
                                                             reuseIdentifier:cellIdentifier];

        cell.textLabel.text = @"Export as playlist";
        if (!_playlistFeature) {
            cell.button.enabled = NO;
            cell.userInteractionEnabled = NO;
        }
        return cell;
    }

    return [self tableView:table createMaxSizeCellForIndexPath:indexPath withCellIdentifier:cellIdentifier];
}

- (UITableViewCell *)tableView:(UITableView *)table
 createMaxSizeCellForIndexPath:(NSIndexPath *)indexPath
            withCellIdentifier:(NSString *)cellIdentifier {
    SettingsMultipleChoiceIntegerTableViewCell *cell = [table dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
        cell = [[%c(SettingsMultipleChoiceIntegerTableViewCell) alloc] initWithStyle:UITableViewCellStyleDefault
                                                                     reuseIdentifier:cellIdentifier];

    // Save numeric values
    if (indexPath.row == 0) {
        cell.value = 30;
    } else if (indexPath.row == 1) {
        cell.value = 100;

        // Default value
        if (!self.prefs[kMaxSize]) {
            self.currentIndexPath = indexPath;
            [cell setCheckmarkAccessory];
        }
    } else if (indexPath.row == 2) {
        cell.value = 500;
    } else {
        cell.value = 0;
    }

    // Set checkmark for saved setting
    if (!self.currentIndexPath && [self.prefs[kMaxSize] integerValue] == cell.value) {
        self.currentIndexPath = indexPath;
        [cell setCheckmarkAccessory];
    }

    // Set text
    if (cell.value == 0) {
        cell.textLabel.text = @"∞";
        cell.textLabel.font = [cell.textLabel.font fontWithSize:24];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"%li", (long)cell.value];
    }

    return cell;
}

- (SPTTableViewSectionHeaderView *)tableView:(SPTTableView *)table viewForHeaderInSection:(NSInteger)section {
    static NSString *headerIdentifier = @"header";
    SPTTableViewSectionHeaderView *view = [table dequeueReusableHeaderFooterViewWithIdentifier:headerIdentifier];
    if (view == nil) {
        view = [[%c(SPTTableViewSectionHeaderView) alloc] initWithReuseIdentifier:headerIdentifier];
    }

    if (section == 0)
        view.title = @"Saving";
    else
        view.title = @"Export";
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 56;
}

- (SPTableHeaderFooterView *)tableView:(SPTTableView *)table viewForFooterInSection:(NSInteger)section {
    SPTableHeaderFooterView *view = [[%c(SPTableHeaderFooterView) alloc] initWithStyle:1 maxWidth:self.view.frame.size.width];

    if (section == 0)
        view.text = @"Changing this will take effect immediately, so be aware that choosing a lower value can delete history.";
        [view setFirstSection:YES];
        [view setLastSection:YES];
    return view;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 69;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [table deselectRowAtIndexPath:indexPath animated:YES];

    // Export
    if (indexPath.section == 1) {
        return [self exportTracks];
    }

    // Max size
    // Same cell as already picked?
    if ([self.currentIndexPath isEqual:indexPath]) {
        return;
    }

    SettingsMultipleChoiceIntegerTableViewCell *cell = nil;
    // Unmark the previously cell
    cell = ((SettingsMultipleChoiceIntegerTableViewCell *)[table cellForRowAtIndexPath:self.currentIndexPath]);
    [cell setAccessoryView:nil];

    // Mark this cell
    cell = ((SettingsMultipleChoiceIntegerTableViewCell *)[table cellForRowAtIndexPath:indexPath]);
    [cell setCheckmarkAccessory];

    // Save value
    NSMutableDictionary *mutablePrefs = [_prefs mutableCopy];
    mutablePrefs[kMaxSize] = [NSNumber numberWithInt:cell.value];

    // Check for track overflow
    if (cell.value != 0 && mutablePrefs[kTracks] &&
        [mutablePrefs[kTracks] count] > cell.value) {
        NSMutableArray *tracks = [mutablePrefs[kTracks] mutableCopy];
        for (int i = cell.value; i < tracks.count;) {
            [tracks removeLastObject];
        }
        mutablePrefs[kTracks] = tracks;

        // Update list
        if (self.historyViewController)
            [_historyViewController updateListWithTracks:tracks];
    }

    self.prefs = mutablePrefs;
    if (![mutablePrefs writeToFile:prefPath atomically:YES]) {
        HBLogError(@"Could not save %@ to path %@", mutablePrefs, prefPath);
    }

    self.currentIndexPath = indexPath;
}

- (CGFloat)tableView:(UITableView *)table heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

- (void)exportTracks {
    NSMutableArray *trackURLs = [NSMutableArray new];
    for (NSDictionary *track in self.prefs[kTracks]) {
        [trackURLs addObject:[NSURL URLWithString:track[@"URI"]]];
    }

    NSDate *date = [[NSDate alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    NSString *playlistName = [NSString stringWithFormat:@"History (%@)", dateString];

    [_playlistFeature presentAddToPlaylistViewControllerWithTrackURLs:trackURLs
                                                         addEntityURL:nil
                                                  defaultPlaylistName:playlistName
                                                           senderView:self.view
                                                           logContext:nil
                                                            sourceURL:nil
                                                     contextSourceURL:nil];
}

@end
