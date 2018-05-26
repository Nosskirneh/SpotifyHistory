#import "SPTHistorySettingsViewController.h"

// Declaring this here since using the iOS 10 SDK results in logs not being visible
@interface UIApplication (iOS10)
- (void)openURL:(NSURL *)url 
        options:(NSDictionary<NSString *,id> *)options 
completionHandler:(void (^)(BOOL success))completion;
@end

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
        self.prefs = [[NSDictionary alloc] initWithContentsOfFile:kPrefPath];
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

    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *buttonCellID = @"ButtonCell";

    if (indexPath.section == 0) {
        static NSString *multipleCellID = @"MultipleChoice";
        return [self tableView:table createMaxSizeCellForIndexPath:indexPath withCellIdentifier:multipleCellID];
    } else if (indexPath.section == 1) {
        SPTSettingsButtonTableViewCell *cell = [table dequeueReusableCellWithIdentifier:buttonCellID];
        if (cell == nil)
            cell = [[%c(SPTSettingsButtonTableViewCell) alloc] initWithStyle:UITableViewCellStyleDefault
                                                             reuseIdentifier:buttonCellID];

        cell.textLabel.text = @"Export to playlist";
        if (!_playlistFeature || !_prefs[kTracks] || [_prefs[kTracks] count] == 0) {
            cell.button.enabled = NO;
            cell.button.userInteractionEnabled = NO;
        }

        self.exportButton = cell.button;
        [self.buttons addObject:cell.button];
        return cell;
    } else if (indexPath.section == 2) {
        SPTSettingsButtonTableViewCell *cell = [table dequeueReusableCellWithIdentifier:buttonCellID];
        if (cell == nil)
            cell = [[%c(SPTSettingsButtonTableViewCell) alloc] initWithStyle:UITableViewCellStyleDefault
                                                             reuseIdentifier:buttonCellID];

        cell.textLabel.text = @"Erase history";
        cell.button.glueStyle.normalBackgroundColor = [UIColor colorWithRed:0.73 green:0.15 blue:0.11 alpha:1.0]; // #B9261D
        cell.button.glueStyle.highlightedBackgroundColor = [UIColor colorWithRed:0.50 green:0.11 blue:0.08 alpha:1.0]; // #7F1B14

        if (!_prefs[kTracks] || [_prefs[kTracks] count] == 0) {
            cell.button.enabled = NO;
            cell.button.userInteractionEnabled = NO;
        }

        [self.buttons addObject:cell.button];
        return cell;
    } else {
        SPTSettingsButtonTableViewCell *cell = [table dequeueReusableCellWithIdentifier:buttonCellID];
        if (cell == nil)
            cell = [[%c(SPTSettingsButtonTableViewCell) alloc] initWithStyle:UITableViewCellStyleDefault
                                                             reuseIdentifier:buttonCellID];

        cell.textLabel.text = @"Donate";
        cell.button.glueStyle.normalBackgroundColor = [UIColor colorWithRed:0.11 green:0.73 blue:0.33 alpha:1.0]; // #1DB954
        cell.button.glueStyle.highlightedBackgroundColor = [UIColor colorWithRed:0.08 green:0.51 blue:0.23 alpha:1.0]; // #14823B
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
    if (view == nil)
        view = [[%c(SPTTableViewSectionHeaderView) alloc] initWithReuseIdentifier:headerIdentifier];

    if (section == 0)
        view.title = @"Saving";
    else if (section == 1)
        view.title = @"Export";
    else if (section == 2)
        view.title = @"Remove";
    else
        view.title = @"Donate";

    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 56;
}

- (SPTableHeaderFooterView *)tableView:(SPTTableView *)table viewForFooterInSection:(NSInteger)section {
    SPTableHeaderFooterView *view = nil;
    if ([%c(SPTableHeaderFooterView) instancesRespondToSelector:@selector(initWithStyle:maxWidth:)]) {
        view = [[%c(SPTableHeaderFooterView) alloc] initWithStyle:1 maxWidth:self.view.frame.size.width];

        if (section == 0) {
            view.text = @"Changing this will take effect immediately, so be aware that choosing a lower value can delete history.";
            [view setFirstSection:YES];
        } else if (section == 3) {
            view.text = @"SpotifyHistory is free. Please consider donating to support the continuous development that is required to support new versions of Spotify.";
            [view setLastSection:YES];
        }
    }

    return view;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0)
        return 50;
    else if (section == 3)
        return 80;

    return 0;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [table deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 1) // Export
        return [self exportTracks];
    else if (indexPath.section == 2) // Erase
        return [self removeHistory];
    else if (indexPath.section == 3) // Donate
        return [self donate];

    // Max size
    // Same cell as already picked?
    if ([self.currentIndexPath isEqual:indexPath])
        return;

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
        for (int i = cell.value; i < tracks.count;)
            [tracks removeLastObject];

        mutablePrefs[kTracks] = tracks;
        [self savePreferences:mutablePrefs];

        // Update list
        if (self.historyViewController)
            [_historyViewController updateListWithTracks:tracks];
    } else {
        [self savePreferences:mutablePrefs];
    }

    self.prefs = mutablePrefs;
    self.currentIndexPath = indexPath;
}

