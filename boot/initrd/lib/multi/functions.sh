#!/bin/sh
#
# Multi - initrd multiboot
# Some common functions
#

multiIsMount()
{
    if mount | grep -q -- "$1"; then
        return 0
    fi

    return 1
}

multiMount()
{
    if ! multiIsMount "/dev"; then
        [ -d /dev ] || mkdir -m 0755 /dev
        if ! mount -t devtmpfs -o mode=0755 udev /dev; then
            echo "W: devtmpfs not available, falling back to tmpfs for /dev"
            mount -t tmpfs -o mode=0755 udev /dev
            [ -e /dev/console ] || mknod -m 0600 /dev/console c 5 1
            [ -e /dev/null ] || mknod /dev/null c 1 3
        fi
        mkdir /dev/pts
        mount -t devpts -o noexec,nosuid,gid=5,mode=0620 devpts /dev/pts || true
    fi
    if ! multiIsMount "/sys"; then
        [ -d /sys ] || mkdir /sys
        mount -t sysfs -o nodev,noexec,nosuid sysfs /sys
    fi
    if ! multiIsMount "/proc"; then
        [ -d /proc ] || mkdir /proc
        mount -t proc -o nodev,noexec,nosuid proc /proc
    fi
    [ -d /tmp ] || mkdir /tmp
    [ -d /root ] || mkdir -m 0700 /root
}

multiUmount()
{
    umount /dev/pts
    umount /dev
    umount /sys
    umount /proc
}

multiHeader()
{
echo "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM home.rabits@gmail.com M  M   MMMM    MMMMMMMMMMMMMM"
echo "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  M+.   M.    MMMMMMMMMMMMMM"
echo "MMMMM.    MMMMMM     MMM   MMMMMMM   MMM.   MMMMMMM             OM.  .MM  MM .       MMMMMMMMMMMMMMM"
echo "MMMMM   . MMMMM?. .  MMO   MMMMMMM.  MMM   MMMMMMMMMMMMM.  MMMMMMM   MMM  MMM,       MMMMMMMMMMMMMMM"
echo "MMMMM. M  MMMMM  O. MMM.  +MMMMMMI   MMM   MMMMMMMMMMMMM.  MMMMMMM   MMM  MMMM       M..    MMMMMMMM"
echo "MMMM.  M  NMMM  M   MMM.  MMMMMMM.  DMM,.  MMMMMMMMMMMM   +MMMMMM,.  MMM  MMMM                .MMMMM"
echo "MMMM.  M.  MM. ,M.  MMM   MMMMMMM.  MMM   MMMMMMMMMMMMM.  MMMMMMM   MMMM  MMM.    _              MMM"
echo "MMMM. :M   M. .MM. 8MM.   MMMMMMM.  MMM.  MMMMMMMMMMMMM.  MMMMMMM.  MMMM  MMMM   |_) _ |_  o _|_  MM"
echo "MMM   MMM  M  MM   MMM.  NMMMMMM.  ?MM8.  MMMMMMMMMMMM    MMMMMM8.  MMMM  MMMM.  | \(_||_) |  |_  MM"
echo "MMM   MMM.   MMM.  MMM    MMMMM.  .MMM   ZMMMMMMMMMMMM   MMMMMMM   8MMMM  MMMM.                   MM"
echo "MMM.  MMM   NMMM. .MMMM    ....   MMMM.          =MMMM.  MMMMMMM.  MMMMM  MMMMMN                   M"
echo "MM~  MMMM. ,MMM.  MMMMMMM. . . =MMMMMM.          MMMM~   MMMMMMM.  MMMMM  MMMMMMMM.               MM"
echo "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMMMMM        .     MMMM"
echo "M Initrd Linux / Android embedded multiboot menu system with installer M  MMMMMMMMM  ,M.       MMMMM"
echo "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMMMMM,=MMMMMMMMMMMMMMMM"
}

multiClear()
{
    clear
    multiHeader
}

multiFindLinuxDevice()
{
    option="${1}"

    # Trying to boot external devices, then - internal mmcblk0p9
    for dev in /dev/sda1 /dev/mmcblk1p1 /dev/sdb1 /dev/mmcblk0p9; do
        if mount | grep -q ${rootmnt} 1>&2; then break; fi
        echo "Trying default root: ${dev}" 1>&2
        if mount -t ext4 ${dev} ${rootmnt} 1>&2; then
            if multiValidateRootInit "$init" 1>&2; then
                if [ "x${option}" != "xnoumount" ]; then umount "${rootmnt}" 1>&2; fi
                device="${dev}"
                break
            fi
            echo "  Target filesystem doesn't have required ${init}." 1>&2
            umount ${rootmnt} 1>&2
        fi
        echo "  FAILED"; 1>&2
        device=""
    done

    echo $device
}

multiValidateRootInit() {
    checktarget="${1}"

    # Work around absolute symlinks
    if [ -d "${rootmnt}" ] && [ -h "${rootmnt}${checktarget}" ]; then
        case $(readlink "${rootmnt}${checktarget}") in /*)
            checktarget="$(chroot ${rootmnt} readlink ${checktarget})"
            ;;
        esac
    fi

    # Make sure the specified init can be executed
    if [ ! -x "${rootmnt}${checktarget}" ]; then
        return 1
    fi

    # Upstart uses /etc/init as configuration directory :-/
    if [ -d "${rootmnt}${checktarget}" ]; then
        return 1
    fi
}

panic()
{
    if command -v chvt >/dev/null 2>&1; then
        chvt 1
    fi

    echo "$@"

    /bin/sh -i </dev/console >/dev/console 2>&1
}
