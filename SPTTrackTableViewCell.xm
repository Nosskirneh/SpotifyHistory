#import "SPTTrackTableViewCell.h"

%subclass SPTTrackTableViewCell : SPTSwipeableTableViewCell
%property (nonatomic, retain) NSURL *trackURI;
%property (nonatomic, retain) NSURL *imageURL;
%property (nonatomic, retain) NSString *trackName;
%property (nonatomic, retain) NSString *artist;
%property (nonatomic, retain) NSString *album;
%property (nonatomic, retain) NSURL *artistURI;
%property (nonatomic, retain) NSURL *albumURI;
%property (nonatomic, retain) SPSession *session;

- (void)layoutSubviews {
    %orig;

    // Labels
    self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x,
                                      self.textLabel.frame.origin.y,
                                      self.frame.size.width - 140,
                                      self.textLabel.frame.size.height);

    self.detailTextLabel.frame = CGRectMake(self.detailTextLabel.frame.origin.x,
                                            self.detailTextLabel.frame.origin.y,
                                            self.frame.size.width - 140,
                                            self.detailTextLabel.frame.size.height);

    // Accessory view
    CGRect adjustedFrame = self.accessoryView.frame;
    adjustedFrame.origin.x += 20.0f;
    self.accessoryView.frame = adjustedFrame;

    // Image view
    adjustedFrame = self.imageView.frame;
    adjustedFrame.origin.x -= 4.0f;
    self.imageView.frame = adjustedFrame;

    // Set lower alpha on tracks not available offline
    NSInteger offlineState = [self.session.offlineManager stateForTrackWithURL:self.trackURI];
    if ([self.session isOffline] && offlineState == isNotAvailableOffline)
        self.alpha = 0.4;
}

%end
