#!/bin/sh
#
# Multi - initrd multiboot
# Initial script
#

. /lib/multi/functions.sh

chown -R 0:0 /
chmod -R g-w /

multiMount

multiClear

# Set console powerdown 0
echo -ne "\033[14;0]" > /dev/console
# Set console blank 0
echo -ne "\033[9;0]" > /dev/console

# Disable dmesg to console
echo "1 1 1 7" > /proc/sys/kernel/printk

export ainit=/init
export init=/sbin/init
export rootmnt=/root
export indevice_rootfs_dir="/data/media/linux"

. /lib/multi/01-main_screen.sh
