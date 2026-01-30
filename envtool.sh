
#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

GITHUB_EXT_URL="https://api.github.com/repos/cixtech/ext/releases"

PARALLEL_GROUP="all"
BUILD_MODE="release"
PLATFORM="cix"
FILESYSTEM="debian"
BUILDMUTTER="N"
KEY_TYPE="rsa3072_product"
KMS="rkms" #lkms, rkms
DRM="disable" #Digital Rights Management: disable, enable
SOC_TYPE="sky1_a0" #sky1_a0, sky1_b1
BOARD="evb" #emu, fpga, evb, crb, cloudbook, batura
TEE_TYPE="optee" #none, optee, trusty
DDR_MODEL="ddr-noc_arch_v0"
SMP="1"
ACPI="1"
ISO_INSTALLER="1"
NEXUS_SITE="customer" #sh: shanghai, zj: zhangjiang, wuh: wuhan, szv: suzhou, ksh: kunshan, wux: wuxi, [release: release, public: customer]
DEBIAN_MODE="1" #0: without debian, 1: gnome+xfce, 2: gnome, 3: xfce, 4: console, 5: openkylin 6: deepin, 7:openkylin-alpha, 8:kylin-v10
FASTBOOT_LOAD="disable" #disable, ddr, nvme, spi, usb
NETWORK="open" #internal, open
ROOT_FREE_SIZE="0" #add the root partition free size with unit K, default is 4G
SWAP_SIZE="21504" #define the swap partition size with unit M: 0 is no swap partition
DATA_SIZE="0" #define the data partition size with unit M: 0 is no data partition
DOCKER_MODE="none"
SECURE_STORAGE="none"
KMS_VERSION="1.0.2"
KMS_PROJECT_ID="sky1_a0_product_01"
AUTO_GUID="1" #0: fixed guid, 1: auto guid
SYSTEMD_TARGET="graphical" #graphical, multi-user
DT="evb" #dtb file in iso
CUSTOMER_HW_INFO="evb_p0" #customer hw information：evb_p0, radxa_p0, orange_pi_p0

SIGN_KEY="" #the key file for signature
SIGN_CERT="" #the cert file for signature

ENABLE_SQUASH_FS="false" #true or false
ENABLE_OVERLAY_FS="false" #true or false

