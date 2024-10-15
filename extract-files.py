#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: 2025 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)

from extract_utils.fixups_lib import (
    lib_fixup_vendorcompat,
    lib_fixups_user_type,
    libs_proto_3_9_1,
)

from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

lib_fixups: lib_fixups_user_type = {
    libs_proto_3_9_1: lib_fixup_vendorcompat,
}

blob_fixups: blob_fixups_user_type = {
    ("vendor/lib/libwvhidl.so",
     "vendor/lib/mediadrm/libwvdrmengine.so"): blob_fixup()
        .add_needed('libcrypto_shim.so'),
    ('vendor/lib64/hw/gatekeeper.mdfpp.so',
     'vendor/lib64/libkeymaster_helper.so',
     'vendor/lib64/libskeymaster4device.so'): blob_fixup()
        .replace_needed('libcrypto.so', 'libcrypto-v33.so'),
    'vendor/lib64/vendor.qti.hardware.camera.postproc@1.0-service-impl.so': blob_fixup()
        .binary_regex_replace(b'\x13\x0A\x00\x94', b'\x1F\x20\x03\xD5'),
}  # fmt: skip

namespace_imports = [
    "hardware/qcom-caf/sm8250",
    "hardware/qcom-caf/wlan",
    "vendor/qcom/opensource/display",
]

module = ExtractUtilsModule(
    'gta4l-common',
    'samsung',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
