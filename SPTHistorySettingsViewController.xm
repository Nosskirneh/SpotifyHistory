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
        self.buttons = [NSMutableArray new];
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
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";

    if (indexPath.section == 0) {
        return [self tableView:table createMaxSizeCellForIndexPath:indexPath withCellIdentifier:cellIdentifier];
    } else if (indexPath.section == 1) {
        SPTSettingsButtonTableViewCell *cell = [table dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil)
            cell = [[%c(SPTSettingsButtonTableViewCell) alloc] initWithStyle:UITableViewCellStyleDefault
                                                             reuseIdentifier:cellIdentifier];

        cell.textLabel.text = @"Export as playlist";
        if (!_playlistFeature) {
            cell.button.enabled = NO;
            cell.button.userInteractionEnabled = NO;
        }

        [self.buttons addObject:cell.button];
        return cell;
    } else {
        SPTSettingsButtonTableViewCell *cell = [table dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil)
            cell = [[%c(SPTSettingsButtonTableViewCell) alloc] initWithStyle:UITableViewCellStyleDefault
                                                             reuseIdentifier:cellIdentifier];

        cell.textLabel.text = @"Erase history";
        cell.button.glueStyle.normalBackgroundColor = [UIColor colorWithRed:0.73 green:0.15 blue:0.11 alpha:1.0]; // #B9261D
        cell.button.glueStyle.highlightedBackgroundColor = [UIColor colorWithRed:0.50 green:0.11 blue:0.08 alpha:1.0]; // #7F1B14

        if (!_prefs[kTracks] || [_prefs[kTracks] count] == 0) {
            cell.button.enabled = NO;
            cell.button.userInteractionEnabled = NO;
        }

        [self.buttons addObject:cell.button];
        return cell;
    }
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
    else if (section == 1)
        view.title = @"Export";
    else
        view.title = @"Remove";

    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 56;
}

- (SPTableHeaderFooterView *)tableView:(SPTTableView *)table viewForFooterInSection:(NSInteger)section {
    SPTableHeaderFooterView *view = [[%c(SPTableHeaderFooterView) alloc] initWithStyle:1 maxWidth:self.view.frame.size.width];

    if (section == 0) {
        view.text = @"Changing this will take effect immediately, so be aware that choosing a lower value can delete history.";
        [view setFirstSection:YES];
    } else if (section == 2) {
        [view setLastSection:YES];
    }

    return view;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return 69;
    }

    return 0;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [table deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 1) {
        // Export
        return [self exportTracks];
    } else if (indexPath.section == 2) {
        // Erase
        return [self removeHistory];
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

- (void)removeHistory {
    // Deactivate buttons
    for (GLUEButton *button in self.buttons) {
        button.enabled = NO;
        button.userInteractionEnabled = NO;
    }

    // Commit the murder
    NSMutableDictionary *mutablePrefs = [self.prefs mutableCopy];
    mutablePrefs[kTracks] = nil;
    if (![mutablePrefs writeToFile:prefPath atomically:YES]) {
        HBLogError(@"Could not save %@ to path %@", mutablePrefs, prefPath);
    }
    self.prefs = mutablePrefs;

    // Update list
    if (self.historyViewController)
        [_historyViewController updateListWithTracks:nil];

    // Show alert
    SPTProgressView *view = [%c(SPTProgressView) progressView];
    view.frame = self.view.frame;
    view.title = @"Erased all history";
    view.mode = crossMode;
    [[[UIApplication sharedApplication] keyWindow] addSubview:view];
    [view animateShowing];
    [view performSelector:@selector(animateHiding) withObject:nil afterDelay:2];
}

@end
