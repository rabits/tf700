#!/bin/sh
#
# Multi - initrd multiboot
# Main screen
#
wait=10

while true; do

multiClear

cat <<EOF

Please, select OS to boot:
==========================
 1         - Linux
 2,voldown - Android
 s         - Shell
==========================
EOF

[ $wait -gt 0 ] && echo "You have $wait Seconds to choose..."
echo -n "Please Select (1,2(voldown),s) [1]: "
read -n1 -t $wait inp
echo
wait=0

case "$inp" in
  2|"")
    echo
    echo "Starting Android"
    echo
    multiUmount
    /init-android "$@"
    exit 1
    ;;
  s)
    echo
    echo "Welcome to HELL..."
    echo
    /bin/sh -i </dev/console >/dev/console 2>&1
    ;;
  *)
    echo
    echo "Starting Linux"
    echo
    . /lib/multi/02-find_linux.sh "$@"
    exit 1
    ;;
esac
done
