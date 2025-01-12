#
# Copyright (C) 2018-2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

ifneq ($(filter gta4l gta4lwifi,$(TARGET_DEVICE)),)

DSP_MOUNT_POINT := $(TARGET_OUT_VENDOR)/dsp
$(DSP_MOUNT_POINT): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating DSP folder: $@"
	@rm -rf $@
	@mkdir -p $@

FIRMWARE_BT_MOUNT_POINT := $(TARGET_OUT_VENDOR)/bt_firmware
$(FIRMWARE_BT_MOUNT_POINT): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating bt firmware folder: $@"
	@rm -rf $@
	@mkdir -p $@

FIRMWARE_MODEM_MOUNT_POINT := $(TARGET_OUT_VENDOR)/firmware-modem
$(FIRMWARE_MODEM_MOUNT_POINT): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating modem firmware folder: $@"
	@rm -rf $@
	@mkdir -p $@

FIRMWARE_MOUNT_POINT := $(TARGET_OUT_VENDOR)/firmware_mnt
$(FIRMWARE_MOUNT_POINT): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating firmware mount folder: $@"
	@rm -rf $@
	@mkdir -p $@

ALL_DEFAULT_INSTALLED_MODULES += \
    $(DSP_MOUNT_POINT) \
    $(FIRMWARE_BT_MOUNT_POINT) \
    $(FIRMWARE_MODEM_MOUNT_POINT) \
    $(FIRMWARE_MOUNT_POINT)

endif
