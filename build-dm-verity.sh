#!/usr/bin/env bash

do_build() {
    DM_VERITY_DIR="${PATH_OUT}/images"
    DATA_IMG="$DM_VERITY_DIR/verity_data.img"
    PROTECT_DATA_DIR="${PATH_ROOT}/verity_data"

    echo "=== create verity_data.img ==="

    if [ ! -d "$PROTECT_DATA_DIR" ]; then
        echo "$PROTECT_DATA_DIR not exist"
        exit 0
    fi

    if [ -z "$(ls -A "$PROTECT_DATA_DIR")" ]; then
        echo "$PROTECT_DATA_DIR is empty"
        exit 0
    fi

    # create img
    FOLDER_SIZE=$(du -sb $PROTECT_DATA_DIR | cut -f1)

    # add extra space
    IMG_SIZE=$(((FOLDER_SIZE * 150 / 100 + 1048575) / 1048576 ))

    # create empty img
    dd if=/dev/zero of=$DATA_IMG bs=1M count=0 seek=${IMG_SIZE}

    mkfs.ext4 -F $DATA_IMG

    # copy data
    find $PROTECT_DATA_DIR -type f | while read file; do
        rel_path=${file#$PROTECT_DATA_DIR/}
        debugfs -w $DATA_IMG -R "write $file $rel_path"
    done

    echo "=== create verity_data.img: finish ==="

    echo "=== set partition dm-verity ==="

    # create dm-verity hash table
    HASHTREE_IMG="$DM_VERITY_DIR/verity_hash.img"
    echo "create dm-verity hash table..."
    OUTPUT=$(veritysetup -v format "$DATA_IMG" "$HASHTREE_IMG" 2>&1)
    echo "$OUTPUT"

    # 2. extract and save the root hash
    ROOT_HASH=$(echo "$OUTPUT" | grep "Root hash:" | awk '{print $3}')
    if [ -z "$ROOT_HASH" ]; then
        echo "error: Extract and save the root hash"
        exit 1
    fi
    echo "root hash: $ROOT_HASH"

    # verify hash table
    if veritysetup verify "$DATA_IMG" "$HASHTREE_IMG" "$ROOT_HASH"; then
        echo "DM-verity verify: success"
    else
        echo "DM-verity verify: fail"
        exit 1
    fi

    # get verity_data.img's UUID
    DATA_UUID=$(blkid -s UUID -o value $DATA_IMG)

    # get verity_hash.img's UUID
    HASH_UUID=$(blkid -s UUID -o value $HASHTREE_IMG)

    echo "=== set partition dm-verity: finish ==="

    echo "=== update kernel command line parameters ==="

    # add dm-verity parameters
    STR="\
        systemd.verity=1 \
        roothash=$ROOT_HASH \
        systemd.verity_root_data=UUID=$DATA_UUID \
        systemd.verity_root_hash=UUID=$HASH_UUID \
        systemd.verity_root_options=panic-on-corruption"

    VERITY_PARAMS=$(echo "$STR" | tr -s '[:space:]' ' ')

    CONFIG_FILE="${PATH_ROOT}/linux/arch/arm64/configs/cix.config"

    if grep -q "^CONFIG_CMDLINE=" "$CONFIG_FILE"; then
        sed -i "s|^CONFIG_CMDLINE=.*|CONFIG_CMDLINE=\"$VERITY_PARAMS\"|" "$CONFIG_FILE"
    else
        echo "CONFIG_CMDLINE=\"$VERITY_PARAMS\"" >> "$CONFIG_FILE"
    fi

    if grep -q "^CONFIG_CMDLINE_EXTEND=" "$CONFIG_FILE"; then
        sed -i "s|^CONFIG_CMDLINE_EXTEND=.*|CONFIG_CMDLINE_EXTEND=y|" "$CONFIG_FILE"
    else
        echo "CONFIG_CMDLINE_EXTEND=y" >> "$CONFIG_FILE"
    fi

    echo "updata: CONFIG_CMDLINE=$VERITY_PARAMS"
    echo "updata: CONFIG_CMDLINE_EXTEND=y"

    echo "=== update kernel command line parameters: finish ==="
}

do_clean(){
    CONFIG_FILE="${PATH_ROOT}/linux/arch/arm64/configs/cix.config"

    # delete CONFIG_CMDLINE
    if grep -q "^CONFIG_CMDLINE=" "$CONFIG_FILE"; then
        sed -i "/^CONFIG_CMDLINE=/d" "$CONFIG_FILE"
        echo "delete CONFIG_CMDLINE "
    else
        echo "CONFIG_CMDLINE not exist"
    fi

    # delete CONFIG_CMDLINE_EXTEND
    if grep -q "^CONFIG_CMDLINE_EXTEND=" "$CONFIG_FILE"; then
        sed -i "/^CONFIG_CMDLINE_EXTEND=/d" "$CONFIG_FILE"
        echo "delete CONFIG_CMDLINE_EXTEND "
    else
        echo "CONFIG_CMDLINE_EXTEND not exist"
    fi

    VERITY_DATA_IMG="${PATH_OUT}/images/verity_data.img"
    VERITY_HASH_IMG="${PATH_OUT}/images/verity_hash.img"

    if [ ! -d "$VERITY_DATA_IMG" ]; then
        echo "$VERITY_DATA_IMG not exist"
        exit 0
    fi

    if [ ! -d "$VERITY_HASH_IMG" ]; then
        echo "$VERITY_HASH_IMG not exist"
        exit 0
    fi

    rm $VERITY_DATA_IMG $VERITY_HASH_IMG
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
