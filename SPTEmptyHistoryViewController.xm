#import "SPTEmptyHistoryViewController.h"

@implementation SPTEmptyHistoryViewController
@dynamic view;

- (void)loadView {
    self.navigationItem = [[UINavigationItem alloc] initWithTitle:@"History"];

    self.view = [[%c(SPTInfoView) alloc] initWithFrame:CGRectZero];
    self.view.title = @"Ohoh, empty history!";
    self.view.text = @"Go and play some music and watch it appear here afterwards.";
    self.view.image = [UIImage spt_infoViewErrorIcon];
}

@end
