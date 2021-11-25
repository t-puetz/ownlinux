#!/bin/bash

function checkBuiltPackage() {
echo " "
echo "Did everything build fine?: [Y/N]"
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

function buildSingleXLib64() {
  PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
  USE_ARCH=64 CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" ./configure $XORG_CONFIG64
  make PREFIX=/usr LIBDIR=/usr/lib64
  sudo make PREFIX=/usr LIBDIR=/usr/lib64 install
}

export -f buildSingleXLib64

#Building the final CLFS System
CLFS=/
CLFSSOURCES=/sources
MAKEFLAGS="-j$(nproc)"
BUILD32="-m32"
BUILD64="-m64"
CLFS_TARGET32="i686-pc-linux-gnu"
PKG_CONFIG_PATH=/usr/lib64/pkgconfig
PKG_CONFIG_PATH64=/usr/lib64/pkgconfig
ACLOCAL="aclocal -I $XORG_PREFIX/share/aclocal"

export CLFS=/
export CLFSSOURCES=/sources
export MAKEFLAGS="-j$(nproc)"
export BUILD32="-m32"
export BUILD64="-m64"
export CLFS_TARGET32="i686-pc-linux-gnu"
export PKG_CONFIG_PATH32=/usr/lib/pkgconfig
export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig
export ACLOCAL="aclocal -I $XORG_PREFIX/share/aclocal"

mkdir -pv ${CLFSSOURCES}/xc
cd ${CLFSSOURCES}/xc

export XORG_PREFIX="/usr"
export XORG_CONFIG64="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var \
  --libdir=$XORG_PREFIX/lib64"

XORG_PREFIX="/usr"
XORG_CONFIG64="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var \
  --libdir=$XORG_PREFIX/lib64"

cat > lib-7.md5 << "EOF"
c5ba432dd1514d858053ffe9f4737dd8  xtrans-1.3.5.tar.bz2
0f618db70c4054ca67cee0cc156a4255  libX11-1.6.5.tar.bz2
52df7c4c1f0badd9f82ab124fb32eb97  libXext-1.3.3.tar.bz2
d79d9fe2aa55eb0f69b1a4351e1368f7  libFS-1.0.7.tar.bz2
addfb1e897ca8079531669c7c7711726  libICE-1.0.9.tar.bz2
499a7773c65aba513609fe651853c5f3  libSM-1.2.2.tar.bz2
eeea9d5af3e6c143d0ea1721d27a5e49  libXScrnSaver-1.2.3.tar.bz2
8f5b5576fbabba29a05f3ca2226f74d3  libXt-1.1.5.tar.bz2
41d92ab627dfa06568076043f3e089e4  libXmu-1.1.2.tar.bz2
20f4627672edb2bd06a749f11aa97302  libXpm-3.5.12.tar.bz2
e5e06eb14a608b58746bdd1c0bd7b8e3  libXaw-1.0.13.tar.bz2
07e01e046a0215574f36a3aacb148be0  libXfixes-5.0.3.tar.bz2
f7a218dcbf6f0848599c6c36fc65c51a  libXcomposite-0.4.4.tar.bz2
802179a76bded0b658f4e9ec5e1830a4  libXrender-0.9.10.tar.bz2
58fe3514e1e7135cf364101e714d1a14  libXcursor-1.1.15.tar.bz2
0cf292de2a9fa2e9a939aefde68fd34f  libXdamage-1.1.4.tar.bz2
0920924c3a9ebc1265517bdd2f9fde50  libfontenc-1.1.3.tar.bz2
b7ca87dfafeb5205b28a1e91ac3efe85  libXfont2-2.0.3.tar.bz2
331b3a2a3a1a78b5b44cfbd43f86fcfe  libXft-2.3.2.tar.bz2
1f0f2719c020655a60aee334ddd26d67  libXi-1.7.9.tar.bz2
0d5f826a197dae74da67af4a9ef35885  libXinerama-1.1.4.tar.bz2
28e486f1d491b757173dd85ba34ee884  libXrandr-1.5.1.tar.bz2
5d6d443d1abc8e1f6fc1c57fb27729bb  libXres-1.2.0.tar.bz2
ef8c2c1d16a00bd95b9fdcef63b8a2ca  libXtst-1.2.3.tar.bz2
210b6ef30dda2256d54763136faa37b9  libXv-1.0.11.tar.bz2
4cbe1c1def7a5e1b0ed5fce8e512f4c6  libXvMC-1.0.10.tar.bz2
d7dd9b9df336b7dd4028b6b56542ff2c  libXxf86dga-1.1.4.tar.bz2
298b8fff82df17304dfdb5fe4066fe3a  libXxf86vm-1.1.4.tar.bz2
d2f1f0ec68ac3932dd7f1d9aa0a7a11c  libdmx-1.1.4.tar.bz2
8f436e151d5106a9cfaa71857a066d33  libpciaccess-0.14.tar.bz2
4a4cfeaf24dab1b991903455d6d7d404  libxkbfile-1.0.9.tar.bz2
42dda8016943dc12aff2c03a036e0937  libxshmfence-1.3.tar.bz2
EOF

mkdir lib
cd lib
grep -v '^#' ../lib-7.md5 | awk '{print $2}' | wget -i- -c \
    -B https://www.x.org/pub/individual/lib/ 
md5sum -c ../lib-7.md5

USE_ARCH=64 CXX="g++ ${BUILD64}" CC="gcc ${BUILD64}" \
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \

export PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 

for package in $(grep -v '^#' ../lib-7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir
  case $packagedir in
    libICE* )
      export PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 
      USE_ARCH=64 \
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CXX="g++ ${BUILD64}" \ 
      CC="gcc ${BUILD64}" ./configure $XORG_CONFIG64 \
        ICE_LIBS=-lpthread
    ;;

    libXfont2-[0-9]* )
      export PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 
      USE_ARCH=64 \
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CXX="g++ ${BUILD64}" \ 
      CC="gcc ${BUILD64}" ./configure $XORG_CONFIG64 \
          --disable-devel-docs
    ;;

    libXt-[0-9]* )
      export PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 
      USE_ARCH=64 \
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CXX="g++ ${BUILD64}" \ 
      CC="gcc ${BUILD64}" ./configure $XORG_CONFIG64 \
                  --with-appdefaultdir=/etc/X11/app-defaults
    ;;

    * )
     export PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 
     USE_ARCH=64 \
     PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
     CXX="g++ ${BUILD64}" \
     CC="gcc ${BUILD64}" ./configure $XORG_CONFIG64
    ;;
  esac
  make PREFIX=/usr LIBDIR=/usr/lib64
  #make check 2>&1 | tee ../$packagedir-make_check.log
  #grep -A9 summary *make_check.log
  sudo make PREFIX=/usr LIBDIR=/usr/lib64 install
  #checkBuiltPackage
  popd
  rm -rf $packagedir
  sudo /sbin/ldconfig
