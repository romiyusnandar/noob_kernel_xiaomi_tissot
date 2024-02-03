#!/bin/bash
#
# Copyright (C) 2023 sirNewbies.
# All rights reserved.

# setup color
red='\033[0;31m'
green='\e[0;32m'
white='\033[0m'
yellow='\033[0;33m'

# Init
KERNEL_DIR="${PWD}"
KERN_IMG="${KERNEL_DIR}"/out/arch/arm64/boot/Image.gz-dtb
ANYKERNEL="${HOME}"/workspaces/anykernel
COMPILER_STRING="Proton Clang 15"

# Repo URL
#CLANG_REPO="https://gitlab.com/LeCmnGend/proton-clang"
ANYKERNEL_REPO="https://github.com/sirnewbies/Anykernel3.git" 
ANYKERNEL_BRANCH="tissot-14"

# Compiler
CLANG_DIR="${HOME}"/workspaces/clang

# Defconfig
DEFCONFIG="tissot_defconfig"
REGENERATE_DEFCONFIG="false" # unset if don't want to regenerate defconfig

# Costumize
KERNEL="noob-kernel"
RELEASE_VERSION=""
DEVICE="tissot"
KERNELTYPE="Treble"
KERNEL_SUPPORT="14"
KERNELNAME="${KERNEL}-${DEVICE}-${KERNELTYPE}-$(TZ=Asia/Jakarta date +%y%m%d-%H%M)"
TEMPZIPNAME="${KERNELNAME}.zip"
ZIPNAME="${KERNELNAME}.zip"

# Telegram
CHATIDQ="-1001930168269"
CHATID="-1001930168269" # Group/channel chatid (use rose/userbot to get it)
TELEGRAM_TOKEN="5136791856:AAGY5TeaVoeJbd6a2BAlxAjOc-MFWOJzZds" # Get from botfather

# Export Telegram.sh
TELEGRAM_FOLDER="${HOME}"/workspaces/telegram
if ! [ -d "${TELEGRAM_FOLDER}" ]; then
    git clone https://github.com/sirnewbies/telegram.sh/ "${TELEGRAM_FOLDER}"
fi

TELEGRAM="${TELEGRAM_FOLDER}"/telegram

tg_cast() {
    "${TELEGRAM}" -t "${TELEGRAM_TOKEN}" -c "${CHATID}" -H \
    "$(
        for POST in "${@}"; do
            echo "${POST}"
        done
    )"
}

# Regenerating Defconfig
regenerate() {
    cp out/.config arch/arm64/configs/"${DEFCONFIG}"
    git add arch/arm64/configs/"${DEFCONFIG}"
    git commit -m "defconfig: Regenerate"
}

# Building
makekernel() {
    echo -e ".........................."
    echo -e ".     Building Kernel    ."
    echo -e ".........................."

    export PATH="/workspaces/clang/bin:$PATH"
    rm -rf "${KERNEL_DIR}"/out/arch/arm64/boot # clean previous compilation
    mkdir -p out
    make O=out ARCH=arm64 ${DEFCONFIG}
    if [[ "${REGENERATE_DEFCONFIG}" =~ "true" ]]; then
        regenerate
    fi
    make -j$(nproc --all) CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- O=out ARCH=arm64

# Check If compilation is success
    if ! [ -f "${KERN_IMG}" ]; then
        END=$(TZ=Asia/Jakarta date +"%s")
        DIFF=$(( END - START ))
        echo -e "$red Kernel compilation failed, See buildlog to fix errors"
        tg_cast "Build for ${DEVICE} <b>failed</b> in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! Check Instance for errors @sirnewbies"
        exit 1
    fi
}

# Packing kranul
packingkernel() {
    echo -e "$yellow ........................"
    echo -e " .    Packing Kernel    ."
    echo -e " ........................ \n$white"
    # Copy compiled kernel
    if [ -d "${ANYKERNEL}" ]; then
        rm -rf "${ANYKERNEL}"
    fi
    git clone "$ANYKERNEL_REPO" -b "$ANYKERNEL_BRANCH" "${ANYKERNEL}"
        cp "${KERN_IMG}" "${ANYKERNEL}"/Image.gz-dtb

    # Zip the kernel, or fail
    cd "${ANYKERNEL}" || exit
    zip -r9 "${TEMPZIPNAME}" ./*

    # Ship it to the CI channel
    "${TELEGRAM}" -f "$ZIPNAME" -t "${TELEGRAM_TOKEN}" -c "${CHATIDQ}" 
}

# Starting
tg_cast "<b>STARTING KERNEL BUILD</b>" \
    "Device: <code>${DEVICE}</code>" \
    "Kernel Name: <code>${KERNEL}</code>" \
    "Build Type: <code>${KERNELTYPE}</code>" \
    "Release Version: <code>${RELEASE_VERSION}</code>" \
    "Linux Version: <code>$(make kernelversion)</code>" \
    "Android Supported: <code>${KERNEL_SUPPORT}</code>"
START=$(TZ=Asia/Jakarta date +"%s")
makekernel
packingkernel
END=$(TZ=Asia/Jakarta date +"%s")
DIFF=$(( END - START ))
tg_cast "Build for ${DEVICE} with ${COMPILER_STRING} <b>succeed</b> took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! by @romiyusnandar"

tg_cast  "<b>Changelog :</b>" \
    "- A14 only" \
    "- Treble build" \

echo -e "$green ........................"
echo -e ".    Build Finished    ."
echo -e "........................"