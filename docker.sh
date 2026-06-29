#!/bin/bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

# docker support running the arm app
# if [[ "$(dpkg -l | grep qemu-user-static)" == "" ]]; then
#     sudo apt-get -y install qemu-user-static binfmt-support
# fi
# docker run --rm --privileged multiarch/qemu-user-static --reset -p yes > /dev/null

SCRIPT_DIR="$(realpath --no-symlinks "$(dirname "${BASH_SOURCE[0]}")")"
WORK_DIR="$(dirname "${SCRIPT_DIR}")" #path to the directory into which TC stack is cloned

BLUE="\e[94m"
YELLOW="\e[33m"
RED="\e[31m"
NC="\e[0m"

#CIX_DOCKER="cix-u20-1.1.3"
#CIX_DOCKER="cix-u22-1.0.5"
#CIX_DOCKER="cix-u24-1.0.2"
#CIX_DOCKER_BASE="docker-harbor-pull.cixtech.com/cix_builder/cix"

CIX_DOCKER="20260519-01"
CIX_DOCKER_BASE="docker-harbor-pull.cixtech.com/cix-buildenv/cix-base"

CIX_DOCKER_URL="${CIX_DOCKER_BASE}:${CIX_DOCKER}"

docker_info=`which docker`
if [[ "$docker_info" == "" ]]; then
    echo -e "${RED}please install docker first.${NC}"
    exit 1
fi

