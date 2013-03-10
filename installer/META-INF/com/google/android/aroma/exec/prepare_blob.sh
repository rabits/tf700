#!/sbin/sh

echo "[prepare_blob.sh] Preparing boot.blob..."
bb=/tmp/aroma/busybox

if [ -d /tmp/ramdisk-patch ]; then
    echo ". Applying patches to ramdisk..."
    cd /tmp/ramdisk
    for patch in $($bb find /tmp/ramdisk-patch/ -name '*.patch'); do
        echo ".   Applying patch: ${patch} ..."
        $bb patch -p1 -i "${patch}"
    done
fi

echo ". Packing ramdisk into /tmp/ramdisk.img ..."
cd /tmp/ramdisk && $bb find | $bb cpio -H newc -o | $bb bzip2 -9 > /tmp/ramdisk.img
cd /
[ ! -f /tmp/ramdisk.img ] && echo "ERROR: Not found /tmp/ramdisk.img" && exit 1
[ ! -f /tmp/zImage ] && echo "ERROR: Not found /tmp/zImage" && exit 1

echo ". Preparing boot.img ..."
/tmp/abootimg --create /tmp/boot.img -k /tmp/zImage -r /tmp/ramdisk.img
[ ! -f /tmp/boot.img ] && echo "ERROR: Not found /tmp/boot.img" && exit 1

echo ". Packing boot.img into boot.blob.pre ..."
/tmp/blobpack /tmp/boot.blob.pre LNX /tmp/boot.img
[ ! -f /tmp/boot.blob.pre ] && echo "ERROR: Not found /tmp/boot.blob.pre" && exit 1

echo ". Signing boot.blob.pre into boot.blob ..."
echo -n "-SIGNED-BY-SIGNBLOB-" > /tmp/boot.blob
dd if=/dev/zero count=8 bs=1 >> /tmp/boot.blob
cat /tmp/boot.blob.pre >> /tmp/boot.blob

exit 0
