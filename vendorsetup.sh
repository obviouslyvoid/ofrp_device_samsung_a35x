#!/usr/bin/env bash
# OrangeFox build options for the Samsung Galaxy A35 5G (SM-A356E, a35x).
if [ "${FOX_BUILD_DEVICE:-}" = a35x ] || [ "${1:-}" = a35x ]; then
    export FOX_BUILD_DEVICE=a35x
    export FOX_BUILD_TYPE=Unofficial
    export OF_MAINTAINER="obviouslyvoid"
    export FOX_TARGET_DEVICES=a35x
    export FOX_VANILLA_BUILD=1
    unset OF_SKIP_FBE_DECRYPTION
    export OF_SKIP_DECRYPTED_ADOPTED_STORAGE=1
    export OF_FORCE_PREBUILT_KERNEL=1
    export FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER=1
    export FOX_RECOVERY_INSTALL_PARTITION=/dev/block/by-name/recovery
    export FOX_RECOVERY_SYSTEM_PARTITION=/dev/block/mapper/system
    export FOX_RECOVERY_VENDOR_PARTITION=/dev/block/mapper/vendor
    # Settings live in the default /sdcard/Fox (decrypted /data/media/0), so they
    # persist across reboots. Do not point FOX_SETTINGS_ROOT_DIRECTORY at /tmp.
    export OF_SCREEN_H=2340
    export OF_STATUS_H=122
    export OF_STATUS_INDENT_LEFT=80
    export OF_STATUS_INDENT_RIGHT=80
    export OF_HIDE_NOTCH=1
    export OF_USE_GREEN_LED=0
    # No /persist on this device: keep the recovery password backup on /cache,
    # which is available before data decryption, so the lock screen comes first.
    export OF_PASSWORD_BACKUP_PARTITION=/cache
    # Samsung health HAL and the decryption services run from the real /vendor.
    export OF_KEEP_VENDOR_MOUNTED=1
    export OF_FLASHLIGHT_ENABLE=1
    export OF_FL_PATH1=/sys/class/camera/flash/rear_flash
    export OF_QUICK_BACKUP_LIST="/boot;/dtbo;"
    export FOX_USE_BASH_SHELL=1
    export FOX_ASH_IS_BASH=1
    export FOX_USE_NANO_EDITOR=1
    export FOX_USE_TAR_BINARY=1
    export FOX_USE_XZ_UTILS=1
    export FOX_USE_SED_BINARY=1
    export OF_ENABLE_LPTOOLS=1
fi
