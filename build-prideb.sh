#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

build_gpu_umd_prideb() {
    pkg_Name="$1"
    if [[ $(check_compile "${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name}" "" "${PATH_DEB}/${pkg_Name}_*.deb") == "true" ]]; then
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

       # add service to auto switch between mali GPU and dGPU
        cat > $build_deb_dir/etc/systemd/system/graphics-switch.service <<- 'EOF'
[Unit]
Description=Auto switch graphics configuration
Before=gdm.service

[Service]
Type=oneshot
ExecStart=/usr/bin/graphics-switch.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

        cat > $build_deb_dir/usr/bin/graphics-switch.sh <<- 'EOF'
#!/bin/sh
set -e

enable_cix_driver() {
    echo "/opt/cixgpu-pro/lib/aarch64-linux-gnu" > /etc/ld.so.conf.d/00-cixgpu-pro.conf
    echo "/opt/cixgpu-compat/lib/aarch64-linux-gnu" > /etc/ld.so.conf.d/01-cixgpu-compat.conf
    # Enable the Wayland session for CIX GPU
    /usr/libexec/gdm-runtime-config set daemon WaylandEnable true
    /usr/libexec/gdm-runtime-config set daemon XorgEnable false
    # Enable Mali Vulkan WSI layer (restore if it was disabled)
    if [ -d /etc/vulkan/implicit_layer.d ] && [ -f /etc/vulkan/implicit_layer.d/VkLayer_window_system_integration.json.disabled ]; then
        mv /etc/vulkan/implicit_layer.d/VkLayer_window_system_integration.json.disabled \
           /etc/vulkan/implicit_layer.d/VkLayer_window_system_integration.json
    fi
    # Enable Mali Vulkan ICD (restore if it was disabled)
    if [ -d /etc/vulkan/icd.d ] && [ -f /etc/vulkan/icd.d/mali.json.disabled ]; then
        mv /etc/vulkan/icd.d/mali.json.disabled /etc/vulkan/icd.d/mali.json
    fi
}

disable_cix_driver() {
    if [ -f /etc/ld.so.conf.d/00-cixgpu-pro.conf ] || [ -f /etc/ld.so.conf.d/01-cixgpu-compat.conf ]; then
        rm -f /etc/ld.so.conf.d/00-cixgpu-pro.conf /etc/ld.so.conf.d/01-cixgpu-compat.conf
    fi
    if [ -d /etc/vulkan/implicit_layer.d ] && [ -f /etc/vulkan/implicit_layer.d/VkLayer_window_system_integration.json ]; then
        mv /etc/vulkan/implicit_layer.d/VkLayer_window_system_integration.json \
           /etc/vulkan/implicit_layer.d/VkLayer_window_system_integration.json.disabled
        echo "Disabling Mali Vulkan WSI layer"
    fi
    if [ -d /etc/vulkan/icd.d ] && [ -f /etc/vulkan/icd.d/mali.json ]; then
        mv /etc/vulkan/icd.d/mali.json /etc/vulkan/icd.d/mali.json.disabled
        echo "Disabling Mali Vulkan ICD (mali.json)"
    fi
}

# enable CIX driver by default
enable_cix_driver

cnt=0
for f in /sys/class/drm/card*-*/status; do
    # Only check connected displays first (early exit optimization)
    if [ -f "$f" ] && [ "$(cat "$f")" = "connected" ]; then
        # Extract card path: remove prefix and suffix to get card name
        # e.g., /sys/class/drm/card0-HDMI-A-1/status -> card0-HDMI-A-1 -> card0
        card_path="${f#/sys/class/drm/}"
        card_path="${card_path%%/*}"
        # Extract just the card number part (card0, card1, etc.)
        card_path="${card_path%%-*}"

        if [ -n "$card_path" ]; then
            modalias="/sys/class/drm/${card_path}/device/modalias"

            if [ -f "$modalias" ] && grep -qiE "linlon|CIXH5010" "$modalias"; then
                cnt=$((cnt + 1))
                echo "Display connected to LINLON DPU at $f"
            fi
        fi
    fi
done

# Only check for GPU if no CIX DPU display is connected (skip unnecessary work)
nvidia_present=0
amd_present=0
if [ "$cnt" -eq 0 ]; then
    # Check for NVIDIA and AMD GPU in a single loop (more efficient)
    for f in /sys/class/drm/card*/device/vendor; do
        if [ -f "$f" ]; then
            vendor=$(cat "$f")
            case "$vendor" in
                "0x10de")
                    echo "NVIDIA GPU detected"
                    nvidia_present=1
                    ;;
                "0x1002")
                    echo "AMD GPU detected"
                    amd_present=1
                    ;;
            esac
            # Exit early if both are found (optional optimization)
            if [ "$nvidia_present" -eq 1 ] && [ "$amd_present" -eq 1 ]; then
                break
            fi
        fi
    done
    # if dGPU is not present, double check lspci info
    if [ "$nvidia_present" -eq 0 ] && [ "$amd_present" -eq 0 ]; then
        if lspci -n | grep -E "0300|0302" | grep -q "10de:"; then
            echo "NVIDIA GPU detected via lspci"
            nvidia_present=1
        fi
        if lspci -n | grep -E "0300|0302" | grep -q "1002:"; then
            echo "AMD GPU detected via lspci"
            amd_present=1
        fi
    fi
