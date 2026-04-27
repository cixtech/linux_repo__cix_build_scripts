#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#
#

# help function, it display the usage of this script.
help() {
cat << EOF
    This script is executed after "source build/envsetup.sh" and "lunch".

    usage:
        `basename $0` <option>

        options:
           -h/--help               display this help info
           -j[<num>]               specify the number of parallel jobs
           memoryconfig            memory_config will be built
           bootloader              bootloader will be built
           kernel                  kernel, include the kernel modules and device tree files will be built
           rtlwifi                 rtl wlan.ko, the rtl wifi driver will be compiled
           npu                     the NPU driver will be built
           gpu                     GPU driver mali_kbase.ko will be built
           isp                     ISP driver armcb_isp.ko will be built
           vpu                     VPU driver will be built
           dtboimage               dtbo images will be built
           bootimage               boot.img will be built
           vendorbootimage         vendor_boot.img will be built
           vendorimage             vendor.img will be built
           -c                      use clean build for kernel, not incremental build
           -b[board_name]          specify the board:
                                   -bfpga    Android image with FPGA board will be built
                                   -bevb     Android image with merak board will be built
                                   -bbatura  Android image with batura board will be built
                                   -bemu     Android image with EMU will be built
           -r[root_fs]             specify the rootfs:
                                   -rFULL Android image that boots to UI will be built
                                   -rVTS  Android VTS version image will be built
           -g[gpu_mode]            specify gpu mode:
                                   -gnomali Andorid image with nomali will be built
                                   -gswr    enable software rendering without gpu
                                   not set  Android image with mali will be built
           -d[vkms]                enbale vkms or not:
                                   -dvkms   Adnroid image with vkms will be built
                                   not set  Android image without vkms will be built
           -m[boot_mode]           specify Android boot mode:
                                   -mnvme   Android NVME boot
                                   not set  Android DDR boot
           -s[debug]               specify Android Debug Switch:
                                   -debug  Android Debug version
                                   not set  Android Release version
           -t[tee_mode]            specify tee mode:
                                   -tnone   disable tee and related security features
                                   -toptee  enable optee
           -k[docker_mode]         build docker mode:
                                   -knone   disable build super image for docker
                                   -kdocker  enable build super image for docker

    an example to build the whole system with maximum parallel jobs as below:
        `basename $0` -j

EOF

exit;
}

# handle special args, now it is used to handle the option for make parallel jobs option(-j).
# the number after "-j" is the jobs in parallel, if no number after -j, use the max jobs in parallel.
# kernel now can't be controlled from this script, so by default use the max jobs in parallel to compile.
handle_special_arg()
{
    # options other than -j are all illegal
    local jobs;
    if [ ${1:0:2} = "-j" ]; then
        jobs=${1:2};
        if [ -z ${jobs} ]; then                                                # just -j option provided
            parallel_option="-j";
        else
            if [[ ${jobs} =~ ^[0-9]+$ ]] && [ ${jobs} -gt 0 ]; then           # integer bigger than 0 after -j
                 parallel_option="-j${jobs}";
            else
                echo invalid -j parameter;
                exit;
            fi
        fi
    elif [ ${1:0:2} = "-b" ]; then
        board_name=${1:2};
    elif [ ${1:0:2} = "-r" ]; then
        root_fs=${1:2};
        export CIX_ANDROID_ROOT_FS=${root_fs};
    elif [ ${1:0:2} = "-g" ]; then
        gpu_mode=${1:2};
        if [ -z ${gpu_mode} ]; then
            echo build with default mali gpu;
        else
            if [ "${gpu_mode}" == "nomali" ]; then
                export CIX_GPU_NO_MALI=${gpu_mode};
            elif [ "${gpu_mode}" == "swr" ]; then
                export CIX_ENABLE_SWR=${gpu_mode};
            else
                echo build with default mali gpu;
            fi
        fi
    elif [ ${1:0:2} = "-d" ]; then
        vkms=${1:2};
        export CIX_ENABLE_VKMS=${vkms};
    elif [ ${1:0:2} = "-m" ]; then
        bootmode=${1:2};
        export CIX_ANDROID_BOOT=${bootmode};
    elif [ ${1:0:2} = "-s" ]; then
        debug=${1:2};
        export CIX_ANDROID_BUILD_MODE=${debug};
        echo $CIX_ANDROID_BUILD_MODE;
    elif [ ${1:0:2} = "-t" ]; then
        teemode=${1:2};
        export CIX_TEE_MODE=${teemode};
    elif [ ${1:0:2} = "-k" ]; then
        dockermode=${1:2};
        export CIX_DOCKER_MODE=${dockermode};
    else
        echo Unknown option: ${1};
        help;
    fi
}

