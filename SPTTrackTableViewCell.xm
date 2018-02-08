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
    CGRect adjustedFrame = self.textLabel.frame;
    adjustedFrame.origin.x -= 7;
    adjustedFrame.size.width = self.frame.size.width - 125;
    self.textLabel.frame = adjustedFrame;

    adjustedFrame = self.detailTextLabel.frame;
    adjustedFrame.origin.x -= 7;
    adjustedFrame.size.width = self.frame.size.width - 125;
    self.detailTextLabel.frame = adjustedFrame;

    // Accessory view
    adjustedFrame = self.accessoryView.frame;
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
