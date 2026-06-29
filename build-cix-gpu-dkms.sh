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
  source_dir=${PATH_ROOT}/component/cix_opensource/gpu/gpu_kernel
  dkms_conf=${source_dir}/dkms.conf
  dkms_name=$(sed -n 's/^PACKAGE_NAME="\([^"]*\)"$/\1/p' "${dkms_conf}" | head -n 1)
  dkms_version=$(sed -n 's/^PACKAGE_VERSION="\([^"]*\)"$/\1/p' "${dkms_conf}" | head -n 1)

    if [[ -z "${dkms_name}" || -z "${dkms_version}" ]]; then
        echo "ERROR: failed to parse PACKAGE_NAME or PACKAGE_VERSION from ${dkms_conf}" >&2
        exit 1
    fi

  rm -rf "${build_deb_dir}"
  mkdir -p "${build_deb_dir}/usr/src" "${build_deb_dir}/DEBIAN"
  cp -a "${source_dir}" "${build_deb_dir}/usr/src/${dkms_name}-${dkms_version}"
  rm -rf $build_deb_dir/usr/src/${dkms_name}-${dkms_version}/.git*

  cat > "${build_deb_dir}/DEBIAN/control" <<- EOF
Package: cix-gpu-dkms
Version: ${dkms_version}
Architecture: all
Maintainer: Cix OS team
Depends: dkms (>> 3.0.10)
Section: kernel
Priority: optional
Multi-Arch: foreign
Description: CIX GPU driver DKMS package
EOF

    cat > "${build_deb_dir}/DEBIAN/postinst" <<- EOF
#!/bin/sh
set -e
DKMS_NAME="${dkms_name}"
DKMS_VERSION="${dkms_version}"
DKMS_SRC="/usr/src/${dkms_name}-${dkms_version}"

case "\$1" in
    configure)
        if [ -x /usr/lib/dkms/common.postinst ]; then
            /usr/lib/dkms/common.postinst "\$DKMS_NAME" "\$DKMS_VERSION" "\$DKMS_SRC" "" "\$2"
        elif [ -x /usr/share/dkms/common.postinst ]; then
            /usr/share/dkms/common.postinst "\$DKMS_NAME" "\$DKMS_VERSION" "\$DKMS_SRC" "" "\$2"
        elif command -v dkms >/dev/null 2>&1; then
dkms add -m "\$DKMS_NAME" -v "\$DKMS_VERSION" || true
            dkms autoinstall -m "\$DKMS_NAME" -v "\$DKMS_VERSION" || true
        fi
    ;;
esac
EOF

    cat > "${build_deb_dir}/DEBIAN/prerm" <<- EOF
#!/bin/sh
set -e
DKMS_NAME="${dkms_name}"
DKMS_VERSION="${dkms_version}"

case "\$1" in
    remove|upgrade|deconfigure)
        if command -v dkms >/dev/null 2>&1 && dkms status -m "\$DKMS_NAME" -v "\$DKMS_VERSION" >/dev/null 2>&1; then
            dkms remove -m "\$DKMS_NAME" -v "\$DKMS_VERSION" --all || true
        fi
    ;;
esac
EOF

  create_cix_deb cix-gpu-dkms
}

do_clean() {
    echo "clean gpu dkms"
    rm -rf ${PATH_OUT_DEB_PACKAGES}/cix-gpu-dkms
    cix_remove_deb_artifacts "cix-gpu-dkms_*.deb"
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