# check whether the build product and build mode is selected
if [ -z ${OUT} ] || [ -z ${TARGET_PRODUCT} ]; then
    help;
fi

if [ ! -d "$OUT/images" ];then
    mkdir -p $OUT/images
fi

# global variables
build_android_flag=0
build_whole_android_flag=0
build_memory_config=""
build_bootloader=""
build_kernel=""
build_kernel_modules=""
build_kernel_dts=""
build_kernel_oot_module_flag=0
build_rtlwifi=""
build_npu=""
build_gpu=""
build_isp=""
build_vpu=""
build_bootimage=""
build_vendorbootimage=""
build_dtboimage=""
build_vendorimage=""
parallel_option=""
clean_build=0
skip_config_or_clean=0
CIX_ANDROID_BUILD_MODE=release

export CIX_ANDROID_BOOT=nvme
export CIX_ANDROID_ROOT_FS=FULL

if [ ${TARGET_PRODUCT} == "sky1_fpga" ]; then
export CIX_ANDROID_BOOT=ddr
export CIX_ANDROID_ROOT_FS=VTS
board_name=fpga
elif [ ${TARGET_PRODUCT} == "sky1_evb" ]; then
board_name=evb
elif [ ${TARGET_PRODUCT} == "sky1_batura" ]; then
board_name=batura
elif [ ${TARGET_PRODUCT} == "sky1_evb_car" ]; then
board_name=evb
elif [ ${TARGET_PRODUCT} == "sky1_orion_o6" ]; then
board_name=evb
fi
#default set tee mode as optee
export CIX_TEE_MODE=optee;

export CIX_DOCKER_MODE=none;

# process of the arguments
args=( "$@" )
for arg in ${args[*]} ; do
    case ${arg} in
        -h) help;;
        --help) help;;
        -c) clean_build=1;;
        memoryconfig) build_memory_config="memory_config";;
        bootloader) build_bootloader="bootloader";;
        kernel) build_kernel="${OUT}/kernel";
                    build_kernel_modules="KERNEL_MODULES";
                    build_kernel_dts="KERNEL_DTB";;
        rtlwifi) build_kernel_oot_module_flag=1
		    build_rtlwifi="rtlwifi";;
        npu) build_kernel_oot_module_flag=1
                    build_npu="npu";;
        gpu) build_kernel_oot_module_flag=1
                    build_gpu="gpu";;
        isp) build_kernel_oot_module_flag=1
                    build_isp="isp";;
        vpu) build_kernel_oot_module_flag=1
                    build_vpu="vpu";;
        bootimage) build_android_flag=1;
                    build_kernel="${OUT}/kernel";
                    build_bootimage="bootimage";;
        vendorbootimage) build_android_flag=1;
                    build_kernel_oot_module_flag=1;
                    build_kernel_dts="KERNEL_DTB";
                    build_kernel_modules="KERNEL_MODULES";
                    build_vendorbootimage="vendorbootimage";;
        dtboimage) build_android_flag=1;
                    build_kernel_dts="KERNEL_DTB";
                    build_dtboimage="dtboimage";;
        vendorimage) build_android_flag=1;
                    build_kernel_oot_module_flag=1;
                    build_kernel_modules="KERNEL_MODULES";
                    build_vendorimage="vendorimage";;
        android) build_android_flag=1;;
        *) handle_special_arg ${arg};;
    esac
