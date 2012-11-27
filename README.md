Asus Transformer Infinity tf700t
================================

Stuff for Asus Infinity tf700t tablet

# Build Linux Kernel
1. Get kernel source from [Asus support](http://support.asus.com/Download.aspx?SLanguage=en&m=ASUS+Transformer+Pad+Infinity+TF700T&p=28&s=1)
2. Unpack it to source/kernel/src directory:
  * $ mkdir -p source/kernel/src
  * $ cd source/kernel/src
  * $ unrar x ../../10_4_4_20_kernel.rar
  * $ tar xvf 10_4_4_20_kernel/*.tar.gz
  * $ rm -rf 10_4_4_20_kernel
  * $ cd ../../
3. Get linaro armhf gcc 4.7 toolchain from [Linaro release site](http://www.linaro.org/downloads/)
4. Unpack it to source/toolchain dir:
  * $ mkdir -p source/toolchain
  * $ tar xvf gcc-linaro-arm-linux-gnueabihf-4.7-2012.10-20121022_linux.tar.bz2 --strip-components=1 -C source/toolchain
5. Create dirs for kernel output and modules; Link kernel config to out:
  * $ mkdir -p source/kernel/out source/kernel/out_modules
  * $ ln -s kernel/.config source/kernel/out/
