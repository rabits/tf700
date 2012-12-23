#!/bin/sh
#
# Multi - initrd multiboot
# Linux init start script
#

[ -d /etc ] || mkdir -m 0755 /etc
[ -d /run ] || mkdir -m 0755 /run

mkdir -p /var/lock

ln -sf /proc/mounts /etc/mtab

mount -t tmpfs -o "nosuid,size=20%,mode=0755" tmpfs /run
mkdir /run/initramfs
ln -s /run/initramfs /dev/.initramfs

export DPKG_ARCH=armhf

export ROOT=

if [ -f "/etc/hostname" ]; then
    /bin/hostname -b -F /etc/hostname 2>&1 1>/dev/null
fi

# Parse command line options
for x in $(cat /proc/cmdline); do
    case $x in
    init=*)
        init=${x#init=}
        ;;
    root=*)
        ROOT=${x#root=}
        case $ROOT in
        LABEL=*)
            ROOT="${ROOT#LABEL=}"

            # support any / in LABEL= path (escape to \x2f)
            case "${ROOT}" in
            */*)
            if command -v sed >/dev/null 2>&1; then
                ROOT="$(echo ${ROOT} | sed 's,/,\\x2f,g')"
            else
                if [ "${ROOT}" != "${ROOT#/}" ]; then
                    ROOT="\x2f${ROOT#/}"
                fi
                if [ "${ROOT}" != "${ROOT%/}" ]; then
                    ROOT="${ROOT%/}\x2f"
                fi
                IFS='/'
                newroot=
                for s in $ROOT; do
                    newroot="${newroot:+${newroot}\\x2f}${s}"
                done
                unset IFS
                ROOT="${newroot}"
            fi
            esac
            ROOT="/dev/disk/by-label/${ROOT}"
            ;;
        esac
        ;;
    esac
done

export BOOT

echo '----MOUNT ROOT----'
if [ "$ROOT" ]; then
    echo "Trying specified root: ${ROOT}..."
    if ! mount -t ext4 ${ROOT} ${rootmnt}; then echo "  FAILED"; fi
fi

multiFindLinuxDevice noumount

if mount | grep -q ${rootmnt};
    echo "Linux mount failed. Fallback to Android..."
    echo
    /init-android "$@"
    exit 1
fi

echo "Mounted: $(mount | grep /root)"
echo '----DONE----'

# Preserve information on old systems without /run on the rootfs
if [ -d ${rootmnt}/run ]; then
    mount -n -o move /run ${rootmnt}/run
else
    # The initramfs udev database must be migrated:
    if [ -d /run/udev ] && [ ! -d /dev/.udev ]; then
        mv /run/udev /dev/.udev
    fi
    # The initramfs debug info must be migrated:
    if [ -d /run/initramfs ] && [ ! -d /dev/.initramfs ]; then
        mv /run/initramfs /dev/.initramfs
    fi
    umount /run
fi

# Move virtual filesystems over to the real filesystem
mount -n -o move /sys ${rootmnt}/sys
mount -n -o move /proc ${rootmnt}/proc

# Check init bootarg
if [ -n "${init}" ]; then
    if ! validate_init "$init"; then
        echo "Target filesystem doesn't have requested ${init}."
        init=
    fi
fi

# Common case: /sbin/init is present
if [ ! -x "${rootmnt}/sbin/init" ]; then
    # ... if it's not available search for valid init
    if [ -z "${init}" ] ; then
        for inittest in /sbin/init /etc/init /bin/init /bin/sh; do
            if validate_init "${inittest}"; then
                init="$inittest"
                break
            fi
        done
    fi

    # No init on rootmount
    if ! validate_init "${init}" ; then
        panic "No init found. Try passing init= bootarg."
    fi
fi

unset DPKG_ARCH
unset ROOT

echo ''
echo '====SYSTEM START===='
echo ''

# Chain to real filesystem
exec run-init ${rootmnt} ${init} "@" <${rootmnt}/dev/console >${rootmnt}/dev/console 2>&1
panic "Could not execute run-init."
