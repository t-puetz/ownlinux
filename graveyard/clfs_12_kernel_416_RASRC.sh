#!/bin/bash

#=================
#LET'S BUILD THE KERNEL
#
#IF YOU DECIDE TO CHANGE THIS SCRIPT AND DO YOUR OWN KERNEL CONF
#CONFIGURE THE KERNEL EXACTLY TO THESE
#INSTRUCTIONS:
#
#http://www.linuxfromscratch.org/~krejzi/basic-kernel.txt 
#http://www.linuxfromscratch.org/hints/downloads/files/lfs-uefi-20170207.txt
#=====================

#Building the final CLFS System
CLFS=/
CLFSSOURCES=/sources
MAKEFLAGS="-j$(nproc)"
BUILD64="-m64"
CLFS_TARGET32="i686-pc-linux-gnu"
PKG_CONFIG_PATH64=/usr/lib64/pkgconfig

export CLFS=/
export CLFSSOURCES=/sources
export MAKEFLAGS="-j$(nproc)"
export BUILD64="-m64"
export CLFS_TARGET32="i686-pc-linux-gnu"
export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig
cd ${CLFSSOURCES}

#LINUX KERNEL
mkdir linux && tar xf linux-4.16*.tar.* -C linux --strip-components 1
cd linux

rm -rf /lib/modules/4.16.*
rm -rf /lib/modules/*4.16.*
rm -rf /boot/efi/System.map-4.16.*
rm -rf /boot/efi/vmlinuz-4.16.*
rm -rf /lib/firmware

make mrproper
cp ${CLFSSOURCES}/kernel416.conf ${CLFSSOURCES}/linux/.config

CC="gcc ${BUILD64}" USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make
CC="gcc ${BUILD64}" USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make modules_install

#With the release of kernel 4.14 the internal firmware folder was dropped
#The kernel now relies on the extra linux-firmware package which can be downcloaded at 
#https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
#CC="gcc ${BUILD64}" USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make firmware_install

cd ${CLFSSOURCES}

git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
cd linux-firmware
CC="gcc ${BUILD64}" USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make FIRMWAREDIR=/lib/firmware install

cd ${CLFSSOURCES}/linux

cp -v arch/x86_64/boot/bzImage /boot/efi/vmlinuz-4.16.0
cp -v System.map /boot/efi/System.map-4.16.0
cp -v .config /boot/efi/config-4.16.0

cd ${CLFSSOURCES}

#Copy source folder to /lib/modules
mv ${CLFSSOURCES}/linux /lib/modules/CLFS-4.16.0-headers

#Properly link the new kernel source folder path to subdirectories
# build/ and source/
unlink /lib/modules/4.16.0-CLFS-SYSVINIT-SVN-x86_64/build
unlink /lib/modules/4.16.0-CLFS-SYSVINIT-SVN-x86_64/source
ln -sfv /lib/modules/CLFS-4.16.0-headers /lib/modules/4.16.0-CLFS-SYSVINIT-SVN-x86_64/build
ln -sfv /lib/modules/CLFS-4.16.0-headers /lib/modules/4.16.0-CLFS-SYSVINIT-SVN-x86_64/source

#Create boot entry for goofiboot

fs_uuid=$(blkid -o value -s PARTUUID /dev/sda4)

touch /boot/efi/loader/entries/clfs-uefi.conf
cd /boot/efi/loader/entries/
echo "title   Cross Linux from Scratch (4.16.0)" >> clfs-uefi.conf
echo "linux   /vmlinuz-4.16.0" >> clfs-uefi.conf

cd ${CLFSSOURCES}

CPUVENDOR=$(cat /proc/cpuinfo | grep "vendor_id" | head -n 1 | awk '{print $3}')

if [[ $CPUVENDOR = GenuineIntel ]]; then
  cp -v ${CLFSSOURCES}/intel-ucode.img /boot/efi/  
  cd /boot/efi/loader/entries/
  echo "initrd /intel-ucode.img" >> clfs-uefi.conf
  cd ${CLFSSOURCES}
fi 

if [[ $CPUVENDOR = AuthenticAMD ]]; then
  CPUFAMILY = $(grep -F -m 1 "cpu family" /proc/cpuinfo | awk '{print $4}')
  if [[ $CPUFAMILY = 23 ]]; then 
  #23 is the Ryzen Gen 1 Family
  #AMD microcode is found in linux-firmare and just be injected without help of the bootloader
  #For Ryzen Gen1 the file is microcode_amd_fam17h.bin
  wget https://salsa.debian.org/hmh/amd64-microcode/raw/master/microcode_amd_fam17h.bin
  mv microcode_amd_fam17* /lib/firmware/amd-ucode/
  fi
  cd ${CLFSSOURCES}
fi 

cd /boot/efi/loader/entries/
echo options root=PARTUUID=`echo $fs_uuid` rw >> clfs-uefi.conf

cat > /boot/efi/loader/loader.conf << "EOF"
default clfs-uefi
timeout 5
EOF

echo " " 
printf "\033c"
echo " "
echo "CONGRATS. You are done! Ownlinux is now bootable."
echo " "
echo " "
printf "\033c"
echo " "
echo "Would you like to delete /tools and /cross-tools now ?"
read answer

if [[ answer = y || answer = Y || answer = yes || answer = Yes || answer = YES ]]; then
  rm -rvf /tools
  rm -rvf /cross-tools
fi

printf "\033c"
echo " "
echo "You may reboot boot now."
