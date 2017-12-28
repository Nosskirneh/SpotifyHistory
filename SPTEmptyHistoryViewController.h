#import "Spotify.h"

@interface SPTEmptyHistoryViewController : UIViewController
@property (nonatomic, strong) SPTInfoView *view;
@property (nonatomic, assign) UINavigationItem *navigationItem;
@property (nonatomic) CGFloat nowPlayingBarHeight;
- (id)initWithNowPlayingBarHeight:(CGFloat)height;
@end
