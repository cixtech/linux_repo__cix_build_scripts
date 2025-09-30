#!/usr/bin/env bash
#  Copyright 2025 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#
#
readonly DO_DESC_build="build gpu dkms"

do_build() {
  build_deb_dir=${PATH_OUT_DEB_PACKAGES}/cix-gpu-dkms
  rm -rf $build_deb_dir
  mkdir -p $build_deb_dir/usr/src
  cp -r ${PATH_ROOT}/component/cix_opensource/gpu/gpu_kernel $build_deb_dir/usr/src/cix-gpu-kmd-1.0.0
  rm -rf $build_deb_dir/cix-gpu-kmd/usr/src/cix-gpu-kmd-1.0.0/.git*
  create_cix_deb cix-gpu-dkms
}

do_clean() {
    echo "clean gpu dkms"
    rm -rf ${PATH_OUT_DEB_PACKAGES}/cix-gpu-dkms
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
