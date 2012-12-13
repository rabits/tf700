Asus Transformer Infinity tf700t
================================

Stuff for Asus Infinity tf700t tablet

# Unlock tf700 bootloader
TODO

# Build Linux Kernel
1. Get kernel source from [Asus support](http://support.asus.com/Download.aspx?SLanguage=en&m=ASUS+Transformer+Pad+Infinity+TF700T&p=28&s=1)
2. Get linaro armhf gcc 4.7 toolchain from [Linaro release site](http://www.linaro.org/downloads/)
3. Unpack it to source/toolchain dir:
  * $ tar xvf gcc-linaro-arm-linux-gnueabihf-4.7-2012.10-20121022_linux.tar.bz2 --strip-components=1 -C source/toolchain
4. Set need environment:
  * $ export KERNEL_OUT=../out
  * $ export MODULES_OUT=../out_modules
  * $ export CROSS_COMPILE=../../toolchain/bin/arm-linux-gnueabihf-
  * $ export ARCH=arm
5. Unpack it to source/kernel/src directory:
  * $ cd source/kernel/src
  * $ unrar x ../../10_4_4_20_kernel.rar
  * $ tar xvf 10_4_4_20_kernel/*.tar.gz
  * $ rm -rf 10_4_4_20_kernel
6. Apply [UKSM patch](http://kerneldedup.org/projects/uksm/download/):
  * $ patch -p1 < ../../../kernel/patch/uksm/uksm*.patch
  * $ patch -p1 < ../../../kernel/patch/uksm/0*.patch
6. Change configuration of kernel:
  * $ make O=$KERNEL_OUT menuconfig
7. Build kernel and install modules:
  * $ make -j4 O=$KERNEL_OUT zImage
  * $ make -j4 modules O=$KERNEL_OUT DESTDIR=$MODULES_OUT
  * $ make -j4 modules_install O=$KERNEL_OUT INSTALL_MOD_PATH=$MODULES_OUT
8. Done

# Create boot image
1. Install abootimg tool:
  * # apt-get install abootimg
2. Make initrd:
  * # cd boot/initrd && find | cpio -H newc -o > ../img/initrd.cpio && cd ../img && gzip -9 initrd.cpio && mv initrd.cpio.gz initrd.img && cd ../..
3. Build boot image:
  * $ abootimg --create boot/img/boot.img -k source/kernel/out/arch/arm/boot/zImage -f boot/bootimg.cfg -r boot/img/initrd.img

# Create rootfs on SD card
TODO

# Pack rootfs
1. Copy rootfs from device to rootfs,img file:
  * by dd utility
2. Clean ext4 empty space for better compression:
  * # apt-get install zerofree
  * $ zerofree rootfs.img
3. Compress rootfs.img
  * $ zip -9 rootfs.img.zip rootfs.img

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
