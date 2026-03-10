#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/google/emu64a

# Inherit from device.mk configuration
$(call inherit-product, $(DEVICE_PATH)/device.mk)

## Device identifier
# Matches ro.product.system.name / ro.build.fingerprint device segment
PRODUCT_DEVICE   := emu64a
PRODUCT_NAME     := twrp_emu64a
PRODUCT_BRAND    := google
PRODUCT_MODEL    := Android SDK built for arm64
PRODUCT_MANUFACTURER := Google
