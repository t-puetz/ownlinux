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

sudo chown -Rv overflyer ${CLFSSOURCES}

function buildSingleXLib64() {
 ./configure $XORG_CONFIG64
  make PREFIX=/usr LIBDIR=/usr/lib64
  sudo make PREFIX=/usr LIBDIR=/usr/lib64 install
}

export -f buildSingleXLib64

#Building the final CLFS System
CLFS=/
CLFSHOME=/home
CLFSSOURCES=/sources
MAKEFLAGS="-j$(nproc)"
BUILD32="-m32"
BUILD64="-m64"
CLFS_TARGET32="i686-pc-linux-gnu"
PKG_CONFIG_PATH=/usr/lib64/pkgconfig
PKG_CONFIG_PATH64=/usr/lib64/pkgconfig
ACLOCAL="aclocal -I $XORG_PREFIX/share/aclocal"

export CLFS=/
export CLFSHOME=/home
export CLFSSOURCES=/sources
export MAKEFLAGS="-j$(nproc)"
export BUILD32="-m32"
export BUILD64="-m64"
export CLFS_TARGET32="i686-pc-linux-gnu"
export PKG_CONFIG_PATH=/usr/lib64/pkgconfig
export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig
export ACLOCAL="aclocal -I $XORG_PREFIX/share/aclocal"

sudo chown -Rv overflyer ${CLFSSOURCES}

cd ${CLFSSOURCES}

mkdir -v ${CLFSSOURCES}/xc 
cd ${CLFSSOURCES}/xc

export XORG_PREFIX="/usr"
export XORG_CONFIG64="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var \
  --libdir=$XORG_PREFIX/lib64 --disable-static" 

XORG_PREFIX="/usr"
XORG_CONFIG64="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var \
  --libdir=$XORG_PREFIX/lib64 --disable-static"
  
#Down there you see one way to create a file as sudo using cat << EOF ... EOF
#Here is an alternative if this ever shouldn't work
#cat << EOF | sudo tee -a /etc/something.conf
#...
#...
#EOF

sudo bash -c 'cat > /etc/profile.d/xorg.sh << EOF
export XORG_PREFIX="/usr"
export XORG_CONFIG32="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var \
  --libdir=$XORG_PREFIX/lib --disable-static"
export XORG_CONFIG64="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var \
  --libdir=$XORG_PREFIX/lib64 --disable-static"
EOF'

chmod 644 /etc/profile.d/xorg.sh

#util-macros 64-bit  
wget https://www.x.org/pub/individual/util/util-macros-1.19.2.tar.bz2 -O \
  util-macros-1.19.2.tar.bz2
  
mkdir util-macros && tar xf util-macros-*.tar.* -C util-macros --strip-components 1
cd util-macros

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
USE_ARCH=64 CC="gcc ${BUILD64}" \ 
CXX="g++ ${BUILD64}" ./configure $XORG_CONFIG64 
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf util-macros

#Xorg Protocol Headers 
wget https://xorg.freedesktop.org/archive/individual/proto/xorgproto-2018.4.tar.bz2 -O \
  xorgproto-2018.4.tar.bz2

mkdir xorgproto && tar xf xorgproto-*.tar.* -C xorgproto --strip-components 1
cd xorgproto

mkdir build
cd build  

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
  USE_ARCH=64 CC="gcc ${BUILD64}" \ 
  CXX="g++ ${BUILD64}" meson --prefix=$XORG_PREFIX --libdir=/usr/lib64

ninja 
sudo ninja install

install -vdm 755 $XORG_PREFIX/share/doc/xorgproto-2018.4 
install -vm 644 ../[^m]*.txt ../PM_spec $XORG_PREFIX/share/doc/xorgproto-2018.4

cd ${CLFSSOURCES}/xc

#libXau 64-bit
wget https://www.x.org/pub/individual/lib/libXau-1.0.8.tar.bz2 -O \
  libXau-1.0.8.tar.bz2
  
mkdir libxau && tar xf libXau-*.tar.* -C libxau --strip-components 1
cd libxau

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libxau

#libXdmcp 64-bit
wget https://www.x.org/pub/individual/lib/libXdmcp-1.1.2.tar.bz2 -O \
  libXdcmp-1.1.2.tar.bz2

mkdir libxdcmp && tar xf libXdcmp-*.tar.* -C libxdcmp --strip-components 1
cd libxdcmp

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libxdcmp

#libffi 64-bit
wget ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz -O \
  libffi-3.2.1.tar.gz

mkdir libffi && tar xf libffi-*.tar.* -C libffi --strip-components 1
cd libffi

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libffi

cd ${CLFSSOURCES}
cd ${CLFSSOURCES}/xc

#xcb-proto 64-bit
wget http://xcb.freedesktop.org/dist/xcb-proto-1.13.tar.bz2 -O \
  xcb-proto-1.13.tar.bz2

  
mkdir xcb-proto && tar xf xcb-proto-*.tar.* -C xcb-proto --strip-components 1
cd xcb-proto

CXX="/usr/bin/g++ ${BUILD64}" \
CC="/usr/bin/gcc ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure $XORG_CONFIG64 

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xcb-proto

#libxcb 64-bit
wget http://xcb.freedesktop.org/dist/libxcb-1.13.tar.bz2 -O \
  libxcb-1.13.tar.bz2

mkdir libxcb && tar xf libxcb-*.tar.* -C libxcb --strip-components 1
cd libxcb

sed -i "s/pthread-stubs//" configure

USE_ARCH=64 CXX="g++ ${BUILD64}" CC="gcc ${BUILD64}" \
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure $XORG_CONFIG64    \
            --enable-xinput   \
            --without-doxygen \
            --libdir=/usr/lib64 \
            --without-doxygen \
            --docdir='${datadir}'/doc/libxcb-1.13
            

make check
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libxcb

#fontconfig 64-bit
wget https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.0.tar.gz -O \
  fontconfig-2.13.0.tar.gz
  
mkdir fontconfig && tar xf fontconfig-*.tar.* -C fontconfig --strip-components 1
cd fontconfig

rm -f src/fcobjshash.h

USE_ARCH=64 CXX="g++ ${BUILD64}" CC="gcc ${BUILD64}" \
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
            --sysconfdir=/etc    \
            --localstatedir=/var \
            --disable-docs       \
            --docdir=/usr/share/doc/fontconfig-2.13.0 \
            --libdir=/usr/lib64

make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf fontconfig
