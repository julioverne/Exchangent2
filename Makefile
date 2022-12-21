include $(THEOS)/makefiles/common.mk

SUBPROJECTS += hooks
SUBPROJECTS += settings

include $(THEOS_MAKE_PATH)/aggregate.mk
