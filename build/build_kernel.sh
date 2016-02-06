#!/bin/sh

#Script needs to be run in kernel root tree with 'bash build/build_kernel.sh'
#Accepts two arguments; cleandirs (remove build ramdisk, copied kernel and boot.img) and startfresh (also make mrproper and make clean)

#Arguments
USER_ARG=$1

#Set kernel build vars
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=/home/thomas/android/toolchain/aarch64-linux-android-4.9-e1a8a48e59638c0d24d2214c2a85046068158a08/bin/aarch64-linux-android-
DEFCONFIG=flykernel_defconfig

#Set locations
KERNEL_BIN=arch/arm64/boot/Image.gz-dtb
RAMDISK_DIR=ramdisk

#Other vars
THREADS=5

#Define helper functions
Cleandirs() {
	echo "Cleaning out directory"
	rm -rf build/out/*
}

Startfresh() {
	echo "Starting fresh"
	rm -rf build/out/*
	make mrproper && make clean
}

#Check the argument given (if any)
if [ "$USER_ARG" == "cleandirs" ];
then
	Cleandirs
fi

if [ "$USER_ARG" == "startfresh" ];
then
	Startfresh
fi

#Build the kernel
make $DEFCONFIG
make -j$THREADS

rm -rf build/install
mkdir -p build/install
make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} -j$THREADS INSTALL_MOD_PATH=build/install INSTALL_MOD_STRIP=1 modules_install
find build/install -name '*.ko' -type f -exec cp '{}' build/out/flashable/system/lib/modules/ \;

#Copy to out
cp $KERNEL_BIN build/out/Image.gz-dtb

#Build Ramdisk
build/bin/mkbootfs build/ramdisk | gzip > build/out/ramdisk.cpio.gz;

#Make boot.img
build/bin/mkbootimg --kernel build/out/Image.gz-dtb --ramdisk build/out/ramdisk.cpio.gz --base 0x00000000 --pagesize 4096 --kernel_offset 0x00008000 --ramdisk_offset 0x01000000 --tags_offset 00000100 --cmdline 'console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 user_debug=31 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 androidboot.selinux=permissive msm_rtb.filter=0x37 boot_cpus=0-5 androidboot.hardware=p1' -o build/out/flashable/boot.img
