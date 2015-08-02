#!/bin/bash

KERNELDIR=$(readlink -f .);
export ARCH=arm
# Your toolchain location
export CROSS_COMPILE=/your/toolchain/location
export PATH=$PATH:tools/lz4demo

# clean the build dir
make clean && make mrproper
rm "$KERNELDIR"/build/*.zip
rm "$KERNELDIR"/build/*.img

# make defconfig and zimage
make d802_defconfig
make -j4

# make modules and move to build dir
make modules -j4
for i in "$KERNELDIR"/build/system/lib/modules/; do
	rm -rf "$i" "$KERNELDIR"/build/system/lib/modules/*;
done;
mkdir -p "$KERNELDIR"/build/system/lib/modules
for i in $(find "$KERNELDIR" -name '*.ko'); do
     cp -av "$i" "$KERNELDIR"/build/system/lib/modules/;
done;
chmod 644 "$KERNELDIR"/build/system/lib/modules/*

# move zImage
mkdir "$KERNELDIR"/build/temp
cp arch/arm/boot/zImage "$KERNELDIR"/build/temp/zImage

# compress ramdisk
for i in $(find "$KERNELDIR"/ramdisk/ -name .place_holder); do
	rm -f "$i";
done;
scripts/mkbootfs "$KERNELDIR"/ramdisk | gzip > ramdisk.gz 2>/dev/null
mv ramdisk.gz "$KERNELDIR"/build/temp/

# run dtbtool
./scripts/dtbTool -v -s 2048 -o "$KERNELDIR"/build/temp/dt.img arch/arm/boot/

# make boot.img
cp scripts/mkbootimg "$KERNELDIR"/build/temp
cd "$KERNELDIR"/build/temp

./mkbootimg --kernel zImage --ramdisk ramdisk.gz --cmdline "console=ttyHSL0,115200,n8 androidboot.hardware=g2 user_debug=31 msm_rtb.filter=0x0 mdss_mdp.panel=1:dsi:0:qcom,mdss_dsi_g2_lgd_cmd" --base 0x00000000 --offset 0x05000000 --tags-addr 0x04800000 --pagesize 2048 --dt dt.img -o boot.img

cp boot.img "$KERNELDIR"/build/boot.img

# delete temp files
cd "$KERNELDIR"/build
rm -rf temp

# make flashable zip
zip -r D802-Kernel-"$(date +"[%d-%m]-[%H-%M]")".zip * >/dev/null
cd "$KERNELDIR"

