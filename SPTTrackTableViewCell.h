#import "Spotify.h"

@interface SPTTrackTableViewCell : SPTSwipeableTableViewCell
@property (nonatomic, retain) NSURL *trackURI;
@property (nonatomic, retain) NSURL *imageURL;
@property (nonatomic, retain) NSString *trackName;
@property (nonatomic, retain) NSString *artist;
@property (nonatomic, retain) NSString *album;
@property (nonatomic, retain) NSURL *artistURI;
@property (nonatomic, retain) NSURL *albumURI;
@property (nonatomic, retain) SPSession *session;
@end
