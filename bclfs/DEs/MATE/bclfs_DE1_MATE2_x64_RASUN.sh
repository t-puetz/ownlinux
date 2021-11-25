#!/bin/bash

function checkBuiltPackage() {
echo ""
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
echo ""
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

export CLFS=/
export CLFSHOME=/home
export CLFSSOURCES=/sources
export MAKEFLAGS="-j$(nproc)"
export BUILD32="-m32"
export BUILD64="-m64"
export CLFS_TARGET32="i686-pc-linux-gnu"
export PKG_CONFIG_PATH=/usr/lib64/pkgconfig
export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig

cd ${CLFSSOURCES}
cd ${CLFSSOURCES}/xc/mate

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 
USE_ARCH=64 
CXX="g++ ${BUILD64}" 
CC="gcc ${BUILD64}"

export PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 
export USE_ARCH=64 
export CXX="g++ ${BUILD64}" 
export CC="gcc ${BUILD64}"

#We left off installing gtk3

#libxml2 WITH ITS PYTHON 2 MODULE

#libxml2 WITH ITS PYTHON 3 MODULE

#libxslt

#Before dconf we need to build everything needed for GTK-Doc
#That is when you have no internet connection!!!
#Otherwise disable nonet parameter for xsltproc in doc/Makefile
#BLFS does not mention that
#Otherwise dconf fails with 
#I/O error : Attempt to load network entity http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl

#dconf and dconf-editor
wget http://ftp.gnome.org/pub/gnome/sources/dconf/0.26/dconf-0.26.1.tar.xz -O \
    Dconf-0.26.1.tar.xz

wget http://ftp.gnome.org/pub/gnome/sources/dconf-editor/3.26/dconf-editor-3.26.2.tar.xz -O \
    dconf-editor-3.26.2.tar.xz

mkdir dconf && tar xf Dconf-*.tar.* -C dconf --strip-components 1
cd dconf

#This 'patch' only works when you have a working itnernet connection
sed -i 's/--nonet//' docs/Makefile

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --sysconfdir=/etc \
   --disable-gtk-doc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

tar -xf ../dconf-editor-3.22.3.tar.xz &&
cd dconf-editor-3.22.3 &&

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --sysconfdir=/etc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf dconf

#json-glib
wget http://ftp.gnome.org/pub/gnome/sources/json-glib/1.4/json-glib-1.4.2.tar.xz -O \
    json-glib-1.4.2.tar.xz

mkdir jsonglib && tar xf json-glib-*.tar.* -C jsonglib --strip-components 1
cd jsonglib

mkdir build &&
cd    build &&

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" meson --prefix=/usr --libdir=/usr/lib64.. 
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 ninja
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 sudo ninja install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf jsonglib

#libcroco

#Vala

#rustc (with cargo)

#librsvg

#shared-mime-info

#libogg

#libvorbis

#alsa-lib

#gstreamer

#gst-plugins-base

#gst-plugins-good

#libcanberra

#littleCMS2

#sqlite

#Valgrind

#libgudev

#libusb

#libgusb

#NSPR

#startup-notification

#mate-common
git clone https://github.com/mate-desktop/mate-common
cd mate-common

ACLOCAL_FLAG=/usr/share/aclocal/ CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr \
   --libdir=/usr/lib64 --sysconfdir=/etc --disable-static \
   --localstatedir=/var --bindir=/usr/bin --sbindir=/usr/sbin \
   --disable-docbook-docs

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo cp -rv macros/*.m4 /usr/share/aclocal 

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf mate-common

#Damned now we really need to build GTK-doc

#sgml-common

#Unzip

#docbook-xml

#docbook-xsl

#itstool

#gtk-doc

#mate-desktop
git clone https://github.com/mate-desktop/mate-desktop
cd mate-desktop

ACLOCAL_FLAG=/usr/share/aclocal/ CC="gcc ${BUILD64}" \
CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr \
--libdir=/usr/lib64 --sysconfdir=/etc --disable-static \
--localstatedir=/var --bindir=/usr/bin --sbindir=/usr/sbin \
--disable-gtk-doc
    
#Deactivate building of the help subdir because it will fail
#sed -i 's/HELP_DIR/#HELP_DIR/' Makefile Makefile.in
#sed -i 's/help/#help/' Makefile Makefile.in Makefile.am

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf mate-desktop
