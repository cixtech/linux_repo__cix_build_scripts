#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#
#

readonly DO_DESC_build="build tools"
do_build() {
    # build deb package
    pkg_Name="cix-tools"
    build_deb_dir=${PATH_OUT_DEB_PACKAGES}/${pkg_Name}
    rm -rf ${build_deb_dir}
    install_dir=${build_deb_dir}/usr/share/cix/bin
    etc_dir=${build_deb_dir}/etc
    mkdir -p ${install_dir} $etc_dir
    cp -rf ${PATH_ROOT}/tools/cix_binary/device/misc/* ${build_deb_dir}
    rm -rf $install_dir/i3ctransfer
    rm -rf $install_dir/spidev_fdx
    rm -rf $install_dir/uart_test
    cat > ${install_dir}/capsule << 'SCRIPT_EOF'
#!/bin/bash

set -e

################################################################################
# Parameters
################################################################################

usage() {
    echo "Usage: $0 -i <input capsule file> [-o <output path, default /boot/EFI/UpdateCapsule>]"
    exit 1
}

CONFIG_FILE="/etc/capsule_update.conf"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    EFI_PARTITION="/dev/nvme0n1p1"
fi

EFI_PARTITION="${EFI_PARTITION:-/dev/nvme0n1p1}"

INPUT=""
OUTPUT="/boot/EFI/UpdateCapsule"

while getopts "i:o:" opt; do
    case "$opt" in
        i) INPUT="$OPTARG" ;;
        o) OUTPUT="$OPTARG" ;;
        *) usage ;;
    esac
done

if [[ -z "$INPUT" ]]; then
    echo "Error: -i <input file> is required."
    exit 1
fi

################################################################################
# Check /boot and auto mount EFI partition
################################################################################

if [[ ! -d "/boot/EFI" ]]; then
    echo "/boot/EFI not found. Attempting to mount $EFI_PARTITION to /boot ..."
    mount "$EFI_PARTITION" /boot 2>/dev/null

    if [[ ! -d "/boot/EFI" ]]; then
        echo "Error: /boot/EFI still does not exist after attempting auto-mount."
        exit 1
    else
        echo "Auto-mount succeeded. /boot/EFI is now available."
    fi
fi

if [[ ! -d "$OUTPUT" ]]; then
    echo "Creating directory: $OUTPUT"
    mkdir -p "$OUTPUT"
fi

################################################################################
# Copy capsule file
################################################################################

echo "Copying capsule file to $OUTPUT ..."
cp -f "$INPUT" "$OUTPUT/bios.cap"

################################################################################
# UEFI variable handling
################################################################################

VARNAME="CapsuleUpdate"
GUID="a4d3f1e5-c2b7-4d8a-9ce5-a6b2a1f7c9e3"
VARFILE="/sys/firmware/efi/efivars/${VARNAME}-${GUID}"

echo "UEFI variable path: $VARFILE"

TMP_BIN=$(mktemp)
TMP_VAR=$(mktemp)

# EFI variable attribute header (4 bytes)
EFI_ATTR_BYTES="\x07\x00\x00\x00"

################################################################################
# Create variable (only 1 byte now) if not present
################################################################################

if [[ ! -f "$VARFILE" ]]; then
    echo "Variable not found. Creating new 1-byte variable."

    printf "\x00" > "$TMP_BIN"

    printf "$EFI_ATTR_BYTES" > "$TMP_VAR"
    cat "$TMP_BIN" >> "$TMP_VAR"

    chattr -i "$VARFILE" 2>/dev/null || true
    cp -f "$TMP_VAR" "$VARFILE"

    echo "New variable created."
fi

################################################################################
# Modify CapsuleUpdate (offset 0)
################################################################################

echo "Writing CapsuleUpdate = 1 ..."

printf "\x01" > "$TMP_BIN"

printf "$EFI_ATTR_BYTES" > "$TMP_VAR"
cat "$TMP_BIN" >> "$TMP_VAR"

chattr -i "$VARFILE" 2>/dev/null || true
chmod a+r "$VARFILE" 2>/dev/null || true
cp -f "$TMP_VAR" "$VARFILE"

echo "Variable update complete."

################################################################################
# Cleanup
################################################################################

rm -f "$TMP_BIN" "$TMP_VAR"

echo "Done."

################################################################################
# Warning before reboot
################################################################################

echo ""
echo "##############################################################"
echo "#                                                            #"
echo "#                                                            #"
echo "#   DO NOT TURN OFF SYSTEM POWER WHILE BIOS UPDATING !       #"
echo "#                                                            #"
echo "#                                                            #"
echo "##############################################################"
echo ""

echo "Rebooting system in 3s ..."
sleep 3
reboot

SCRIPT_EOF

    chmod a+x ${install_dir}/capsule
    echo "EFI_PARTITION=/dev/nvme0n1p1" > ${etc_dir}/capsule_update.conf
    create_cix_deb "${pkg_Name}"
    # finish build deb package

}

readonly DO_DESC_clean="clean tools"
do_clean() {
    echo "nothing to do"
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
