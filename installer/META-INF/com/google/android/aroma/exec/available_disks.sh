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
        # Disk size in Mb!
        echo "available.${disk}=$($bb expr ${disksize} / 1024)" >> /tmp/available_disks.prop
        echo "${disk}" >> /tmp/available_disks.list
        diskinfo=""
        [ "x${disk}" = "xmmcblk0p8" ] && device="mmcblk0" || device="${disk}"
        [ -e "/sys/class/block/${device}/device/name" ]   && diskinfo="${diskinfo} $(cat "/sys/class/block/${device}/device/name")"
        [ -e "/sys/class/block/${device}/device/type" ]   && diskinfo="${diskinfo} $(cat "/sys/class/block/${device}/device/type")"
        [ -e "/sys/class/block/${device}/device/vendor" ] && diskinfo="${diskinfo} $(cat "/sys/class/block/${device}/device/vendor")"
        [ -e "/sys/class/block/${device}/device/model" ]  && diskinfo="${diskinfo} $(cat "/sys/class/block/${device}/device/model")"
        diskinfo=$(echo "${diskinfo}" | tr -s "[:space:]" | sed 's/^[ \t]*//;s/[ \t]*$//') 
        [ "x${diskinfo}" != "x" ] && echo "available.${disk}.info='${diskinfo}'" >> /tmp/available_disks.prop
        echo "Writed ${disk} (${diskinfo}) to prop"
        out=0
    fi
done

exit $out
