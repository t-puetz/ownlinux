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

#Mount efi boot partition
echo ""
echo "Let's check if your efivars are mounted or not"
ls /sys/firmware/efi

checkBuiltPackage

espdevice=$(cat /clfs-system.config | grep "espdev" | sed 's/espdev=//g')

mkdir -pv /boot/efi
mount -vt vfat $espdevice /boot/efi

checkBuiltPackage

cd ${CLFSSOURCES}

kernelver=$(cat /clfs-system.config | grep "kernel" | sed 's/kernel=//g')
kernelmajor=$(echo $kernelver | cut -d'.' -f1)
kernelminor=$(echo $kernelver | cut -d'.' -f2 | sed 's/-rc[0-9]//g')
rcversion=$(echo $kernelver | grep "rc")
kernelvernorc=$(echo $kernelver | cut -d'.' -f2 | sed 's/-rc[0-9]//g')
clfsrootdev=$(cat /clfs-system.config | grep "clfsrootdev" | sed 's/clfsrootdev=//g')
prevkernelminor=$(expr $kernelminor - 1)
prevkernel=$kernelmajor.$prevkernelminor

#LINUX KERNEL
mkdir linux && tar xf linux-$kernelver*.tar.* -C linux --strip-components 1
cd linux

#rm -rf /lib/modules/$kernelver*
rm -rf /lib/modules/*$kernelver*
rm -rf /boot/efi/System.map-$kernelver*
rm -rf /boot/efi/vmlinuz-$kernelver*
rm -rf /lib/firmware

make mrproper

if [[ -e ${CLFSSOURCES}/kernel$kernelvernorc.conf ]]; then
  cp -v ${CLFSSOURCES}/kernel${kernelvernorc}.conf ${CLFSSOURCES}/linux/.config
else
  cp -v ${CLFSSOURCES}/kernel${prevkernel}.conf ${CLFSSOURCES}/linux/.config
fi

CC="gcc ${BUILD64}" USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make oldconfig
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

cp -v arch/x86_64/boot/bzImage /boot/efi/vmlinuz-$kernelver
cp -v System.map /boot/efi/System.map-$kernelver
cp -v .config /boot/efi/config-$kernelver

cd ${CLFSSOURCES}

#Copy source folder to /lib/modules
mv ${CLFSSOURCES}/linux /lib/modules/CLFS-$kernelver-headers

#Properly link the new kernel source folder path to subdirectories
# build/ and source/

if [[ $rcversion != "" ]]; then
  unlink /lib/modules/$kernelmajor.$kernelminor.0-$rcversion-CLFS-SYSVINIT-SVN-x86_64/build
  unlink /lib/modules/$kernelmajor.$kernelminor.0-$rcversion-CLFS-SYSVINIT-SVN-x86_64/source
  ln -sfv /lib/modules/CLFS-$kernelver-headers /lib/modules/$kernelmajor.$kernelminor.0-$rcversion-CLFS-SYSVINIT-SVN-x86_64/build
  ln -sfv /lib/modules/CLFS-$kernelver-headers /lib/modules/$kernelmajor.$kernelminor.0-$rcversion-CLFS-SYSVINIT-SVN-x86_64/source
else
  unlink /lib/modules/$kernelver-CLFS-SYSVINIT-SVN-x86_64/build
  unlink /lib/modules/$kernelver-CLFS-SYSVINIT-SVN-x86_64/source
  ln -sfv /lib/modules/CLFS-$kernelver-headers /lib/modules/$kernelver-CLFS-SYSVINIT-SVN-x86_64build
  ln -sfv /lib/modules/CLFS-$kernelver-headers /lib/modules/$kernelver-CLFS-SYSVINIT-SVN-x86_64/source
fi

#Create boot entry for goofiboot

fs_uuid=$(blkid -o value -s PARTUUID $clfsrootdev)

touch /boot/efi/loader/entries/clfs-uefi.conf
cd /boot/efi/loader/entries/
echo "title   Cross Linux from Scratch ($kernelver)" >> clfs-uefi.conf
echo "linux   /vmlinuz-$kernelver" >> clfs-uefi.conf

cd ${CLFSSOURCES}

CPUVENDOR=$(cat /proc/cpuinfo | grep "vendor_id" | head -n 1 | awk '{print $3}')

if [[ $CPUVENDOR = GenuineIntel ]]; then
  cp -v ${CLFSSOURCES}/intel-ucode.img /boot/efi/
  cd /boot/efi/loader/entries/
  echo "initrd /intel-ucode.img" >> clfs-uefi.conf
  cd ${CLFSSOURCES}
fi

if [[ $CPUVENDOR = AuthenticAMD ]]; then
  CPUFAMILY=$(grep -F -m 1 "cpu family" /proc/cpuinfo | awk '{print $4}')
  if [[ $CPUFAMILY = 23 ]]; then
  #23 is the Ryzen Gen 1 Family
  #AMD microcode is found in linux-firmare and just be injected without help of the bootloader
  #For Ryzen Gen1 the file is microcode_amd_fam17h.bin
  wget https://salsa.debian.org/hmh/amd64-microcode/raw/master/microcode_amd_fam17h.bin -P \
    /lib/firmware/amd-ucode/
  fi
  cd ${CLFSSOURCES}
fi

cd /boot/efi/loader/entries/
echo options root=PARTUUID=`echo $fs_uuid` rw >> clfs-uefi.conf

cat > /boot/efi/loader/loader.conf << "EOF"
default clfs-uefi
timeout 5
EOF

echo
echo "CONGRATS. You are done! Ownlinux is now bootable."
echo

echo "You may reboot boot now."

exit
