#!/bin/bash
toolchain=$HOME/toolchain/linaro-4.9
source=$HOME/kernel_samsung_n9005
config=$PWD/hlte-eur_defconfig
ramdisk=$PWD/ramdisk
build=$PWD/out

info()
{
   echo Usage: ./$(basename $BASH_SOURCE) [option]
   echo
   echo General options:
   echo '--build     - start building kernel from source'
   echo '--clean     - remove output directory'
   echo
   echo ADB options:
   echo '--flash     - flash boot.img to connected device'
   echo '--backup    - backup current device boot.img'
   echo '--restore   - restore device backup boot.img'
   echo
}

check()
{
   if [ ! -d $toolchain ]; then
      echo --- no toolchain at: $toolchain ---
      exit 0; fi

   if [ ! -d $source ]; then
      echo --- no kernel source at: $source ---
      exit 0; fi

   if [ ! -f $config ]; then
      echo --- no defconfig at: $config ---
      exit 0; fi
}

variable()
{
   cross=$(ls $toolchain/bin | grep -m 1 gcc)
   export CROSS_COMPILE=${cross::-3}
   export PATH=$PATH:$PWD/tools:$toolchain/bin
   export USE_CCACHE=1
   export ARCH=arm
}

build_kernel()
{
   if [ ! -f $build/kernel/arch/arm/boot/zImage ]; then
      start=$(date +%s)
      make -C $source O=$source mrproper
      mkdir -p $build/kernel
      echo
      echo "--- making defconfig ---"
      ln -fs $config $source/arch/arm/configs/temp_defconfig
      make -C $source O=$build/kernel temp_defconfig
      rm $source/arch/arm/configs/temp_defconfig
      echo
      echo "--- building kernel ---"
      make -C $source -j$(grep -c processor /proc/cpuinfo) O=$build/kernel

      if [ ! -f $build/kernel/arch/arm/boot/zImage ]; then
         exit 0; fi

      stop=$(date +%s)
      let "time=$stop-$start"
      minutes=$((time / 60))
      seconds=$((time % 60))
      echo
      echo "--- compile time $minutes:$seconds ---"; fi
      echo
}

build_ramdisk()
{
   if [ ! -d $ramdisk ]; then
      echo "--- no ramdisk found ---"
      exit 0; fi

   mkbootfs $ramdisk | xz --format=lzma > $build/ramdisk.lzma

   if [ ! -f $build/zImage ]; then
      cp $build/kernel/arch/arm/boot/zImage $build; fi

   if [ ! -f $build/dt.img ]; then
      dtbtool -o $build/dt.img $build/kernel/arch/arm/boot/

      if [ ! -f $build/dt.img ]; then
         echo "--- no dt.img created ---"
         exit 0; fi; fi

   base_addr=0x00000000
   ramd_addr=0x02000000
   tags_addr=0x01e00000
   cmdline="androidboot.hardware=qcom user_debug=23 msm_rtb.filter=0x37 ehci-hcd.park=3"

   echo
   echo "--- creating boot.img ---"
   mkbootimg --kernel $build/zImage --ramdisk $build/ramdisk.lzma --dt $build/dt.img --base $base_addr --ramdisk_offset $ramd_addr --tags_offset $tags_addr --cmdline "$cmdline" --pagesize 2048 -o $build/boot.img

   if [ ! -f $build/boot.img ]; then
      echo "--- no boot.img created ---"
      exit 0; fi

   mkdir -p $build/backup
   mv $build/zImage $build/backup
   mv $build/ramdisk.lzma $build/backup
   mv $build/dt.img $build/backup
   exit 0
}

clean()
{
   echo "--- cleaning up ---"
   rm -rf $build
   make -C $source O=$source mrproper
   exit 0
}

access()
{
   device=$(adb shell getprop ro.boot.boot_recovery | tr -d '\r')

   if [ "$device" = "" ]; then
      echo "--- device not accessible ---"
      exit 0; fi
}

image()
{
   if [ "$device" = 1 ]; then
      adb shell "dd if=/data/local/tmp/boot.img of=/dev/block/platform/msm_sdcc.1/by-name/boot"
      adb shell "rm /data/local/tmp/boot.img"
   else
      adb shell su -c "dd if=/data/local/tmp/boot.img of=/dev/block/platform/msm_sdcc.1/by-name/boot"
      adb shell su -c "rm /data/local/tmp/boot.img"; fi

   adb reboot
   exit 0
}

flash()
{
   if [ ! -f $build/boot.img ]; then
      echo "--- no boot.img found ---"
      exit 0; fi

   access

   echo "--- push boot.img to device ---"
   adb push $build/boot.img /data/local/tmp

   image
}

backup()
{
   access

   if [ "$device" = 1 ]; then
      adb shell "mkdir -p /sdcard/backup"
      adb shell "dd if=/dev/block/platform/msm_sdcc.1/by-name/boot of=/sdcard/backup/boot_default.img"
   else
      adb shell su -c "mkdir -p /sdcard/backup"
      adb shell su -c "dd if=/dev/block/platform/msm_sdcc.1/by-name/boot of=/sdcard/backup/boot_default.img"; fi

   echo "--- pull boot.img from device ---"
   adb pull /sdcard/backup/boot_default.img backup/boot_default.img
   echo "--- file saved at: backup/boot_default.img ---"
   exit 0
}

restore()
{
   access

   if [ -f backup/boot_default.img ]; then
      echo "--- push local backup to device ---"
      adb push backup/boot_default.img /data/local/tmp/boot.img
      image; fi

   search=$(adb shell "if [ -f /sdcard/backup/boot_default.img ]; then echo found; fi" | tr -d '\r')
   if [ "$search" = found ]; then
      echo "--- found backup on device ---"

      if [ "$device" = 1 ]; then
         adb shell "cp /sdcard/backup/boot_default.img /data/local/tmp/boot.img"
      else
         adb shell su -c "cp /sdcard/backup/boot_default.img /data/local/tmp/boot.img"

      image; fi; fi

   echo "--- no backup found ---"
   exit 0
}

case $1 in
--build)
   check
   variable
   build_kernel
   build_ramdisk
   ;;
--clean)
   check
   variable
   clean
   ;;
--flash)
   flash
   ;;
--backup)
   backup
   ;;
--restore)
   restore
   ;;
esac

info
