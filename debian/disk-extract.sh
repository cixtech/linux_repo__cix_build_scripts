#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

# Description: extract the images from the disk file
# Author: Xinjun
# Date: 2025-08-14
# Revision: original v1.0
#

trap '
if [[ -e "./mnt" ]]; then
    sudo umount "./mnt" || true;
fi
' EXIT

readonly BOLD="\e[1m"
readonly NORMAL="\e[0m"
readonly RED="\e[31m"
readonly GREEN="\e[32m"
readonly YELLOW="\e[33m"
readonly BLUE="\e[94m"
readonly CYAN="\e[36m"

SELF=$0
WORKSPACE="$(realpath --no-symlinks "$(dirname "${BASH_SOURCE[0]}")")"
GPT_TOOL="${WORKSPACE}/cix_tool"
PATH_DST="$(pwd)"
PATH_SRC="${PATH_DST}/linux-fs.sdcard"

function do_help() {
    echo -e "${BOLD}Usage:"
    echo -e "    $SELF <the disk file> ${CYAN} <options>${NORMAL}"
    echo

cat <<- EOF
    <options>:
        -h, --help:                        show the help information.
        --show:                            show the partitions' information.
        -a, --extract <dest path>:         extract all images.
        --extract-xxx <dest path>:         extract the <xxx> image. xxx maybe boot, root, data, swap.
        -g, --gpt <dest path>:             extract the gpt image.
        -b, --boot <dest path>:            extract the boot image.
        -r, --root <dest path>:            extract the rootfs image.
        -d, --data <dest path>:            extract the data image.
        -s, --swap <dest path>:            extract the swap image.
        -u, --uefi                         create the uefi flashing disk with uefi_tool.sh
EOF
}

function change_image_name() {
    local src=$1
    local dst=$2
    if [[ -e "${src}" ]] && [[ ! -e "${dst}" ]]; then
        mv ${src} ${dst}
    fi
}

function extract_gpt() {
    if [[ ${PATH_DST} == "" ]]; then
        echo -e "${RED}the dest path is blank.${NORMAL}"
        do_help
        exit 0
    fi
    if [[ ! -e "${PATH_DST}" ]]; then
        mkdir -p "${PATH_DST}"
    fi
    ${GPT_TOOL} --release-tool --gpt -f ${PATH_SRC} --extract-gpt ${PATH_DST}
}