RED=${RED-\e[31m}
NC=${NC-\e[0m}

EX_CUSTOMER="customer_linux"
EX_PROJECT="2025q3"
EX_VERSION="25q4_rc3.3"
EX_NEXUS_USER="svc.public"
EX_NEXUS_PASS="svc.public"
USERDATA_RESIZE="enable"

#show env params
function _showParams() {
    local root_free_size=$(($ROOT_FREE_SIZE / 1024 / 1024))
    local swap_size=$(($SWAP_SIZE / 1024))
    local data_size=$(($DATA_SIZE / 1024))
    echo -e "workspace:             \e[32m$PATH_ROOT\e[0m"
    echo -e "systemd target(-S):    \e[32m$SYSTEMD_TARGET\e[0m (graphical, multi-user)"
    echo -e "parallel group(-g):    \e[32m$PARALLEL_GROUP\e[0m (all, minimum, all-private)"
    echo -e "build mode(-d):        \e[32m$BUILD_MODE\e[0m (release, debug)"
    echo -e "platform(-p):          \e[32m$PLATFORM\e[0m (cix)"
    echo -e "file system(-f):       \e[32m$FILESYSTEM\e[0m (debian, android)"
    echo -e "mutter build(-q):      \e[32m$BUILDMUTTER\e[0m (Y:real build,N:download deb from nexus)"
    echo -e "key type(-k):          \e[32m$KEY_TYPE\e[0m (rsa3072_product, sm2_product, rsa3072_prototype, sm2_prototype)"
    echo -e "kms(-m):               \e[32m$KMS\e[0m (lkms, rkms)"
    echo -e "drm(-e):               \e[32m$DRM\e[0m (disable, enable)"
    echo -e "hardware soc(-h):      \e[32m$SOC_TYPE\e[0m (sky1_a0, sky1_b1)"
    echo -e "board(-b):             \e[32m$BOARD\e[0m (fpga, emu, evb, crb, cloudbook, batura)"
    echo -e "tee type(-t):          \e[32m$TEE_TYPE\e[0m (none, optee, trusty)"
    echo -e "secure storage(-T):    \e[32m$SECURE_STORAGE\e[0m (none, secure-storage)"
    echo -e "ddr model(-r):         \e[32m$DDR_MODEL\e[0m (axi-4G,ddr-noc_arch_v[0|1|2|...][-hash<128|512>][-ddrch<2|4>])"
    echo -e "smp(-s):               \e[32m$SMP\e[0m (0: not smp, 1: smp)"
    echo -e "acpi(-a):              \e[32m$ACPI\e[0m (0: not acpi, 1: acpi)"
    echo -e "iso(-i):               \e[32m$ISO_INSTALLER\e[0m (0: no iso, 1: generate iso disk)"
    echo -e "nexus(-x):             \e[32m$NEXUS_SITE\e[0m (sh: shanghai, zj: zhangjiang, wuh: wuhan, szv: suzhou, ksh: kunshan, wux: wuxi, [release: release, public: customer])"
    echo -e "os debian mode(-o):    \e[32m$DEBIAN_MODE\e[0m (0: without debian, 1: gnome+xfce, 4: console, 5: openkylin2.0-Release, 6:deepin, 7:openkylin-alpha, 8:kylin-v10)"
    echo -e "fastboot load(-l):     \e[32m$FASTBOOT_LOAD\e[0m (disable, ddr, nvme, spi)"
    echo -e "network(-w):           \e[32m$NETWORK\e[0m (internal, open)"
    echo -e "root free size(-R):    \e[32m$root_free_size\e[0m (add the root partition free size with unit G bytes)"
    echo -e "swap size(-W):         \e[32m$swap_size\e[0m (swap partition size with unit G bytes [0 is no swap])"
    echo -e "data size(-E):         \e[32m$data_size\e[0m (data partition size with unit G bytes [0 is no data])"
    echo -e "docker mode(-K):       \e[32m$DOCKER_MODE\e[0m (none, docker)"
    echo -e "kms version(-V):       \e[32m$KMS_VERSION\e[0m"
    echo -e "kms project id(-U):    \e[32m$KMS_PROJECT_ID\e[0m"
    echo -e "dt(-D):                \e[32m$DT\e[0m"
    echo -e "auto guid(-G):         \e[32m$AUTO_GUID\e[0m (0: fixed guid, 1: auto guid)"
    echo -e "sign key(-H):          \e[32m$SIGN_KEY\e[0m"
    echo -e "sign cert(-I):         \e[32m$SIGN_CERT\e[0m"
    echo -e "userdata resize(-u):   \e[32m$USERDATA_RESIZE\e[0m (disable, enable)"
    echo -e "squash fs(-Q):         \e[32m$ENABLE_SQUASH_FS\e[0m (true or false)"
    echo -e "overlay fs(-O):        \e[32m$ENABLE_OVERLAY_FS\e[0m (true or false), the data partition is required if true"
}

function download() {
    if [[ $# -gt 1 ]]; then
        repo artifact-dl "${1}" "${2}"
        return
    fi
}

function download_binary_files() {
    local NEXUS_URL=$(echo $1 | sed 's#/*$##')
    local CUSTOMER=$2
    local PROJECT=$3
    local TAG=$4
    local SAVE_DIR=$5
    local USERNAME=$6
    local PASSWORD=$7
    local NEXUS_CLI_FILE="${HOME}/.nexus-cli"
    local TEMP_FILE
    local total_files=0
    local current_file=0
    local CONF_FLAG=0
    # 创建一个临时文件
    TEMP_FILE=$(mktemp)

    if [ -f "${NEXUS_CLI_FILE}" ]; then
        mv ${NEXUS_CLI_FILE} ${NEXUS_CLI_FILE}.bak
        CONF_FLAG=1
    fi
    # 检查目录是否存在，如果不存在则创建
    if [ ! -d "$SAVE_DIR" ]; then
        mkdir -p "$SAVE_DIR"
    fi

    nexus3 login -U ${NEXUS_URL} -u ${USERNAME} -p ${PASSWORD} --no-x509_verify
    # 要下载的文件的URL
    nexus3 list ${CUSTOMER}/${PROJECT}/${TAG} 1>${TEMP_FILE}  2>/dev/null

    # 计算总文件数量
    total_files=$(wc -l < "${TEMP_FILE}")

    # 使用while循环读取文件列表并下载
    while read -r line
    do
        # 提取文件路径（不包括文件名）
        local FILE_PATH=$(dirname "${line}")
        local FILE_NAME=$(basename "${line}")
        # 完整的保存路径
        local FULL_SAVE_PATH=("${SAVE_DIR}/`echo "${FILE_PATH}" | cut -d '/' -f 3-`")
        # 检查并创建保存路径
        if [ ! -d "$FULL_SAVE_PATH" ]; then
            mkdir -p "$FULL_SAVE_PATH"
        fi
        if [ -f "${FULL_SAVE_PATH}/${FILE_NAME}" ] ; then
            file_md5=$(md5sum "${FULL_SAVE_PATH}/${FILE_NAME}" | awk '{print $1}')

            nexus_md5=$(curl -k -s -X GET -u "${USERNAME}:${PASSWORD}" "${NEXUS_URL}/service/rest/v1/search?repository=${CUSTOMER}&name=${line}" |jq -r '.items[0].assets[0].checksum.md5')

            if [ "$file_md5" = "$nexus_md5" ]; then
                echo "${FULL_SAVE_PATH}/${FILE_NAME} is same as artifact,won't  download"
            else
                #md5不同时，删除原文件，重新下载
                rm -f "${FULL_SAVE_PATH}/${FILE_NAME}"
                wget -O "${FULL_SAVE_PATH}/${FILE_NAME}"  --no-check-certificate --user=${USERNAME} --password=${PASSWORD} "${NEXUS_URL}/repository/${CUSTOMER}/${line}"
                echo "${FULL_SAVE_PATH}/${FILE_NAME}  downloaded"
            fi
         else
                # 使用wget下载文件，并保存到指定的目录和文件名
                wget -O  "${FULL_SAVE_PATH}/${FILE_NAME}"  --no-check-certificate --user=${USERNAME} --password=${PASSWORD} "${NEXUS_URL}/repository/${CUSTOMER}/${line}"
                echo "${FULL_SAVE_PATH}/${FILE_NAME}  downloaded"
        fi
        if [ $? -eq 0 ]; then
            current_file=$((current_file+1))
            # 计算并显示进度
            echo -ne "download file: ${current_file} , total ${total_files}\r"
        else
            echo -e "\033[31m failed \033[0m : Failed to download ${CUSTOMER}/${line}"
        fi
    done < "${TEMP_FILE}"

    # 删除临时文件
    rm "${TEMP_FILE}"

    if [ ${CONF_FLAG} -eq 1 ]; then
        mv  ${NEXUS_CLI_FILE}.bak ${NEXUS_CLI_FILE}
    fi

    # 对比下载文件的MD5
    MD5_LIST="${SAVE_DIR}/MD5_LIST.txt"
    local FULL_SAVE_PATH=${SAVE_DIR}

    # 检查MD5_LIST.txt文件是否存在
    if [ -f "$MD5_LIST" ]; then
        echo "${MD5_LIST} exist,checking MD5..."
        # 读取MD5_LIST.txt文件，并按行处理
        while read -r line; do
            # 提取文件路径和期望的MD5值
            FILE_PATH=${FULL_SAVE_PATH}/$(echo "$line" | awk '{print $1}')
            EXPECTED_MD5=$(echo "$line" | awk '{print $2}')

            # 检查文件是否存在
            if [ -f "$FILE_PATH" ]; then
                # 计算实际文件的MD5值
                ACTUAL_MD5=$(md5sum "$FILE_PATH" | awk '{print $1}')

                # 比较期望的MD5值和实际的MD5值
                if [ "$EXPECTED_MD5" != "$ACTUAL_MD5" ]; then
                    echo -e "\033[31m failed \033[0m : $FILE_PATH  MD5 mismatch. expect: $EXPECTED_MD5  Actual: $ACTUAL_MD5"
                else
                    echo " $FILE_PATH MD5 check pass"
                fi
            else
               echo -e "\033[31m failed \033[0m : file $FILE_PATH not exist"
            fi
        done < "$MD5_LIST"
    else
        echo -e "\033[31m failed \033[0m : file ${MD5_LIST} not exist"
    fi
}

function updateres() {
    cd "${PATH_ROOT}/build-scripts"
    local githubTag="$(git remote -v | grep "github.com")X"
    cd -
    if [[ "${githubTag}" != "X" ]]; then
        if [[ ! -e "${PATH_ROOT}/ext_7z" ]]; then
            mkdir "${PATH_ROOT}/ext_7z"
        fi
        curl ${GITHUB_EXT_URL} | jq ".[] | select(.tag_name == \"${EX_VERSION}\") | .assets" > "${PATH_ROOT}/ext_7z/result.json"
        cat "${PATH_ROOT}/ext_7z/result.json" | jq '.[].browser_download_url' | while read -r url; do
            url=$(echo $url | sed 's/^"\(.*\)"$/\1/')
            file="${PATH_ROOT}/ext_7z/$(basename ${url})"
            sha256_remote=$(cat "${PATH_ROOT}/ext_7z/result.json" | jq ".[] | select(.browser_download_url == \"${url}\") | .digest" | awk -F ":" '{print $2}' | awk -F '"' '{print $1}')
            for i in {1..10}; do
                sha256=""
                if [[ -e "${file}" ]]; then
                    sha256=$(sha256sum ${file} | awk '{print $1}')
                fi
                if [[ "${sha256}" == "${sha256_remote}" ]]; then
                    break
                else
                    echo "download $url -> ${file}"
                    wget -c -O "${file}" --no-check-certificate "${url}"
                    sleep 1
                fi
            done
        done
        if [[ -e "${PATH_ROOT}/ext_7z/cix_ext.7z.001" ]]; then
            cd "${PATH_ROOT}/ext_7z/"
            if [[ ! -e "${PATH_ROOT}/ext_7z/ext" ]]; then
                7z x cix_ext.7z.001
            fi
            if [[ -e "${PATH_ROOT}/ext_7z/ext" ]] && [[ ! -e "${PATH_ROOT}/ext" ]]; then
                mv "${PATH_ROOT}/ext_7z/ext" "${PATH_ROOT}/ext"
            fi
            cd -
        fi
        if [[ ! -e "${PATH_ROOT}/ext" ]]; then
            echo -e "${RED}Error: resources (ext) are absent. please retry this step.${NORMAL}"
            exit 1
        fi
    else
        local _nexus="$NEXUS_SITE"
        if [[ "${_nexus}" != "" ]]; then
            if [[ "${_nexus}" != "sh" ]]; then
                _nexus="${_nexus}-"
            else
                _nexus="zj-"
            fi
        fi
        download_binary_files "https://${_nexus}artifacts.cixtech.com" "${EX_CUSTOMER}" "${EX_PROJECT}" "${EX_VERSION}" "${PATH_ROOT}/ext" ${EX_NEXUS_USER} ${EX_NEXUS_PASS}
    fi
}

#show help
function help() {
    cat <<EOF

Run "help" for help with the build system itself.

Invoke ". ./build-scripts/envtool.sh" from your shell to add the following functions to your environment:
- help:       Show the help information.
              example: help
- newer_env:  install all bulding dependences
- download:   download some big images via the high-speed prefix
              example:
                      download <nexus url> <local path>
                      download "https://artifacts.cixcomputing.com/#browse/browse:debian12_dev_env:dl_debian%2Fdebian-12.2.0-arm64-DVD-1.iso" "./tmp"
- updateres:  update the binary resources from the nexus server for the external deliver customer
              example:
                      updateres
- cixgdb:     run the arm gdb, default param is cix kernel vmlinux
              example:
                      cixgdb
                      cixgdb <vmlinux file>
- addr2line:  show the line number of source from the address of cix kernel vmlinux
              example:
                      addr2line <address>
- debug:      enable the debug switches for kernel
              example: debug --kasan
                      debug --mte
                      debug --memleak
                      debug --deadlock
                      debug --kasan --mte
                      debug --all
- config:     set the parameters
              example: config -g all (lparallel will list all supported parallel groups)
                      config -d debug (release)
                      config -p cix 
                      config -f debian (android)
                      config -k sm2_product (rsa3072_product, sm2_product, rsa3072_prototype, sm2_prototype)
                      config -b fpga (emu, evb, crb, cloudbook, batura)
                      config -t none (optee, trusty)
                      config -r axi-4G (ddr-noc_arch_v[0|1|2|...][-hash<128|512>][-ddrch<2|4>])
                      config -s 0 (1); 0: not SMP, 1: SMP
                      config -a 0 (1); 0: not ACPI, 1: ACPI
                      config -d debug -p cix -f debian -k rsa3072 -b fpga -t optee -r axi-4G -s 1 -a 1
                      config -i 0 (1); 0: no iso installer, 1: make iso intaller
                      config -x sh (wuh, szv, ksh, wux); sh: shanghai, wuh: wuhan, szv: suzhou, ksh: kunshan, wux: wuxi
                      config -o 0 (1,4,5,6,7,8); 0: without debian, 1: gnome+xfce, 4: console, 5: openkylin, 6:deepin, 7:openkylin-alpha, 8:kylin-v10
                      config -P config the proxy for PC(not server)
                      config -N cancel the proxy of PC(not server)
                      config -M deliver mode(codereview, release-git, git)
- croot:      Changes directory to the top of the tree, or a subdirectory thereof.
- mgrep:      Grep on all repo manifest files (.repo/manifests/*.xml)
              example: mgrep gpu
- bgrep:      Grep on all building script files (build-scripts/*.sh)
              example: bgrep gpu
- lmodules:   List the building module list
              example: lmodules
- lparallel:  List the parallel building module list
              example: lparallel
- build:      Build module for build-scripts/build-xxx.sh (build xxx)
              example: build all
                      build bt wlan
- buildonly:  Build module for build-scripts/build-xxx.sh and ignore the dependences (buildonly xxx)
              example: buildonly all
                      buildonly bt wlan
- clean:      clean module for build-scripts/build-xxx.sh (clean xxx)
              example: clean all
                      clean bt wlan
- cleanonly:  clean module for build-scripts/build-xxx.sh and ignore the dependences (cleanonly xxx)
              example: cleanonly all
                      cleanonly bt wlan
- execute:      execute a command for a module
                example: execute build all
                         execute clean all
                         execute flash storage
- path2hex:   convert the path (includes all content) to the hex file
              path2hex path <hex>
              the hex file will be "output/hex/path.hex" if no hex file
              example: path2hex ./build-scripts <tmp.hex>
EOF
}

function newer_env() {
    local ver=$(cat /etc/issue | grep "Ubuntu" | awk '{print $2}' | awk -F "." '{print $1}')
    sudo groupadd messagebus
    sudo apt-get -y update
    sudo apt-get -y install lsb-release \
        apt-utils \
        autoconf \
        autopoint \
        bc \
        bison \
        build-essential \
        cpio \
        curl \
        device-tree-compiler \
        dosfstools \
        doxygen \
        fdisk \
        flex \
        gdisk \
        gettext-base \
        git \
        libssl-dev \
        m4 \
        mtools \
        pkg-config \
        python3 \
        python3-pyelftools \
        rsync \
        snapd \
        unzip \
        uuid-dev \
        wget \
        scons \
        perl \
        libwayland-dev \
        wayland-protocols \
        indent \
        libtool \
        dwarves \
        libarchive-tools \
        xorriso \
        jigdo-file \
        vim \
        sudo \
        parted \
        cmake \
        golang \
        libffi-dev \
        u-boot-tools \
        img2simg \
        android-sdk-libsparse-utils \
        libxcb-randr0 \
        libxcb-randr0-dev \
        libxcb-present-dev \
        libxau-dev \
        python3-mako \
        libglib2.0-dev-bin \
        binfmt-support \
        qemu \
        qemu-user-static \
        debootstrap \
        multistrap \
        debian-archive-keyring \
        ser2net \
        git-lfs \
        zstd \
        debhelper \
        jq \
        pigz \
        kmod \
        uuid-runtime \
        python3-docutils \
        texinfo \
        help2man \
        gawk \
        libtool-bin \
        libgtk-3-dev \
        tree \
        ninja-build \
        gettext \
        libasound2-dev \
        libsdl1.2-dev \
        libspice-protocol-dev \
        libspice-server-dev \
        libusb-1.0-0-dev \
        libusbredirhost-dev \
        acpica-tools \
        valgrind \
        virt-manager \
        qemu-system-x86 \
        libvirt-daemon-system \
        libvirt-clients \
        virtinst \
        libfdt-dev \
        alsa-utils \
        dracut

    PIP_ASSIST=""
    case "${ver}" in
        "24")
            sudo apt-get -y install \
                libncurses6 \
                libncurses6-dev \
                libtinfo6 \
                gcc-11 \
                g++-11
            sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100
            sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100
            sudo update-alternatives --install /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-11 100
            PIP_ASSIST="--break-system-packages"
            sudo apt-get -y install qemu-system qemu-utils
            sudo tee /etc/binfmt.d/qemu-aarch64.conf <<EOF
:qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:OC
EOF
            sudo systemctl restart systemd-binfmt
            ;;
        *)
            sudo apt-get -y install \
                libncurses5 \
                libncurses5-dev \
                libtinfo5 \
                python2 \
                python3-distutils
        ;;
    esac

    # yocto environment
    sudo apt-get -y install gawk \
        wget \
        git-core \
        diffstat \
        unzip \
        texinfo \
        gcc-multilib \
        build-essential \
        chrpath \
        socat \
        cpio \
        python3 \
        python3-pip \
        python3-pexpect \
        xz-utils \
        debianutils \
        iputils-ping \
        python3-git \
        python3-jinja2 \
        libegl1-mesa \
        libsdl1.2-dev \
        pylint3 \
        xterm
    sudo locale-gen en_US.UTF-8

    rm -rf get-pip.py*
    PYTHON_VERSION=$(python3 -c 'import sys; print(sys.version_info < (3, 9))')
    if [[ ${PYTHON_VERSION} == 'True' ]]; then
        wget https://bootstrap.pypa.io/pip/3.8/get-pip.py
    else
        wget https://bootstrap.pypa.io/get-pip.py
    fi
    python3 get-pip.py
    echo "y" | pip3 uninstall pyOpenSSL
    pip3 install --upgrade --force-reinstall 'requests==2.31.0' urllib3 'meson==1.4.0' 'ply==3.11' 'cryptography==44.0.2' 'cmake==3.24.2' 'docutils==0.18.1' openpyxl nexus3-cli launchpadlib pyOpenSSL mako pylint pyyaml

    # if [[ "${NEXUS_SITE}" != "customer" ]]; then
    #     if [[ ! -e "${HOME}/bin" ]]; then
    #         mkdir "${HOME}/bin"
    #     fi
    #     curl https://codereview.cixtech.com/static/repo > ~/bin/repo
    #     chmod 755 ~/bin/repo
    #     echo 'export PATH=~/bin:$PATH' >> ~/.bashrc
    #     source ~/.bashrc

    #     git config --global http.sslVerify false

    #     # case "${NEXUS_SITE}" in
    #     # ("wuh")
    #     #     git config --global lfs.url https://wuh-artifacts.cixtech.com/repository/gerrit-lfs/info/lfs
    #     #     git config --global lfs.pushurl https://artifacts.cixtech.com/repository/gerrit-lfs/info/lfs
    #     #     git config --global lfs.https://wuh-artifacts.cixtech.com/repository/gerrit-lfs/info/lfs.locksverify false
    #     #     ;;
    #     # ("szv")
    #     #     git config --global lfs.url https://szv-artifacts.cixtech.com/repository/gerrit-lfs/info/lfs
    #     #     git config --global lfs.pushurl https://artifacts.cixtech.com/repository/gerrit-lfs/info/lfs
    #     #     git config --global lfs.https://szv-artifacts.cixtech.com/repository/gerrit-lfs/info/lfs.locksverify false
    #     #     ;;
    #     # ("ksh")
    #     #     git config --global lfs.url https://ksh-artifacts.cixtech.com/repository/gerrit-lfs/info/lfs
    #     #     git config --global lfs.pushurl https://artifacts.cixtech.com/repository/gerrit-lfs/info/lfs
    #     #     git config --global lfs.https://ksh-artifacts.cixtech.com/repository/gerrit-lfs/info/lfs.locksverify false
    #     #     ;;
    #     # ("wux")
    #     #     git config --global lfs.url https://wux-artifacts.cixtech.com/repository/gerrit-lfs/info/lfs
    #     #     git config --global lfs.pushurl https://artifacts.cixtech.com/repository/gerrit-lfs/info/lfs
    #     #     git config --global lfs.https://wux-artifacts.cixtech.com/repository/gerrit-lfs/info/lfs.locksverify false
    #     #     ;;
    #     # (*)
    #     #     git config --global lfs.url https://artifacts.cixtech.com/repository/gerrit-lfs/info/lfs
    #     #     git config --global lfs.https://artifacts.cixtech.com/repository/gerrit-lfs/info/lfs.locksverify false
    #     #     ;;
    #     # esac
    # fi
}

function adapter_project() {
    # refer to: https://confluence.cixtech.com/pages/viewpage.action?pageId=58378001
    cd "${cd $PATH_ROOT}"
    curl -k -L -o enable_lfs https://codereview.cixtech.com/static/enable_lfs
    chmod 755 enable_lfs
    ./enable_lfs
    cd -
}

function millisec2time() {
    local ms=$((${1}%1000))
    local s=$((${1}/1000%60))
    local m=$((${1}/60000%60))
    local h=$((${1}/3600000))
    printf "%02d:%02d:%02d.%03d" $h $m $s $ms
}

function armrun() {
    local attach=""
    if [[ `uname -m` != "aarch64" ]]; then
        attach="${PATH_ROOT}/tools/gcc/arm-gnu-toolchain-12.3.rel1-x86_64-aarch64-none-linux-gnu/arm-gnu-toolchain-12.3.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-"
    fi
    ${attach}$@
}

function cixgdb() {
    if [[ $# -gt 0 ]]; then
        armrun "gdb" "$@"
    else
        if [[ ! -e "${PATH_ROOT}/linux/vmlinux" ]]; then
            echo "${PATH_ROOT}/linux/vmlinux does not exist, build kernel first."
        else
            armrun "gdb" "${PATH_ROOT}/linux/vmlinux"
        fi
    fi
}

function addr2line() {
    if [[ $# -gt 2 ]]; then
        armrun "addr2line" "$@"
    else
        if [[ ! -e "${PATH_ROOT}/linux/vmlinux" ]]; then
            echo "${PATH_ROOT}/linux/vmlinux does not exist, build kernel first."
        else
            armrun "addr2line" -e "${PATH_ROOT}/linux/vmlinux" "$@"
        fi
    fi
}

function debug() {
    "${PATH_ROOT}/build-scripts/debug_switch.sh" "$@"
}

function ramparser() {
    "${PATH_ROOT}/build-scripts/ramparser/ramparser.sh" "$@"
}

function config() {
    local _parallel_group=$PARALLEL_GROUP
    local _build_mode=$BUILD_MODE
    local _platform=$PLATFORM
    local _file_system=$FILESYSTEM
    local _build_mutter=$BUILDMUTTER
    local _key_type=$KEY_TYPE
    local _kms=$KMS
    local _drm=$DRM
    local _soc_type=$SOC_TYPE
    local _board=$BOARD
    local _tee_type=$TEE_TYPE
    local _secure_storage=$SECURE_STORAGE
    local _ddr_model=$DDR_MODEL
    local _smp=$SMP
    local _acpi=$ACPI
    local _iso=$ISO_INSTALLER
    local _nexus=$NEXUS_SITE
    local _debian_mode=$DEBIAN_MODE
    local _fastboot_load=$FASTBOOT_LOAD
    local _systemd_target=$SYSTEMD_TARGET
    local _network=$NETWORK
    local _root_free_size=$ROOT_FREE_SIZE
    local _swap_size=$SWAP_SIZE
    local _data_size=$DATA_SIZE
    local _notclear=0
    local _clear=0
    local _docker_mode=$DOCKER_MODE
    local _kms_version=$KMS_VERSION
    local _kms_project_id=$KMS_PROJECT_ID
    local _auto_guid=$AUTO_GUID
    local _dt=$DT
    local _userdata_resize=$USERDATA_RESIZE
    OPTIND=0
    while getopts "g:d:p:f:k:m:e:h:b:t:T:r:s:a:ni:x:o:l:w:R:W:K:q:PNS:U:V:G:D:C:E:H:I:u:Q:O:" opt; do
        case $opt in
        ("P")
            export http_proxy="http://shproxy.cixtech.com:3128"
            export https_proxy="http://shproxy.cixtech.com:3128"
            export ftp_proxy="http://shproxy.cixtech.com:3128"
            #export no_proxy="localhost,localhost:*,127.*,*.cixcomputing.com,*.cixtech.com,*.cixcomputing.cn,10.128.*"
            export no_proxy="127.0.0.1,repo.cixcomputing.com,codereview.cixtech.com,repo.cixcomputing.cn,10.128.0.0/16,10.134.0.0/16,gitmirror.cixtech.com,artifacts.cixtech.com,ksh-artifacts.cixtech.com"
            echo "config proxy-http_proxy:$http_proxy , no_proxy:$no_proxy"
            ;;
        ("N")
            unset http_proxy https_proxy tfp_proxy no_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY NO_PROXY
            ;;
        ("g") _parallel_group="$OPTARG" ;;
        ("d")
            _build_mode="$OPTARG"
            if [[ "$BUILD_MODE" != "$_build_mode" ]]; then
                _clear=1
            fi
            ;;
        ("p") _platform="$OPTARG" ;;
        ("f") _file_system="$OPTARG" ;;
        ("q") _build_mutter="$OPTARG" ;;
        ("k")
            _key_type="$OPTARG"
            if [[ "$KEY_TYPE" != "$_key_type" ]]; then
                _clear=1
            fi
            ;;
        ("m")
            _kms="$OPTARG"
            if [[ "$KMS" != "$_kms" ]]; then
                _clear=1
            fi
            ;;
        ("e") _drm="$OPTARG" ;;
        ("h")
            _soc_type="$OPTARG"
            if [[ "$SOC_TYPE" != "$_soc_type" ]]; then
                _clear=1
            fi
            ;;
        ("b")
            _board="$OPTARG"
            if [[ "$_board" == "fpga" ]]; then
                _ddr_model="axi-4G"
            elif [[ "$_board" == "emu" ]]; then
                _ddr_model="ddr-noc_arch_v0"
            else
                _smp="1"
                _ddr_model="ddr-noc_arch_v0"
            fi
            if [[ "$BOARD" != "$_board" ]]; then
                _clear=1
            fi
            ;;
        ("t")
            _tee_type="$OPTARG"
            if [[ "$TEE_TYPE" != "$_tee_type" ]]; then
                _clear=1
            fi
            ;;
        ("T") _secure_storage="$OPTARG"
            if [[ "$SECURE_STORAGE" != "$_secure_storage" ]]; then
                _clear=1
            fi
            ;;
        ("r")
            _ddr_model="$OPTARG"
            if [[ "$DDR_MODEL" != "$_ddr_model" ]]; then
                _clear=1
            fi
            ;;
        ("s")
            if [[ "$_board" == "fpga" ]] || [[ "$_board" == "emu" ]]
            then
                _smp="$OPTARG"
            else
                _smp="1"
            fi
            ;;
        ("a") _acpi="$OPTARG" ;;
        ("i") _iso="$OPTARG" ;;
        ("x") _nexus="$OPTARG" ;;
        ("o") _debian_mode="$OPTARG" ;;
        ("l") _fastboot_load="$OPTARG" ;;
        ("S") _systemd_target="$OPTARG" ;;
        ("w") _network="$OPTARG" ;;
        ("R") _root_free_size="$OPTARG" ;;
        ("W") _swap_size="$OPTARG" ;;
        ("E") _data_size="$OPTARG" ;;
        ("n") _notclear=1 ;;
        ("K") _docker_mode="$OPTARG" ;;
        ("U") _kms_project_id="$OPTARG" ;;
        ("V") _kms_version="$OPTARG" ;;
        ("G") _auto_guid="$OPTARG" ;;
        ("D") _dt="$OPTARG" ;;
        ("H")
            if [[ ${#OPTARG} -gt 2 ]]; then
                export SIGN_KEY=$(realpath --no-symlinks "$(echo "$OPTARG" | sed "s:\"::g")")
            else
                export SIGN_KEY=""
            fi
            ;;
        ("I")
            if [[ ${#OPTARG} -gt 2 ]]; then
                export SIGN_CERT=$(realpath --no-symlinks "$(echo "$OPTARG" | sed "s:\"::g")")
            else
                export SIGN_CERT=""
            fi
            ;;
        ("u") _userdata_resize="$OPTARG" ;;
        ("Q")
            export ENABLE_SQUASH_FS="$OPTARG"
            ;;
        ("O")
            export ENABLE_OVERLAY_FS="$OPTARG"
            if [[ "${_data_size}" == "0" ]]; then
                _data_size="1"
            fi
            ;;
        esac
    done
    if [[ $_root_free_size =~ ^[0-9]+$ ]]; then
        if [[ ${_root_free_size} -lt 256 ]]; then
            _root_free_size=$(($_root_free_size * 1024 * 1024))
            # if [[ ${_root_free_size} -gt 0 ]]; then
            #     _root_free_size=$(expr $_root_free_size \* 1024 \* 1024)
            # fi
        fi
    else
        _root_free_size=$((4 * 1024 * 1024))
    fi
    if [[ $_swap_size =~ ^[0-9]+$ ]]; then
        if [[ ${_swap_size} -lt 256 ]]; then
            _swap_size=$(($_swap_size * 1024))
            # if [[ ${_swap_size} -gt 0 ]]; then
            #     _swap_size=$(expr $_swap_size \* 1024)
            # fi
        fi
    else
        _swap_size="0"
    fi
    if [[ $_data_size =~ ^[0-9]+$ ]]; then
        if [[ ${_data_size} -lt 256 ]]; then
            _data_size=$(($_data_size * 1024))
        fi
    else
        _data_size="0"
    fi

    # if [[ $_notclear -eq 0 ]] && [[ $_clear -gt 0 ]]; then
    #     echo -n -e "\e[33mYour config is changed. Maybe you need clean this workspace(\e[32myes\e[33m will do clean, \e[32melse\e[33m will ignore all)\e[0m"
    #     read -p "$" value
    #     if [[ $value == "yes" ]] || [[ $value == "y" ]] || [[ $value == "YES" ]]
    #     then
    #         clean all
    #     fi
    #     echo "board:$BOARD"
    # fi

    if [[ "$PARALLEL_GROUP" != "$_parallel_group" ]]; then
        export PARALLEL_GROUP=$_parallel_group
    fi
    if [[ "$BUILD_MODE" != "$_build_mode" ]]; then
        export BUILD_MODE=$_build_mode
    fi
    if [[ "$PLATFORM" != "$_platform" ]]; then
        export PLATFORM=$_platform
    fi
    if [[ "$FILESYSTEM" != "$_file_system" ]]; then
        export FILESYSTEM=$_file_system
    fi
    if [[ "$BUILDMUTTER" != "$_build_mutter" ]]; then
        export BUILDMUTTER=$_build_mutter
    fi
    if [[ "$KEY_TYPE" != "$_key_type" ]]; then
        export KEY_TYPE=$_key_type
    fi
    if [[ "$KMS" != "$_kms" ]]; then
        export KMS=$_kms
    fi
    if [[ "$DRM" != "$_drm" ]]; then
        export DRM=$_drm
    fi
    if [[ "$SOC_TYPE" != "$_soc_type" ]]; then
        export SOC_TYPE=$_soc_type
    fi
    if [[ "$BOARD" != "$_board" ]]; then
        export BOARD=$_board
    fi
    if [[ "$TEE_TYPE" != "$_tee_type" ]]; then
        export TEE_TYPE=$_tee_type
    fi
    if [[ "$SECURE_STORAGE" != "$_secure_storage" ]]; then
        export SECURE_STORAGE=$_secure_storage
    fi
    if [[ "$DDR_MODEL" != "$_ddr_model" ]]; then
        export DDR_MODEL=$_ddr_model
    fi
    if [[ "$SMP" != "$_smp" ]]; then
        export SMP=$_smp
    fi
    if [[ "$ACPI" != "$_acpi" ]]; then
        export ACPI=$_acpi
    fi
    if [[ "$ISO_INSTALLER" != "$_iso" ]]; then
        export ISO_INSTALLER=$_iso
    fi
    if [[ "$NEXUS_SITE" != "$_nexus" ]]; then
        export NEXUS_SITE=$_nexus
    fi
    if [[ "$DEBIAN_MODE" != "$_debian_mode" ]]; then
        export DEBIAN_MODE=$_debian_mode
    fi
    if [[ "$FASTBOOT_LOAD" != "$_fastboot_load" ]]; then
        export FASTBOOT_LOAD=$_fastboot_load
    fi
    if [[ "$SYSTEMD_TARGET" != "$_systemd_target" ]]; then
        export SYSTEMD_TARGET=$_systemd_target
    fi
    if [[ "$NETWORK" != "$_network" ]]; then
        export NETWORK=$_network
    fi
    if [[ "$ROOT_FREE_SIZE" != "$_root_free_size" ]]; then
        export ROOT_FREE_SIZE=$_root_free_size
    fi
    if [[ "$SWAP_SIZE" != "$_swap_size" ]]; then
        export SWAP_SIZE=$_swap_size
    fi
    if [[ "$DATA_SIZE" != "$_data_size" ]]; then
        export DATA_SIZE=$_data_size
    fi
    if [[ "$DOCKER_MODE" != "$_docker_mode" ]]; then
        export DOCKER_MODE=$_docker_mode
    fi
    if [[ "$KMS_PROJECT_ID" != "${_kms_project_id}" ]]; then
        export KMS_PROJECT_ID=$_kms_project_id
    fi
    if [[ "$KMS_VERSION" != "${_kms_version}" ]]; then
        export KMS_VERSION=$_kms_version
    fi
    if [[ "$AUTO_GUID" != "$_auto_guid" ]]; then
        export AUTO_GUID=$_auto_guid
    fi
    if [[ "$DT" != "$_dt" ]]; then
        export DT=$_dt
    fi
    if [[ "$USERDATA_RESIZE" != "$_userdata_resize" ]]; then
        export USERDATA_RESIZE=$_userdata_resize
    fi
    echo "-g ${PARALLEL_GROUP} -d ${BUILD_MODE} -p ${PLATFORM} -q ${BUILDMUTTER} -f ${FILESYSTEM} -k ${KEY_TYPE} -m ${KMS} -h ${SOC_TYPE} -b ${BOARD} -t ${TEE_TYPE} -T ${SECURE_STORAGE} -r ${DDR_MODEL} -s ${SMP} -a ${ACPI} -i ${ISO_INSTALLER} -x ${NEXUS_SITE} -o ${DEBIAN_MODE} -l ${FASTBOOT_LOAD} -S ${SYSTEMD_TARGET} -e ${DRM} -w ${NETWORK} -R ${ROOT_FREE_SIZE} -W ${SWAP_SIZE} -E ${DATA_SIZE} -K ${DOCKER_MODE} -u ${USERDATA_RESIZE} -U ${KMS_PROJECT_ID} -V ${KMS_VERSION} -G ${AUTO_GUID} -D ${DT} -H \"${SIGN_KEY}\" -I \"${SIGN_CERT}\" -Q ${ENABLE_SQUASH_FS} -O ${ENABLE_OVERLAY_FS}" > "${PATH_ROOT}/build-scripts/.env.cix"
    _showParams
}

function gettop
{
    local TOPFILE=build-scripts/envtool.sh
    if [ -n "$TOP" -a -f "$TOP/$TOPFILE" ] ; then
        # The following circumlocution ensures we remove symlinks from TOP.
        (cd "$TOP"; PWD= /bin/pwd)
    else
        if [ -f $TOPFILE ] ; then
            # The following circumlocution (repeated below as well) ensures
            # that we record the true directory name and not one that is
            # faked up with symlink names.
            PWD= /bin/pwd
        else
            local HERE=$PWD
            local T=
            while [ \( ! \( -f $TOPFILE \) \) -a \( "$PWD" != "/" \) ]; do
                \cd ..
                T=`PWD= /bin/pwd -P`
            done
            \cd "$HERE"
            if [ -f "$T/$TOPFILE" ]; then
                echo "$T"
            fi
        fi
    fi
}

function croot()
{
    local T=$(gettop)
    if [ "$T" ]; then
        if [ "$1" ]; then
            \cd $(gettop)/$1
        else
            \cd $(gettop)
        fi
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

#find key string in repo manifests
function mgrep() {
    find "${PATH_ROOT}/.repo/manifests" -maxdepth 1 -name "*.xml" | xargs grep --color "$1"
}

#find key string in building scripts
function bgrep() {
    find "${PATH_ROOT}/build-scripts" -maxdepth 1 -name "*.sh" | xargs grep --color "$1"
}

#list the modules to build
function lmodules() {
    local replaceString=".sh"
    local modules=`find "${PATH_ROOT}/build-scripts" -maxdepth 1 -name "build-*.sh" | xargs echo`
    modules=`echo $modules | sed s/[[:space:]]//g | sed 's/\.sh/,/g'`
    #echo $modules
    OLD_IFS="$IFS"
    IFS=","
    arr=($modules)
    IFS="$OLD_IFS"
    len=${#arr[@]}
    for ((i=0;i<$len;i++))
    do
        s=${arr[$i]}
        arr[$i]=${s##*build-}
    done
    list=$(echo ${arr[@]} | tr ' ' '\n' | sort -n)
    declare -i i
    i=0
    for s in $list
    do
        printf "\033[33m%-30s\033[0m" $s
        i=$i+1
        if [[ $i -gt 5 ]]; then
            ret=""
            i=0
            printf "\n"
        fi
        #echo $s
    done
    if [[ $i -gt 0 ]]; then
        printf "\n"
    fi
}

function lparallel() {
    local replaceString=".config"
    local modules=`find "${PATH_ROOT}/build-scripts/config" -maxdepth 1 -name "*.config" | xargs echo`
    modules=`echo $modules | sed s/[[:space:]]//g | sed 's/\.config/,/g'`
    #echo $modules
    OLD_IFS="$IFS"
    IFS=","
    arr=($modules)
    IFS="$OLD_IFS"
    len=${#arr[@]}
    for ((i=0;i<$len;i++))
    do
        s=${arr[$i]}
        arr[$i]=${s##*/}
    done
    list=$(echo ${arr[@]} | tr ' ' '\n' | sort -n)
    declare -i i
    i=0
    for s in $list
    do
        printf "\033[33m%-30s\033[0m" $s
        i=$i+1
        if [[ $i -gt 5 ]]; then
            ret=""
            i=0
            printf "\n"
        fi
        #echo $s
    done
    if [[ $i -gt 0 ]]; then
        printf "\n"
    fi
}

#build module(s)
function build() {
    startTime=$(date +%s%3N)
    echo -n "" > "${PATH_ROOT}/.modules"
    echo -n "" > "${PATH_ROOT}/.modules_stastics"
    local CMD=""
    local _input=""
    local _param=""
    while [[ $# -gt 0 ]]; do
        case $1 in
        ("--help")
            shift
            if [[ -e "${PATH_ROOT}/build-scripts/build-$1.sh" ]]; then
                "${PATH_ROOT}/build-scripts/build-$1.sh" -H
            else
                echo -e "\e[31mmodule $1 does not exist\e[0m"
            fi
            return 0
            ;;
        ("--proxy")
            _param="${_param} -v"
            ;;
        ("-d")
            CMD="$DOCKER"
            ;;
        ("--disable-output-root")
            if [[ "$CMD" == "$DOCKER" ]]; then
                CMD="$CMD --disable-output-root"
            fi
            ;;
        ("-i")
            shift
            _input="-i $1"
            ;;
        (*)
            # if [[ "$1" == "parallel" ]] || [[ "$1" == "make" ]]; then
            #     _input="-i ${PARALLEL_GROUP}"
            # fi
            if [[ -e "${PATH_ROOT}/build-scripts/build-$1.sh" ]]; then
                $CMD "${PATH_ROOT}/build-scripts/build-$1.sh" ${_input} ${_param} -d $BUILD_MODE -p $PLATFORM -f $FILESYSTEM -h $SOC_TYPE -b $BOARD -k $KEY_TYPE -m $KMS -t $TEE_TYPE -T $SECURE_STORAGE -r $DDR_MODEL -s $SMP -a $ACPI -x $NEXUS_SITE -o $DEBIAN_MODE -l $FASTBOOT_LOAD -e $DRM -w $NETWORK -K $DOCKER_MODE -u $USERDATA_RESIZE -U $KMS_PROJECT_ID -V ${KMS_VERSION} -G ${AUTO_GUID} build
                ret=$?
                if [[ $ret -ne 0 ]]; then
                    return $ret
                fi
            else
                echo -e "\e[31mmodule $1 does not exist\e[0m"
            fi
            ;;
        esac
        shift
    done
    echo -e "\e[36mhandled modules:\e[33m"
    cat "${PATH_ROOT}/.modules_stastics" | sed "s/ /\n/g"
    echo -e "\e[0m"
    stopTime=$(date +%s%3N)
    echo "total elapsed time: $(millisec2time $(($stopTime - $startTime)))"
}

#buildonly module(s)
function buildonly() {
    startTime=$(date +%s%3N)
    echo -n "" > "${PATH_ROOT}/.modules"
    echo -n "" > "${PATH_ROOT}/.modules_stastics"
    local CMD=""
    local _input=""
    local _param=""
    while [[ $# -gt 0 ]]; do
        case $1 in
        ("--help")
            shift
            if [[ -e "${PATH_ROOT}/build-scripts/build-$1.sh" ]]; then
                "${PATH_ROOT}/build-scripts/build-$1.sh" -H
            else
                echo -e "\e[31mmodule $1 does not exist\e[0m"
            fi
            return 0
            ;;
        ("--proxy")
            _param="${_param} -v"
            ;;
        ("-d")
            CMD="$DOCKER"
            ;;
        ("--disable-output-root")
            if [[ "$CMD" == "$DOCKER" ]]; then
                CMD="$CMD --disable-output-root"
            fi
            ;;
        ("-i")
            shift
            _input="-i $1"
            ;;
        (*)
            # if [[ "$1" == "parallel" ]] || [[ "$1" == "make" ]]; then
            #     _input="-i ${PARALLEL_GROUP}"
            # fi
            if [[ -e "${PATH_ROOT}/build-scripts/build-$1.sh" ]]; then
                $CMD "${PATH_ROOT}/build-scripts/build-$1.sh" -M ${_input} ${_param} -d $BUILD_MODE -p $PLATFORM -f $FILESYSTEM -h $SOC_TYPE -b $BOARD -k $KEY_TYPE -m $KMS -t $TEE_TYPE -T $SECURE_STORAGE -r $DDR_MODEL -s $SMP -a $ACPI -x $NEXUS_SITE -o $DEBIAN_MODE -l $FASTBOOT_LOAD -e $DRM -w $NETWORK -K $DOCKER_MODE -u $USERDATA_RESIZE -U $KMS_PROJECT_ID -V ${KMS_VERSION} -G ${AUTO_GUID} build
                ret=$?
                if [[ $ret -ne 0 ]]; then
                    return $ret
                fi
            else
                echo -e "\e[31mmodule $1 does not exist\e[0m"
            fi
            ;;
        esac
        shift
    done
    echo -e "\e[36mhandled modules:\e[33m"
    cat "${PATH_ROOT}/.modules_stastics" | sed "s/ /\n/g"
    echo -e "\e[0m"
    stopTime=$(date +%s%3N)
    echo "total elapsed time: $(millisec2time $(($stopTime - $startTime)))"
}

#clean module(s)
function clean() {
    startTime=$(date +%s%3N)
    echo -n "" > "${PATH_ROOT}/.modules"
    echo -n "" > "${PATH_ROOT}/.modules_stastics"
    local CMD=""
    local _input=""
    local _param=""
    while [[ $# -gt 0 ]]; do
        case $1 in
        ("--help")
            shift
            if [[ -e "${PATH_ROOT}/build-scripts/build-$1.sh" ]]; then
                "${PATH_ROOT}/build-scripts/build-$1.sh" -H
            else
                echo -e "\e[31mmodule $1 does not exist\e[0m"
            fi
            return 0
            ;;
        ("--proxy")
            _param="${_param} -v"
            ;;
        ("-d")
            CMD="$DOCKER"
            ;;
        ("--disable-output-root")
            if [[ "$CMD" == "$DOCKER" ]]; then
                CMD="$CMD --disable-output-root"
            fi
            ;;
        ("-i")
            shift
            _input="-i $1"
            ;;
        (*)
            # if [[ "$1" == "parallel" ]] || [[ "$1" == "make" ]]; then
            #     _input="-i ${PARALLEL_GROUP}"
            # fi
            if [[ -e "${PATH_ROOT}/build-scripts/build-$1.sh" ]]; then
                $CMD "${PATH_ROOT}/build-scripts/build-$1.sh" ${_input} ${_param} -d $BUILD_MODE -p $PLATFORM -f $FILESYSTEM -h $SOC_TYPE -b $BOARD -k $KEY_TYPE -m $KMS -t $TEE_TYPE -T $SECURE_STORAGE -r $DDR_MODEL -s $SMP -a $ACPI -x $NEXUS_SITE -o $DEBIAN_MODE -l $FASTBOOT_LOAD -e $DRM -w $NETWORK -K $DOCKER_MODE -u $USERDATA_RESIZE -U $KMS_PROJECT_ID -V ${KMS_VERSION} -G ${AUTO_GUID} clean
                ret=$?
                if [[ $ret -ne 0 ]]; then
                    return $ret
                fi
            else
                echo -e "\e[31mmodule $1 does not exist\e[0m"
            fi
            ;;
        esac
        shift
    done
    echo -e "\e[36mhandled modules:\e[33m"
    cat "${PATH_ROOT}/.modules_stastics" | sed "s/ /\n/g"
    echo -e "\e[0m"
    stopTime=$(date +%s%3N)
    echo "total elapsed time: $(millisec2time $(($stopTime - $startTime)))"
}

#cleanonly module(s)
function cleanonly() {
    startTime=$(date +%s%3N)
    echo -n "" > "${PATH_ROOT}/.modules"
    echo -n "" > "${PATH_ROOT}/.modules_stastics"
    local CMD=""
    local _input=""
    local _param=""
    while [[ $# -gt 0 ]]; do
        case $1 in
        ("--help")
            shift
            if [[ -e "${PATH_ROOT}/build-scripts/build-$1.sh" ]]; then
                "${PATH_ROOT}/build-scripts/build-$1.sh" -H
            else
                echo -e "\e[31mmodule $1 does not exist\e[0m"
            fi
            return 0
            ;;
        ("--proxy")
            _param="${_param} -v"
            ;;
        ("-d")
            CMD="$DOCKER"
            ;;
        ("--disable-output-root")
            if [[ "$CMD" == "$DOCKER" ]]; then
                CMD="$CMD --disable-output-root"
            fi
            ;;
        ("-i")
            shift
            _input="-i $1"
            ;;
        (*)
            # if [[ "$1" == "parallel" ]] || [[ "$1" == "make" ]]; then
            #     _input="-i ${PARALLEL_GROUP}"
            # fi
            if [[ -e "${PATH_ROOT}/build-scripts/build-$1.sh" ]]; then
                $CMD "${PATH_ROOT}/build-scripts/build-$1.sh" -M ${_input} ${_param} -d $BUILD_MODE -p $PLATFORM -f $FILESYSTEM -h $SOC_TYPE -b $BOARD -k $KEY_TYPE -m $KMS -t $TEE_TYPE -T $SECURE_STORAGE -r $DDR_MODEL -s $SMP -a $ACPI -x $NEXUS_SITE -o $DEBIAN_MODE -l $FASTBOOT_LOAD -e $DRM -w $NETWORK -K $DOCKER_MODE -U $KMS_PROJECT_ID -V ${KMS_VERSION} -G ${AUTO_GUID} clean
                ret=$?
                if [[ $ret -ne 0 ]]; then
                    return $ret
                fi
            else
                echo -e "\e[31mmodule $1 does not exist\e[0m"
            fi
            ;;
        esac
        shift
    done
    echo -e "\e[36mhandled modules:\e[33m"
    cat "${PATH_ROOT}/.modules_stastics" | sed "s/ /\n/g"
    echo -e "\e[0m"
    stopTime=$(date +%s%3N)
    echo "total elapsed time: $(millisec2time $(($stopTime - $startTime)))"
}

#execute a command
function execute() {
    local CMD=""
    local _input=""
    local _param=""
    while [[ $# -gt 0 ]]; do
        case $1 in
        ("--help")
            shift
            if [[ -e "${PATH_ROOT}/build-scripts/build-$1.sh" ]]; then
                "${PATH_ROOT}/build-scripts/build-$1.sh" -H
            else
                echo -e "\e[31mmodule $1 does not exist\e[0m"
            fi
            return 0
            ;;
        ("--proxy")
            _param="${_param} -v"
            ;;
        ("-d")
            CMD="$DOCKER"
            ;;
        ("--disable-output-root")
            if [[ "$CMD" == "$DOCKER" ]]; then
                CMD="$CMD --disable-output-root"
            fi
            ;;
        ("-i")
            shift
            _input="-i $1"
            ;;
        (*)
            # if [[ "$2" == "parallel" ]] || [[ "$2" == "make" ]]; then
            #     _input="-i ${PARALLEL_GROUP}"
            # fi
            if [[ -e "${PATH_ROOT}/build-scripts/build-$2.sh" ]]; then
                $CMD "${PATH_ROOT}/build-scripts/build-$2.sh" -M ${_input} ${_param} -d $BUILD_MODE -p $PLATFORM -f $FILESYSTEM -h $SOC_TYPE -b $BOARD -k $KEY_TYPE -m $KMS -t $TEE_TYPE -T $SECURE_STORAGE -r $DDR_MODEL -s $SMP -a $ACPI -x $NEXUS_SITE -o $DEBIAN_MODE -l $FASTBOOT_LOAD -e $DRM -w $NETWORK -K $DOCKER_MODE -u $USERDATA_RESIZE -U $KMS_PROJECT_ID -V ${KMS_VERSION} -G ${AUTO_GUID} $1
                ret=$?
                if [[ $ret -ne 0 ]]; then
                    return $ret
                fi
            else
                echo -e "\e[31mmodule $2 does not exist\e[0m"
            fi
            shift
        esac
        shift
    done
}

#path to hex
function path2hex() {
    if [[ $# -lt 2 ]]; then
        echo path2hex [path] [output] [ddrmodel] [offset]
        return
    fi
    if [[ $# -gt 2 ]]; then
        ddrmodel=$3
    else
        ddrmodel="axi-4G"
    fi
    if [[ $# -gt 3 ]]; then
        offset=$4
    else
        offset=0
    fi
    startTime=$(date +%s%3N)
    bash "${PATH_ROOT}/tools/sw_tools_open/host/path_hex/path2hex.sh" "$1" "$2" "$ddrmodel" "$offset"
    stopTime=$(date +%s%3N)
    echo "total elapsed time: $(millisec2time $(($stopTime - $startTime)))"
}

#diff two directories
function diffpath() {
    local pathSrc=$1
    local pathDst=$2
    for file in "${pathSrc}"/*; do
        local bn=$(basename ${file})
        if [[ -f "${file}" ]]; then
            if [[ ! -e "${pathDst}/${bn}" ]]; then
                 echo "${bn}" does not exist in ${pathDst}
            elif [[ ! -f "${pathDst}/${bn}" ]]; then
                echo "${bn}" is not as a file in ${pathDst}
            fi
        elif [[ -d "${file}" ]]; then
            diffpath "${file}" "${pathDst}/${bn}"
        fi
    done
    for file in "${pathDst}"/*; do
        local bn=$(basename ${file})
        if [[ -f "${file}" ]]; then
            if [[ ! -e "${pathSrc}/${bn}" ]]; then
                 echo "${bn}" does not exist in ${pathSrc}
            elif [[ ! -f "${pathSrc}/${bn}" ]]; then
                echo "${bn}" is not as a file in ${pathSrc}
            fi
        elif [[ -d "${file}" ]]; then
            diffpath "${pathSrc}/${bn}" "${file}"
        fi
    done
}

SOURCE="${BASH_SOURCE[0]:-$0}";
while [ -h "$SOURCE" ]; do
    PATH_ROOT="$( cd "$( dirname "$SOURCE" )" >/dev/null && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$PATH_ROOT/$SOURCE"
done
PATH_ROOT="$( cd "$( dirname "$SOURCE/" )/../" >/dev/null && pwd )"
DOCKER="${PATH_ROOT}/build-scripts/docker.sh"

# switch working area to the project ROOT
cd $PATH_ROOT

source "${PATH_ROOT}/build-scripts/check_dep.sh"

#_showParams
if [[ -e "${PATH_ROOT}/build-scripts/.env.cix" ]]; then
    config -n $(cat "${PATH_ROOT}/build-scripts/.env.cix")
else
    config -n
fi

export PARALLEL_GROUP=$PARALLEL_GROUP
export BUILD_MODE=$BUILD_MODE
export PATH_ROOT=$PATH_ROOT
export PLATFORM=$PLATFORM
export FILESYSTEM=$FILESYSTEM
export BUILDMUTTER=$BUILDMUTTER
export KEY_TYPE=$KEY_TYPE
export KMS=$KMS
export DRM=$DRM
export SOC_TYPE=$SOC_TYPE
export BOARD=$BOARD
export TEE_TYPE=$TEE_TYPE
export SECURE_STORAGE=$SECURE_STORAGE
export DDR_MODEL=$DDR_MODEL
export SMP=$SMP
export ACPI=$ACPI
export ISO_INSTALLER=$ISO_INSTALLER
export NEXUS_SITE=$NEXUS_SITE
export DEBIAN_MODE=$DEBIAN_MODE
export FASTBOOT_LOAD=$FASTBOOT_LOAD
export SYSTEMD_TARGET=$SYSTEMD_TARGET
export DOCKER=$DOCKER
export NETWORK=$NETWORK
export ROOT_FREE_SIZE=$ROOT_FREE_SIZE
export SWAP_SIZE=$SWAP_SIZE
export DATA_SIZE=$DATA_SIZE
export DT=$DT

export EX_CUSTOMER=$EX_CUSTOMER
export EX_PROJECT=$EX_PROJECT
export EX_VERSION=$EX_VERSION
export EX_NEXUS_USER=$EX_NEXUS_USER
export EX_NEXUS_PASS=$EX_NEXUS_PASS
export DOCKER_MODE=$DOCKER_MODE
export USERDATA_RESIZE=$USERDATA_RESIZE
export KMS_PROJECT_ID=$KMS_PROJECT_ID
export KMS_VERSION=${KMS_VERSION}
export AUTO_GUID=${AUTO_GUID}

export SIGN_KEY=${SIGN_KEY:-}
export SIGN_CERT=${SIGN_CERT:-}

export ENABLE_SQUASH_FS=${ENABLE_SQUASH_FS}
export ENABLE_OVERLAY_FS=${ENABLE_OVERLAY_FS}
