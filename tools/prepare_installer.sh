#!/bin/sh
#
# Prepare Installer
# Script for preparing zip archive with Aroma installer
#
# Run it in tf700 repository root
#

OUTPUT="$1"
KERNEL="$2"
BUSYBOX="$3"

DIST_VER=$(git tag | tail -n1)
DIST_DATE=$(date "+%d/%m/%Y")
AROMACONFIG='installer/META-INF/com/google/android/aroma-config'

head -n4 $0 | tail -n2

if [ ! -e "${AROMACONFIG}" ]; then
    echo "E: I can't find ${AROMACONFIG} file." 1>&2
    echo "   Please, cd to tf700 repo directory" 1>&2
    exit 1
else
    echo "I: Recognized $PWD as tf700 repo dir"
fi

[ "x${KERNEL}" = "x" ] && KERNEL="source/kernel/out/arch/arm/boot/zImage"
[ "x${BUSYBOX}" = "x" ] && BUSYBOX="source/busybox/out/_install/bin/busybox"

if [ "x${OUTPUT}" = "x" ]; then
    echo "E: To create installer, please specify output file" 1>&2
    echo "Usage: $0 <output_file.zip> [zImage] [busybox]" 1>&2
    exit 1
fi
touch "${OUTPUT}"
if [ ! -w "${OUTPUT}" ]; then
    echo "E: To create installer, please specify writable output file, ${OUTPUT} - not found." 1>&2
    echo "Usage: $0 <output_file.zip> [zImage] [busybox]" 1>&2
    rm -f "${OUTPUT}"
    exit 1
fi
rm -f "${OUTPUT}"
if [ ! -r "${KERNEL}" ]; then
    echo "E: To create installer, please specify readable kernel file, ${KERNEL} - not found." 1>&2
    echo "Usage: $0 <output_file.zip> [zImage] [busybox]" 1>&2
    exit 1
fi
if [ ! -r "${BUSYBOX}" ]; then
    echo "E: To create installer, please specify readable busybox file, ${BUSYBOX} - not found." 1>&2
    echo "Usage: $0 <output_file.zip> [zImage] [busybox]" 1>&2
    exit 1
fi

OUTPUT=`readlink -f "${OUTPUT}"`
KERNEL=`readlink -f "${KERNEL}"`
BUSYBOX=`readlink -f "${BUSYBOX}"`


echo "I: Preparing ${DIST_VER} installer zip: ${OUTPUT}"

#################

echo -n "I: Preparing config..."
sed -i "s|ini_set(\"rom_version\".*|ini_set(\"rom_version\", \"${DIST_VER}\");|g" "${AROMACONFIG}" &&\
    sed -i "s|ini_set(\"rom_date\".*|ini_set(\"rom_date\",    \"${DIST_DATE}\");|g" "${AROMACONFIG}" && echo " ok" || echo " fail"

echo -n "I: Copying ramdisks and remove symlinks..."
rm -rf installer/ramdisk && cp -al boot/ramdisk installer/ramdisk &&\
    find installer/ramdisk -type l | while read link; do
        echo "  Removing ${link}"
        rm -f "${link}"
    done && echo " ok" || echo " fail"

echo -n "I: Linking ${KERNEL} as zImage file into archive..."
ln -sf "${KERNEL}" installer/zImage && echo " ok" || echo " fail"

echo -n "I: Linking ${BUSYBOX} as busybox file into archive..."
ln -sf "${BUSYBOX}" installer/META-INF/com/google/android/aroma/exec/busybox && echo " ok" || echo " fail"

echo "I: Creating ${OUTPUT} zip installer file..."
cd installer && zip -r -9 "${OUTPUT}" . --exclude \*.zip && echo " DONE" || echo " FAILED" ; cd ..
