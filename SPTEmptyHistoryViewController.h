#import "Spotify.h"

@interface SPTEmptyHistoryViewController : UIViewController
@property (nonatomic, strong) SPTInfoView *view;
@property (nonatomic, strong) UINavigationItem *navigationItem;
@property (nonatomic, strong) NSDictionary *prefs;
@property (nonatomic) CGFloat nowPlayingBarHeight;
- (id)initWithPreferences:(NSDictionary *)prefs
      nowPlayingBarHeight:(CGFloat)height;
@end
