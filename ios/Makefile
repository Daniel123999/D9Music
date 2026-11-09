TARGET := iphone:clang:9.3:9.0
ARCHS := armv7
INSTALL_TARGET_PROCESSES = FuoEvolve9

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = FuoEvolve9
FuoEvolve9_FILES = main.m AppDelegate.m RootViewController.m PlayerViewController.m SearchViewController.m
FuoEvolve9_FRAMEWORKS = UIKit Foundation CoreFoundation AVFoundation QuartzCore
FuoEvolve9_LIBRARIES = z
FuoEvolve9_USE_MODULES = 0
FuoEvolve9_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
FuoEvolve9_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/application.mk
