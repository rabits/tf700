#!/sbin/sh

echo "[start_install.sh] Verify installation properties and start installation process..."
bb=/tmp/aroma/busybox

echo "exit=1" > /tmp/install_exit.prop

read_prop()
{
    prop=$1
    file=$2
    data=$(grep -F "${prop}=" "${file}" 2>/dev/null | tail -n1)
    echo ". prop ${prop}: ${data}" 1>&2
    echo "$(echo "${data}" | cut -d'=' -f2)"
}

error()
{
    line=$2
    msg="ERROR (${line}): $1"
    echo "message=${msg}" >> /tmp/install_exit.prop
    echo "${msg}"
    exit $line
}

###### INSTALL PROPERTIES ######

echo "Reading properties..."
install_rootfs_name=$(read_prop "install.rootfs_name" /tmp/install.prop)
[ "${install_rootfs_name}" ] || error "install.rootfs_name variable is empty" 30
install_rootfs_dev=$(read_prop "install.rootfs_dev" /tmp/install.prop)
[ "${install_rootfs_dev}" ] || error "install.rootfs_dev variable is empty" 32
install_rootfs_disk=$(read_prop "install.rootfs_disk" /tmp/install.prop)
[ "${install_rootfs_disk}" ] || error "install.rootfs_disk variable is empty" 34

install_disk=$(read_prop "install.disk" /tmp/install.prop)
[ "${install_disk}" ] || error "install.disk variable is empty" 37
install_dev=$(read_prop "install.dev" /tmp/install.prop)
install_to=$(read_prop "install.to" /tmp/install.prop)
[ "${install_to}" ] || error "install.to variable is empty" 40
install_replace=$(read_prop "install.replace" /tmp/install.prop)
install_moveto=$(read_prop "install.moveto" /tmp/install.prop)
install_available=$(read_prop "install.available" /tmp/install.prop)
[ "${install_available}" ] || error "install.available variable is empty" 44
install_rootsize=$(read_prop "install.rootsize" /tmp/install.prop)
[ "${install_rootsize}" ] || error "install.rootsize variable is empty" 46

options_separatehome=$(read_prop "item.0.1" /tmp/aroma-data/options.prop)
# TODO: implement
options_encryptroot=$(read_prop "item.0.2" /tmp/aroma-data/options.prop)
echo "done"


###### ROOTFS ARCHIVE ######

echo "Preparing root filesystem archive, placed on '${install_rootfs_dev}' with name '${install_rootfs_name}'..."
rootfs_searchfolder=$(df | grep -F "${install_rootfs_dev} " | head -n1 | awk '{print $6}')
if [ "x${install_rootfs_disk}" = "xmmcblk0p8" ]; then
    rootfs_searchfolder="${rootfs_searchfolder}/media"
    echo ". Disk with rootfs archive - is internal emmc and should be already mounted into ${rootfs_searchfolder}"
else
    echo ". Disk with rootfs archive - is external storage and should be mounted manually..."
    if [ "x${rootfs_searchfolder}" = "x" ]; then
        echo ". . Yeah, disk not mounted - mount it into '/tmp/mount/${install_rootfs_disk}'"
        [ -d "/tmp/mount/${install_rootfs_disk}" ] || mkdir -p "/tmp/mount/${install_rootfs_disk}"
        [ -e "${install_rootfs_dev}" ] && mount "${install_rootfs_dev}" "/tmp/mount/${install_rootfs_disk}" && echo ". . done"
        rootfs_searchfolder=$(df | grep -F "${install_rootfs_dev} " | head -n1 | awk '{print $6}')
    fi
fi
[ "${rootfs_searchfolder}" ] || error "empty directory '${rootfs_searchfolder}' with root filesystem archive" 70
[ -d "${rootfs_searchfolder}" ] || error "not found directory '${rootfs_searchfolder}' with root filesystem archive" 71

install_rootfs_path="${rootfs_searchfolder}/${install_rootfs_name}"
echo ". Full path to archive is: '${install_rootfs_path}'"
[ -f "${install_rootfs_path}" ] || error "not found rootfs archive '${install_rootfs_path}'" 75


###### VIRTUAL DISK FILE PREPARATION ######

