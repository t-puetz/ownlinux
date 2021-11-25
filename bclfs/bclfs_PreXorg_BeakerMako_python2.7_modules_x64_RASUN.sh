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

sudo chown -Rv overflyer ${CLFSSOURCES}

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
export PKG_CONFIG_PATH=/usr/lib64/pkgconfig
export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig
export ACLOCAL="aclocal -I $XORG_PREFIX/share/aclocal"

mkdir -pv ${CLFSSOURCES}/xc
cd ${CLFSSOURCES}/xc

#Build Python Module Beaker
#required by Python Module Mako

wget https://pypi.python.org/packages/93/b2/12de6937b06e9615dbb3cb3a1c9af17f133f435bdef59f4ad42032b6eb49/Beaker-1.9.0.tar.gz -O \
  Beaker-1.9.0.tar.gz

mkdir pybeaker && tar xf Beaker-*.tar.* -C pybeaker --strip-components 1
cd pybeaker

CXX="g++ ${BUILD64}" USE_ARCH=64 CC="gcc ${BUILD64}" PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 

python2.7 setup.py build
sudo python2.7 setup.py install --verbose --prefix=/usr/lib64 --install-lib=/usr/lib64/python2.7/site-packages --optimize=1

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf pybeaker

#Build Python Module MarkupSafe
#required by Python Module Mako

wget https://files.pythonhosted.org/packages/4d/de/32d741db316d8fdb7680822dd37001ef7a448255de9699ab4bfcbdf4172b/MarkupSafe-1.0.tar.gz -O \
  MarkupSafe-1.0.tar.gz

mkdir pyMarkupSafe && tar xf MarkupSafe-*.tar.* -C pyMarkupSafe --strip-components 1
cd pyMarkupSafe

CXX="g++ ${BUILD64}" USE_ARCH=64 CC="gcc ${BUILD64}" PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 

python2.7 setup.py build
sudo python2.7 setup.py install --verbose --prefix=/usr --install-lib=/usr/lib64/python2.7/site-packages --optimize=1

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf pyMarkupSafe

#Python 2.7 Mako modules
#64-bit
wget https://pypi.python.org/packages/source/M/Mako/Mako-1.0.4.tar.gz -O \
  Mako-1.0.4.tar.gz

mkdir pymako && tar xf Mako-*.tar.* -C pymako --strip-components 1
cd pymako

CXX="g++ ${BUILD64}" USE_ARCH=64 CC="gcc ${BUILD64}" PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 

python2.7 setup.py build
sudo python2.7 setup.py install --verbose --prefix=/usr --install-lib=/usr/lib64/python2.7/site-packages --optimize=1

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf pymako
