TARGET = iphone:clang:9.2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SpotifyHistory
SpotifyHistory_FILES = $(wildcard *.xm)
SPTHistoryViewController_CFLAGS = -fobjc-arc
SPTTrackTableViewCell_CFLAGS = -fobjc-arc
SPTHistorySwipeDelegate_CFLAGS = -fobjc-arc
SPTHistorySettingsViewController_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Spotify"
