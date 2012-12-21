#!/bin/sh
#
# Multi - initrd multiboot
# Main screen
#

clear

wait=10

cat <<EOF

Please, select OS to boot:
==========================
 1         - Linux
 2,voldown - Android
 i         - Install
 s         - Shell
==========================
You have $wait Seconds to choose...
EOF
echo -n "Please Select (1,2(voldown),s) [1]: "
read -n1 -t $wait inp
echo

case "$inp" in
  2|"")
    echo "Starting Android"
    echo
    multiUmount
    /init-android "$@"
    exit 1
    ;;
  i)
    echo "Installing..."
    echo
    . 02-install.sh
    ;;
  s)
    echo "Welcome to HELL..."
    echo
    /bin/sh -i </dev/console >/dev/console 2>&1
    exit 1
    ;;
  *)
    echo "Starting Linux"
    echo
    . 03-boot_linux.sh "$@"
    exit 1
    ;;
esac