done

cd ${CLFSSOURCES}/xc

#xcb-util 64-bit
wget http://xcb.freedesktop.org/dist/xcb-util-0.4.0.tar.bz2 -O \
  xcb-util-0.4.0.tar.bz2
  
mkdir xcb-util && tar xf xcb-util-*.tar.* -C xcb-util --strip-components 1
cd xcb-util

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xcb-util

#xcb-util-image 64-bit
wget http://xcb.freedesktop.org/dist/xcb-util-image-0.4.0.tar.bz2 -O \
  xcb-util-image-0.4.0.tar.bz2
  
mkdir xcb-util-image && tar xf xcb-util-image-*.tar.* -C xcb-util-image --strip-components 1
cd xcb-util-image

buildSingleXLib64
#LD_LIBRARY_PATH=$XORG_PREFIX/lib make check

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xcb-util-image

#xcb-util-keysyms 64-bit
wget http://xcb.freedesktop.org/dist/xcb-util-keysyms-0.4.0.tar.bz2 -O \
  xcb-util-keysyms-0.4.0.tar.bz2
  
mkdir xcb-util-keysyms && tar xf xcb-util-keysyms-*.tar.* -C xcb-util-keysyms --strip-components 1
cd xcb-util-keysyms

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xcb-util-keysyms

#xcb-util-renderutil 64-bit
wget http://xcb.freedesktop.org/dist/xcb-util-renderutil-0.3.9.tar.bz2 -O \
  xcb-util-renderutil-0.3.9.tar.bz2
    
mkdir xcb-util-renderutil && tar xf xcb-util-renderutil-*.tar.* -C xcb-util-renderutil --strip-components 1
cd xcb-util-renderutil

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xcb-util-renderutil

#xcb-util-wm 64-bit
wget http://xcb.freedesktop.org/dist/xcb-util-wm-0.4.1.tar.bz2 -O \
  xcb-util-wm-0.4.1.tar.bz2

mkdir xcb-util-wm && tar xf xcb-util-wm-*.tar.* -C xcb-util-wm --strip-components 1
cd xcb-util-wm

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xcb-util-wm

