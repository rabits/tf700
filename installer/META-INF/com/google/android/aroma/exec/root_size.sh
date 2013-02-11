#!/sbin/sh

echo "[root_size.sh] Set installation size of root partition..."
bb=/tmp/aroma/busybox

selected_number=$(cut -d'=' -f2 /tmp/aroma-data/rootsize.prop)
[ $selected_number -lt 7 ] && size=$(($selected_number+2))
[ $selected_number -eq 7 ] && size=10
[ $selected_number -eq 8 ] && size=12
[ $selected_number -eq 9 ] && size=15
[ $selected_number -eq 10 ] && size=20

echo "Selected install size: ${size}Gb"
echo "install.rootsize=${size}" >> /tmp/install.prop

exit 0
