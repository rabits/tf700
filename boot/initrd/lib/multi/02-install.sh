#!/bin/sh
#
# Multi - initrd multiboot
# Install screen
#

echo "Please, wait. Preparing for installation..."

tar_rootfs=$(multiFindInstallArchive)

if [ -f "${tar_rootfs}" ]; then
    echo "Get device free space info..."
    [ -d /data ] || mkdir /data
    mount -t ext4 /dev/mmcblk0p8 /data
    disk_free=$(($(df /dev/mmcblk0p8 | tail -n1 | awk '{print $4}')/1024/1024))
    overall_space_available=$disk_free

    echo "Search already present virtual disk..."
    if [ -f "${indevice_rootfsfile}" ]; then
        out_image_size=$(($(ls -l "${indevice_rootfsfile}" | awk '{print $3}')/1024/1024/1024))
        out_image_already_present="Yes (${out_image_size}GB)"
        overall_space_available=$(($disk_free+$out_image_size))
    else
        out_image_already_present="No"
    fi

    # Get image size
    while [ "x${out_size}" = "x" ]; do
        echo -n "Please, select virtual disk size (only number, 3...$((${overall_space_available}-1))GB): "
        read out_size
        out_size=$(echo "$out_size" | sed 's/[^0-9]*\([0-9]\+\).*/\1/g')
        if [ "x${out_size}" = "x" -o $out_size -lt 3 -a $out_size -gt $(($overall_space_available-1)) ]; then
            echo "Virtual disk size (${out_size}) should be greater then 2 and less then ${overall_space_available}GB, please try again..."
            out_size=""
        fi
    done

    echo "====================================================="
    echo " - TAR.LZMA rootfs archive:   ${tar_rootfs}"
    echo " - Install path:              ${indevice_rootfsfile}"
    echo " - Image already present:     ${out_image_already_present}"
    echo " - Required / free space:     ${out_size}GB / ${disk_free}GB"
    echo "====================================================="
    echo

    if [ "x${out_image_already_present}" != "xNo" ]; then
        echo "WARNING: I found already existing image file ${indevice_rootfsfile} - it will be overwritten!"
        echo "HINT: To prevent the loss of data - cancel the installation and do backup of this img file."
        echo
    fi

    echo -n "Can I start the process? Are you sure? (y/n) [n]: "
    read -n1 inp
    echo

    case "$inp" in
      y|Y)
        echo "Start of installation process..."
        echo
        echo "INFO: Creating virtual filesystem file ${indevice_rootfsfile} ${out_size}GB..."
        rm -f "${indevice_rootfsfile}"
        dd if=/dev/zero of=${indevice_rootfsfile} bs=$((1024*1024)) count=1 seek=$((${out_size}*1024))
        echo "INFO: Writing ext4 filesystem..."
        if [ -f "${indevice_rootfsfile}" ]; then
            mke2fs -F -O has_journal,extent,huge_file,flex_bg,uninit_bg,dir_nlink,extra_isize,extent -E discard,lazy_itable_init=0,lazy_journal_init=0 -I 256 "${indevice_rootfsfile}"
            echo "INFO: Mount virtual filesystem..."
            [ -d /mnt ] || mkdir /mnt
            mount -t ext4 "${indevice_rootfsfile}" /mnt
            echo "INFO: Unpacking rootfs archive (Please, be patient - it can take ~10 min)..."
            if mount | grep -q "/mnt" 1>&2; then
                cd /mnt
                lzmp -dc ${tar_rootfs} | tar xp
                echo "INFO: Removing android data from linux fstab - we use bind in boot process later"
                cp etc/fstab etc/fstab.back
                cat etc/fstab.back | grep -v '/dev/mmcblk0p8' > etc/fstab
                cd /
                umount /mnt
                umount ${rootmnt}
                echo "INFO: Done. Now you can boot as usual from main menu."
            else
                echo "ERROR: Can't mount virtual disk ${indevice_rootfsfile}. Installation aborted"
            fi
        else
            echo "ERROR: After creation of virtual disk: ${indevice_rootfsfile} - is not a file. Installation aborted"
        fi
        ;;
      *)
        echo "Install aborted"
        echo
        ;;
    esac
else
    echo "Not found rootfs file archive (${tar_rootfs})..."
fi

umount /mnt 1>/dev/null 2>&1 
umount ${rootmnt} 1>/dev/null 2>&1
losetup -d `losetup -a | awk -F: '{print $1}'` 1>/dev/null 2>&1
umount /data 1>/dev/null 2>&1
rmdir /mnt /data 1>/dev/null 2>&1

echo
echo -n "Please hit any key to return to main menu: "
read -n1 inp
