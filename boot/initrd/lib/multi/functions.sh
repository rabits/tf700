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
    echo <<EOF

MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  M,MMMMMMM   MMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM home.rabits@gmail.com M  M   MMMM    MMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  M+.   M.    MMMMMMMMMMMMMM
MMMMM.    MMMMMM     MMM   MMMMMMM   MMM.   MMMMMMM             OM.  .MM  MM .       MMMMMMMMMMMMMMM
MMMMM   . MMMMM?. .  MMO   MMMMMMM.  MMM   MMMMMMMMMMMMM.  MMMMMMM   MMM  MMM,       MMMMMMMMMMMMMMM
MMMMM. M  MMMMM  O. MMM.  +MMMMMMI   MMM   MMMMMMMMMMMMM.  MMMMMMM   MMM  MMMM       M..    MMMMMMMM
MMMM.  M  NMMM  M   MMM.  MMMMMMM.  DMM,.  MMMMMMMMMMMM   +MMMMMM,.  MMM  MMMM                .MMMMM
MMMM.  M.  MM. ,M.  MMM   MMMMMMM.  MMM   MMMMMMMMMMMMM.  MMMMMMM   MMMM  MMM.    _              MMM
MMMM. :M   M. .MM. 8MM.   MMMMMMM.  MMM.  MMMMMMMMMMMMM.  MMMMMMM.  MMMM  MMMM   |_) _ |_  o _|_  MM
MMM   MMM  M  MM   MMM.  NMMMMMM.  ?MM8.  MMMMMMMMMMMM    MMMMMM8.  MMMM  MMMM.  | \(_||_) |  |_  MM
MMM   MMM.   MMM.  MMM    MMMMM.  .MMM   ZMMMMMMMMMMMM   MMMMMMM   8MMMM  MMMM.                   MM
MMM.  MMM   NMMM. .MMMM    ....   MMMM.          =MMMM.  MMMMMMM.  MMMMM  MMMMMN                   M
MM~  MMMM. ,MMM.  MMMMMMM. . . =MMMMMM.          MMMM~   MMMMMMM.  MMMMM  MMMMMMMM.               MM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMMMMM        .     MMMM
M Initrd Linux / Android embedded multiboot menu system with installer M  MMMMMMMMM  ,M.       MMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMMMMM,=MMMMMMMMMMMMMMMM

EOF
}

clear()
{
    busybox clear
    multiHeader()
}
