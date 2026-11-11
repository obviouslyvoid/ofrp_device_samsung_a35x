LOCAL_PATH := $(call my-dir)

# Device hooks for Format Data (see a35x_partition.cpp).
include $(CLEAR_VARS)
LOCAL_MODULE := librecovery_twrp_a35x
LOCAL_SRC_FILES := a35x_partition.cpp
LOCAL_C_INCLUDES := \
    bootable/recovery \
    bootable/recovery/twrpinstall/include \
    system/vold
LOCAL_SHARED_LIBRARIES := libbase libcutils libziparchive
LOCAL_CFLAGS := -Wall -Werror
include $(BUILD_STATIC_LIBRARY)
