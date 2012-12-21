#!/bin/sh
#
# Multi - initrd multiboot
# Install screen
#

echo "Please, wait. Preparing for installation..."
echo "====================================================="
echo " - Device with linux image:   ${img_device}"
echo " - Install path:              ${to_path}"
echo " - Image already present:     ${to_image_already_present}"
echo " - Required / free space:     ${img_size}/${to_free}"
echo "====================================================="
echo

if [ "x${to_image_already_present}" == "xYes" ]; then
    echo "WARNING: I found already existing image file ${to_path} - it will be overwritten!"
    echo "HINT: To prevent the loss of data - cancel the installation and do backup of this file."
    echo
fi

echo -n "Can I start teh process? Are you sure? (y/n) [n]: "
read -n1 inp
echo

case "$inp" in
  y|Y|Yes|yes)
    echo "Start of installation process..."
    echo
    ;;
  *)
    echo "Install aborted"
    echo
    sleep 1
    ;;
esac
