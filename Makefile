ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LordVCAMBypass

LordVCAMBypass_FILES = LordVCAM_Bypass.xm
LordVCAMBypass_CFLAGS = -fobjc-arc -Wno-unused-variable
LordVCAMBypass_FRAMEWORKS = Foundation UIKit
LordVCAMBypass_LIBRARIES =
LordVCAMBypass_INSTALL_PATH = /var/jb/Library/MobileSubstrate/DynamicLibraries

include $(THEOS)/makefiles/tweak.mk
include $(THEOS)/makefiles/package.mk