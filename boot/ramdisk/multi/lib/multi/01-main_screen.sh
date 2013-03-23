#!/bin/sh
#
# Multi - initrd multiboot
# Author - Rabit <home@rabits.org>
#
# Main screen
#

wait=10

while true; do

multiClear

    cat <<EOF

Please, select OS to boot:
==========================
EOF
if [ "${DEFAULT_SYS}" = "Android" ]; then
    cat <<EOF
 1         - ${BASIC_SYS_NAME}
 2,voldown - ${SECOND_SYS_NAME}
EOF
else
    cat <<EOF
 1         - ${SECOND_SYS_NAME}
 2,voldown - ${BASIC_SYS_NAME}
EOF
fi

cat <<EOF
 s         - Shell
==========================
EOF

[ $wait -gt 0 ] && echo "You have $wait secs to choose..."
echo -n "Please Select (1,2(voldown),s) [1]: "
read -n1 -t $wait inp
echo
wait=0

case "$inp" in
  2|"")
    echo
    if [ "${DEFAULT_SYS}" = "Android" ]; then
        echo "Starting ${SECOND_SYS_NAME}"
        echo
        . /lib/multi/02-find_linux.sh "$@"
    else
        echo "Starting ${BASIC_SYS_NAME}"
        echo
        multiSysUmount
        /init-android "$@"
    fi
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
    if [ "${DEFAULT_SYS}" = "Android" ]; then
        echo "Starting ${BASIC_SYS_NAME}"
        echo
        multiSysUmount
        /init-android "$@"
    else
        echo "Starting ${SECOND_SYS_NAME}"
        echo
        . /lib/multi/02-find_linux.sh "$@"
    fi
    exit 1
    ;;
esac
done
