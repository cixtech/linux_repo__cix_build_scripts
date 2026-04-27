#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

export  BOLD="\e[1m"
export  NORMAL="\e[0m"
export	RED="\e[31m"
export	GREEN="\e[32m"
export	YELLOW="\e[33m"
export  BLUE="\e[94m"
export  CYAN="\e[36m"

readonly DO_DESC_build="build uefi"
do_build() {
    set +u
    if [[ -e "${PATH_ROOT}/vendor/cix_opensource/uefi_release/edk2" ]]; then
        local path_bsp_root="vendor/cix_opensource"
    else
       local path_bsp_root="bsp"
    fi
    local path_uefi="${PATH_ROOT}/${path_bsp_root}/uefi_release"
    local open_firmwre_build_script="${path_uefi}/edk2-non-osi/Platform/CIX/Sky1/PackageTool/build_and_package.sh"
    local package_internal_binary_script="${PATH_ROOT}/${path_bsp_root}/cix_bsp_release/package_internal_flash_binary.sh"

    local UEFI_PROJECT="android"

    case "$TARGET_PRODUCT" in
    ("sky1_evb")
        UEFI_PROJECT="android"
        ;;
    ("sky1_orion_o6")
        UEFI_PROJECT="androidO6"
        ;;
    (*)
        UEFI_PROJECT="android"
        ;;
    esac

    cd "${path_uefi}"

    if [[ ! -e "${open_firmwre_build_script}" ]]; then
        echo -e "${RED}There is no ${open_firmwre_build_script}!${NORMAL}"
        exit 1
    fi

    ${open_firmwre_build_script} "${UEFI_PROJECT}"

    if [[ ! -e "${path_uefi}/output/cix_flash_all.bin" ]]; then
        echo -e "${RED}Generate ${path_uefi}/output/cix_flash_all.bin failed!${NORMAL}"
    fi

    if [[ ! -e "${path_uefi}/output/cix_flash_ota.bin" ]]; then
        echo -e "${RED}Generate ${path_uefi}/output/cix_flash_ota.bin failed!${NORMAL}"
    fi

    cp "${path_uefi}/output/cix_flash_all.bin" "${PATH_OUT}/images/cix_flash_all.bin"
    cp "${path_uefi}/output/cix_flash_ota.bin" "${PATH_OUT}/images/cix_flash_ota.bin"

    cp "${path_uefi}/output/cix_flash_all.bin" "${PATH_OUT}/images/cix_flash_all_rsa_pr.bin"
    cp "${path_uefi}/output/cix_flash_ota.bin" "${PATH_OUT}/images/cix_flash_ota_rsa_pr.bin"

    if [[ -e "${package_internal_binary_script}" ]]; then
        ${package_internal_binary_script}
        if [ ${TARGET_PRODUCT} == "sky1_evb" ]; then
	    # proto release image
            if [[ ! -e "${path_uefi}/output/cix_flash_all_rsa_proto.bin" ]]; then
                echo -e "${RED}Generate ${path_uefi}/output/cix_flash_all_rsa_proto.bin failed!${NORMAL}"
            fi

            if [[ ! -e "${path_uefi}/output/cix_flash_ota_rsa_proto.bin" ]]; then
                echo -e "${RED}Generate ${path_uefi}/output/cix_flash_ota_rsa_proto.bin failed!${NORMAL}"
            fi

            cp "${path_uefi}/output/cix_flash_all_rsa_proto.bin" "${PATH_OUT}/images/cix_flash_all_rsa_proto.bin"
            cp "${path_uefi}/output/cix_flash_ota_rsa_proto.bin" "${PATH_OUT}/images/cix_flash_ota_rsa_proto.bin"
        fi
        # debug image
        if [[ ! -e "${path_uefi}/output/cix_flash_all_rsa_pr_debug.bin" ]]; then
            echo -e "${RED}Generate ${path_uefi}/output/cix_flash_all_rsa_pr_debug.bin failed!${NORMAL}"
        fi

        if [[ ! -e "${path_uefi}/output/cix_flash_ota_rsa_pr_debug.bin" ]]; then
            echo -e "${RED}Generate ${path_uefi}/output/cix_flash_ota_rsa_pr_debug.bin failed!${NORMAL}"
        fi

        cp "${path_uefi}/output/cix_flash_all_rsa_pr_debug.bin" "${PATH_OUT}/images/cix_flash_all_rsa_pr_debug.bin"
        cp "${path_uefi}/output/cix_flash_ota_rsa_pr_debug.bin" "${PATH_OUT}/images/cix_flash_ota_rsa_pr_debug.bin"

    fi

    if [[ -f "${path_uefi}/output/LinuxLoader.efi.cap" ]]; then
        cp "${path_uefi}/output/LinuxLoader.efi.cap" "${PATH_OUT}/LinuxLoader.efi.cap"
    fi

    echo -e "${GREEN}Generate ${PATH_OUT}/images/cix_flash_all.bin successful!${NORMAL}"

    cd -
}

readonly DO_DESC_clean="clean uefi"
do_clean() {
    echo "clean uefi"
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
