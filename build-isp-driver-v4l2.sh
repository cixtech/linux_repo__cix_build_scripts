#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#
#
DEPENDENT_MODULES="build-kernel.sh"

readonly DO_DESC_build="build isp driver(v4l2) and embed into debian system"
do_build() {
    export ARCH=arm64
    local DRV_DIR=${PATH_ROOT}/component/cix_opensource/isp/isp_driver
    local KSRC=${PATH_LINUX}

    MODULE=armcb_isp_v4l2

    cd "${DRV_DIR}"
    echo -e "Build isp driver..."
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j${PARALLELISM} build
    cd -

    if [ -f ${DRV_DIR}/${MODULE}.ko ]; then
        # build deb package
        pkg_Name="cix-isp-driver-v4l2"
        build_deb_dir=${PATH_OUT_DEB_PACKAGES}/${pkg_Name}
        rm -rf ${build_deb_dir}
        install_dir=${build_deb_dir}/lib/modules/${linux_version}/extra
        mkdir -p ${install_dir}
        cp ${DRV_DIR}/${MODULE}.ko ${install_dir}
        create_cix_deb "${pkg_Name}"
    else
        echo error ${MODULE}.ko module not exist
        exit
    fi
}

readonly DO_DESC_clean="clean isp driver project"
do_clean() {
    local DRV_DIR=${PATH_ROOT}/component/cix_opensource/isp/isp_driver
    make -C "${DRV_DIR}" clean
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
