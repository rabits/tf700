#!/bin/sh
#
# Multi - initrd multiboot
# Initial script
#

. functions.sh

multiMount

clear

# Set console powerdown 0
echo "\033[14;0]"
# Set console blank 0
echo "\033[9;0]"

# Disable dmesg to console
echo "4 1 1 7" > /proc/sys/kernel/printk

. 01-main_screen.sh
