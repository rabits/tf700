#!/sbin/sh

echo "[available_rootfs.sh] Get list of available rootfs archives on any media..."
bb=/tmp/aroma/busybox

rootfs_starts="rootfs-"
rootfs_ext=".tar"
rootfs_extadd=".tar.lzma .tar.gz .tar.bz2 .tar.xz .tar"

num_found=0

echo -n "" > /tmp/available_rootfs.prop

exclude_disk=$(grep -F 'install.disk=' /tmp/install.prop | cut -d'=' -f2)

for disk in mmcblk0p8 sda sdb mmcblk1; do
    if [ "x${disk}" != "x${exclude_disk}" ]; then
        echo "Working with disk '${disk}'"
        partitions=$(grep -F "${disk}" /proc/partitions | awk '{print $4}')
        for part in $partitions; do
            echo "Trying partition '${part}'"
            if [ "x${disk}" = "xmmcblk0p8" ]; then
                # It sould be already mounted by available_space.sh
                searchfolder="/data/media"
            else
                echo "Find partitions and try mount it"
                searchfolder=$(df | grep -F "/${part} " | head -n1 | awk '{print $6}')

                if [ "x${searchfolder}" = "x" ]; then
                    [ -d "/tmp/mount/${part}" ] || mkdir -p "/tmp/mount/${part}"
                    [ -e "/dev/block/${part}" ] && mount "/dev/block/${part}" "/tmp/mount/${part}"
                    [ -e "/dev/${part}" ] && mount "/dev/${part}" "/tmp/mount/${part}"
                    searchfolder=$(df | grep -F "/${part} " | head -n1 | awk '{print $6}')
                fi
            fi

            if [ "x${searchfolder}" != "x" ]; then
                echo "Trying to search rootfs archive in ${searchfolder}"
                rootfss=$($bb find "${searchfolder}" -type f -maxdepth 1 -name "${rootfs_starts}*${rootfs_ext}*" -exec basename '{}' \;)
                if [ "${rootfss}" ]; then
                    for rootfs in $rootfss; do
                        echo "${rootfs}"
                        num_found=$(($num_found + 1))
                        for ext in $rootfs_extadd; do
                            found_ext=$(echo "${rootfs}" | $bb sed "s/^.*\(${ext}\)$/\1/")
                            if [ "x${ext}" = "x${found_ext}" ]; then
                                echo "${ext}"
                                size=$($bb expr $($bb stat -c "%s" "${searchfolder}/${rootfs}") / 1024 / 1024)
                                echo "Found rootfs archive ${num_found} '${rootfs}' on '${part}' size:${size}Mb"
                                echo "available.rootfs${num_found}.name=${rootfs}" >> /tmp/available_rootfs.prop
                                echo "available.rootfs${num_found}.disk=${part}" >> /tmp/available_rootfs.prop
                                echo "available.rootfs${num_found}.size=${size}" >> /tmp/available_rootfs.prop
                            fi
                        done
                        [ $num_found -gt 8 ] && break
                    done
                fi

                if [ "x${disk}" != "xmmcblk0p8" ]; then
                    echo "Umounting '${part}'"
                    umount "/tmp/mount/${part}"
                fi
            else
                echo "Partition '${part}' is not mounted to any direcory - skipped"
            fi
        done
    else
        echo "Skip disk ${disk} - it used as installation taget"
    fi
done

exit $num_found