done

if [ ${CIX_DOCKER_MODE} != "docker" ]; then
    if [ "${CIX_ANDROID_BUILD_MODE}" = "debug" ]; then
        ROOT_DIR=`pwd`
        KMD_DRV_DIR=$ROOT_DIR/vendor/cix_opensource/wlan/rtl_wlan_driver
        make -C "${KMD_DRV_DIR}" clean
    ./build-scripts/debug_switch.sh --all;
    else
    ./build-scripts/debug_switch.sh --none;
    fi
fi

# Build memory config
if [ -n "${build_memory_config}" ]; then
    $(dirname ${BASH_SOURCE[0]})/build-scripts/build-memory-config.sh -b ${board_name} -f android -p cix build
    exit
fi

# if bootloader and kernel not in arguments, all need to be made
if [ "${build_bootloader}" = "" ] && [ "${build_kernel}" = "" ] && \
        [ "${build_kernel_modules}" = "" ] && [ "${build_kernel_dts}" = "" ] && \
        [ ${build_kernel_oot_module_flag} -eq 0 ] && [ ${build_android_flag} -eq 0 ]; then
    if [ ${CIX_DOCKER_MODE} != "docker" ]; then
        ROOT_DIR=`pwd`
        build_bootloader="bootloader";
        build_kernel="${OUT}/kernel";
        build_kernel_modules="KERNEL_MODULES";
        build_kernel_dts="KERNEL_DTB";
    fi
    build_whole_android_flag=1
fi

# OOT kernel drivers need to be built with in-tree modules for kernel build
if [ -n "${build_kernel_modules}" ]; then
    build_npu="npu";
    build_rtlwifi="rtlwifi";
    build_gpu="gpu";
    build_isp="isp";
    build_vpu="vpu";
    build_kernel_oot_module_flag=1;
fi

build_gpu="gpu";
build_isp="";