- (void)savePreferences:(NSDictionary *)prefs {
    if (![prefs writeToFile:kPrefPath atomically:NO])
        HBLogError(@"Could not save %@ to path %@", prefs, kPrefPath);
}

- (CGFloat)tableView:(UITableView *)table heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

- (void)exportTracks {
    if (!self.prefs[kTracks] || [self.prefs[kTracks] count] == 0)
        return;

    NSMutableArray *trackURLs = [NSMutableArray new];
    NSMutableSet *trackURLsSet = [NSMutableSet new];
    for (NSDictionary *track in self.prefs[kTracks]) {
        [trackURLs addObject:[NSURL URLWithString:track[@"URI"]]];
        [trackURLsSet addObject:[NSURL URLWithString:track[@"URI"]]];
    }

    if (trackURLsSet.count < trackURLs.count) {
        // Found duplicates
        // Build actions
        UIAlertAction *skip = [UIAlertAction actionWithTitle:@"Skip Those"
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction *action) {
                                                         [self presentAddToPlaylistViewControllerWithTrackURLs:[trackURLsSet allObjects]];
                                                      }];
        UIAlertAction *all = [UIAlertAction actionWithTitle:@"Add All"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
                                                        [self presentAddToPlaylistViewControllerWithTrackURLs:trackURLs];
                                                      }];
        SPTAlertPresenter *presenter = nil;
        if ([%c(SPTAlertPresenter) respondsToSelector:@selector(sharedInstance)])
            presenter = [%c(SPTAlertPresenter) sharedInstance];
        else if ([%c(SPTAlertPresenter) respondsToSelector:@selector(defaultPresenterWithWindow:)])
            presenter = [%c(SPTAlertPresenter) defaultPresenterWithWindow:[UIApplication sharedApplication].keyWindow];


        if ([presenter respondsToSelector:@selector(alertControllerWithTitle:message:actions:)] &&
            [presenter respondsToSelector:@selector(queueAlertController:)] &&
            [presenter respondsToSelector:@selector(showNextAlert)]) {
            UIAlertController *alert = [presenter alertControllerWithTitle:@"Duplicate Songs" message:@"Some of these songs exist several times in history" actions:@[skip, all]];
            [presenter queueAlertController:alert];
            [presenter showNextAlert];
        }
    }
}

- (void)presentAddToPlaylistViewControllerWithTrackURLs:(NSArray *)trackURLs {
    NSDate *date = [[NSDate alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    NSString *playlistName = [NSString stringWithFormat:@"History (%@)", dateString];

    if ([_playlistFeature respondsToSelector:@selector(presentAddToPlaylistViewControllerWithTrackURLs:addEntityURL:defaultPlaylistName:senderView:logContext:sourceURL:contextSourceURL:)]) {
        [_playlistFeature presentAddToPlaylistViewControllerWithTrackURLs:trackURLs
                                                             addEntityURL:nil
                                                      defaultPlaylistName:playlistName
                                                               senderView:self.exportButton
                                                               logContext:nil
                                                                sourceURL:nil
                                                         contextSourceURL:nil];
    }
}

- (void)removeHistory {
    if (!self.prefs[kTracks] || [self.prefs[kTracks] count] == 0)
        return;

    // Deactivate buttons
    for (GLUEButton *button in self.buttons) {
        button.enabled = NO;
        button.userInteractionEnabled = NO;
    }

    // Commit the murder
    NSMutableDictionary *mutablePrefs = [self.prefs mutableCopy];
    mutablePrefs[kTracks] = nil;
    [self savePreferences:mutablePrefs];
    self.prefs = mutablePrefs;

    // Update list
    if (self.historyViewController)
        [_historyViewController updateListWithTracks:nil];

    // Show alert
    if (%c(SPTProgressView) && [%c(SPTProgressView) respondsToSelector:@selector(progressView)]) {
        SPTProgressView *view = [%c(SPTProgressView) progressView];
        view.frame = self.view.frame;
        view.title = @"Erased all history";
        view.mode = crossMode;
        [[[UIApplication sharedApplication] keyWindow] addSubview:view];
        [view animateShowing];
        [view performSelector:@selector(animateHiding) withObject:nil afterDelay:2];
    }
}

- (void)donate {
    UIApplication *application = [UIApplication sharedApplication];
    NSURL *URL = [NSURL URLWithString:@"https://paypal.me/nosskirneh"];

    if ([application respondsToSelector:@selector(openURL:options:completionHandler:)])
        [application openURL:URL options:nil completionHandler:nil];
    else
        [application openURL:URL]; // iOS 9 and below
}

@end
