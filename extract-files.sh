#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

XTENDED_ROOT="${MY_DIR}"/../../..

HELPER="${XTENDED_ROOT}/vendor/xtended/build/tools/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

function blob_fixup() {
    case "${1}" in
    vendor/etc/permissions/com.fingerprints.extension.xml )
        sed -i -e 's/\/system\/framework\//\/vendor\/framework\//g' "${2}"
        ;;
    product/etc/permissions/qcnvitems.xml | product/etc/permissions/vendor.qti.hardware.factory.xml | product/etc/permissions/vendor-qti-hardware-sensorscalibrate.xml )
        sed -i -e 's/\/system\/framework\//\/system\/product\/framework\//g' "${2}"
        ;;
    product/etc/permissions/vendor.qti.hardware.data.connection-V1.0-java.xml | product/etc/permissions/vendor.qti.hardware.data.connection-V1.1-java.xml )
        sed -i -e 's|xml version=\"2.0\"|xml version=\"1.0\"|g' "${2}"
        ;;
    esac
    case "${DEVICE}" in
        dumpling )
        case "${1}" in
            vendor/lib/hw/fingerprint.goodix.so | vendor/lib64/hw/fingerprint.goodix.so )
            sed -i "s|\x00goodix.fingerprint\x00|\x00fingerprint\x00\x00\x00\x00\x00\x00\x00\x00|" "${2}"
            ;;
            esac
    ;;
    esac
}

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

SECTION=
KANG=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

# Initialize the helper for common device
setup_vendor "${DEVICE_COMMON}" "${VENDOR}" "${XTENDED_ROOT}" true "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
        "${KANG}" --section "${SECTION}"

if [ -s "${MY_DIR}/../${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    setup_vendor "${DEVICE}" "${VENDOR}" "${XTENDED_ROOT}" false "${CLEAN_VENDOR}"

    extract "${MY_DIR}/../${DEVICE}/proprietary-files.txt" "${SRC}" \
            "${KANG}" --section "${SECTION}"
fi

COMMON_BLOB_ROOT="${XTENDED_ROOT}/vendor/${VENDOR}/${DEVICE_COMMON}/proprietary"

"${MY_DIR}/setup-makefiles.sh"
