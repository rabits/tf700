#!/bin/sh
#
# Multi - initrd multiboot
# Linux rootfs find script
#

multiFindLinuxDevice
if multiValidateRootInit "$init" 1>&2 || multiValidateRootInit "$ainit" 1>&2; then
    echo
    echo "Starting Linux from device"
    echo
    . /lib/multi/03-boot_linux.sh "$@"
    panic
fi

wait=5

multiClear

# If linux not found on device - trying to search it on loop device:
mkdir /data
mount -t ext4 -o defaults,noatime,nodiratime,discard,errors=remount-ro,commit=60 /dev/mmcblk0p8 /data
loop_list=$(find "${indevice_rootfs_dir}" -type f -name '*.img' | sed -n '1,9p')

cat <<EOF

Please, select image to boot:
==========================
$(echo "${loop_list}" | sed "s|${indevice_rootfs_dir}/||g" | awk '{print NR, "-", $0}')
==========================
EOF

[ $wait -gt 0 ] && echo "You have $wait Seconds to choose..."
echo -n "Please Select (1..9) [1]: "
read -n1 -t $wait input
echo
wait=0

[ "${input}" -gt "0" ] 2>/dev/null || input=1

selected_img=$(echo "${loop_list}" | sed -n "${input}p")

multiMountLinuxLoop "${selected_img}"

if multiValidateRootInit "$init" 1>&2 || multiValidateRootInit "$ainit" 1>&2; then
    echo "Found init"
else
    umount /data
fi

echo
echo "Starting Linux"
echo
. /lib/multi/03-boot_linux.sh "$@"
panic
