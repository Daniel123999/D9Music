# iOS 9 / armv7 Theos baseline for FuoEvolve9 (iPhone 4S / iOS 9.3.6)
TARGET := iphone:clang:9.3:9.0
ARCHS := armv7
INSTALL_TARGET_PROCESSES = FuoEvolve9

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = FuoEvolve9
FuoEvolve9_FILES = $(wildcard *.m) $(wildcard Models/*.m) $(wildcard Providers/*.m) $(wildcard Player/*.m) $(wildcard Lyrics/*.m) $(wildcard Playlist/*.m) $(wildcard Login/*.m) $(wildcard LocalMusic/*.m) $(wildcard Utils/*.m) $(wildcard UI/*.m)
FuoEvolve9_FRAMEWORKS = UIKit Foundation CoreFoundation AVFoundation QuartzCore MediaPlayer CoreMedia AudioToolbox
FuoEvolve9_USE_MODULES = 0
USE_MODULES = 0
FuoEvolve9_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error=deprecated-module-dot-map -I. -IModels -IProviders -IPlayer -ILyrics -IPlaylist -ILogin -ILocalMusic -IUtils -IUI
FuoEvolve9_INFOPLIST = $(THEOS_PROJECT_DIR)/Info.plist
FuoEvolve9_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/application.mk
