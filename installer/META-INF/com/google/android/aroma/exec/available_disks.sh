#!/sbin/sh

echo "[available_disks.sh] Get list of devices and its size..."
bb=/tmp/aroma/busybox

echo -n "" > /tmp/available_disks.prop
echo -n "" > /tmp/available_disks.list
out=1

for disk in mmcblk0p8 sda sdb mmcblk1; do
    echo "Processing ${disk}"
    disksize=$(grep "${disk}$" /proc/partitions | awk '{print $3}')
    if [ "x${disksize}" != "x" ]; then
        echo "Found ${disk}, size ${disksize}Kb"
        diskvendor=""
        diskmodel=""
        # Disk size in Mb!
        echo "available.${disk}=$($bb expr ${disksize} / 1024)" >> /tmp/available_disks.prop
        echo "${disk}" >> /tmp/available_disks.list
        [ -e "/sys/class/block/${disk}/device/vendor" ] && diskvendor=$(cat "/sys/class/block/${disk}/device/vendor")
        [ -e "/sys/class/block/${disk}/device/model" ] && diskmodel=$(cat "/sys/class/block/${disk}/device/model")
        [ "x${diskvendor} ${diskmodel}" != "x " ] && echo "available.${disk}.info='${diskvendor} ${diskmodel}'" >> /tmp/available_disks.prop
        echo "Writed ${disk} to prop"
        out=0
    fi
done

exit $out
