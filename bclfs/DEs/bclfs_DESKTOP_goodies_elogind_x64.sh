#!/bin/bash

function checkBuiltPackage() {
echo " "
echo "Make sure you are able to continue... [Y/N]"
while read -n1 -r -p "[Y/N]   " && [[ $REPLY != q ]]; do
  case $REPLY in
    Y) break 1;;
    N) echo "$EXIT"
       echo "Fix it!"
       exit 1;;
    *) echo " Try again. Type y or n";;
  esac
done
echo " "
}

#Building the final CLFS System
CLFS=/
CLFSHOME=/home
CLFSSOURCES=/sources
CLFSTOOLS=/tools
CLFSCROSSTOOLS=/cross-tools
CLFSFILESYSTEM=ext4
CLFSROOTDEV=/dev/sda4
CLFSHOMEDEV=/dev/sda5
MAKEFLAGS="-j$(nproc)"
BUILD32="-m32"
BUILD64="-m64"
CLFS_TARGET32="i686-pc-linux-gnu"
PKG_CONFIG_PATH=/usr/lib64/pkgconfig
PKG_CONFIG_PATH64=/usr/lib64/pkgconfig

export CLFS=/
export CLFSUSER=clfs
export CLFSHOME=/home
export CLFSSOURCES=/sources
export CLFSTOOLS=/tools
export CLFSCROSSTOOLS=/cross-tools
export CLFSFILESYSTEM=ext4
export CLFSROOTDEV=/dev/sda4
export CLFSHOMEDEV=/dev/sda5
export MAKEFLAGS="-j$(nproc)"
export BUILD32="-m32"
export BUILD64="-m64"
export CLFS_TARGET32="i686-pc-linux-gnu"
export PKG_CONFIG_PATH=/usr/lib64/pkgconfig
export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig

cd ${CLFSSOURCES}
cd ${CLFSSOURCES}/xc/mate

#We will only do 64-bit builds in this script
#We compiled Xorg with 32-bit libraries
#That should suffice

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 
USE_ARCH=64 
CXX="g++ ${BUILD64}" 
CC="gcc ${BUILD64}"

export PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 
export USE_ARCH=64 
export CXX="g++ ${BUILD64}" 
export CC="gcc ${BUILD64}"

#elogind
git clone https://github.com/elogind/elogind
cd elogind

#patch meson.build
#483 +        ['memfd_create',      '''#define _GNU_SOURCE
#    +                                 #include <sys/mman.h>'''],
#497 +        ['copy_file_range',   '''#define _GNU_SOURCE
#    +                                 #include <sys/syscall.h>
#    +                                 #include <unistd.h>'''],

#patch src/basic/fileio.h
#30 + define _GNU_SOURCE
#31 + #include <sys/mman.h>

patch -Np0 -i ../elogind_235.3_memfd_copyfilerange.patch 

PKG_CONFIG_PATH=/usr/lib64/pkgconfig/ \
meson build --prefix=/usr            \
	--sysconfdir=/etc            \
	--localstatedir=/var         \
	--libexecdir=/usr/lib64      \
	--bindir=/usr/bin            \
	--sbindir=/usr/sbin          \
	-Dpamlibdir=/lib64/security  \
	-Dpamconfdir=/etc/pam.d      \
	--libdir=/usr/lib64          \
	-Drootlibexecdir=/usr/lib64/elogind


CPPFLAGS="-I/usr/include" LD_LIBRARY_PATH="/usr/lib64" LD_LIB_PATH="/usr/lib64" \
LIBRARY_PATH="/usr/lib64" PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64} -lrt" \
USE_ARCH=64 CXX="g++ ${BUILD64}" PREFIX=/usr LIBDIR=/usr/lib64 ninja -C build
sudo ninja -C build install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf elogind
