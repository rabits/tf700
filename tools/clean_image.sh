#!/bin/sh
#
# Clean Image
# Script for cleaning img from personal and junk info, like history, users etc.
#
# Run it in root of mounted image 
#

default_user="ubuntu"

head -n4 $0 | tail -n2

if [ "$USER" != "root" ]; then
    echo "E: This script must be run as root" 1>&2
    exit 1
fi

if [ ! -e etc/init/tf700.conf ]; then
    echo "E: File etc/init/tf700.conf is not present - current dir $PWD is not rootfs for tf700" 1>&2
    exit 1
else
    echo "I: Recognized $PWD as tf700 root dir"
fi

echo "I: Cleaning users..."
for i in home/*; do
    if [ "$i" != "home/${default_user}" ]; then
        echo "I:  Delete '$i'"
        rm -rf "$i"
        subuser=$(echo "$i" | sed 's|^home/||')
        echo "I:   Remove '${subuser}' from passwd*, group*, shadow*, gsadow* "
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
mv etc/init/ssh.conf /etc/init/ssh.disabled && echo " ok" || echo " fail"

echo -n "I: Remove network-manager net configs..."
rm -rf etc/NetworkManager/* && echo " ok" || echo " fail"

echo -n "I: Remove xorg specific configuration..."
rm -rf etc/X11/xorg.conf.d/05-*.conf && echo " ok" || echo " fail"
