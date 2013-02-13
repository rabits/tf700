#!/bin/sh
#
# Prepare Installer
# Script for preparing zip archive with Aroma installer
#
# Run it in tf700 repository root
#

OUTPUT="$1"
BOOTBLOB="$3"
BOOTBLOBD2SD="$4"
BUSYBOX="$5"

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

[ "x${BOOTBLOB}" = "x" ] && BOOTBLOB="boot/img/boot.blob"
[ "x${BOOTBLOBD2SD}" = "x" ] && BOOTBLOBD2SD="boot/img/boot-data2sd.blob"
[ "x${BUSYBOX}" = "x" ] && BUSYBOX="source/busybox/out/_install/bin/busybox"

if [ "x${OUTPUT}" = "x" ]; then
    echo "E: To create installer, please specify output file" 1>&2
    echo "Usage: $0 <output_file.zip>" 1>&2
    exit 1
fi
touch "${OUTPUT}"
if [ ! -w "${OUTPUT}" ]; then
    echo "E: To create installer, please specify writable output file, ${OUTPUT} - not found." 1>&2
    echo "Usage: $0 <output_file.zip> [boot.blob] [boot-data2sd.blob] [busybox]" 1>&2
    rm -f "${OUTPUT}"
    exit 1
fi
rm -f "${OUTPUT}"
if [ ! -r "${BOOTBLOB}" ]; then
    echo "E: To create installer, please specify readable output file, ${BOOTBLOB} - not found." 1>&2
    echo "Usage: $0 <output_file.zip> [boot.blob] [boot-data2sd.blob] [busybox]" 1>&2
    exit 1
fi
if [ ! -r "${BOOTBLOBD2SD}" ]; then
    echo "E: To create installer, please specify readable output file, ${BOOTBLOBD2SD} - not found." 1>&2
    echo "Usage: $0 <output_file.zip> [boot.blob] [boot-data2sd.blob] [busybox]" 1>&2
    exit 1
fi
if [ ! -r "${BUSYBOX}" ]; then
    echo "E: To create installer, please specify readable output file, ${BUSYBOX} - not found." 1>&2
    echo "Usage: $0 <output_file.zip> [boot.blob] [boot-data2sd.blob] [busybox]" 1>&2
    exit 1
fi

OUTPUT=`readlink -f "${OUTPUT}"`
BOOTBLOB=`readlink -f "${BOOTBLOB}"`
BOOTBLOBD2SD=`readlink -f "${BOOTBLOBD2SD}"`
BUSYBOX=`readlink -f "${BUSYBOX}"`


echo "I: Preparing ${DIST_VER} installer zip: ${OUTPUT}"

#################

echo -n "I: Preparing config..."
sed -i "s|ini_set(\"rom_version\".*|ini_set(\"rom_version\", \"${DIST_VER}\");|g" "${AROMACONFIG}" &&\
    sed -i "s|ini_set(\"rom_date\".*|ini_set(\"rom_date\",    \"${DIST_DATE}\");|g" "${AROMACONFIG}" && echo " ok" || echo " fail"

echo -n "I: Linking ${BOOTBLOB} as boot.blob file into archive..."
ln -sf "${BOOTBLOB}" installer/boot.blob && echo " ok" || echo " fail"
echo -n "I: Linking ${BOOTBLOBD2SD} as boot-data2sd.blob file into archive..."
ln -sf "${BOOTBLOBD2SD}" installer/boot-data2sd.blob && echo " ok" || echo " fail"

echo -n "I: Linking ${BUSYBOX} as busybox file into archive..."
ln -sf "${BUSYBOX}" installer/META-INF/com/google/android/aroma/exec/busybox && echo " ok" || echo " fail"

echo "I: Creating ${OUTPUT} zip installer file..."
cd installer && zip -r -9 "${OUTPUT}" . --exclude \*.zip && echo " DONE" || echo " FAILED" ; cd ..
