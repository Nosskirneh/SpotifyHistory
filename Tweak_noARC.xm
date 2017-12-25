#import "Spotify.h"

SPSession *session;

// Used to check offline mode
// Does for some reason not work with ARC, hence the split
%group SPSession_8433
// Earlier than 8.4.34
%hook SPSession

- (id)initWithCore:(id)arg1 coreCreateOptions:(id)arg2 isPerfTracingEnabled:(id)arg3 core:(id)arg4 session:(id)arg5 accesspointHandler:(id)arg6 coreTime:(id)arg7 connectivityManager:(id)arg8 scheduler:(id)arg9 clientVersionString:(id)arg10 acceptLanguages:(id)arg11 {
    return session = %orig;
}

%end
%end

// 8.4.34
%group SPSession_8434
%hook SPSession

- (id)initWithCore:(id)arg1 coreCreateOptions:(id)arg2 isPerfTracingEnabled:(id)arg3 core:(id)arg4 session:(id)arg5 accesspointHandler:(id)arg6 serverTime:(id)arg7 connectivityManager:(id)arg8 scheduler:(id)arg9 clientVersionString:(id)arg10 acceptLanguages:(id)arg11 {
	//HBLogDebug(@"init");
    return session = %orig;
}

%end
%end


%ctor {
	if ([%c(SPSession) instancesRespondToSelector:@selector(initWithCore:coreCreateOptions:isPerfTracingEnabled:core:session:accesspointHandler:serverTime:connectivityManager:scheduler:clientVersionString:acceptLanguages:)]) {
		%init(SPSession_8434);
	} else if ([%c(SPSession) instancesRespondToSelector:@selector(initWithCore:coreCreateOptions:isPerfTracingEnabled:core:session:accesspointHandler:coreTime:connectivityManager:scheduler:clientVersionString:acceptLanguages:)]) {
		%init(SPSession_8433);
	}
}