fi

# if display is connected to CIX DPU
#     enable CIX driver
# elif NVIDIA or AMD GPU is present
#     disable CIX driver
#     if NVIDIA GPU is present
#         set gnome session to Xorg
#     elif AMD GPU is present
#         set gnome session to Wayland
#     fi
# else no dGPU present and no display connected to CIX DPU
#     enable CIX driver for offscreen
# fi

if [ "$cnt" -gt 0 ]; then
    echo "Enabling CIX driver"
    enable_cix_driver
elif [ "$nvidia_present" -eq 1 ] || [ "$amd_present" -eq 1 ]; then
    echo "Disabling CIX driver"
    disable_cix_driver
    if [ "$nvidia_present" -eq 1 ]; then
        echo "Setting GDM to use Xorg session for NVIDIA GPU"
        # Set GDM to use Xorg session for NVIDIA GPU
        /usr/libexec/gdm-runtime-config set daemon WaylandEnable false
        /usr/libexec/gdm-runtime-config set daemon XorgEnable true
    elif [ "$amd_present" -eq 1 ]; then
        echo "Setting GDM to use Wayland session for AMD GPU"
        # Set GDM to use Wayland session for AMD GPU
        /usr/libexec/gdm-runtime-config set daemon WaylandEnable true
        /usr/libexec/gdm-runtime-config set daemon XorgEnable false
    fi
else
    echo "Enabling CIX driver for offscreen"
    enable_cix_driver
fi
ldconfig
EOF

	    cat > $build_deb_dir/DEBIAN/postinst <<- 'EOF'
#!/bin/sh
set -e
KERNEL_VERSION=$(uname -r 2>/dev/null) || KERNEL_VERSION="unknown"
MODULES_DIR="/lib/modules/$KERNEL_VERSION"

if [ ! -d "$MODULES_DIR" ]; then
	echo "Kernel module not found."
	echo "Mali kernel driver may not work properly."
else
	depmod $KERNEL_VERSION -a
fi

exit 0
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
        record_compile "${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name}"
    fi
}

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
            cat > "$build_deb_dir/DEBIAN/control" <<- EOF
Package: cix-noe-umd
Version: 1.0.0
Architecture: arm64
Maintainer: Cix OS team
Depends: python3-pip
Section: utils
Priority: optional
Multi-Arch: foreign
Description: cix-noe-umd package
EOF

        cat > $build_deb_dir/DEBIAN/postinst <<-'EOF'
#!/bin/sh
set -e

PIP_OPTIONS=""

if command -v lsb_release >/dev/null 2>&1; then
    os_name=$(lsb_release -is)
    codename=$(lsb_release -c | awk '{print $2}')

    # Ubuntu 24.04 (noble) 及以上、或其他 OS，一律加上 --break-system-packages
    if [ "$os_name" = "Ubuntu" ]; then
        if [ "$codename" = "noble" ] || [ "$codename" = "oracular" ] || [ "$codename" = "plucky" ]; then
            PIP_OPTIONS="--break-system-packages"
            echo "Detected Ubuntu ($codename), use --break-system-packages option"
        else
            echo "Detected Ubuntu ($codename), no option needed"
        fi
    else
        PIP_OPTIONS="--break-system-packages"
        echo "Detected $os_name ($codename), use --break-system-packages option"
    fi
else
    echo "Unknown OS, use --break-system-packages by default"
    PIP_OPTIONS="--break-system-packages"
fi

pip3 install /usr/share/cix/pypi/libnoe-*-py3-none-manylinux2014_aarch64.whl $PIP_OPTIONS

exit 0
EOF
            chmod a+x $build_deb_dir/DEBIAN/postinst
            create_cix_deb "$pkg_Name"
            record_compile "${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name}"
        fi

        #isp-umd
        pkg_Name="cix-isp-umd"
        if [[ -e "${PATH_OUT_PRIVATE_DEB_PACKAGES}/${pkg_Name}" ]]; then
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
            cat > $build_deb_dir/etc/systemd/system/isp-daemon.service <<- 'EOF'
[Unit]
Description=ISP Daemon
After=network.target

[Service]
WorkingDirectory=/usr/share/cix/bin
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
            cat > $build_deb_dir/DEBIAN/postinst <<- 'EOF'
#!/bin/sh
set -e

# Enable the service to start isp_app on boot
systemctl enable isp-daemon.service || true

exit 0
EOF
            create_cix_deb "$pkg_Name"
        fi
    fi

    #gpu
    build_gpu_umd_prideb cix-gpu-umd

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