function extract_boot() {
    if [[ ! -e "${PATH_DST}/boot.img" ]]; then
        echo -e "${RED}the ${PATH_DST}/boot.img does not exist.${NORMAL}" 
        exit 0
    fi
    if [[ ! -e "${WORKSPACE}/mnt" ]]; then
        mkdir -p "${WORKSPACE}/mnt"
    fi
    sudo mount "${PATH_DST}/boot.img" "${WORKSPACE}/mnt"
    cp "${WORKSPACE}/mnt"/*.DTB ${PATH_DST}/
    find "${PATH_DST}" -iname *.dtb -exec bash -c 'for file do mv "${file}" "${file,,}"; done' bash {} +
    cp "${WORKSPACE}/mnt"/IMAGE ${PATH_DST}/Image
    cp "${WORKSPACE}/mnt"/GRUB/GRUB.CFG ${PATH_DST}/grub.cfg
    cp "${WORKSPACE}/mnt"/rootfs.cpio.gz ${PATH_DST}/rootfs.cpio.gz
    sudo umount "${WORKSPACE}/mnt"
    rm -rf "${WORKSPACE}/mnt"
}

function extract_with_name() {
    if [[ ${PATH_DST} == "" ]]; then
        echo -e "${RED}the dest path is blank.${NORMAL}"
        do_help
        exit 0
    fi
    if [[ ! -e "${PATH_DST}" ]]; then
        mkdir -p "${PATH_DST}"
    fi

    local name=$1
    echo "extract the $name partition"
    if [[ "$(${GPT_TOOL} --release-tool --gpt -f ${PATH_SRC} --dump ${name} | grep ${name})" == "" ]]; then
        echo -e "${RED}the ${name} partition does not exist.${NORMAL}"
        exit 0
    fi
    ${GPT_TOOL} --release-tool --gpt -f ${PATH_SRC} --extract-${name} ${PATH_DST}

    if [[ "${name}" == "boot" ]]; then
        extract_boot
    elif [[ "${name}" == "root" ]]; then
        change_image_name "${PATH_DST}/root.img" "${PATH_DST}/rootfs.ext4"
        change_image_name "${PATH_DST}/root_sparse.img" "${PATH_DST}/rootfs_sparse.ext4"
    elif [[ "${name}" == "data" ]]; then
        change_image_name "${PATH_DST}/data.img" "${PATH_DST}/data.ext4"
        change_image_name "${PATH_DST}/data_sparse.img" "${PATH_DST}/data_sparse.ext4"
    fi
}

function extract_all() {
    if [[ ${PATH_DST} == "" ]]; then
        echo -e "${RED}the dest path is blank.${NORMAL}"
        do_help
        exit 0
    fi
    if [[ ! -e "${PATH_DST}" ]]; then
        mkdir -p "${PATH_DST}"
    fi
    ${GPT_TOOL} --release-tool --gpt -f ${PATH_SRC} --extract ${PATH_DST}
    extract_boot
    change_image_name "${PATH_DST}/root.img" "${PATH_DST}/rootfs.ext4"
    change_image_name "${PATH_DST}/root_sparse.img" "${PATH_DST}/rootfs_sparse.ext4"
    change_image_name "${PATH_DST}/data.img" "${PATH_DST}/data.ext4"
    change_image_name "${PATH_DST}/data_sparse.img" "${PATH_DST}/data_sparse.ext4"
}

function uefi_tool() {
    local ueif_tool="${PATH_DST}/uefi_tool.sh"
    if [[ ! -e "${ueif_tool}" ]]; then
        echo -e "${RED}${ueif_tool} does not exist.${NORMAL}"
        exit 0
    fi
    if [[ ! -e "${PATH_DST}/partition-table.img" ]]; then
        ${GPT_TOOL} --release-tool --gpt -f ${PATH_SRC} --extract-gpt ${PATH_DST}
    fi
    if [[ ! -e "${PATH_DST}/boot.img" ]]; then
        ${GPT_TOOL} --release-tool --gpt -f ${PATH_SRC} --extract-boot ${PATH_DST}
    fi
    if [[ ! -e "${PATH_DST}/rootfs.ext4" ]]; then
        ${GPT_TOOL} --release-tool --gpt -f ${PATH_SRC} --extract-root ${PATH_DST}
        change_image_name "${PATH_DST}/root.img" "${PATH_DST}/rootfs.ext4"
        change_image_name "${PATH_DST}/root_sparse.img" "${PATH_DST}/rootfs_sparse.ext4"
    fi
    ${ueif_tool}
}

if [[ $# -gt 0 ]]; then
    if [[ ${1:0:1} != "-" ]]; then
        PATH_SRC=$1
        shift
    fi
fi

if [[ ! -e "${PATH_SRC}" ]]; then
    echo -e "${YELLOW}${PATH_SRC}${NORMAL}: ${RED}file does not exist.${NORMAL}"
    exit 0
fi

if [[ "${PATH_SRC}" == *".zst" ]]; then
    zstd -d "${PATH_SRC}"
    PATH_SRC=${PATH_SRC%????}
fi
if [[ ! -e "${PATH_SRC}" ]]; then
    echo -e "${YELLOW}${PATH_SRC}${NORMAL}: ${RED}file does not exist.${NORMAL}"
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case $1 in
    ("-h" | "--help")
        do_help
        exit 0
        ;;
    ("-g" | "--gpt")
        shift
        PATH_DST="$1"
        extract_gpt
        ;;
    ("-b" | "--boot")
        shift
        PATH_DST="$1"
        extract_with_name boot
        ;;
    ("-s" | "--swap")
        shift
        PATH_DST="$1"
        extract_with_name swap
        ;;
    ("-r" | "--root")
        shift
        PATH_DST="$1"
        extract_with_name root
        ;;
    ("-d" | "--data")
        shift
        PATH_DST="$1"
        extract_with_name data
        ;;
    ("--show")
        ${GPT_TOOL} --release-tool --gpt -f ${PATH_SRC} --dump
        ;;
    ("-a" | "--extract")
        shift
        PATH_DST="$1"
        extract_all
        ;;
    ("--extract-"*)
        PART="${1:10}"
        shift
        PATH_DST="$1"
        extract_with_name ${PART}
        ;;
    ("-u" | "--uefi")
        shift
        PATH_DST="$1"
        uefi_tool
        ;;
    (*)
        echo -e "${RED}option $1 is not supported.${NORMAL}"
        do_help
        exit 0
        ;;
    esac
    shift
done
