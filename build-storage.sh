#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

PRIVATE_WORKSPACE=${PWD}

trap '
if [[ -e "/mnt/boot-debian" ]]; then
    sudo umount "/mnt/boot-debian" || true;
fi

' EXIT

isUEFI="1"

function replace_line_if_exist() {
    local src=$1
    local dst=$2
    local file=$3

    if [[ -e "$file" ]]; then
        set +E
        local res=`grep -n "${src}" "${file}"`
        #echo "res:$res"
        if [[ ${#res} -gt 0 ]]; then
            line=`echo "${res}" | cut -d ":" -f 1`
        fi
        set -E
        #echo "line: $line"
        if [[ $line -gt 0 ]]; then
            sed -i "${line}c${dst}" "${file}"
        fi
    fi
}

function copy_if_exist() {
    if [[ -e "$1" ]]; then
        cp -rf "$1" "$2"
    fi
}

function grub_header() {
    echo "set debug="loader,mm"
set term="vt100"
set default="${1}"
set timeout="${2}"
" > "${SCRIPT_DIR}/grub-post-silicon.cfg"
}

function grub_entry() {
    local title="Cix Sky1"
    local acpi="Device Tree"
    local dt=""
    local linux="    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
"
    local initrd=""
    OPTIND=0
    while getopts "t:d:a:r:ni" opt; do
        case $opt in
            ("t")
                #title=$(echo ${OPTARG} | tr a-z A-Z)
                title=${OPTARG}
            ;; #title
            ("d")
                dt="    devicetree /sky1-${OPTARG}.dtb
"
            ;; #device tree
            ("a")
                if [[ "${OPTARG}" == "force" ]]; then
                    acpi="ACPI"
                    linux=$linux"        cma=640M \\
"
                fi
                linux=$linux"        acpi=${OPTARG} \\
"
            ;; #acpi
            ("r") linux=$linux"        root=/dev/${OPTARG} rootwait rw \\
"
            ;; #root
            ("n") linux=$linux"        nosmp \\
"
            ;; #nosmp
            ("i") initrd="    initrd /rootfs.cpio.gz
"
            ;; #initrd
        esac
    done
    linux=$linux"        debug
"
    if [[ "${acpi}" == "ACPI" ]]; then
        dt=""
    fi
    local entry="menuentry '${title} (${acpi})' {
"
    echo "${entry}${dt}${linux}${initrd}}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"
}

readonly DO_DESC_mkgrub="make the grub.cfg for the boards of cix"
do_mkgrub() {
    grub_header 0 2 #<default> <timeout>
    grub_entry -t "0 Cix Sky1 on EVB" -d "evb" -a "off" -r "nvme0n1p2"
    grub_entry -t "1 Cix Sky1 on EVB" -d "evb" -a "force" -r "nvme0n1p2"
    grub_entry -t "2 Cix Sky1 on CRB" -d "crb" -a "off" -r "nvme0n1p2"
    grub_entry -t "3 Cix Sky1 on CRB" -d "crb" -a "force" -r "nvme0n1p2"
    grub_entry -t "4 Cix Sky1 on CLOUDBOOK" -d "cloudbook" -a "off" -r "nvme0n1p2"
    grub_entry -t "5 Cix Sky1 on CLOUDBOOK" -d "cloudbook" -a "force" -r "nvme0n1p2"

    echo "menuentry '6 Cix Sky1 EVB on EMU/FPGA (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        acpi=off \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        nosmp
    initrd /rootfs.cpio.gz
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

    echo "menuentry '7 Cix Sky1 on minisys EVB (Device Tree)' {
    devicetree /sky1-evb-minisys.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        acpi=off \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        nosmp
    initrd /rootfs.cpio.gz
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

    grub_entry -t "8 Cix Sky1 CPIO on EVB" -d "evb" -a "off" -i #buildroot
    grub_entry -t "9 Cix Sky1 USB on EVB" -d "evb" -a "off" -r "sda2" #-n #usb
    grub_entry -t "10 Cix Sky1 CPIO on EVB" -d "evb" -a "force" -i #buildroot
    grub_entry -t "11 Cix Sky1 USB on EVB" -d "evb" -a "force" -r "sda2" #-n #usb

echo "menuentry '12 Cix Sky1 on usb smp EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/sda2 rootwait rw
   }
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '13 Cix Sky1 on nvme smp EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw
   }
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '14 Cix Sky1 HDA ALC256 NVME on EVB (Device Tree)' {
    devicetree /sky1-evb-hda-alc256.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        loglevel=4 \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '15 Cix Sky1 HDA ALC256 USB on EVB (Device Tree)' {
    devicetree /sky1-evb-hda-alc256.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        loglevel=4 \\
        root=/dev/sda2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '16 Cix Sky1 NFS(10.128.0.10) on EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        nosmp \\
        acpi=off \\
        root=/dev/nfs rw nfsroot=10.128.0.10:/sw_bringup/nfs_os/debian,proto=tcp,nfsvers=3 rootwait ip=dhcp
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '17 Cix Sky1 NFS(10.128.0.10) smp on EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nfs rw nfsroot=10.128.0.10:/sw_bringup/nfs_os/debian,proto=tcp,nfsvers=3 rootwait ip=dhcp
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '18 Cix Sky1 NFS(172.16.64.11) on EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        nosmp \\
        acpi=off \\
        root=/dev/nfs rw nfsroot=172.16.64.11:/data/debian,proto=tcp,nfsvers=4 rootwait ip=dhcp
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '19 Cix Sky1 NFS(172.16.64.11) smp on EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nfs rw nfsroot=172.16.64.11:/data/debian,proto=tcp,nfsvers=4 rootwait ip=dhcp
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"
    grub_entry -t "20 Cix Sky1 USB on CRB" -d "crb" -a "off" -r "sda2"
    grub_entry -t "21 Cix Sky1 USB on CLOUDBOOK" -d "cloudbook" -a "off" -r "sda2"

echo "menuentry '22 Cix Sky1 LT7911UXC AUDIO NVME on EVB (Device Tree)' {
    devicetree /sky1-evb-lt7911uxc-audio.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '23 Cix Sky1 LT7911UXC AUDIO USB on EVB (Device Tree)' {
    devicetree /sky1-evb-lt7911uxc-audio.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/sda2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '24 Cix Sky1 NPU ReserveMEM nvme smp on EVB (Device Tree)' {
    devicetree /sky1-evb-npu-resmem.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '25 Cix Sky1 isp on nvme smp EVB (Device Tree)' {
    devicetree /sky1-evb-isp.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '26 Cix Sky1 performance on EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw \\
        loglevel=6 \\
        systemd.mask=NetworkManager-wait-online.service
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '27 Cix Sky1 on nvme smp docker EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \
        console=ttyAMA2,115200 \
        efi=noruntime \
        earlycon=pl011,0x040d0000 \
        arm-smmu-v3.disable_bypass=0 \
        acpi=off \
        cpufreq.off=1 \
        cpuidle.off=1 \
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '28 Cix Sky1 on Orion O6 (Device Tree)' {
    devicetree /sky1-orion-o6.dtb
    linux /Image \\
        loglevel=0 \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '29 Cix Sky1 on Orion O6 40 pin (Device Tree)' {
    devicetree /sky1-orion-o6-40pin.dtb
    linux /Image \\
        loglevel=0 \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '30 Cix Sky1 SOF ALC5682-ALC1019 AUDIO NVME on EVB (Device Tree)' {
    devicetree /sky1-evb-sof-alc5682-alc1019.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        loglevel=4 \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '33 Cix Sky1 CSI-DMA-LT7911 on EVB (Device Tree)' {
    devicetree /sky1-evb-csidma-lt7911.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        loglevel=4 \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

}

BOOT_SIZE=500 # M bytes

readonly DO_DESC_boot="package the boot image"
do_boot() {
    local boot_size=$(expr $BOOT_SIZE \* 1024 \* 1024)
    local swap_size=${SWAP_SIZE:-0}
    echo "boot size: ${BOOT_SIZE} M bytes, swap size: ${swap_size} M bytes"

    case "$PLATFORM" in
    ("cix")
        local is_post_silicon="false"
        case "$BOARD" in
        ("emu" | "fpga" | "qemu")
            cp "${SCRIPT_DIR}/grub-pre-silicon.cfg" "${SCRIPT_DIR}/grub.cfg"
            if [[ "$ACPI" == "1" ]]; then
                sed -i 's/acpi=off/acpi=force/g' "${SCRIPT_DIR}/grub.cfg"
                sed -i 's/console=ttyAMA2/console=ttyAMA0/g' "${SCRIPT_DIR}/grub.cfg"
                sed -i '/devicetree/d' "${SCRIPT_DIR}/grub.cfg"
            fi
            case "$BOARD" in
            ("emu")
                if [[ "$ACPI" == "1" ]]; then
                    if [[ "$SMP" == "1" ]]; then
                        sed -i '3cset default="12"' "${SCRIPT_DIR}/grub.cfg"
                    else
                        sed -i '3cset default="11"' "${SCRIPT_DIR}/grub.cfg"
                    fi
                else
                    if [[ "$SMP" == "1" ]]; then
                        sed -i '3cset default="8"' "${SCRIPT_DIR}/grub.cfg"
                    else
                        sed -i '3cset default="1"' "${SCRIPT_DIR}/grub.cfg"
                    fi
                fi
                ;;
            ("fpga")
                if [[ "$ACPI" == "1" ]]; then
                    sed -i '3cset default="0"' "${SCRIPT_DIR}/grub.cfg"
                else
                    sed -i '3cset default="2"' "${SCRIPT_DIR}/grub.cfg"
                fi
                ;;
            ("qemu")
                sed -i '3cset default="4"' "${SCRIPT_DIR}/grub.cfg"
                sed -i '4cset timeout="5"' "${SCRIPT_DIR}/grub.cfg"
                ;;
            esac

            if  [[ "$FASTBOOT_LOAD" == "nvme" ]]; then
                sed -i '3cset default="13"' "${SCRIPT_DIR}/grub.cfg"
            elif [[ "$FASTBOOT_LOAD" == "spi" ]]; then
                sed -i '3cset default="2"' "${SCRIPT_DIR}/grub.cfg"
            elif [[ "$FASTBOOT_LOAD" == "usb" ]]; then
                sed -i '3cset default="14"' "${SCRIPT_DIR}/grub.cfg"
            fi
            ;;
        (*)
            is_post_silicon="true"
            cp "${SCRIPT_DIR}/grub-post-silicon.cfg" "${SCRIPT_DIR}/grub.cfg"
            sed -i s/linux_version/${linux_version}/g ${SCRIPT_DIR}/grub.cfg
            if [[ "${ENABLE_OVERLAY_FS}" == "true" ]] && [[ "$DEBIAN_MODE" != "0" ]]; then
                sed -i "s/rootwait\ rw/rootwait\ ro/g" ${SCRIPT_DIR}/grub.cfg
            fi
            if [[ "$ACPI" == "1" ]]; then
                #default select menuentry '1 Cix Sky1 on EVB (ACPI)'
                sed -i '3cset default=1' "${SCRIPT_DIR}/grub.cfg"
            fi
            if [[ "$BOARD" == "cloudbook" ]]; then
                sed -i '3cset default=4' "${SCRIPT_DIR}/grub.cfg"
            fi
            if [[ "$DOCKER_MODE" == "docker" ]]; then
                sed -i '3cset default=27' "${SCRIPT_DIR}/grub.cfg"
            fi
            if [[ -e "${PATH_OUT}/images/partition-table.img" ]]; then
                set +E
                local swap_device_guid=$("${PATH_ROOT}/build-scripts/debian/cix_tool" --release-tool --gpt -f "${PATH_OUT}/images/partition-table.img" --dump swap | grep "part guid: " | awk -F "part guid: " '{print $2}')
                local root_device_guid=$("${PATH_ROOT}/build-scripts/debian/cix_tool" --release-tool --gpt -f "${PATH_OUT}/images/partition-table.img" --dump root | grep "part guid: " | awk -F "part guid: " '{print $2}')
                if [[ ${#swap_device_guid} -gt 0 ]] && [[ ${swap_size} -gt 0 ]]; then
                    echo "linux cmd line with swap partition in boot.img (swap size: ${swap_size})"
                    sed -i "s:root=/dev/nvme0n1p2:resume=PARTUUID=${swap_device_guid} noresume root=PARTUUID=${root_device_guid}:g" "${SCRIPT_DIR}/grub.cfg"
                    sed -i "s:root=/dev/sda2:resume=PARTUUID=${swap_device_guid} noresume root=PARTUUID=${root_device_guid}:g" "${SCRIPT_DIR}/grub.cfg"
                else
                    echo "linux cmd line without swap partition in boot.img"
                    sed -i "s:root=/dev/nvme0n1p2:root=PARTUUID=${root_device_guid}:g" "${SCRIPT_DIR}/grub.cfg"
                    sed -i "s:root=/dev/sda2:root=PARTUUID=${root_device_guid}:g" "${SCRIPT_DIR}/grub.cfg"
                fi
                set -E
            fi
            ;;
        esac

        local dtbs=(`find "${PATH_OUT}" -maxdepth 1 -name "*.dtb" | xargs echo`)
        local count=${#dtbs[@]}
        all_dtb=""
        for ((i=0;i<$count;i++))
        do
            dtb=${dtbs[$i]##*/}
            all_dtb="${all_dtb} ${PATH_OUT}/${dtb} /${dtb}"
        done

        sign_file "${PATH_OUT}/grub.efi" "${PATH_OUT}/grub.efi"

        if [[ "${is_post_silicon}" != "true" ]]; then
            if  [[ "$DEBIAN_MODE" != "0" ]]; then
                if  [[ "$FASTBOOT_LOAD" != "nvme" ]]; then
                    sed -i '3cset default="7"' "${SCRIPT_DIR}/grub.cfg"
                    if [[ "$FASTBOOT_LOAD" == "spi" ]]; then
                        sed -i '3cset default="2"' "${SCRIPT_DIR}/grub.cfg"
                    elif [[ "$FASTBOOT_LOAD" == "usb" ]]; then
                        sed -i '3cset default="14"' "${SCRIPT_DIR}/grub.cfg"
                    fi
                fi

                "${SCRIPT_DIR}/tools/mk-part-fat" \
                    -o "${PATH_OUT}/images/boot_os.img" \
                    -s "${boot_size}" \
                    -l "ESP" \
                    -i "${volume_id}" \
                    "${PATH_OUT}/grub.efi" "/EFI/BOOT/BOOTAA64.EFI" \
                    "${SCRIPT_DIR}/grub.cfg" "/grub/grub.cfg" \
                    "${PATH_OUT}/Image" "/Image" \
                    ${all_dtb} \
                    "${PATH_CIX_BINARY}/device/images/rootfs.cpio.gz" "/rootfs.cpio.gz"

                if  [[ "$FASTBOOT_LOAD" != "nvme" ]]; then
                    sed -i '3cset default="10"' "${SCRIPT_DIR}/grub.cfg"
                    if [[ "$FASTBOOT_LOAD" == "spi" ]]; then
                        sed -i '3cset default="2"' "${SCRIPT_DIR}/grub.cfg"
                    elif [[ "$FASTBOOT_LOAD" == "usb" ]]; then
                        sed -i '3cset default="14"' "${SCRIPT_DIR}/grub.cfg"
                    fi
                fi
            fi
        fi

        if  [[ "$DEBIAN_MODE" == "0" ]]; then
            sed -i '/initrd.img/d' "${SCRIPT_DIR}/grub.cfg"
        fi
        "${SCRIPT_DIR}/tools/mk-part-fat" \
            -o "${PATH_OUT}/images/boot.img" \
            -s "${boot_size}" \
            -l "ESP" \
            -i "${volume_id}" \
            "${PATH_OUT}/grub.efi" "/EFI/BOOT/BOOTAA64.EFI" \
            "${SCRIPT_DIR}/grub.cfg" "/grub/grub.cfg" \
            "${PATH_OUT}/Image" "/Image" \
            ${all_dtb} \
            "${PATH_CIX_BINARY}/device/images/rootfs.cpio.gz" "/rootfs.cpio.gz"
        ;;
    esac

    if [[ ! -d /mnt/boot-debian ]]; then
      sudo mkdir /mnt/boot-debian
    fi
    if  [[ "$DEBIAN_MODE" != "0" ]]; then
        if [[ -e "$PATH_OUT/images/boot.img" ]]; then
            if [[ -e $PATH_DEBIAN/boot/initrd.img-$linux_version ]]; then
                sudo mount $PATH_OUT/images/boot.img /mnt/boot-debian
                sudo cp $PATH_DEBIAN/boot/initrd.img-$linux_version /mnt/boot-debian/
                sudo umount /mnt/boot-debian
                sudo rm -rf /mnt/boot-debian
            else
                echo "No initrd.img found, please check the build"
            fi
        else
            echo "No boot.img found, please check the build"
        fi
    fi
    if [[ -e "${PATH_OUT}/images/boot.img" ]]; then
        img2simg "${PATH_OUT}/images/boot.img" "${PATH_OUT}/images/boot_sparse.img" 1048576
    fi
    if [[ -e "${PATH_OUT}/images/boot_os.img" ]]; then
        img2simg "${PATH_OUT}/images/boot_os.img" "${PATH_OUT}/images/boot_os_sparse.img" 1048576
    fi
}

readonly DO_DESC_swap="package the swap image"
do_swap() {
    local swap_size=${SWAP_SIZE:-0}
    if [[ ${swap_size} -gt 0 ]]; then
        echo "create the swap image (swap size: ${swap_size})"
        local swap_img="${PATH_OUT}/images/swap.img"
        dd if=/dev/zero of="${swap_img}" bs=1M count=$swap_size
        # echo mkswap -f "${swap_img}"
        sudo chmod 0600 "${swap_img}"
        sudo chown ${USER}:${USER} "${swap_img}"
        mkswap -f "${swap_img}"
        img2simg "${swap_img}" "${PATH_OUT}/images/swap_sparse.img" 1048576
    else
        rm -f ${PATH_OUT}/images/swap*.img
    fi
}

readonly DO_DESC_data="package the data image"
do_data() {
    local data_size=${DATA_SIZE:-0}
    if [[ ${data_size} -gt 0 ]]; then
        echo "create the data image (data size: ${data_size})"
        local data_img="${PATH_OUT}/images/data.ext4"
        dd if=/dev/zero of="${data_img}" bs=1M count=$data_size
        sudo mkfs.ext4 "${data_img}"
        sudo chown ${USER}:${USER} "${data_img}"
        img2simg "${data_img}" "${PATH_OUT}/images/data_sparse.ext4" 1048576
    else
        rm -f ${PATH_OUT}/images/data*.ext4
    fi
}

readonly DO_DESC_disk="create the disk image with gpt, boot, root, etc."
do_disk() {
    local path="${PATH_OUT}/images"
    local file="${path}/linux-fs.sdcard"
    echo "image: ${file}"

    local images=""
    if [[ -e "${path}/boot.img" ]]; then
        images="${images} --image-name boot --image-file ${path}/boot.img"
    fi

    if [[ -e "${path}/swap.img" ]]; then
        images="${images} --image-name swap --image-file ${path}/swap.img"
    fi

    local uuid=${CIX_CONST_ROOT_UUID}
    if [[ "${AUTO_GUID}" != "0" ]]; then
        uuid=$(uuidgen)
    fi

    if [[ "${ENABLE_SQUASH_FS}" == "true" ]]; then
        if [[ -e "${path}/squashfs_raw.img" ]]; then
            rm -f "${path}/squashfs_raw.img"
        fi
        sudo mksquashfs ${PATH_OUT}/debian ${path}/squashfs_raw.img -comp xz
        sudo chown $USER:$USER ${path}/squashfs_raw.img

        # dd if=/dev/zero of="${path}/squashfs_full.img" bs=1M count=10240
        # dd if="${path}/squashfs_raw.img" of="${path}/squashfs_full.img" bs=1048576 conv=notrunc
        # img2simg "${path}/squashfs_full.img" "${path}/squashfs_sparse.img" 1048576
        # images="${images} --image-name root --image-file ${path}/squashfs_full.img --image-uuid ${uuid}"

        img2simg "${path}/squashfs_raw.img" "${path}/squashfs_sparse.img" 1048576
        images="${images} --image-name root --image-file ${path}/squashfs_raw.img --part-size 10G --image-uuid ${uuid}"
    else
        if [[ -e "${path}/rootfs.ext4" ]]; then
            images="${images} --image-name root --image-file ${path}/rootfs.ext4 --image-uuid ${uuid}"
        fi
    fi

    if [[ -e "${path}/verity_data.img" ]]; then
        images="${images} --image-file ${path}/verity_data.img --image-name verity_data --image-uuid a4f6d8e2-3b91-4c73-8f59-1e2d3c4b5a67 --image-type-uuid 9b2c1f0a-7e8d-4f6c-9a3b-2c1d0e9f8a56"
    fi

    if [[ -e "${path}/verity_hash.img" ]]; then
        images="${images} --image-file ${path}/verity_hash.img --image-name verity_hash --image-uuid 7d4e2c1b-6a9f-4e8c-9d2a-1b2c3d4e5f67 --image-type-uuid 1c3e5f7a-9b8d-4c7e-8f9a-2b3c4d5e6f78"
    fi

    if [[ -e "${path}/data.ext4" ]]; then
        images="${images} --image-name data --image-file ${path}/data.ext4"
    fi

    sudo ${PATH_ROOT}/build-scripts/debian/cix_tool --release-tool --gpt --create -f ${file} ${images}
    sudo chown $USER:$USER ${file}
    sudo ${PATH_ROOT}/build-scripts/debian/cix_tool --release-tool --gpt -f ${file} --extract-gpt ${path}
    sudo chown $USER:$USER ${path}/partition-table.img

    sudo ${PATH_ROOT}/build-scripts/debian/cix_tool --release-tool --gpt --create-gpt -s 512 -f ${path}/partition-table-512.img ${images}
    sudo ${PATH_ROOT}/build-scripts/debian/cix_tool --release-tool --gpt --create-gpt -s 4096 -f ${path}/partition-table-4096.img ${images}
    sudo chown $USER:$USER ${path}/partition-table-512.img
    sudo chown $USER:$USER ${path}/partition-table-4096.img

    if [[ -e "${PATH_OUT}/images/boot.img" ]]; then
        img2simg "${PATH_OUT}/images/boot.img" "${PATH_OUT}/images/boot_sparse.img" 1048576
    fi
    if [[ -e "${PATH_OUT}/images/boot_os.img" ]]; then
        img2simg "${PATH_OUT}/images/boot_os.img" "${PATH_OUT}/images/boot_os_sparse.img" 1048576
    fi

    if [[ ! -d /mnt/boot-debian ]]; then
      sudo mkdir /mnt/boot-debian
    fi
    sudo mount ${PATH_OUT}/images/boot.img /mnt/boot-debian
    sudo cp -f /mnt/boot-debian/GRUB/GRUB.CFG "${PATH_OUT}/images/grub.cfg"
    sudo chown $USER:$USER "${PATH_OUT}/images/grub.cfg"
    sudo umount /mnt/boot-debian
    sudo rm -rf /mnt/boot-debian
    fdisk ${file} -l
}

readonly DO_DESC_build="package all modules into a total image"
do_build() {
    do_boot
    do_swap
    do_data
    do_disk

    if [[ ! -e "${PATH_OUT}/images/elf" ]]; then
        mkdir -p "${PATH_OUT}/images/elf"
    fi

    #for debug
    copy_if_exist "${PATH_EXPORT_FIRMWARE}/tfa_fw/bl31.elf" "${PATH_OUT}/images/elf/"
    copy_if_exist "${PATH_EXPORT_FIRMWARE}/pbl_fw/bl2.elf" "${PATH_OUT}/images/elf/"
    copy_if_exist "${PATH_ROOT}/linux/vmlinux" "${PATH_OUT}/images/elf/"

    #for package tool
    copy_if_exist "${PATH_CIX_BINARY}/device/images/rootfs.cpio.gz" "${PATH_OUT}/images/rootfs.cpio.gz"
    copy_if_exist "${PATH_CIX_BINARY}/device/images/mini_rootfs.cpio.gz" "${PATH_OUT}/images/mini_rootfs.cpio.gz"
    copy_if_exist "${PATH_OUT}/Image" "${PATH_OUT}/images/Image"
    copy_if_exist "${PATH_EXPORT_FIRMWARE}/se_fw/se_fw.bin" "${PATH_OUT}/images/se_fw.bin"
    copy_if_exist "${PATH_EXPORT_FIRMWARE}/pm_fw/pm_fw.bin" "${PATH_OUT}/images/pm_fw.bin"
    copy_if_exist "${PATH_OUT}/pbl_fw.bin" "${PATH_OUT}/images/pbl_fw.bin"
    copy_if_exist "${PATH_OUT}/tf-a.bin" "${PATH_OUT}/images/tf-a.bin"
    copy_if_exist "${PATH_OUT}/tee.bin" "${PATH_OUT}/images/tee.bin"
    copy_if_exist "${PATH_OUT}/SKY1_BL33_UEFI.fd" "${PATH_OUT}/images/SKY1_BL33_UEFI.fd"
    cp -rf "${PATH_OUT}"/*.dtb "${PATH_OUT}/images/"
    copy_if_exist "${PATH_OUT}/grub.efi" "${PATH_OUT}/images/grub.efi"
    #copy_if_exist "${SCRIPT_DIR}/grub.cfg" "${PATH_OUT}/images/grub.cfg"
    copy_if_exist "${PATH_CIX_BINARY}/host/packagetool/package-tool.sh" "${PATH_OUT}/"
    copy_if_exist "${PATH_CIX_BINARY}/host/packagetool/bin" "${PATH_OUT}/"
    copy_if_exist "${PATH_CIX_BINARY}/host/packagetool/overlay" "${PATH_OUT}/"

    copy_if_exist "${PATH_ROOT}/build-scripts/debian/boot/EFI" "${PATH_OUT}/images"
    copy_if_exist "${PATH_ROOT}/build-scripts/debian/uefi_tool.sh" "${PATH_OUT}/images"
    chmod +x "${PATH_OUT}/images/uefi_tool.sh"

    copy_if_exist "${PATH_ROOT}/build-scripts/debian/cix_tool" "${PATH_OUT}/images"
    copy_if_exist "${PATH_ROOT}/build-scripts/debian/disk-extract.sh" "${PATH_OUT}/images"
}

readonly DO_DESC_clean="clean rootfs and linux-fs.sdcard"
do_clean() {
    rm -f "${PATH_OUT}/images/rootfs.ext4"
    rm -f "${PATH_OUT}/linux-fs.sdcard"
    rm -rf "${PATH_OUT}/images/boot.img"
}

readonly DO_DESC_flash_bios="flash bios"
do_flash_bios() {
    local ipAddr=" -i ${INPUT}"
    local path="${PATH_OUT}/images/cix_flash_all.bin"
    if [[ "${path}" ]]; then
        echo "flash bios: ${path}"
        sudo ${PATH_ROOT}/build-scripts/debian/cix_tool ${ipAddr} -i "${path}"
    fi
}

readonly DO_DESC_flash_images="flash images"
do_flash_images() {
    local ipAddr=" -i ${INPUT}"
    local path="${PATH_OUT}/images"

    if [[ ! -e "${path}/partition-table.img" ]]; then
        echo "${path}/partition-table.img does not exist."
        exit 1
    fi

    echo "enter fastboot mode."
    sudo ${PATH_ROOT}/build-scripts/debian/cix_tool ${ipAddr} --enter-fastboot
    sleep 3
    echo "fastboot flash gpt ${path}/partition-table.img"
    sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash gpt "${path}/partition-table.img"
    ${PATH_ROOT}/build-scripts/debian/cix_tool --release-tool --gpt -f "${path}/partition-table.img" --dump | grep name | while read line; do
        local name=$(echo ${line} | awk '{print $4}')
        echo $name
        if [[ -e "${path}/${name}_sparse.img" ]]; then
            echo "fastboot flash ${name} ${path}/${name}_sparse.img"
            sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash ${name} "${path}/${name}_sparse.img"
        elif [[ ${name} == "root" ]]; then
            if [[ -e "${path}/rootfs_sparse.ext4" ]]; then
                echo "fastboot flash ${name} ${path}/rootfs_sparse.ext4"
                sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash ${name} "${path}/rootfs_sparse.ext4"
            fi
        elif [[ ${name} == "data" ]]; then
            if [[ -e "${path}/data_sparse.ext4" ]]; then
                echo "fastboot flash ${name} ${path}/data_sparse.ext4"
                sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash ${name} "${path}/data_sparse.ext4"
            fi
        else
            echo "no image can flash for partition ${name}"
        fi
    done
    sleep 1
    echo "exit fastboot mode."
    sudo ${PATH_ROOT}/build-scripts/debian/cix_tool ${ipAddr} --exit-fastboot
}

readonly DO_DESC_flash="flash images onto the device"
do_flash() {
    case "$PLATFORM" in
    ("cix")
        local path="${PATH_OUT}/images"
        local file=${INPUT}
        if [[ -d "${file}" ]]; then
            path=${file}
            file="${path}/partition-table.img"
        elif [[ -d "${PRIVATE_WORKSPACE}/${file}" ]]; then
            path="${PRIVATE_WORKSPACE}/${file}"
            file="${path}/partition-table.img"
        fi
        if [[ ${#file} -lt 1 ]]; then
            file=${PATH_OUT}/images/partition-table.img
        fi
        echo "gpt image: ${file}"
        # if [[ -e "${PATH_OUT}/images/cix_flash_all.bin" ]]; then
        #     sudo ${PATH_ROOT}/build-scripts/debian/cix_tool -i "${PATH_OUT}/images/cix_flash_all.bin"
        # elif [[ -e "${PATH_OUT}/images/cix_flash_all_rsa_pr.bin" ]]; then
        #     sudo ${PATH_ROOT}/build-scripts/debian/cix_tool -i "${PATH_OUT}/images/cix_flash_all_rsa_pr.bin"
        # fi

        sleep 1
        sudo ${PATH_ROOT}/build-scripts/debian/cix_tool --enter-fastboot
        sleep 3

        if [[ -e "${path}/cix_flash_all_rsa_proto.bin" ]]; then
            sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash bootloader "${path}/cix_flash_all_rsa_proto.bin"
        elif [[ -e "${path}/cix_flash_all_rsa_pr.bin" ]]; then
            sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash bootloader "${path}/cix_flash_all_rsa_pr.bin"
        elif [[ -e "${path}/cix_flash_all.bin" ]]; then
            sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash bootloader "${path}/cix_flash_all.bin"
        else
            echo "no bios can flash."
        fi

        if [[ -e "${file}" ]]; then
            echo "fastboot flash gpt ${file}"
            sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash gpt "${file}"
            ${PATH_ROOT}/build-scripts/debian/cix_tool --release-tool --gpt -f "${file}" --dump | grep name | while read line; do
                local name=$(echo ${line} | awk '{print $4}')
                echo $name
                if [[ -e "${path}/${name}_sparse.img" ]]; then
                    echo "fastboot flash ${name} ${path}/${name}_sparse.img"
                    sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash ${name} "${path}/${name}_sparse.img"
                elif [[ ${name} == "root" ]]; then
                    if [[ -e "${path}/rootfs_sparse.ext4" ]]; then
                        echo "fastboot flash ${name} ${path}/rootfs_sparse.ext4"
                        sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash ${name} "${path}/rootfs_sparse.ext4"
                    fi
                else
                    echo "no image can flash for partition ${name}"
                fi
            done
        fi

        sleep 1
        sudo ${PATH_ROOT}/build-scripts/debian/cix_tool --exit-fastboot
        ;;
    esac
}

readonly DO_DESC_run="run rootfs and kernel on qemu"
do_run() {
    qemu-system-aarch64 -machine virt,virtualization=true,gic-version=3  \
        -cpu cortex-a57 \
        -smp 2 \
        -kernel "${PATH_OUT}/Image" \
        -initrd "${PATH_OUT}/rootfs_debian.cpio.gz" \
        -m size=2G \
        -append "root=/dev/ram rdinit=/sbin/init" \
        -nographic

    #qemu-system-aarch64 -machine virt,kernel_irqchip=on,gic-version=3 -cpu cortex-a57 -m 2G -bios "${PATH_CIX_BINARY}/device/images/QEMU_EFI.fd" -hda "${PATH_OUT}/images/boot.img" -nographic

    #ESC
    #Boot Manager
    #EFI Internal Shell
    #f0:
    #
}

readonly DO_DESC_extract="extract the disk image"
do_extract() {
    local file=${INPUT}
    if [[ ! -f "${file}" ]]; then
        if [[ -f "${PRIVATE_WORKSPACE}/${file}" ]]; then
            file="${PRIVATE_WORKSPACE}/${file}"
        fi
    fi
    if [[ ${#file} -lt 1 ]]; then
        file=${PATH_OUT}/images/linux-fs.sdcard
    fi

    if [[ -e "${file}" ]]; then
        echo "image: ${file}"
        sudo ${PATH_ROOT}/build-scripts/debian/cix_tool --release-tool --gpt -f ${file} --extract ${PRIVATE_WORKSPACE}/extracted
        echo "${file} is extracted to the path ${PRIVATE_WORKSPACE}/extracted"
        sudo chown $USER:$USER "${PRIVATE_WORKSPACE}/extracted" -R
    fi
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
