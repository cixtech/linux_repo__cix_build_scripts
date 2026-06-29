#!/bin/sh

trap '
if [ -e "/tmp/rootfs" ]; then
    umount "/tmp/rootfs" || true;
fi
' EXIT

check_size() {
    local str=$1
    if expr "$str" : ".*G$" >/dev/null; then
        str=${str%G}
    elif expr "$str" : ".*M$" >/dev/null; then
        str=$((${str%M} / 1024))
    elif expr "$str" : ".*K$" >/dev/null; then
        str=$((${str%K} / 1024 / 1024))
    fi
    echo ${str}
}

# Grow root. This will expand the root partition to the total disk
grow_root() {
    echo "auto grow the root size"
    local uuid=$(echo $(cat /proc/cmdline) | awk -F "root=" '{print $2}' | awk -F "=" '{print $2}' | awk '{print $1}')
    case $uuid in
    *-*-*-*-*)
        local root=$(blkid | grep "$uuid" | awk -F ":" '{print $1}')
        local device=$root
        case $device in
        *[0-9])
            device=${device:0:${#device}-1}
            case $device in
            *p)
                device=${device:0:${#device}-1}
                ;;
            esac
            ;;
        esac
        echo "root uuid: ${uuid}, device: ${device}, root: ${root}"
        local mounted_content=$(mount -l | grep "$root")
        if [ "${mounted_content}" != "" ]; then
            echo "$root has been mounted. exit now"
            return
        fi
        local totalSize=$(cat /proc/partitions | grep "$(echo ${device} | awk -F '/' '{print $NF}')" | head -n 1 | awk '{print $3}')
        local bs=512
        local gptSize=$(/bin/cix-gpt -f ${device} --dump -s ${bs} | grep "backup lba: " | awk -F "backup lba: " '{print $2}')
        if [ "$gptSize" == "" ]; then
            bs=4096
            gptSize=$(/bin/cix-gpt -f ${device} --dump -s ${bs} | grep "backup lba: " | awk -F "backup lba: " '{print $2}')
        fi
        totalSize=$((${totalSize} / 1024 / 1024))
        gptSize=$((${gptSize} * ${bs} / 1024 / 1024 / 1024))
        if [ ! -e /tmp/rootfs ]; then
            mkdir -p /tmp/rootfs
        fi
        mount $root /tmp/rootfs
        # local dfSize=$(($(df | grep $root | awk '{print $2}') / 1024 / 1024))
        local dfSize=$(($(dumpe2fs -h ${root} 2>/dev/null | grep "Block count" | awk -F ":" '{print $2}' | awk '{print $1}') * $(dumpe2fs -h ${root} 2>/dev/null | grep "Block size" | awk -F ":" '{print $2}' | awk "{print $1}") / 1024 / 1024 / 1024))
        umount /tmp/rootfs
        rm -rf /tmp/rootfs
        local fdiskSize=$(cat /proc/partitions | grep "$(echo ${root} | awk -F '/' '{print $NF}')" | head -n 1 | awk '{print $3}')
        fdiskSize=$((${fdiskSize} / 1024 / 1024))
        echo "dfSize=${dfSize}, fdiskSize=${fdiskSize} totalSize=${totalSize} gptSize=${gptSize}"
        if [ $dfSize -lt $(($fdiskSize - 50)) ]; then
            e2fsck -f -y $root
            resize2fs $root #${fdiskSize}G
            echo "resize $root to ${fdiskSize}G only"
            return
        fi
        if [ $gptSize -lt $(($totalSize - 50)) ]; then
            if [ "$(/bin/cix-gpt -f "${device}" --dump | grep "name: data")" != "" ]; then
                echo "expand root and data"
                /bin/cix-gpt -f $device --expand-root auto --expand-data auto
            else
                echo "expand root"
                /bin/cix-gpt -f $device --expand-root auto
            fi
            echo "expand root partition"
        else
            echo "no work to expand root"
        fi
        ;;
    *)
        echo "invalid uuid: ${uuid}"
        return
        ;;
    esac
}

if [ -e "/run/initramfs" ]; then
    grow_root > /run/initramfs/growroot.log
else
    grow_root
fi
