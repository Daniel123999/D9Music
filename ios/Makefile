# iOS 9 / armv7 Theos baseline for FuoEvolve9 (iPhone 4S / iOS 9.3.6)
TARGET := iphone:clang:9.3:9.0
ARCHS := armv7
INSTALL_TARGET_PROCESSES = FuoEvolve9

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = FuoEvolve9
FuoEvolve9_FILES = $(wildcard *.m)
FuoEvolve9_FRAMEWORKS = UIKit Foundation CoreFoundation AVFoundation QuartzCore
FuoEvolve9_USE_MODULES = 0
FuoEvolve9_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
FuoEvolve9_INFOPLIST = $(THEOS_PROJECT_DIR)/Info.plist
# iOS 9.3 SDK 的 libsystem_c.tbd 未导出 _memset 等编译器内建符号（真机 libSystem 有）。
# 这是已确认的 9.3 stub 缺口，仅对缺失符号使用动态查找。
FuoEvolve9_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/application.mk
