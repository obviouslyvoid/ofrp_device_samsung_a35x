#!/usr/bin/env bash
# OrangeFox options for the private SM-A356E recovery-only target.
if [ "${FOX_BUILD_DEVICE:-}" = a35x ] || [ "${1:-}" = a35x ]; then
    export FOX_BUILD_DEVICE=a35x
    export FOX_BUILD_TYPE=Unofficial
    export FOX_VARIANT=AOSP
    export OF_MAINTAINER="Private SM-A356E port"
    export FOX_TARGET_DEVICES=a35x
    export FOX_VANILLA_BUILD=1
    unset OF_SKIP_FBE_DECRYPTION
    export OF_SKIP_DECRYPTED_ADOPTED_STORAGE=1
    export OF_FORCE_PREBUILT_KERNEL=1
    export FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER=1
    export FOX_RECOVERY_INSTALL_PARTITION=/dev/block/by-name/recovery
    export FOX_RECOVERY_SYSTEM_PARTITION=/dev/block/mapper/system
    export FOX_RECOVERY_VENDOR_PARTITION=/dev/block/mapper/vendor
    # Volatile settings/log support even with no accessible external card.
    export FOX_SETTINGS_ROOT_DIRECTORY=/tmp/OrangeFox
    export OF_DONT_KEEP_LOG_HISTORY=1
    export OF_SCREEN_H=2340
    export OF_STATUS_H=122
    export OF_STATUS_INDENT_LEFT=80
    export OF_STATUS_INDENT_RIGHT=80
    export OF_HIDE_NOTCH=1
    export OF_ALLOW_DISABLE_NAVBAR=0
    export OF_ADVANCED_SECURITY=0
    export OF_USE_GREEN_LED=0
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
