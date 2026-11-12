# iOS 9 / armv7 Theos baseline for D9Music (iPhone 4S / iOS 9.3.6)
TARGET := iphone:clang:9.3:9.0
ARCHS := armv7
INSTALL_TARGET_PROCESSES = D9Music

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = D9Music
D9Music_FILES = $(wildcard *.m) $(wildcard Models/*.m) $(wildcard Providers/*.m) $(wildcard Player/*.m) $(wildcard Lyrics/*.m) $(wildcard Playlist/*.m) $(wildcard Login/*.m) $(wildcard LocalMusic/*.m) $(wildcard Utils/*.m) $(wildcard UI/*.m)
D9Music_FRAMEWORKS = UIKit Foundation CoreFoundation AVFoundation QuartzCore MediaPlayer CoreMedia AudioToolbox
D9Music_USE_MODULES = 0
USE_MODULES = 0
D9Music_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I. -IModels -IProviders -IPlayer -ILyrics -IPlaylist -ILogin -ILocalMusic -IUtils -IUI
D9Music_INFOPLIST = $(THEOS_PROJECT_DIR)/Info.plist
D9Music_RESOURCE_DIRS = icons
D9Music_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/application.mk
