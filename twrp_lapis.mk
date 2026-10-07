#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit some common TWRP stuff.
$(call inherit-product, vendor/twrp/config/common.mk)

# Inherit from lapis device
$(call inherit-product, device/lenovo/lapis/device.mk)

PRODUCT_DEVICE := lapis
PRODUCT_NAME := twrp_lapis
PRODUCT_BRAND := Lenovo
PRODUCT_MODEL := TB520FU
PRODUCT_MANUFACTURER := lenovo

PRODUCT_GMS_CLIENTID_BASE := android-lenovo
