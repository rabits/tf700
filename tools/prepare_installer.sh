#!/bin/sh
#
# Prepare Installer
# Script for preparing zip archive with Aroma installer
#
# Run it in tf700 repository root
#

OUTPUT="$1"
ROOTFS="$2"
BOOTBLOB="$3"

DIST_VER=$(git tag | tail -n1)
DIST_DATE=$(date "+%d/%m/%Y")
AROMACONFIG='installer/META-INF/com/google/android/aroma-config'

head -n4 $0 | tail -n2

if [ "x${OUTPUT}" = "x" ]; then
    echo "E: To create installer, please specify output file" 1>&2
    echo "Usage: $0 <output_file.tar.lzma>" 1>&2
    exit 1
fi
touch "${OUTPUT}"
if [ ! -f "${OUTPUT}" -o -f "${ROOTFS}" -o -f "${BOOTBLOB}" ]; then
    echo "E: To create installer, please specify valid output file, and rootfs archive. Also you should have boot.blob file." 1>&2
    echo "Usage: $0 <output_file.zip> <rootfs.tar.lzma> [boot.blob]" 1>&2
    exit 1
fi
rm -f "${OUTPUT}"

echo "I: Preparing ${DIST_VER} installer zip: ${OUTPUT}"

if [ ! -e installer/META-INF/com/google/android/aroma-config ]; then
    echo "E: I can't find ${AROMACONFIG} file." 1>&2
    echo "   Please, cd to tf700 repo directory" 1>&2
    exit 1
else
    echo "I: Recognized $PWD as tf700 repo dir"
fi

#################

echo -n "I: Preparing config..."
sed -i "s|ini_set(\"rom_version\".*|ini_set(\"rom_version\", \"${DIST_VER}\");|g" "${AROMACONFIG}" &&\
    sed -i "s|ini_set(\"rom_date\".*|ini_set(\"rom_date\",    \"${DIST_DATE}\");|g" "${AROMACONFIG}" && echo " ok" || echo " fail"
