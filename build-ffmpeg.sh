#!/usr/bin/env bash
#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
##
DEPENDENT_MODULES="build-vpu_driver.sh"
readonly DO_DESC_build="build ffmpeg"
trap '
if [[ -e "${PATH_DEBIAN_COMPILE_debian_cc}/mnt/ffmpeg" ]]; then
    sudo umount "${PATH_DEBIAN_COMPILE_debian_cc}/mnt/ffmpeg" || true;
fi
' EXIT
do_build() {
    if [[ "$DEBIAN_MODE" == "0" ]]; then
        echo "debian mode: ${DEBIAN_MODE}, without debian"
        return
    fi
    local path_ffmpeg="${PATH_ROOT}/component/cix_opensource/ffmpeg"
    local path_ffmpeg_cix="${PATH_ROOT}/component/cix_opensource/ffmpeg-cix"
    if [[ -e "${path_ffmpeg_cix}" ]]; then
        if [[ -e "${path_ffmpeg}" ]]; then
            # ffmpeg folder integrity check. If failed, re-clone it and apply patches.
            if [[ ! -e "${path_ffmpeg}/libavcodec/v4l2_dma_pool.c" ]]; then
                rm -rf "${path_ffmpeg}"
            fi
        fi
        if [[ ! -e "${path_ffmpeg}" ]]; then
            git clone -b debian/7%5.1.7-0+deb12u1 --depth=1 https://salsa.debian.org/multimedia-team/ffmpeg.git "${path_ffmpeg}"
            cd "${path_ffmpeg}"
            git apply "${path_ffmpeg_cix}/debian/ffmpeg-5.1.7/patches/ffmpeg_5_1_7_debian_for_cix.patch"
            git apply "${path_ffmpeg_cix}/debian/ffmpeg-5.1.7/patches/ffmpeg_5_1_7_for_cix_2025q4.patch"
            cd -
            if [[ ! -e "${path_ffmpeg}/libavcodec/v4l2_dma_pool.c" ]]; then
                echo "ffmpeg folder integrity check failed after patching, exit build."
                return
            fi
        fi
    fi
    if [[ ! -e "${PATH_DEBIAN_COMPILE_debian_cc}/etc" ]]; then
        cix_download -s "debian12_dev_env:debian_cc%2Fdebian_cc-${debian_cc_version}.tgz" -d "${PATH_DEBIAN_COMPILE_debian_cc}" -b debian_cc-${debian_cc_version}.tgz -p sudo
    fi
    sudo rm -rf ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/*.deb ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/*.dsc \
      ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/*.xz ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/*.changes \
      ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/*.buildinfo
    if [[ ! -e "${PATH_DEBIAN_COMPILE_debian_cc}/mnt/ffmpeg" ]]; then
        sudo mkdir -p "${PATH_DEBIAN_COMPILE_debian_cc}/mnt/ffmpeg"
    fi
    cat > ./build-ffmpeg.sh <<- EOF
#!/bin/bash
export LANG=C
cd /mnt/ffmpeg
dh_make --createorig -p ffmpeg_5.1.6 -sy
dpkg-source -b .
dpkg-buildpackage --sanitize-env -aarm64 -Pcross,nocheck -us -uc -nc -d
./debian/rules clean
cd -
EOF
    sudo mv ./build-ffmpeg.sh ${PATH_DEBIAN_COMPILE_debian_cc}
    sudo chmod +x "${PATH_DEBIAN_COMPILE_debian_cc}/build-ffmpeg.sh"
    sudo cp ${PATH_SYSROOT}/usr/share/cix/include/mvx-v4l2-controls.h ${PATH_DEBIAN_COMPILE_debian_cc}/usr/include
    sudo cp ${PATH_SYSROOT}/include/linux/videodev2.h ${PATH_DEBIAN_COMPILE_debian_cc}/usr/aarch64-linux-gnu/include/linux/
    sudo cp -rf ${PATH_SYSROOT}/usr/include/va ${PATH_DEBIAN_COMPILE_debian_cc}/usr/include/
    sudo mount -t none "${path_ffmpeg}" "${PATH_DEBIAN_COMPILE_debian_cc}/mnt/ffmpeg" -o bind
    sudo chroot "${PATH_DEBIAN_COMPILE_debian_cc}" "/build-ffmpeg.sh"
    sleep 1
    cp -f ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/libavcodec59_5.1.*.deb  "${PATH_OUT}/debs"
    cp -f ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/ffmpeg_5.1.*.deb  "${PATH_OUT}/debs"
    cp -f ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/libavformat59_5.1.*.deb  "${PATH_OUT}/debs"
    cp -f ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/libavutil57_5.1.*.deb  "${PATH_OUT}/debs"
    cp -f ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/libavfilter8_5.1.*.deb  "${PATH_OUT}/debs"
    cp -f ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/libavdevice59_5.1.*.deb  "${PATH_OUT}/debs"
    cp -f ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/libswscale6_5.1.*.deb  "${PATH_OUT}/debs"
}
readonly DO_DESC_clean="clean ffmpeg"
do_clean() {
    local path_ffmpeg="${PATH_ROOT}/component/cix_opensource/ffmpeg"
    if [[ ! -e "${PATH_DEBIAN_COMPILE_debian_cc}/etc" ]]; then
        cix_download -s "debian12_dev_env:debian_cc%2Fdebian_cc-${debian_cc_version}.tgz" -d "${PATH_DEBIAN_COMPILE_debian_cc}" -b debian_cc-${debian_cc_version}.tgz -p sudo
    fi
    if [[ ! -e "${PATH_DEBIAN_COMPILE_debian_cc}/mnt/ffmpeg" ]]; then
        sudo mkdir -p "${PATH_DEBIAN_COMPILE_debian_cc}/mnt/ffmpeg"
    fi
    cat > clean.sh <<- EOF
#!/bin/bash
export LANG=C
cd /mnt/ffmpeg
./debian/rules clean
cd -
EOF
    sudo mv clean.sh ${PATH_DEBIAN_COMPILE_debian_cc}
    sudo chmod +x "${PATH_DEBIAN_COMPILE_debian_cc}/clean.sh"
    sudo rm -rf ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/*.deb ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/*.dsc \
      ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/*.xz ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/*.changes \
      ${PATH_DEBIAN_COMPILE_debian_cc}/mnt/*.buildinfo
    sudo mount -t none "${path_ffmpeg}" "${PATH_DEBIAN_COMPILE_debian_cc}/mnt/ffmpeg" -o bind
    sudo chroot "${PATH_DEBIAN_COMPILE_debian_cc}" "/clean.sh"
    if [[ -e "${PATH_ROOT}/component/cix_opensource/ffmpeg-cix" ]]; then
        sudo rm -rf "${PATH_ROOT}/component/cix_opensource/ffmpeg"
    fi
    sleep 1
}
source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
