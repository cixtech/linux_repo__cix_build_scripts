#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

DEPENDENT_MODULES="build-kernel.sh"
readonly DO_DESC_build="build cix grub config"

do_build() {
    # if [[ "${ISO_INSTALLER:-0}" != "1" ]]; then
    #     return 0
    # fi

    rm -rf $PATH_OUT_DEB_PACKAGES/cix-grubcfg
    cp -r $PATH_SOURCE_DEB/cix-grubcfg ${PATH_OUT_DEB_PACKAGES}
    mkdir -p "$PATH_OUT_DEB_PACKAGES/cix-grubcfg/boot"

    local dt="${DT}"
    local EFI_CONFIG=""
    if [[ "${BOARD}" != "evb" ]]; then
        dt=${BOARD}
    fi
    if [[ "${BOARD}" == "${dt}" ]]; then
        EFI_CONFIG="efi=noruntime "
    fi
    if [[ "${ACPI}" == "0" ]]; then
        cp -pf $PATH_OUT/sky1-${dt}.dtb $PATH_OUT_DEB_PACKAGES/cix-grubcfg/boot/
        sed -i s/sky1-evb.dtb/sky1-${dt}.dtb/g $PATH_OUT_DEB_PACKAGES/cix-grubcfg/etc/grub.d/09_cix_linux
        replace_or_add_line "GRUB_CMDLINE_LINUX=" "GRUB_CMDLINE_LINUX=\"console=ttyAMA2,115200 ${EFI_CONFIG}earlycon=pl011,0x040d0000 kasan=off loglevel=4 arm-smmu-v3.disable_bypass=0 splash acpi=off\"" "$PATH_OUT_DEB_PACKAGES/cix-grubcfg/etc/default/grub.d/cix_grub.cfg"
     else
        replace_or_add_line "devicetree" "\ " "$PATH_OUT_DEB_PACKAGES/cix-grubcfg/etc/grub.d/09_cix_linux"
        replace_or_add_line "GRUB_CMDLINE_LINUX=" "GRUB_CMDLINE_LINUX=\"console=ttyAMA2,115200 ${EFI_CONFIG}earlycon=pl011,0x040d0000 kasan=off loglevel=4 arm-smmu-v3.disable_bypass=0 cma=640M splash acpi=force\"" "$PATH_OUT_DEB_PACKAGES/cix-grubcfg/etc/default/grub.d/cix_grub.cfg"
    fi
    if [[ ${BUILD_MODE} != "debug" ]]; then
        sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/d' "$PATH_OUT_DEB_PACKAGES/cix-grubcfg/etc/default/grub.d/cix_grub.cfg"
    fi
    create_cix_deb cix-grubcfg
}

do_clean() {
  echo "nothing to do"
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
