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

sudo chown -Rv overflyer ${CLFSSOURCES}

cd ${CLFSSOURCES}

echo " "
echo "You need to install expat first. Abort otherwise!"
echo " "

checkBuiltPackage

#Python 3 64-bit

mkdir Python-3 && tar xf Python-3.7*.tar.xz -C Python-3 --strip-components 1
cd Python-3

patch -Np1 -i ../python370-multilib_gentoo.patch
patch -Np1 -i ../python370-multilib_suse.patch

checkBuiltPackage

autoreconf -fiv

checkBuiltPackage
LDFLAGS="-Wl,-rpath /usr/lib64" \
LD_LIBRARY_PATH=/usr/lib64 \
LD_LIB_PATH=/usr/lib64 \
LIBRARY_PATH=/usr/lib64 \
PYTHONPATH=/usr/lib64/python3.7/ \
USE_ARCH=64 CXX="/usr/bin/g++ ${BUILD64}" \
    CC="/usr/bin/gcc ${BUILD64}" \
    PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
            --enable-shared     \
            --libdir=/usr/lib64 \
            --libexecdir=/usr/lib64 \
            --with-system-expat \
            --with-system-ffi   \
            --with-ensurepip=yes \
            #--enable-optimizations
            LDFLAGS="-Wl,-rpath /usr/lib64"
checkBuiltPackage

LDFLAGS="-Wl,-rpath /usr/lib64" \
LD_LIBRARY_PATH=/usr/lib64 \
LD_LIB_PATH=/usr/lib64 \
LIBRARY_PATH=/usr/lib64 \
PYTHONPATH=/usr/lib64/python3.7/ \
PLATLIBDIR=/usr/lib64 make

checkBuiltPackage

PYTHONPATH=/usr/lib64/python3.7/ \
PLATLIBDIR=/usr/lib64 make altinstall

cp -rv /usr/lib/python3.7/ /usr/lib64/
rm -rf /usr/lib/python3.7/

#checkBuiltPackage

chmod -v 755 /usr/lib64/libpython3.7m.so
chmod -v 755 /usr/lib64/libpython3.so

ln -svf /usr/lib64/libpython3.7m.so /usr/lib64/libpython3.7.so
ln -svf /usr/lib64/libpython3.7m.so.1.0 /usr/lib64/libpython3.7.so.1.0
ln -sfv /usr/bin/python3.7 /usr/bin/python3

ldconfig

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf Python-3