#xcb-util-cursor 64-bit
wget http://xcb.freedesktop.org/dist/xcb-util-cursor-0.1.3.tar.bz2 -O \
  xcb-util-cursor-0.1.3.tar.bz2

mkdir xcb-util-cursor && tar xf xcb-util-cursor-*.tar.* -C xcb-util-cursor --strip-components 1
cd xcb-util-cursor

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xcb-util-cursor

#libdrm 64-bit
wget https://dri.freedesktop.org/libdrm/libdrm-2.4.92.tar.bz2 -O \
  libdrm-2.4.92.tar.bz2

mkdir libdrm && tar xf libdrm-*.tar.* -C libdrm --strip-components 1

cd libdrm
mkdir build 
cd build 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
  USE_ARCH=64 CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" \
meson --prefix=$XORG_PREFIX -Dudev=true --libdir=/usr/lib64
ninja 
sudo ninja install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libdrm

#So before we can build Mesa
#There are some recommended deps
#elfutils-0.169 (required for the radeonsi driver)
#libvdpau-1.1.1 (to build VDPAU drivers)
#LLVM-4.0.1 (required for Gallium3D, r300, and radeonsi drivers and for the llvmpipe software rasterizer)
#See http://www.mesa3d.org/systems.html for more information)
#I have an NVIDIA GTX 1080
#I will go with vdpau for now
#Later I will install the proprietary NVIDIA drivers

#libvdpau 64-bit
wget http://people.freedesktop.org/~aplattner/vdpau/libvdpau-1.1.1.tar.bz2 -O \
  libvdpau-1.1.1.tar.bz2
  
mkdir libvdpau && tar xf libvdpau-*.tar.* -C libvdpau --strip-components 1
cd libvdpau

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
USE_ARCH=64 CC="gcc ${BUILD64}" \
CXX="g++ ${BUILD64}" ./configure $XORG_CONFIG64 \
            --docdir=/usr/share/doc/libvdpau-1.1.1 &&

make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf libvdpau

#Mesa 64-bit
wget https://mesa.freedesktop.org/archive/mesa-18.1.5.tar.xz -O \
  Mesa-18.1.5.tar.xz
  
wget http://www.linuxfromscratch.org/patches/blfs/svn/mesa-18.1.5-add_xdemos-1.patch -O \
    mesa-18.1.5-add_xdemos-1.patch

mkdir Mesa && tar xf Mesa-*.tar.* -C Mesa --strip-components 1
cd Mesa

patch -Np1 -i ../mesa*.patch

checkBuiltPackage

GLL_DRV="i915,r600,nouveau,svga,swrast"

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
USE_ARCH=64 CC="gcc ${BUILD64}" \
CXX="g++ ${BUILD64}" ./autogen.sh CFLAGS='-O2' CXXFLAGS='-O2' \
            --prefix=$XORG_PREFIX        \
            --sysconfdir=/etc            \
            --enable-texture-float       \
            --libdir=/usr/lib64          \
            --enable-osmesa              \
            --enable-xa                  \
            --enable-glx-tls             \
            --with-platforms="drm,x11" \
            --with-gallium-drivers=$GLL_DRV 

unset GLL_DRV

make PREFIX=/usr LIBDIR=/usr/lib64
make -C xdemos DEMOS_PREFIX=$XORG_PREFIX LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install
sudo make -C xdemos DEMOS_PREFIX=$XORG_PREFIX LIBDIR=/usr/lib64 install

install -v -dm755 /usr/share/doc/mesa-18.1.5 &&
cp -rfv docs/* /usr/share/doc/mesa-18.1.5

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf Mesa

cd ${CLFSSOURCES}/xc

#xbitmaps 64-bit
wget https://www.x.org/pub/individual/data/xbitmaps-1.1.2.tar.bz2 -O \
  xbitmaps-1.1.2.tar.bz2
  
mkdir xbitmaps && tar xf xbitmaps-*.tar.* -C xbitmaps --strip-components 1
cd xbitmaps

buildSingleXLib64

cd ${CLFSSOURCES}/xc
echo " "
echo "Add this point you COULD install Linux-PAM!"
echo "Xorg Apps will follow now and accept Linux-PAM as ooptional dep"
echo "If you want that answer next question with No"
echo "And after Linux-PAM is install, sudo and shadow and cracklib are rebuilt"
echo "start thies script again with"
echo "bash <(sed -n '<linenumber>,\$p' <scriptname.sh>)"
echo "Remove that one backslash befor the prompt/dollar sign though though!"
echo "Also you must run cblfs_1 script for installing libpng!!! Required Dep!"
echo " "

checkBuiltPackage
rm -rf xbitmaps