product_makefile=`pwd`/`find device/cix -maxdepth 4 -name "${TARGET_PRODUCT}.mk"`;
product_path=${product_makefile%/*}
soc_path=${product_path%/*}
cix_git_path=${soc_path%/*}

sed -i 's/KMS="rkms"/KMS="lkms"/g' $(dirname ${BASH_SOURCE[0]})/build-scripts/parse_params.sh
# Build bootloader
if [ -n "${build_bootloader}" ]; then
    $(dirname ${BASH_SOURCE[0]})/build-scripts/build-android-bootloader.sh -b ${board_name} -f android -p cix -t ${CIX_TEE_MODE} build || exit
fi
sed -i 's/KMS="lkms"/KMS="rkms"/g' $(dirname ${BASH_SOURCE[0]})/build-scripts/parse_params.sh

# redirect standard input to /dev/null to avoid manually input in kernel configuration stage
if [ ${CIX_DOCKER_MODE} != "docker" ]; then
soc_path=${soc_path} product_path=${product_path} cix_git_path=${cix_git_path} clean_build=${clean_build} \
    make -C ./ -f ${cix_git_path}/common/build/Makefile ${parallel_option} \
    ${build_kernel} </dev/null || exit
fi
# in the execution of this script, if the kernel build env is cleaned or configured, do not trigger that again
if [ -n "${build_kernel}" ]; then
    skip_config_or_clean=1
fi

if [ -n "${build_kernel_modules}" ]; then
    soc_path=${soc_path} product_path=${product_path} cix_git_path=${cix_git_path} clean_build=${clean_build} \
        skip_config_or_clean=${skip_config_or_clean} make -C ./ -f ${cix_git_path}/common/build/Makefile ${parallel_option} \
        ${build_kernel_modules} </dev/null || exit
    skip_config_or_clean=1
fi

if [ -n "${build_kernel_dts}" ]; then
    soc_path=${soc_path} product_path=${product_path} cix_git_path=${cix_git_path} clean_build=${clean_build} \
        skip_config_or_clean=${skip_config_or_clean} make -C ./ -f ${cix_git_path}/common/build/Makefile ${parallel_option} \
        ${build_kernel_dts} </dev/null || exit
    skip_config_or_clean=1
fi

if [ ${build_kernel_oot_module_flag} -eq 1 ] || [ -n "${build_kernel_modules}" ]; then
    soc_path=${soc_path} product_path=${product_path} cix_git_path=${cix_git_path} clean_build=${clean_build} \
        skip_config_or_clean=${skip_config_or_clean} make -C ./ -f ${cix_git_path}/common/build/Makefile ${parallel_option} \
        ${build_rtlwifi} ${build_npu} ${build_gpu} ${build_isp} ${build_vpu} </dev/null || exit
fi

# rm uefi release Android.mk
if [ -f $ROOT_DIR/vendor/cix_opensource/uefi_release/edk2/RedfishPkg/Library/JsonLib/jansson/Android.mk ]; then
  rm $ROOT_DIR/vendor/cix_opensource/uefi_release/edk2/RedfishPkg/Library/JsonLib/jansson/Android.mk
fi

if [ ${build_android_flag} -eq 1 ] || [ ${build_whole_android_flag} -eq 1 ]; then
    # source envsetup.sh before building Android rootfs, the time spent on building bootloader/kernel
    # before this does not count in the final result
    source build/envsetup.sh
    android_version=$(get_build_var PLATFORM_SDK_VERSION)
    if [ ${android_version} -eq 33 ]; then
        ./vendor/cix_opensource/gpu/gralloc/configure
    fi
    if [ -n "${build_bootimage}" ] || [ ${build_whole_android_flag} -eq 1 ]; then
        rm -rf ${OUT}/boot.img
    fi
    make ${parallel_option} ${build_bootimage} ${build_vendorbootimage} ${build_dtboimage} ${build_vendorimage} || exit
fi

if [ ${board_name} == "fpga" ]; then
    echo "build fpga hex"
    ./tools/sw_tools_open/host/android_hex.sh
else
    echo "build evb"
    ./device/cix/common/tools/android_images_export.sh
fi

if [ ${CIX_DOCKER_MODE} == "docker" ]; then
    echo "make lpunpack..."
    make lpunpack
    TARGET_PRODUCT=`get_build_var TARGET_PRODUCT`
    BUILD_VARIANT=`get_build_var TARGET_BUILD_VARIANT`
    ANDROID_VERSION=`get_build_var PLATFORM_VERSION`
    PROJECT_TOP=`gettop`

    echo "pack android docker images: ${TARGET_PRODUCT}_${ANDROID_VERSION}_${BUILD_VARIANT}..."
    mkdir -p $PROJECT_TOP/IMAGES/
    cp $PROJECT_TOP/out/target/product/$TARGET_PRODUCT/images/super.img $PROJECT_TOP/IMAGES/

    cd $PROJECT_TOP/IMAGES/
    rm -rf super_img
    mkdir super_img

    simg2img super.img super.img.ext4
    lpunpack super.img.ext4 super_img/

    tar --use-compress-program=pigz -cvpf $TARGET_PRODUCT-$ANDROID_VERSION-$BUILD_VARIANT-super.img.tgz super_img
    cp $TARGET_PRODUCT-$ANDROID_VERSION-$BUILD_VARIANT-super.img.tgz $PROJECT_TOP/out/target/product/$TARGET_PRODUCT/images/
    cd $PROJECT_TOP
    rm -rf $PROJECT_TOP/IMAGES/
fi

