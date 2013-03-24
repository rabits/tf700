Asus Transformer Infinity tf700t
================================

Stuff for Asus Infinity tf700t tablet

# Unlock tf700 bootloader
TODO

# Backup tf700 through nvflash
1. Reboot in APX mode (Power+VolUp)
2. Connect tf700 to usb
3. Load bootloader through whelle:
  * # wheelie --blob backup/AndroidRoot/blob.bin
4. Get backup:
  * # nvflash -r --rawdeviceread 0 2944 backup/block/bricksafe_0_2944.img
  * # nvflash -r --getpartitiontable backup/block/partitiontable.txt
  * # nvflash -r --read 2 backup/block/02_BCT.img
  * # nvflash -r --read 3 backup/block/03_PT.img
  * # nvflash -r --read 4 backup/block/04_EBT.img
  * # nvflash -r --read 5 backup/block/05_SOS.img
  * # nvflash -r --read 6 backup/block/06_LNX.img
  * # nvflash -r --read 7 backup/block/07_CER.img
  * # nvflash -r --read 8 backup/block/08_IMG.img
  * # nvflash -r --read 9 backup/block/09_GP1.img
5. Also you can get other partitions with android:
  * # nvflash -r --read 10 backup/block/10_APP.img
  * # nvflash -r --read 11 backup/block/11_CAC.img
  * # nvflash -r --read 12 backup/block/12_MSC.img
  * # nvflash -r --read 13 backup/block/13_USP.img
  * # nvflash -r --read 14 backup/block/14_PER.img
  * # nvflash -r --read 15 backup/block/15_YTU.img
  * # nvflash -r --read 16 backup/block/16_CRA.img
  * # nvflash -r --read 17 backup/block/17_UDA.img

# Backup tf700 through dd on unlocked rooted android
1. Go to root mode:
  * $ su
2. Try to get locked information:
  * # hexdump -C | head -n3
3. If you see:
  * Non-zero bytes from 0x00000000 to 0x00000020 - you have unlocked bootloader and can continue backup
  * Zero bytes from 0x00000000 to 0x00380000 - you have locked or nvflashed (AndroidRoot) bootloader and can't continue this backup
4. Get partitions:
  * # dd if=/dev/block/mmcblk0 of=backup/block/bricksafe_0_2944.img ibs=4096 bs=4096 count=2944
  * # dd if=/dev/block/mmcblk0 of=backup/block/02_BCT.img ibs=4096 bs=4096 count=768
  * # dd if=/dev/block/mmcblk0 of=backup/block/03_PT.img ibs=4096 bs=4096 count=128 skip=767
  * # dd if=/dev/block/mmcblk0 of=backup/block/04_EBT.img ibs=4096 bs=4096 count=2048 skip=896
  * # dd if=/dev/block/mmcblk0 of=backup/block/05_SOS.img ibs=4096 bs=4096 skip=2944 count=2048
  * # dd if=/dev/block/mmcblk0 of=backup/block/06_LNX.img ibs=4096 bs=4096 skip=4992 count=2048
  * # dd if=/dev/block/mmcblk0 of=backup/block/07_CER.img ibs=4096 bs=4096 skip=7040 count=2048
  * # dd if=/dev/block/mmcblk0 of=backup/block/08_IMG.img ibs=4096 bs=4096 skip=9088 count=2048
  * # dd if=/dev/block/mmcblk0 of=backup/block/09_GP1.img ibs=4096 bs=4096 skip=11136 count=256

