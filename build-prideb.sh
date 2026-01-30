#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

do_build() {
    if [[ -e "${PATH_ROOT}/ext_debs" ]]; then
        for dir in "${PATH_ROOT}/ext_debs"/*; do
            if [[ -d "${dir}" ]]; then
                dpkg-deb -b --root-owner-group "${dir}" "${PATH_DEB}/$(basename "${dir}").deb"
            fi
        done
    fi

    #dpu-ddk
    pkg_Name="cix-dpu-ddk"
    if [[ -e "${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name}" ]]; then
        rm -rf ${PATH_OUT_DEB_PACKAGES}/$pkg_Name
        cp -r ${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name} ${PATH_OUT_DEB_PACKAGES}/$pkg_Name
        create_cix_deb "$pkg_Name"
    fi

    if [[ "${DOCKER_MODE}" != "docker" ]]; then
        #npu-umd
        pkg_Name="cix-npu-umd"
        if [[ -e "${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name}" ]]; then
            rm -rf ${PATH_OUT_DEB_PACKAGES}/$pkg_Name
            cp -r ${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name} ${PATH_OUT_DEB_PACKAGES}/$pkg_Name
            create_cix_deb "$pkg_Name"
        fi

        #npu-noe-umd
        pkg_Name="cix-noe-umd"
        if [[ -e "${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name}" ]]; then
            rm -rf ${PATH_OUT_DEB_PACKAGES}/$pkg_Name
            cp -r ${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name} ${PATH_OUT_DEB_PACKAGES}/$pkg_Name
            build_deb_dir=${PATH_OUT_DEB_PACKAGES}/$pkg_Name
            if [[ ! -e $build_deb_dir/DEBIAN ]]; then
                mkdir -p $build_deb_dir/DEBIAN
            fi
            cat > $build_deb_dir/DEBIAN/postinst <<- EOF
#!/bin/sh
set -e

pip3 install /usr/share/cix/pypi/libnoe-*-py3-none-manylinux2014_aarch64.whl --break-system-packages
pip3 install /usr/share/cix/pypi/noe_engine-*-py3-none-manylinux2014_aarch64.whl --break-system-packages

exit 0
EOF
            chmod a+x $build_deb_dir/DEBIAN/postinst
            create_cix_deb "$pkg_Name"
        fi

        #isp-umd
        pkg_Name="cix-isp-umd"
        rm -rf ${PATH_OUT_DEB_PACKAGES}/$pkg_Name
        cp -r ${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name} ${PATH_OUT_DEB_PACKAGES}/$pkg_Name
        build_deb_dir=${PATH_OUT_DEB_PACKAGES}/$pkg_Name
        if [ ! -e $build_deb_dir/etc/systemd/system ]; then
            mkdir -p $build_deb_dir/etc/systemd/system
        fi
        rm -rf  $build_deb_dir/etc/systemd/system/load-isp-modules.service 
	if [ ! -e $build_deb_dir/usr/bin ]; then
            mkdir -p $build_deb_dir/usr/bin
        fi
        
	rm -rf  $build_deb_dir/usr/bin/load-isp-modules.sh
        if [[ ! -e $build_deb_dir/DEBIAN ]]; then
            mkdir -p $build_deb_dir/DEBIAN
        fi
        cat > $build_deb_dir/etc/systemd/system/isp-daemon.service <<- EOF
[Unit]
Description=ISP Daemon
After=network.target 

[Service]
Type=simple
Environment=LD_LIBRARY_PATH="/usr/share/cix/lib"
ExecStart=/usr/share/cix/bin/isp_app -c &
Restart=always
RestartSec=1
StartLimitInterval=10
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF
    if [[ ! -e $build_deb_dir/DEBIAN ]]; then
        mkdir -p $build_deb_dir/DEBIAN
    fi
    cat > $build_deb_dir/DEBIAN/postinst <<- EOF
#!/bin/sh
set -e

# Enable the service to start isp_app on boot
systemctl enable isp-daemon.service || true

exit 0
EOF
        create_cix_deb "$pkg_Name"
        fi

    #gpu
    pkg_Name="cix-gpu-umd"
    rm -rf ${PATH_OUT_DEB_PACKAGES}/$pkg_Name
    cp -r ${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name} ${PATH_OUT_DEB_PACKAGES}/$pkg_Name
    if [[ -e "${PATH_ROOT}/debian12/script/99-cma-device.rules" ]]; then
        mkdir -p ${PATH_OUT_DEB_PACKAGES}/$pkg_Name/lib/udev/rules.d
        cp -fp "${PATH_ROOT}/debian12/script/99-cma-device.rules" ${PATH_OUT_DEB_PACKAGES}/$pkg_Name/lib/udev/rules.d
    fi
    build_deb_dir=${PATH_OUT_DEB_PACKAGES}/$pkg_Name
    if [ ! -e $build_deb_dir/etc/systemd/system ]; then
        mkdir -p $build_deb_dir/etc/systemd/system
    fi
    if [ ! -e $build_deb_dir/usr/bin ]; then
        mkdir -p $build_deb_dir/usr/bin
    fi
    if [[ ! -e $build_deb_dir/DEBIAN ]]; then
        mkdir -p $build_deb_dir/DEBIAN
    fi
    
    cat > $build_deb_dir/DEBIAN/triggers <<- EOF
activate-noawait ldconfig
EOF
    cat > $build_deb_dir/DEBIAN/shlibs <<- EOF
libgbm 1 cix-gpu-umd (>= 1.0.0-1)
EOF
    if [[ -e $PATH_OUT_DEB_PACKAGES/cix-gpu-test ]]; then
        rm -rf $PATH_OUT_DEB_PACKAGES/cix-gpu-test
    fi
    mkdir -p $PATH_OUT_DEB_PACKAGES/cix-gpu-test/usr/share
    if [[ -e $build_deb_dir/usr/share/cix ]]; then
        # Move gpu_utilization_clock_tracing, malisc, mali_clcc to cix-gpu-umd package
        # These are released as GPU tools by cix-go
        if [[ -e "$build_deb_dir/usr/share/cix/bin/gpu_utilization_clock_tracing" ]]; then
            mv $build_deb_dir/usr/share/cix/bin/gpu_utilization_clock_tracing $build_deb_dir/usr/bin
            chmod a+x $build_deb_dir/usr/bin/gpu_utilization_clock_tracing
        fi
        if [[ -e "$build_deb_dir/usr/share/cix/bin/malisc" ]]; then
            mv $build_deb_dir/usr/share/cix/bin/malisc $build_deb_dir/usr/bin
            chmod a+x $build_deb_dir/usr/bin/malisc
        fi
        if [[ -e "$build_deb_dir/usr/share/cix/bin/mali_clcc" ]]; then
            mv $build_deb_dir/usr/share/cix/bin/mali_clcc $build_deb_dir/usr/bin
            chmod a+x $build_deb_dir/usr/bin/mali_clcc
        fi

        mv $build_deb_dir/usr/share/cix $PATH_OUT_DEB_PACKAGES/cix-gpu-test/usr/share
    fi
    rm -rf $build_deb_dir/usr/bin/load-gpu-modules.sh
    rm -rf $build_deb_dir/etc/systemd/system/load-gpu-modules.service
    create_cix_deb "cix-gpu-test"
    create_cix_deb "$pkg_Name"

    #dsp
    pkg_Name="cix-audio-dsp"
    if [[ -e "${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name}" ]]; then
        rm -rf ${PATH_OUT_DEB_PACKAGES}/$pkg_Name
        cp -r ${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name} ${PATH_OUT_DEB_PACKAGES}/$pkg_Name
        create_cix_deb "$pkg_Name"
    fi

    if [[ "${DOCKER_MODE}" != "docker" ]]; then
        #hdcp
        pkg_Name="cix-hdcp2"
        if [[ -e "${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name}" ]]; then
            rm -rf ${PATH_OUT_DEB_PACKAGES}/$pkg_Name
            cp -r ${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name} ${PATH_OUT_DEB_PACKAGES}/$pkg_Name
            create_cix_deb "$pkg_Name"
        fi
    fi
}
do_clean() {
  rm -rf ${PATH_DEB}/cix-hdcp2*.deb
  rm -rf ${PATH_DEB}/cix-audio*.deb
  rm -rf ${PATH_DEB}/cix-gpu-umd*.deb
  rm -rf ${PATH_DEB}/cix-isp-umd*.deb
  rm -rf ${PATH_DEB}/cix-npu-umd*.deb
  rm -rf ${PATH_DEB}/cix-noe-umd*.deb
  rm -rf ${PATH_DEB}/cix-dpu-ddk*.deb
}
source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