function replace_line_if_exist() {
    local src=$1
    local dst=$2
    local file=$3

    if [[ -e "$file" ]]; then
        set +E
        local res=`grep -n "${src}" "${file}"`
        #echo "res:$res"
        if [[ ${#res} -gt 0 ]]; then
            line=`echo "${res}" | cut -d ":" -f 1`
        fi
        set -E
        #echo "line: $line"
        if [[ $line -gt 0 ]]; then
            sed -i "${line}c${dst}" "${file}"
        fi
    fi
}

function new_docker() {
    echo "create a new docker with the docker script: ${WORK_DIR}/docker/Dockerfile"
    docker build -t docker-harbor.cixtech.com/cix-buildenv/cix-base:${CIX_DOCKER} ${SCRIPT_DIR}/docker

    #docker build -t cix:cix-docker $SCRIPT_DIR/docker
    #docker tag cix:cix-docker docker-harbor.cixtech.com/cix_builder/cix:$CIX_DOCKER
    #docker push docker-harbor.cixtech.com/cix_builder/cix:${CIX_DOCKER}
    # docker push docker-harbor.cixtech.com/cix-buildenv22.04:${CIX_DOCKER}

    # docker run -it cix:cix-docker /bin/bash &
    # local containerID=`docker ps | grep "cix:cix-docker" | awk '{print $1}'`
    # if [[ "${containerID}" != "" ]]; then
    #     if [[ ! -e "$HOME/dl/docker" ]]; then
    #         mkdir -p $HOME/dl/docker
    #     fi
    #     docker export -o $HOME/dl/docker/cix-docker.tar ${containerID}
    #     docker rmi ${containerID} -f
    #     cd $HOME/dl/docker/
    #     tar -czf cix-docker.tgz ./cix-docker.tar
    #     cd -
    # fi
}

function save_docker() {
    local path_out
    case "$FILESYSTEM" in
    ("android")
        if [[ -z "$TARGET_PRODUCT" ]]; then
            echo -e "TARGET_PRODUCT must be set when filesystem is android"
            echo -e "Please run 'source build/envsetup.sh' and 'lunch'"
            exit 1
        fi
        path_out="${PATH_ROOT}/out/target/product/$TARGET_PRODUCT/"
        ;;
    (*)
        path_out="${PATH_ROOT}/output/${PLATFORM}_${BOARD}"
        ;;
    esac

    echo "save the docker image to a tgz file"
    docker save -o ${path_out}/mirror/cix-docker.tgz ${CIX_DOCKER_URL}
    # local containerID=$(docker ps -a | grep cix-container | head -n 1 | awk '{print $1}')
    # if [[ "${containerID}" == "" ]]; then
    #     docker run -d --name cix-container ${CIX_DOCKER_URL} || true
    #     containerID=$(docker ps -a | grep cix-container | head -n 1 | awk '{print $1}')
    # fi
    # echo "containerID: ${containerID}, path_out: ${path_out}/mirror/cix-docker.tgz"
    # if [[ "${containerID}" != "" ]]; then
    #     if [[ ! -e "${path_out}/mirror" ]]; then
    #         mkdir -p "${path_out}/mirror"
    #     fi
    #     docker export -o "${path_out}/mirror/cix-docker.tar" ${containerID}
    #     docker rm ${containerID} -f
    #     cd "${path_out}/mirror"
    #     tar -czf cix-docker.tgz ./cix-docker.tar
    #     rm -f ./cix-docker.tar
    #     cd -
    # else
    #     echo -e "${RED}container ${CIX_DOCKER_URL} does not exist.${NC}"
    # fi
}

if [[ $# > 0 && "$1" == "--new" ]]; then
    new_docker
    exit 0
fi

if [[ $# > 0 && "$1" == "--save" ]]; then
    save_docker
    echo -e "${NC}"
    exit 0
fi

if [[ "$(docker images | grep "${CIX_DOCKER}" | grep "${CIX_DOCKER_BASE}")" == "" ]]; then
    echo "docker ${CIX_DOCKER_URL} does not exist, run it first"
    if [[ "${NEXUS_SITE}" == "customer" ]] && [[ ! -e "${PATH_ROOT}/ext/mirror/cix-docker.tgz" ]]; then
        if [[ ! -e "${PATH_ROOT}/ext/mirror" ]]; then
            mkdir -p "${PATH_ROOT}/ext/mirror"
        fi
        nexus_md5=$(curl -k -s -X GET -u "${EX_NEXUS_USER}:${EX_NEXUS_PASS}" "https://${NEXUS_SITE}-artifacts.cixtech.com/service/rest/v1/search?repository=docker_image&name=${CIX_DOCKER}%2Fcix-base.tgz" | jq -r '.items[0].assets[0].checksum.md5')
        file_md5=""
        if [[ -e "${PATH_ROOT}/ext/mirror/cix-docker.tgz.md5" ]]; then
            file_md5=$(cat "${PATH_ROOT}/ext/mirror/cix-docker.tgz.md5")
        fi
        if [[ "${file_md5}" != "${nexus_md5}" ]]; then
            echo "${nexus_md5}" > "${PATH_ROOT}/ext/mirror/cix-docker.tgz.md5"
            wget -O "${PATH_ROOT}/ext/mirror/cix-docker.tgz"  --no-check-certificate --user=${EX_NEXUS_USER} --password=${EX_NEXUS_PASS} "https://${NEXUS_SITE}-artifacts.cixtech.com/repository/docker_image/${CIX_DOCKER}%2Fcix-base.tgz"
        fi
    fi
    if [[ -e "${PATH_ROOT}/ext/mirror/cix-docker.tgz" ]]; then
        docker load -i "${PATH_ROOT}/ext/mirror/cix-docker.tgz"
    else
        echo "start docker with the docker server (${CIX_DOCKER_URL})"
        docker pull ${CIX_DOCKER_URL}
    fi
else
    echo "docker ${CIX_DOCKER_URL} exists."
fi

replace_line_if_exist "FROM docker" "FROM ${CIX_DOCKER_URL}" "${SCRIPT_DIR}/docker_user/Dockerfile"

if [[ "$(docker images 2>/dev/null | grep "${USER}_${CIX_DOCKER}")" == "" ]]; then
    docker build --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" --build-arg CUSTOMER="${USER}" -t cix:${USER}_${CIX_DOCKER} ${SCRIPT_DIR}/docker_user
fi

CIX_ANDROID_BUILD_MODE=${CIX_ANDROID_BUILD_MODE:-}
CIX_ANDROID_BOOT=${CIX_ANDROID_BOOT:-}
env_opts=" -e PLATFORM=$PLATFORM \
        -e FILESYSTEM=$FILESYSTEM \
        -e BUILD_MODE=$BUILD_MODE \
        -e CIX_ANDROID_BOOT=$CIX_ANDROID_BOOT \
        -e CIX_ANDROID_BUILD_MODE=$CIX_ANDROID_BUILD_MODE \
        -e SOC_TYPE=$SOC_TYPE \
        -e BOARD=$BOARD \
        -e KEY_TYPE=$KEY_TYPE \
        -e DRM=$DRM \
        -e TEE_TYPE=$TEE_TYPE \
        -e DDR_MODEL=$DDR_MODEL \
        -e KMS=$KMS \
        -e SMP=$SMP \
        -e ACPI=$ACPI \
        -e ISO_INSTALLER=${ISO_INSTALLER:-} \
        -e BUILDMUTTER=${BUILDMUTTER:-} \
        -e NEXUS_SITE=${NEXUS_SITE:-} \
        -e DEBIAN_MODE=${DEBIAN_MODE:-} \
        -e FASTBOOT_LOAD=${FASTBOOT_LOAD:-} \
        -e DOCKER_MODE=${DOCKER_MODE:-} \
        -e SYSTEMD_TARGET=${SYSTEMD_TARGET:-graphical} \
        -e PARALLEL_GROUP=${PARALLEL_GROUP:-all} \
        -e NETWORK=${NETWORK:-internal} \
        -e ROOT_FREE_SIZE=${ROOT_FREE_SIZE:-4194304} \
        -e SWAP_SIZE=${SWAP_SIZE:-0} \
        -e EX_CUSTOMER=${EX_CUSTOMER:-default} \
        -e EX_PROJECT=${EX_PROJECT:-pc} \
        -e EX_VERSION=${EX_VERSION:-rc1} \
        -e EX_NEXUS_USER=${EX_NEXUS_USER:-svc.public} \
        -e EX_NEXUS_PASS=${EX_NEXUS_PASS:-svc.public} \
        -e KMS_PROJECT_ID=${KMS_PROJECT_ID} \
        -e KMS_VERSION=${KMS_VERSION} \
        -e SIGN_KEY=${SIGN_KEY:-} \
        -e SIGN_CERT=${SIGN_CERT:-} \
        -e AUTO_GUID=${AUTO_GUID} \
        -e DT=${DT} \
        -e TFA_LOAD_TYPE=${TFA_LOAD_TYPE:-ddr} \
        -e GPT_BLOCKSIZE=${GPT_BLOCKSIZE:-512} \
        -e SKIP_DEBIAN_STORAGE_BUILD=${SKIP_DEBIAN_STORAGE_BUILD:-true} \
        -e ENABLE_XPU_SCREEN_CHIP_TEST=${ENABLE_XPU_SCREEN_CHIP_TEST:-false} \
        -e BL_TYPE=${BL_TYPE} \
        -e USER=$USER \
        -e HOME=$HOME \
        -e LM_LICENSE_FILE=${LM_LICENSE_FILE:-} \
        -e PATH_ROOT=${PATH_ROOT:-${WORK_DIR}}"

if [[ "${http_proxy}" != "" ]]; then
        env_opts+=" -e http_proxy=${http_proxy:-} \
                    -e https_proxy=${https_proxy:-} \
                    -e ftp_proxy=${ftp_proxy:-} \
                    -e no_proxy=localhost,localhost:*,127.*,*.cixcomputing.com,*.cixtech.com,10.128.* "
fi

if [[ "$FILESYSTEM" == "android" ]]; then
    if [[ -z "$TARGET_PRODUCT" ]]; then
        echo -e "TARGET_PRODUCT must be set when filesystem is android"
        echo -e "Please run 'source build/envsetup.sh' and 'lunch'"
        exit 1
    fi
    env_opts+=" -e TARGET_PRODUCT=$TARGET_PRODUCT -e ANDROID_PRODUCT_OUT=$ANDROID_PRODUCT_OUT"
fi

#netrc file contains artifactory credentials for cloning ddk code and PATH variable has armclang tool path
if [[ $FILESYSTEM == "debian" ]]; then
        #env_opts+=" -e PATH=$(echo $PATH | sed 's:\.local/bin:bin:g')"
        env_opts+=" -e PATH=${HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
fi
# here should change the python version according docker
env_opts+=" -e PYTHONPATH=/usr/lib/python310.zip:/usr/lib/python3.10:/usr/lib/python3.10/lib-dynload:/usr/local/lib/python3.10/dist-packages:/usr/lib/python3/dist-packages"

# if [[ -e "$HOME/.netrc" ]]; then
#     env_opts+=" -v $HOME/.netrc:$HOME/.netrc"
# fi

#check for ssh key agent status and if not running will try to explicitly run it
echo -e "${BLUE}INFO: Checking for ssh-agent status ${NC}"
if [[ -z "$SSH_AUTH_SOCK" ]] ; then
    eval "$(ssh-agent -s)"
    if [[ -z "$SSH_AUTH_SOCK" ]] ; then
        error_echo "unable to restart ssh-agent .. exiting script"
        exit 1
    fi
fi

disable_output_root="false"
debug_output_root="false"

if [[ $# > 0 && "$1" == "--disable-output-root" ]]; then
    disable_output_root="true"
    shift
fi

if [[ $# > 0 && "$1" == "--debug" ]]; then
    debug_output_root="true"
    shift
fi

echo -e "${BLUE}INFO: ssh agent is working ${NC}"
#Start docker container
echo -e "${BLUE}INFO: ENTERING DOCKER CONTAINER ${NC}"

docker_args="--rm --net=host --mount type=bind,source=$WORK_DIR,target=$WORK_DIR \
        --privileged=true \
        $env_opts \
        -v $HOME:$HOME \
        -v $SSH_AUTH_SOCK:/ssh.socket -e SSH_AUTH_SOCK=/ssh.socket \
        --workdir /$SCRIPT_DIR \
        --user $(id -u):$(id -g)"

if [[ -e "/data/.c/cache" ]]; then
    docker_args="$docker_args \
        -v /data/.c/cache:/data/.c/cache:ro"
fi

if [[ -e "/data/.c/ccache" ]]; then
    docker_args="$docker_args \
        -v /data/.c/ccache:/data/.c/ccache"
fi

if [[ -e "/public/devops/settings" ]]; then
    docker_args="$docker_args \
        -v /public/devops/settings:/public/devops/settings:ro"
fi

if [[ "${debug_output_root}" == "true" ]]; then
    docker run $docker_args -it cix:${USER}_${CIX_DOCKER} /bin/bash
    ### enable apt install xxx
    #sudo sed -i '/messagebus/d' /var/lib/dpkg/statoverride
    #sudo groupadd -r _apt && sudo useradd -r -g _apt _apt
    #
else
    # docker run $docker_args -i cix:${USER}_${CIX_DOCKER} $@
    if [[ "$1" == "/bin/bash" ]] && [[ "$2" == "-c" ]]; then
        shift 2
        docker run $docker_args -i cix:${USER}_${CIX_DOCKER} /bin/bash -c "$*"
    else
        docker run $docker_args -i cix:${USER}_${CIX_DOCKER} $@
    fi
fi

docker_rc=${?}

if [[ "$disable_output_root" == "true" ]]; then
    docker run $docker_args -i cix:${USER}_${CIX_DOCKER} sudo chown $(id -un):$(id -gn) $SCRIPT_DIR/../output -R
fi

echo -e "${BLUE}INFO: EXITING DOCKER CONTAINER ${NC}"
exit ${docker_rc}