# Build Linux Kernel
1. Get kernel source from [Hundsbuah](git://github.com/Hundsbuah/tf700t_kernel.git)
  * $ git clone git://github.com/Hundsbuah/tf700t_kernel.git source/kernel/src
2. Get linaro armhf gcc 4.7 toolchain from [Linaro release site](http://www.linaro.org/downloads/)
3. Unpack it to source/toolchain dir:
  * $ tar xvf gcc-linaro-arm-linux-gnueabihf-*.tar.bz2 --strip-components=1 -C source/toolchain
4. Set need environment:
  * $ export KERNEL_OUT=../out MODULES_OUT=../out_modules CROSS_COMPILE=../../toolchain/bin/arm-linux-gnueabihf-  ARCH=arm
5. Build kernel and install modules:
  * $ cd source/kernel/src && make -j4 O=$KERNEL_OUT zImage && make -j4 modules O=$KERNEL_OUT DESTDIR=$MODULES_OUT && make -j4 modules_install O=$KERNEL_OUT INSTALL_MOD_PATH=$MODULES_OUT ; cd ../../..
6. Copy modules to Multi:
  * $ rm -rf boot/img/ramdisk/lib/modules && cp -a source/kernel/out_modules/lib/modules boot/img/ramdisk/lib/

# Create boot image
1. Install abootimg tool:
  * # apt-get install abootimg
2. Prepare ramdisk:
  * $ rm -rf boot/img/ramdisk; cp -af boot/ramdisk/stock boot/img/ramdisk && cp -af boot/ramdisk/multi/* boot/img/ramdisk/
3. Make ramdisk:
  * $ cd boot/img/ramdisk && find | cpio -H newc -o | lzma -9 > ../initrd.img && cd ../../..
4. Build boot image:
  * $ abootimg --create boot/img/boot.img -k source/kernel/out/arch/arm/boot/zImage -f boot/bootimg.cfg -r boot/img/initrd.img
5. Init blobtools:
  * $ git submodule update --init tools/blobtools
6. Build blobtools:
  * $ cd tools/blobtools && make && cd ../..
7. Prepare blob file:
  * $ tools/blobtools/blobpack boot/img/boot.blob.tosign LNX boot/img/boot.img
8. Prepend header of the blob, thanx [that](http://forum.xda-developers.com/showpost.php?p=35408420&postcount=67):
  * $ echo -ne "-SIGNED-BY-SIGNBLOB-\0\0\0\0\0\0\0\0" | cat - boot/img/boot.blob.tosign > boot/img/boot.blob

# Create rootfs on SD card
1. Name of rootfs archive file should start with "rootfs-" string
2. You can use tar.lzma (by default), tar.gz, tar.bz2, tar.xz rootfs file extensions
3. If you prepared working disk.img - you can mount it and use tools/prepare_tar.sh

# Test boot linux
1. Power off android
2. Insert SD card into dock SD cardreader
3. Connect your pad to host system by usb datacable
4. Install fastboot tool:
  * # apt-get install android-tools-fastboot
5. Power on pad and goto fastboot mode:
  * Hold on Power and Volume Down buttons
  * You see message and wait 5 seconds
  * Now you see 3 items in menu - select fastboot by click on Volume Down
  * Select fastboot mode by click on Volume Up button
  * Now you're pad in fastboot mode
6. Test your device:
  * # fastboot devices
  * You will see your device in output list
7. Boot with your boot image:
  * # fastboot boot boot/img/boot.img
8. Done. Device should boot your rootfs

# Build busybox
1. $ git submodule update --init source/busybox/src
2. $ cd source/busybox/src
3. $ export KBUILD_OUTPUT=../out ARCH=arm CROSS_COMPILE=../../toolchain/bin/arm-linux-gnueabihf-
4. $ make -j4 install
5. $ cd ../../..

# Create installer
1. Prepare kernel zImage and modules
2. Prepare busybox binary
3. Create zip archive:
  * $ tools/prepare_installer.sh installer.zip

# MISK

## elan-touchscreen xorg driver "mtev":
1. Get it:
  * $ git clone git://gitorious.org/gabrbedd/xorg-x11-drv-mtev.git
2. Unpack archive:
  * $ cd xorg-x11-drv-mtev
  * $ tar xvf *.tar.gz
3. Patch it to current Xorg api version and add button emulation:
  * $ cd xorg-x11-drv-mtev
  * $ patch -p1 < ../xorg-x11-drv-mtev-0.1.13-update-code-for-xserver-1.11.patch
  * $ patch -p1 < ../xorg-x11-drv-mtev-0.1.13-add-right-mouse-button-emulation.patch
4. Install deps:
  * $ sudo apt-get install libxi-dev
5. Build & install package:
  * $ dpkg-buildpackage -b -uc -rfakeroot
  * $ sudo dpkg -i ../xserver-xorg-input-mtev_0.1.13_armhf.deb

## ubuntu-touch specific:
* Follow this build instructions: https://wiki.ubuntu.com/Touch/Devices/tf700t
