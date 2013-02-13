#!/sbin/sh

echo "[selected_rootfs.sh] Get selected rootfs archive and write it to /tmp/install.prop..."
bb=/tmp/aroma/busybox

number=$(cut -d'=' -f2 /tmp/aroma-data/rootfs_source.prop)
name=$(grep -F "available.rootfs${number}.name" /tmp/available_rootfs.prop | cut -d'=' -f2)
disk=$(grep -F "available.rootfs${number}.disk" /tmp/available_rootfs.prop | cut -d'=' -f2)
echo "Selected rootfs archive ${name} on ${disk}"

[ -e "/dev/block/${disk}" ] && diskdevice="/dev/block/${disk}"
[ -e "/dev/${disk}" ] && diskdevice="/dev/${disk}"

echo "install.rootfs_disk=${disk}" >> /tmp/install.prop
echo "install.rootfs_dev=${diskdevice}" >> /tmp/install.prop
echo "install.rootfs_name=${name}" >> /tmp/install.prop

exit 0
