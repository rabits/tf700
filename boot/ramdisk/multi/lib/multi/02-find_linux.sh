#!/bin/sh
#
# Multi - initrd multiboot
# Author - Rabit <home@rabits.org>
#
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

# If linux not found on device - trying to search it on loop device:
mkdir /data
multiMount /dev/mmcblk0p8 /data
loop_list=$(find "${indevice_rootfs_dir}" -mindepth 1 -maxdepth 1 \( -type f -name '*.img' \) -o -type d | sed -n '1,9p')

multiClear

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

selected_rootfs=$(echo "${loop_list}" | sed -n "${input}p")

multiMountLinuxRootfs "${selected_rootfs}"

echo
echo "Starting Linux"
echo
. /lib/multi/03-boot_linux.sh "$@"
panic
