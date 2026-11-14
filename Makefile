TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Meu3105
Meu3105_FILES = Tweak.xm
Meu3105_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
