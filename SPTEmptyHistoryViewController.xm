#import "SPTEmptyHistoryViewController.h"
#import "SPTHistorySettingsViewController.h"

@implementation SPTEmptyHistoryViewController
@dynamic view;

- (id)initWithNowPlayingBarHeight:(CGFloat)nowPlayingBarHeight {
    if (self == [super init]) {
        self.nowPlayingBarHeight = nowPlayingBarHeight;

        self.navigationItem = [[UINavigationItem alloc] initWithTitle:@"History"];
        UIImage *settingsIcon = [UIImage imageForSPTIcon:11 size:CGSizeMake(24, 24)];
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithImage:settingsIcon
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(presentSettings:)];
        [self.navigationItem setRightBarButtonItem:rightItem];
    }

    return self;
}

- (void)loadView {
    self.view = [[%c(SPTInfoView) alloc] initWithFrame:CGRectZero];
    self.view.title = @"Ohoh, empty history!";
    self.view.text = @"Go and play some music and watch it appear here afterwards.";
    self.view.image = [UIImage spt_infoViewErrorIcon];
}

- (void)presentSettings:(UIBarButtonItem *)sender {
    SPTHistorySettingsViewController *vc = [[SPTHistorySettingsViewController alloc] initWithNowPlayingBarHeight:self.nowPlayingBarHeight
                                                                                           historyViewController:nil
                                                                                                 playlistFeature:nil];
    [self.navigationController pushViewControllerOnTopOfTheNavigationStack:vc animated:YES];
}

@end
