TARGET = iphone:clang:9.2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SpotifyHistory
SpotifyHistory_FILES = Tweak.xm SPTHistoryViewController.xm SPTEmptyHistoryViewController.xm
SPTHistoryViewController_CFLAGS = -fobjc-arc
SPTEmptyHistoryViewController_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Spotify"
