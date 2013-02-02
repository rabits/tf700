#!/sbin/sh

rootfsfile=/data/media/linux-rootfs.img

echo "Get device free space info..."
mounted=`df | grep mmcblk0p8 | grep /data | head -n1`

if [ "x${mounted}" = "x" ]; then
    [ -d /data ] || mkdir /data
    [ -e /dev/block/mmcblk0p8 ] mount -t ext4 /dev/block/mmcblk0p8 /data
    [ -e /dev/mmcblk0p8 ] mount -t ext4 /dev/mmcblk0p8 /data
    mounted=`df | grep mmcblk0p8 | grep /data | head -n1`
fi

disk_free=$(($(echo "${mounted}" | awk '{print $4}')/1024/1024))
overall_space_available=$disk_free

echo "Search already present virtual disk..."
if [ -f "${rootfsfile}" ]; then
    out_image_size=$(($(ls -l "${rootfsfile}" | awk '{print $3}')/1024/1024/1024))
    overall_space_available=$(($disk_free+$out_image_size))
fi

# Get image size
echo "Please, select virtual disk size (3...${overall_space_available}Gb): "

exit ${overall_space_available}
