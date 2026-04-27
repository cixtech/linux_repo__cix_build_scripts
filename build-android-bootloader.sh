#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#
#

for_each_build_script() {
    local scripts=(
    #    "build-uefi.sh"
    #    "build-tf-a.sh"
    #    "build-mkimage.sh"
         "build-firmware-release-android.sh"
    )

    local script
    for script in "${scripts[@]}" ; do
        echo "$SCRIPT_DIR/$script -p $PLATFORM -b $BOARD -f $FILESYSTEM -t $TEE_TYPE $@"
        "$SCRIPT_DIR/$script" -n -p "$PLATFORM" -b $BOARD -f "$FILESYSTEM" -s 1 -t "$TEE_TYPE" "$@" || exit 1
    done
}

readonly DO_DESC_build="build all modules"
do_build() {
    for_each_build_script build
}

readonly DO_DESC_clean="clean all modules"
do_clean() {
    for_each_build_script clean
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
