#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

do_build() {
    pkg_Name="cix-common-misc"
    cp -r $PATH_SOURCE_DEB/$pkg_Name ${PATH_OUT_DEB_PACKAGES}
    create_cix_deb "${pkg_Name}"

    pkg_Name="cix-alsa-conf"
    cp -r $PATH_SOURCE_DEB/$pkg_Name ${PATH_OUT_DEB_PACKAGES}
    create_cix_deb "${pkg_Name}"

    if [ $DEBIAN_MODE == 7 ]; then
        pkg_Name="cix-openkylin-adapter"
        cp -r $PATH_SOURCE_DEB/$pkg_Name ${PATH_OUT_DEB_PACKAGES}
        create_cix_deb "${pkg_Name}"

    elif [ $DEBIAN_MODE == 6 ]; then
        pkg_Name="cix-deepin-adapter"
        cp -r $PATH_SOURCE_DEB/$pkg_Name ${PATH_OUT_DEB_PACKAGES}
        create_cix_deb "${pkg_Name}"

    elif [ "$DEBIAN_MODE" == "5" -o "$DEBIAN_MODE" == "8" ]; then
        pkg_Name="cix-openkylin-beta2"
        cp -r $PATH_SOURCE_DEB/$pkg_Name ${PATH_OUT_DEB_PACKAGES}
        create_cix_deb "${pkg_Name}"
    else
        pkg_Name="cix-debian-misc"
        cp -r $PATH_SOURCE_DEB/$pkg_Name ${PATH_OUT_DEB_PACKAGES}
        cd $PATH_ROOT/build-scripts
        BRANCH_INFO=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        COMMIT_ID=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        OS_VERSION="$BRANCH_INFO-$COMMIT_ID"
        cd -
        cd $PATH_ROOT/linux
        TAG_INFO=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
        cd -
        cat > "${PATH_OUT_DEB_PACKAGES}/cix-debian-misc/etc/cix-release" <<- EOF
VERSION="$OS_VERSION"
COMMIT_ID="$COMMIT_ID"
BRANCH_INFO="$BRANCH_INFO"
TAG_INFO="$TAG_INFO"
EOF
        if [[ "${DOCKER_MODE}" == "docker" ]]; then
            if [[ ! -e "${PATH_OUT_DEB_PACKAGES}/${pkg_Name}/usr/lib/systemd/system/cix-docker-env.service" ]]; then
                echo "error, miss cix-docker-env.service!"
                exit 1
            fi
        else
            rm -f ${PATH_OUT_DEB_PACKAGES}/${pkg_Name}/usr/lib/systemd/system/cix-docker-env.service
        fi
        create_cix_deb "${pkg_Name}"
    fi
}
do_clean() {
    rm -rf ${PATH_DEB}/cix-common-misc*.deb
}
source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