if [ "${install_disk}" = 'virtual' ]; then
    echo "Preparing virtual disk"
    if [ -f "${install_to}" ]; then
        echo ". Virtual disk '${install_to}' already exists!"
        if [ "${install_replace}" != '1' ]; then
            echo ". . Backupping '${install_to}' to '${install_moveto}'"
            [ "${install_moveto}" ] || error "install.moveto variable is empty" 86
            mv "${install_to}" "${install_moveto}" && echo ". . done"
            [ -f "${install_moveto}" ] || error "can't create backup target '${install_moveto}'" 88
        else
            echo ". . It will be replaced"
        fi
    fi

    install_to_dir=$(dirname "${install_to}")
    [ "${install_to_dir}" ] || error "empty '${install_to}' install directory" 95
    if [ ! -d "${install_to_dir}" ]; then
        echo ". Install directory '${install_to_dir}' not found. It will be created now..."
        mkdir -p "${install_to_dir}" && echo ". done"
    fi

    [ -d "${install_to_dir}" ] || error "can't create install directory '${install_to_dir}'" 101

    echo ". Start of creation virtual disk file '${install_to}' ${install_rootsize}Gb..."
    [ -f "${install_to}" ] && rm -f "${install_to}" && echo ". . Removed old virtual disk file"

    $bb dd if=/dev/zero of="${install_to}" bs=1M count=1 seek="${install_rootsize}K" && echo ". ..done"
    [ -f "${install_to}" ] || error "can't create virtual disk file '${install_to}'" 107
else
    echo "Preparing block device"
    [ -b "${install_to}" ] || error "'${install_to}' - isn't block device" 110
    echo ". Running fdisk to repartition of th device ${install_to} partition 1 to size ${install_rootsize}"
    echo "o\nn\np\n1\n\n+${install_rootsize}G\nw\n" | $bb fdisk "${install_to}" && echo ". done"
    install_to="$(dirname "${install_to}")/$(grep -F "${install_disk}" /proc/partitions | tail -n1 | awk '{print $4}')"
    [ -b "${install_to}" ] || error "'${install_to}' - not found created first partition" 114
fi


####### CREATING EXT4 FILESYSTEM && MOUNT ######
echo "Creating filesystem on '${install_to}'"
$bb mke2fs -F -O has_journal,extent,huge_file,flex_bg,uninit_bg,dir_nlink,extra_isize,extent -E discard,lazy_itable_init=0,lazy_journal_init=0 -I 256 "${install_to}" && echo "done"

mount_target="/tmp/mount/target"
echo "Mounting prepared filesystem '${install_to}' to '${mount_target}' directory"
[ ! -d "${mount_target}" ] && mkdir -p "${mount_target}"
mount -t ext4 "${install_to}" "${mount_target}" && echo "done"
grep -qF "${mount_target}" /proc/mounts || error "'${mount_target}' is not mount point of '${install_to}' device" 126


###### UNPACKING ROOTFS INTO MOUNTPOINT ######
echo "Unpacking rootfs archive into '${mount_target}'"
cd "${mount_target}" && $bb tar xf "${install_rootfs_path}" && echo "done"
cd /

###### CHANGES IN FSTAB TO RUN LOOP ROOT ######
if [ -f "${mount_target}/etc/fstab" ]; then
    if [ "${install_disk}" = 'virtual' ]; then
        echo "Removing android data from linux fstab - we use bind in boot process later..."
        cp "${mount_target}/etc/fstab" "${mount_target}/etc/fstab.back"
        grep -v '/dev/mmcblk0p8' "${mount_target}/etc/fstab.back" > "${mount_target}/etc/fstab"
        echo "" >> "${mount_target}/etc/fstab"
        echo "# WARNING!" >> "${mount_target}/etc/fstab"
        echo "# /dev/mmcblk0p8 /mnt/android/data ext4 - is mounted and moved by initrd (it mounted to use virtual disk ${install_to})" >> "${mount_target}/etc/fstab"
    fi
else
    echo "Not found fstab in new Linux root, ok"
fi


###### IF SET OPTION TO USE MMCBLK0P8 AS HOME ######
if [ "${options_separatehome}" = "1" ]; then
    echo "Bind home directory to mmcblk0p8"
    echo "" >> "${mount_target}/etc/fstab"
    echo "# Bind home directory" >> "${mount_target}/etc/fstab"
    echo "/mnt/android/data /home none defaults,bind 0 0" >> "${mount_target}/etc/fstab"
    if [ -d "${mount_target}/home/ubuntu" ]; then
        echo ". Move ubuntu homedir to mmcblk0p8"
        if [ -d "/data/ubuntu" ]; then
            echo ". . Backup /data/ubuntu to /data/ubuntu-old"
            mv -f /data/ubuntu /data/ubuntu-old && echo ". . done"
        fi
        mv -f "${mount_target}/home/ubuntu" /data/ubuntu && echo ". done"
    fi
fi


###### UNMOUNTING DEVICES #######
echo "Unmounting mounted devices"
if [ "x${install_rootfs_disk}" != "xmmcblk0p8" ]; then
    echo ". Umounting rootfs archive fs"
    umount "${rootfs_searchfolder}" && echo ". done"
fi

echo ". Umounting created root filesystem"
umount "${mount_target}" && echo "done"

###### DONE ######
echo "Installation completed!"
sync
echo "exit=0" > /tmp/install_exit.prop
exit 0
