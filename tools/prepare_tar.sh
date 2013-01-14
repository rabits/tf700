#!/bin/sh
#
# Prepare Tar
# Script for preparing tar archive with rootfs from current directory rootfs
#
# Run it in root of mounted rootfs
#

default_user="ubuntu"

DIST_REPO=$(dirname $0)/../.git
DIST_VER=$(git --git-dir="${DIST_REPO}" tag | tail -n1)

OUTPUT="$1"

head -n4 $0 | tail -n2

if [ "x${OUTPUT}" = "x" ]; then
    echo "E: To create archive please specify output file" 1>&2
    echo "Usage: $0 <output_file.tar.lzma>" 1>&2
    exit 1
fi
touch "${OUTPUT}"
if [ ! -f "${OUTPUT}" ]; then
    echo "E: To create archive please specify valid output file" 1>&2
    echo "Usage: $0 <output_file.tar.lzma>" 1>&2
    exit 1
fi
rm -f "${OUTPUT}"

echo "I: Preparing ${DIST_VER} tar file"

if [ "x${USER}" != "xroot" ]; then
    echo "E: This script must be run as root" 1>&2
    exit 1
fi

if [ ! -e etc/init/tf700.conf ]; then
    echo "E: File etc/init/tf700.conf is not present - current dir $PWD is not rootfs for tf700" 1>&2
    exit 1
else
    echo "I: Recognized $PWD as tf700 root dir"
fi

#################

echo "I: Backupping some files..."
[ -d  tmp/preparing/etc ] || mkdir -p tmp/preparing/etc
cp -a etc/group etc/group- etc/passwd etc/passwd- etc/shadow etc/shadow- etc/gshadow- etc/gshadow etc/hostname etc/hosts tmp/preparing/etc/
[ -d  tmp/preparing/ssh ] || mkdir -p tmp/preparing/ssh
cp -a etc/ssh/ssh_host*_key* tmp/preparing/ssh/
cp -a etc/NetworkManager/system-connections tmp/preparing/system-connections

echo "I: Excluding users..."
for i in home/*; do
    if [ "$i" != "home/${default_user}" ]; then
        echo "I:  Exclude '$i'"
        excludes="${excludes} --exclude=$i"
        subuser=$(echo "$i" | sed 's|^home/||')
        echo "I:   Remove '${subuser}' from passwd*, group*, shadow*, gsadow*"
        sed -i "s/${subuser},\|,${subuser}\|${subuser}$//g" etc/group etc/group- etc/passwd etc/passwd- etc/shadow etc/shadow- etc/gshadow- etc/gshadow
        sed -i ":a;N;\$!ba;s/\n${subuser}[^\n]*//g" etc/group etc/group- etc/passwd etc/passwd- etc/shadow etc/shadow- etc/gshadow- etc/gshadow
    fi
done
echo "I: done"

echo "I: Cleaning lightdm sessions..."
for i in var/cache/lightdm/dmrc/*; do
    if [ "$i" != "${default_user}" ]; then
        echo "I:   Remove session $i"
        rm -rf "$i"
    fi
done
echo "I: done"

echo -n "I: Cleaning ${default_user} user..."
cd "home/${default_user}" && \
rm -rf .cache .mozilla .bash_history examples.desktop .gksu.lock .goutputstream-* \
    .ICEauthority .Xauthority .viminfo .xsession-errors .xsession-errors.old && \
cd ../.. && echo " ok" || echo " fail"

echo -n "I: Cleaning logs..."
cd var/log && \
rm -rf apt/*.log.* ConsoleKit/*.* cups/*.* lightdm/* upstart/* && \
rm -rf Xorg.* alternatives.log.* aptitude.* auth.log.* btmp.* daemon.log.* \
    debug.* \ dmesg.* dpkg.log.* kdm.log.* kern.log.* messages.* pm-powersave.* \
    pm-suspend.log.* popularity-contest.* syslog.* user.log.* wtmp.* Xorg.* && \
echo -n "" > auth.log && \
    echo -n "" > boot && \
    echo -n "" > daemon.log && \
    echo -n "" > debug && \
    echo -n "" > dmesg && \
    echo -n "" > faillog && \
    echo -n "" > fontconfig.log && \
    echo -n "" > kern.log && \
    echo -n "" > lastlog && \
    echo -n "" > messages && \
    echo -n "" > pm-suspend.log && \
    echo -n "" > syslog && \
    echo -n "" > udev && \
    echo -n "" > user.log && \
cd ../.. && echo " ok" || echo " fail"

echo -n "I: Set hostname..."
echo "tf700" > etc/hostname && \
echo "127.0.0.1   localhost
127.0.1.1   tf700" > etc/hosts && echo " ok" || echo " fail"

echo -n "I: Remove ssh keys..."
rm -rf etc/ssh/ssh_host*_key* && echo " ok" || echo " fail"

echo -n "I: Disable ssh daemon..."
mv etc/init/ssh.conf etc/init/ssh.disabled && echo " ok" || echo " fail"

echo -n "I: Remove network-manager net configs..."
rm -rf etc/NetworkManager/system-connections/* && echo " ok" || echo " fail"

echo -n "I: Remove xorg specific configuration..."
rm -rf etc/X11/xorg.conf.d/05-*.conf && echo " ok" || echo " fail"

echo -n "I: Set lsb_version..."
cat - > etc/lsb-release <<EOF
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=12.10
DISTRIB_CODENAME=quantal
DISTRIB_DESCRIPTION="Ubuntu 12.10 tf700${DIST_VER}"
EOF
echo "Ubuntu 12.10 tf700${DIST_VER} \n \l" > etc/issue
echo " ok"

echo "I: Creating archive '${OUTPUT}' ..."
tar cp --exclude=lost+found --exclude='proc/*' --exclude='proc/.*' --exclude='sys/*' --exclude='sys/.*' --exclude='dev/*' --exclude='dev/.*' --exclude='tmp/*' --exclude='tmp/.*' --exclude='var/cache/apt/archives/*.deb' $excludes . | lzma -9 > "$OUTPUT"
echo "done"

echo "I: Recover backupped files"
mv -f tmp/preparing/etc/* etc/
mv -f tmp/preparing/ssh/* etc/ssh/
mv -f tmp/preparing/system-connections/* etc/NetworkManager/system-connections/
mv -f etc/init/ssh.disabled etc/init/ssh.conf
echo "done"

echo
echo "PREPARATION OF TAR ARCHIVE IS COMPLETE"
