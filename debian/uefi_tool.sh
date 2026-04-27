#!/usr/bin/env bash

# refer to: https://confluence.cixtech.com/pages/viewpage.action?spaceKey=SW&title=UEFI+Flash+Update+Tool
# refer to: https://confluence.cixtech.com/display/SW/UEFI+Burn+Image+Tool

WORKSPACE="$(realpath --no-symlinks "$(dirname "${BASH_SOURCE[0]}")")"
PATH_DEST="${WORKSPACE}/udisk"

if [[ $# -gt 0 ]]; then
    PATH_DEST="$1"
fi

if [[ ! -e "${PATH_DEST}" ]]; then
    mkdir -p "${PATH_DEST}"
fi
rm -f ${PATH_DEST}/*.*
cp -rf "${WORKSPACE}/EFI" "${PATH_DEST}"
cp -f "${WORKSPACE}/BurnImage.efi" "${PATH_DEST}"
cp -f "${WORKSPACE}/FlashUpdate.efi" "${PATH_DEST}"
cp -f "${WORKSPACE}/cix_flash_all"*".bin" "${PATH_DEST}"
cp -f "${WORKSPACE}/partition-table.img" "${PATH_DEST}"
# cp -f "${WORKSPACE}/partition-table-4096.img" "${PATH_DEST}"
cp -f "${WORKSPACE}/boot.img" "${PATH_DEST}"
split -b 512M -d "${WORKSPACE}/rootfs.ext4" "${PATH_DEST}/rootfs.ext4."
# cp -f "${WORKSPACE}/rootfs.ext4" "${PATH_DEST}"
cd "${PATH_DEST}"
md5sum *.* > md5.txt
cd -

cat > "${PATH_DEST}/check-md5.sh" <<- EOF
#!/usr/bin/env bash
WORKSPACE="\$(realpath --no-symlinks "\$(dirname "\${BASH_SOURCE[0]}")")"
if [[ \$# -lt 1 ]]; then
    MD5_CONFIG="\${WORKSPACE}/md5.txt"
else
    MD5_CONFIG="\$(realpath --no-symlinks "\$1")"
fi
echo "\${MD5_CONFIG}"
if [[ ! -e "\${MD5_CONFIG}" ]]; then
    echo "\${MD5_CONFIG} does not exist."
    exit 1
fi
PATH_DEST="\$(dirname "\${MD5_CONFIG}")"
cat "\${MD5_CONFIG}" | while IFS= read -r line
do
    data=(\$line)
    file="\${PATH_DEST}/\${data[1]}"
    value=(\$(md5sum "\${file}"))
    echo "check: \${file}"
    if [[ "\${data[0]}" != "\${value[0]}" ]]; then
        echo "FAIL: md5 \${value[0]} is changed for \${file}"
        exit 1
    fi
done
if [[ "\$?" != "1" ]]; then
    echo "SUCCESS"
fi
EOF
chmod +x "${PATH_DEST}/check-md5.sh"

cat > "${PATH_DEST}/check-md5.bat" <<- EOF
@echo off
set WORKSPACE=%~dp0
for /f "tokens=*" %%l in (%WORKSPACE%\md5.txt) do (
    for /F "tokens=1,2 delims= " %%a in ("%%l") do (
        echo check: %WORKSPACE%%%b
        setlocal enabledelayedexpansion
        set value=
        for /F "skip=1 delims=" %%m in ('CertUtil -hashfile %WORKSPACE%%%b MD5') do (
            if not defined value (set value=%%m)
        )
        if not "%%a"=="!value: =!" (
            echo "FAIL: md5 !value: =! is changed for %WORKSPACE%%%b"
            endlocal
            goto end
        )
        endlocal
    )
)
echo "SUCCESS"
:end
pause
EOF
chmod +x "${PATH_DEST}/check-md5.bat"

