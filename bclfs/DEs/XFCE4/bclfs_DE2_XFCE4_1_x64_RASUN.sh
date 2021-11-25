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
CLFSSOURCES=/sources
MAKEFLAGS="-j$(nproc)"
BUILD32="-m32"
BUILD64="-m64"
CLFS_TARGET32="i686-pc-linux-gnu"
PKG_CONFIG_PATH=/usr/lib64/pkgconfig
PKG_CONFIG_PATH64=/usr/lib64/pkgconfig

export CLFS=/
export CLFSUSER=clfs
export CLFSSOURCES=/sources
export MAKEFLAGS="-j$(nproc)"
export BUILD32="-m32"
export BUILD64="-m64"
export CLFS_TARGET32="i686-pc-linux-gnu"
export PKG_CONFIG_PATH=/usr/lib64/pkgconfig
export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig

sudo rm -rf ${CLFSSOURCES}/xc/xfce4

sudo mkdir -pv ${CLFSSOURCES}/xc/xfce4
cd ${CLFSSOURCES}/xc/xfce4

sudo chown -Rv overflyer ${CLFSSOURCES}/xc

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

#PCRE (NOT PCRE2!!!)
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.41.tar.bz2 -O \
  pcre-8.41.tar.bz2

mkdir pcre && tar xf pcre-*.tar.* -C pcre --strip-components 1
cd pcre

./configure --prefix=/usr                     \
            --docdir=/usr/share/doc/pcre-8.41 \
            --enable-unicode-properties       \
            --enable-pcre16                   \
            --enable-pcre32                   \
            --enable-pcregrep-libz            \
            --enable-pcregrep-libbz2          \
            --enable-pcretest-libreadline     \
            --disable-static                  \
            --libdir=/usr/lib64

make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install 
sudo mv -v /usr/lib64/libpcre.so.* /lib64 &&
sudo ln -sfv ../../../../lib64/$(readlink /usr/lib64/libpcre.so) /usr/lib64/libpcre.so
sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf pcre

#Glib
wget http://ftp.gnome.org/pub/gnome/sources/glib/2.54/glib-2.54.3.tar.xz -O \
  glib-2.54.3.tar.xz

wget http://www.linuxfromscratch.org/patches/blfs/svn/glib-2.54.3-meson_fixes-1.patch -O \
  Glib-2.54.3-meson_fixes-1.patch
  
wget http://www.linuxfromscratch.org/patches/blfs/svn/glib-2.54.3-skip_warnings-1.patch -O \
  Glib-2.54.3-skip_warnings-1.patch

mkdir glib && tar xf glib-*.tar.* -C glib --strip-components 1
cd glib

patch -Np1 -i ../Glib-2.54.3-skip_warnings-1.patch
checkBuiltPackage
echo
patch -Np1 -i ../Glib-2.54.3-meson_fixes-1.patch 
checkBuiltPackage

mkdir build-glib 
cd    build-glib 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" meson --prefix=/usr --libdir=/usr/lib64 \
	-Dwith-pcre=system -Dwith-docs=no .. &&
ninja
sudo ninja install

chmod -v 755 /usr/bin/{gdbus-codegen,glib-gettextize} 

mkdir -p /usr/share/doc/glib-2.54.3 
cp -r ../docs/reference/{NEWS,README,gio,glib,gobject} /usr/share/doc/glib-2.54.3

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf glib

#shared-mime-info
wget http://freedesktop.org/~hadess/shared-mime-info-1.9.tar.xz -O \
    shared-mime-info-1.9.tar.xz

mkdir sharedmimeinfo && tar xf shared-mime-info-*.tar.* -C sharedmimeinfo --strip-components 1
cd sharedmimeinfo

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 

make check
checkBuiltPackage

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf sharedmimeinfo

cd ${CLFSSOURCES} 

#harfbuzz 64-bit
mkdir harfbuzz && tar xf harfbuzz-*.tar.* -C harfbuzz --strip-components 1
cd harfbuzz

ln -sfv /usr/bin/python3.7 /usr/bin/python
ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python

LIBDIR=/usr/lib64 USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
CXX="g++ ${BUILD64}" CC="gcc ${BUILD64}" PYTHON=/usr/bin/python \
./configure --prefix=/usr --libdir=/usr/lib64 --with-gobject
PREFIX=/usr LIBDIR=/usr/lib64 PYTHON=/usr/bin/python make 
PREFIX=/usr LIBDIR=/usr/lib64 PYTHON=/usr/bin/python make install

unset PYTHON
unlink /usr/bin/python
unlink /usr/bin/python-config

cd ${CLFSSOURCES} 
checkBuiltPackage
rm -rf harfbuzz

cd ${CLFSSOURCES}/xc/xfce4

#libxfce4util
wget http://archive.xfce.org/src/xfce/libxfce4util/4.12/libxfce4util-4.12.1.tar.bz2 -O \
  libxfce4util-4.12.1.tar.bz2

mkdir libxfce4util && tar xf libxfce4util-*.tar.* -C libxfce4util --strip-components 1
cd libxfce4util

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-gtk-doc

make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libxfce4util

#dbus
wget https://dbus.freedesktop.org/releases/dbus/dbus-1.12.8.tar.gz -O \
  dbus-1.12.8.tar.gz

mkdir dbus && tar xf dbus-*.tar.* -C dbus --strip-components 1
cd dbus

sudo groupadd -g 18 messagebus 
sudo useradd -c "D-Bus Message Daemon User" -d /var/run/dbus \
        -u 18 -g messagebus -s /bin/false messagebus

./configure --prefix=/usr                        \
            --sysconfdir=/etc                    \
            --libdir=/usr/lib64                  \
            --localstatedir=/var                 \
            --disable-doxygen-docs               \
            --disable-xml-docs                   \
            --disable-static                     \
            --docdir=/usr/share/doc/dbus-1.12.8 \
            --with-console-auth-dir=/run/console \
            --with-system-pid-file=/run/dbus/pid \
            --with-system-socket=/run/dbus/system_bus_socket \
            --disable-systemd \
            --without-systemdsystemunitdir
            
make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install 

sudo mkdir /lib/lsb
sudo mkdir /lib64/lsb

sudo mkdir /etc/dbus-1/
sudo mkdir /usr/share/dbus-1/
sudo mkdir /var/run/dbus
 
sudo dbus-uuidgen --ensure

sudo bash -c 'cat > /etc/dbus-1/session-local.conf << "EOF"
<!DOCTYPE busconfig PUBLIC
 "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>

  <!-- Search for .service files in /usr/local -->
  <servicedir>/usr/local/share/dbus-1/services</servicedir>

</busconfig>
EOF'

#Add dbus openRC-Script here

#More info ondbus:
#http://www.linuxfromscratch.org/hints/downloads/files/execute-session-scripts-using-kdm.txt

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf dbus

#dbus-glib
wget http://dbus.freedesktop.org/releases/dbus-glib/dbus-glib-0.110.tar.gz -O \
    dbus-glib-0.110.tar.gz

mkdir dbus-glib && tar xf dbus-glib-*.tar.* -C dbus-glib --strip-components 1
cd dbus-glib

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
            --sysconfdir=/etc \
            --libdir=/usr/lib64 \
            --disable-static \
            --disable-gtk-doc
            
make PREFIX=/usr LIBDIR=/usr/lib4
sudo make PREFIX=/usr LIBDIR=/usr/lib4 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf dbus-glib

#Xfconf
wget http://archive.xfce.org/src/xfce/xfconf/4.12/xfconf-4.12.1.tar.bz2 -O \
  xfconf-4.12.1.tar.bz2

mkdir xfconf && tar xf xfconf-*.tar.* -C xfconf --strip-components 1
cd xfconf

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
            --libdir=/usr/lib64 \
            --disable-static \
            --disable-gtk-doc
            
make PREFIX=/usr LIBDIR=/usr/lib4
sudo make PREFIX=/usr LIBDIR=/usr/lib4 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfconf

sudo pip3.7 install six
sudo cp -rv /usr/lib/python3.7 /usr/lib64
sudo rm -rf /usr/lib/python3.7

#desktop-file-utils
wget http://freedesktop.org/software/desktop-file-utils/releases/desktop-file-utils-0.23.tar.xz -O \
  desktop-file-utils-0.23.tar.xz

mkdir desktop-file-utils && tar xf desktop-file-utils-*.tar.* -C desktop-file-utils --strip-components 1
cd desktop-file-utils

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
    --prefix=/usr \
    --libdir=/usr/lib64

make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo update-desktop-database /usr/share/applications

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf desktop-file-utils

#gobj-introspection
wget https://github.com/GNOME/gobject-introspection/archive/1.56.1.tar.gz -O \
        gobject-introspection-1.56.1.tar.gz

ln -sfv /usr/bin/python3.7 /usr/bin/python
ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python

mkdir gobject-introspection && tar xf gobject-introspection-*.tar.* -C gobject-introspection --strip-components 1
cd gobject-introspection

sh autogen.sh

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PYTHON=/usr/bin/python ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static \
     --enable-shared \
     --with-python=/usr/bin/python3.7

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" install

unset PYTHON
unlink /usr/bin/python
unlink /usr/bin/python-config

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gobject-introspection

#at-spi2-core
wget http://ftp.gnome.org/pub/gnome/sources/at-spi2-core/2.28/at-spi2-core-2.28.0.tar.xz -O \
  at-spi2-core-2.28.0.tar.xz
  
ln -sfv /usr/bin/python3.7 /usr/bin/python
ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python

mkdir atspi2core && tar xf at-spi2-core-*.tar.* -C atspi2core --strip-components 1
cd atspi2core

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PYTHON=/usr/bin/python3.7 meson \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static \
     --enable-shared \
     --sysconfdir=/etc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ninja PREFIX=/usr LIBDIR=/usr/lib64
sudo ninja PREFIX=/usr LIBDIR=/usr/lib64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" install

unset PYTHON
unlink /usr/bin/python
unlink /usr/bin/python-config

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf atspi2core

#ATK
wget http://ftp.gnome.org/pub/gnome/sources/atk/2.28/atk-2.28.1.tar.xz -O \
    atk-2.28.1.tar.xz

ln -sfv /usr/bin/python3.7 /usr/bin/python
ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python

mkdir atk && tar xf atk-*.tar.* -C atk --strip-components 1
cd atk

mkdir build 
cd    build 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PYTHON=/usr/bin/python3.7 meson --prefix=/usr \
     --libdir=/usr/lib64 \
     --sysconfdir=/etc
     
ninja
sudo ninja install

unset PYTHON
unlink /usr/bin/python
unlink /usr/bin/python-config

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf atk

#at-spi2-atk
wget http://ftp.gnome.org/pub/gnome/sources/at-spi2-atk/2.26/at-spi2-atk-2.26.2.tar.xz -O \
  at-spi2-atk-2.26.2.tar.xz

mkdir atspi2atk && tar xf at-spi2-atk-*.tar.* -C atspi2atk --strip-components 1
cd atspi2atk

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static \
     --enable-shared \
     --sysconfdir=/etc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf atspi2atk

#Cython
wget https://pypi.python.org/packages/ee/2a/c4d2cdd19c84c32d978d18e9355d1ba9982a383de87d0fcb5928553d37f4/Cython-0.27.3.tar.gz -O \
    Cython-0.27.3.tar.gz

mkdir cython && tar xf Cython-*.tar.* -C cython --strip-components 1
cd cython

python3 setup.py build
sudo python3 setup.py install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf cython

#yasm
wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz -O \
    yasm-1.3.0.tar.gz

mkdir yasm && tar xf yasm-*.tar.* -C yasm --strip-components 1
cd yasm

sed -i 's#) ytasm.*#)#' Makefile.in

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf yasm

#libjpeg-turbo
wget http://downloads.sourceforge.net/libjpeg-turbo/libjpeg-turbo-1.5.3.tar.gz -O \
    libjpeg-turbo-1.5.3.tar.gz

mkdir libjpeg-turbo && tar xf libjpeg-turbo-*.tar.* -C libjpeg-turbo --strip-components 1
cd libjpeg-turbo

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --mandir=/usr/share/man \
     --with-jpeg8            \
     --disable-static        \
     --docdir=/usr/share/doc/libjpeg-turbo-1.5.3

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libjpeg-turbo

#libpng installed by goofibootbootloader script ....sh
#libepoxy installed by Xorg script

#libtiff
wget http://download.osgeo.org/libtiff/tiff-4.0.9.tar.gz -O \
    tiff-4.0.9.tar.gz

mkdir libtiff && tar xf tiff-*.tar.* -C libtiff --strip-components 1
cd libtiff

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libtiff

#ICU
wget http://download.icu-project.org/files/icu4c/61.1/icu4c-61_1-src.tgz -O \
    icu4c-61_1-src.tgz

mkdir icu && tar xf icu*.tgz -C icu --strip-components 1
cd icu
cd source

#this patch is probably ONLY for glibx 2.26
#it might cause icu to fail building for another glibc version
#sed -i 's/xlocale/locale/' i18n/digitlst.cpp

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf icu

#harfbuzz, freetype2 and which were installed by Xorg scripts
#Pixman and libpng needed by  Cairo are also already installed by UEFI-bootloader script and Xorg script, respectively

#Cairo
wget http://cairographics.org/releases/cairo-1.14.12.tar.xz -O \
    cairo-1.14.12.tar.xz

mkdir cairo && tar xf cairo-*.tar.* -C cairo --strip-components 1
cd cairo

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static \
     --enable-tee

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf cairo

#Pango
wget http://ftp.gnome.org/pub/gnome/sources/pango/1.42/pango-1.42.1.tar.xz -O \
    pango-1.42.1.tar.xz
    
ln -sfv /usr/bin/python3.7 /usr/bin/python
ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python

mkdir pango && tar xf pango-*.tar.* -C pango --strip-components 1
cd pango

mkdir build
cd build

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PYTHON=/usr/bin/python3.7 meson --prefix=/usr \
     --libdir=/usr/lib64 \
     --sysconfdir=/etc

ninja
sudo ninja install

unset PYTHON
unlink /usr/bin/python
unlink /usr/bin/python-config

sudo install -vm 644 ../pango-view/pango-view.1.in /usr/share/man/man1/pango-view.1

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf pango

#hicolor-icon-theme
wget http://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.17.tar.xz -O \
    hicolor-icon-theme-0.17.tar.xz

mkdir hicoloricontheme && tar xf hicolor-icon-theme-*.tar.* -C hicoloricontheme --strip-components 1
cd hicoloricontheme

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 

sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf hicoloricontheme

#adwaita-icon-theme
wget http://ftp.gnome.org/pub/gnome/sources/adwaita-icon-theme/3.26/adwaita-icon-theme-3.26.1.tar.xz -O \
    adwaita-icon-theme-3.26.1.tar.xz

mkdir adwaiticontheme && tar xf adwaita-icon-theme-*.tar.* -C adwaiticontheme --strip-components 1
cd adwaiticontheme

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
     --libdir=/usr/lib64 

sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf adwaiticontheme

#libxml2 WITH ITS PYTHON 2 MODULE
wget http://xmlsoft.org/sources/libxml2-2.9.8.tar.gz -O \
    libxml2-2.9.8.tar.gz

#Download testsuite. WE NEED IT to build the Python module!
wget http://www.w3.org/XML/Test/xmlts20130923.tar.gz -O \
    xmlts20130923.tar.gz

mkdir libxml2 && tar xf libxml2-*.tar.* -C libxml2 --strip-components 1
cd libxml2

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --disable-static \
   --with-history   \
   --libdir=/usr/lib64 \
   --with-python=/usr/bin/python2.7 \
   --with-icu \
   --with-threads

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64

tar xf ../xmlts20130923.tar.gz
make check > check.log
grep -E '^Total|expected' check.log
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install 

cd ${CLFSSOURCES}/xc/xfce4

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libxml2

#libxml2 WITH ITS PYTHON 3 MODULE

wget http://www.linuxfromscratch.org/patches/blfs/svn/libxml2-2.9.8-python3_hack-1.patch -O \
	libxml2-2.9.8-python3_hack-1.patch

mkdir libxml2 && tar xf libxml2-*.tar.* -C libxml2 --strip-components 1
cd libxml2

patch -Np1 -i ../libxml2-2.9.8-python3_hack-1.patch

#run this to build Python3 module
#Python2 module would be the default
#We try not to use Python2 in CLFS multib!
sed -i '/_PyVerify_fd/,+1d' python/types.c

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --disable-static \
   --with-history   \
   --libdir=/usr/lib64 \
   --with-python=/usr/bin/python3.7 \
   --with-icu \
   --with-threads

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64

tar xf ../xmlts20130923.tar.gz
make check > check.log
grep -E '^Total|expected' check.log
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install 

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libxml2

#gdk-pixbuf
wget http://ftp.gnome.org/pub/gnome/sources/gdk-pixbuf/2.36/gdk-pixbuf-2.36.12.tar.xz -O \
    gdk-pixbuf-2.36.12.tar.xz
    
ln -sfv /usr/bin/python3.7 /usr/bin/python
ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python3.7

mkdir gdk-pixbuf && tar xf gdk-pixbuf-*.tar.* -C gdk-pixbuf --strip-components 1
cd gdk-pixbuf

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PYTHON=/usr/bin/python3.7 ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --with-x11

make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64

#make -k check
#checkBuiltPackage

sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

unset PYTHON
unlink /usr/bin/python
unlink /usr/bin/python-config

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gdk-pixbuf

#GTK2
wget http://ftp.gnome.org/pub/gnome/sources/gtk+/2.24/gtk+-2.24.32.tar.xz -O \
    gtk+-2.24.32.tar.xz

ln -sfv /usr/bin/python3.7 /usr/bin/python
ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python3.7

mkdir gtk2 && tar xf gtk+-2*.tar.* -C gtk2 --strip-components 1
cd gtk2

sed -e 's#l \(gtk-.*\).sgml#& -o \1#' \
    -i docs/{faq,tutorial}/Makefile.in     

CC="gcc ${BUILD64}" PYTHON=/usr/bin/python3.7 \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
  --sysconfdir=/etc --libdir=/usr/lib64

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PYTHON=/usr/bin/python make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make PYTHON=/usr/bin/python LIBDIR=/usr/lib64 PREFIX=/usr install

cat > ~/.gtkrc-2.0 << "EOF"
include "/usr/share/themes/Glider/gtk-2.0/gtkrc"
gtk-icon-theme-name = "hicolor"
EOF

sudo bash -c 'cat > /etc/gtk-2.0/gtkrc << "EOF"
include "/usr/share/themes/Clearlooks/gtk-2.0/gtkrc"
gtk-icon-theme-name = "elementary"
EOF'

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gtk2

#gtk3
wget http://ftp.gnome.org/pub/gnome/sources/gtk+/3.22/gtk+-3.22.30.tar.xz -O \
    gtk+-3.22.30.tar.xz

mkdir gtk3 && tar xf gtk+-3*.tar.* -C gtk3 --strip-components 1
cd gtk3

ln -sfv /usr/bin/python3.7 /usr/bin/python
ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python3.7

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PYTHON=/usr/bin/python ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --sysconfdir=/etc         \
     --enable-broadway-backend \
     --enable-x11-backend      \
     --disable-wayland-backend 

make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PYTHON=/usr/bin/python PREFIX=/usr LIBDIR=/usr/lib64

make -k check
checkBuiltPackage

sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PYTHON=/usr/bin/python PREFIX=/usr LIBDIR=/usr/lib64 install

mkdir -vp ~/.config/gtk-3.0
cat > ~/.config/gtk-3.0/settings.ini << "EOF"
[Settings]
gtk-theme-name = Adwaita
gtk-icon-theme-name = oxygen
gtk-font-name = DejaVu Sans 12
gtk-cursor-theme-size = 18
gtk-toolbar-style = GTK_TOOLBAR_BOTH_HORIZ
gtk-xft-antialias = 1
gtk-xft-hinting = 1
gtk-xft-hintstyle = hintslight
gtk-xft-rgba = rgb
gtk-cursor-theme-name = Adwaita
EOF

unset PYTHON
unlink /usr/bin/python
unlink /usr/bin/python-config

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gtk3

#startup-notification
wget http://www.freedesktop.org/software/startup-notification/releases/startup-notification-0.12.tar.gz -O \
    startup-notification-0.12.tar.gz

mkdir startup-notification && tar xf startup-notification-*.tar.* -C startup-notification --strip-components 1
cd startup-notification

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo install -v -m644 -D doc/startup-notification.txt \
    /usr/share/doc/startup-notification-0.12/startup-notification.txt

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf startup-notification

#Test::Needs (optional for Perl Module Tests)

#URI
wget https://www.cpan.org/authors/id/E/ET/ETHER/URI-1.74.tar.gz -O \
  URI-1.74.tar.gz

mkdir URI && tar xf URI-*.tar.* -C URI --strip-components 1
cd URI

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL 
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
#make test
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf URI

##HTML-Tagset
#http://search.cpan.org/CPAN/authors/id/P/PE/PETDANCE/HTML-Tagset-3.20.tar.gz -O \
#  HTML-Tagset-3.20.tar.gz
#
#mkdir HTML-Tagset && tar xf HTML-Tagset-*.tar.* -C HTML-Tagset --strip-components 1
#cd HTML-Tagset
#
#PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL 
#PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
##make test
#sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install
#
#cd ${CLFSSOURCES}/xc/xfce4
#checkBuiltPackage
#sudo rm -rf HTML-Tagset
#
##HTML::Parser
#wget https://www.cpan.org/authors/id/G/GA/GAAS/HTML-Parser-3.72.tar.gz -O \
#  HTML-Parser-3.72.tar.gz
# 
#mkdir HTML-Parser && tar xf HTML-Parser-*.tar.* -C HTML-Parser --strip-components 1
#cd HTML-Parser
#
#PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL 
#PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
##make test
#sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install
#
#cd ${CLFSSOURCES}/xc/xfce4
#checkBuiltPackage
#sudo rm -rf HTML-Parser
#
#Encode::Locale
#URI
#HTML::Parser
#HTTP::Date
#IO::HTML
#LWP:MediaTypes
#HTTP::Message
#HTML::Form
#HTTP::Cookies
#HTTP::Negotiate
#Net::HTTP
#WWW::RobotRules
#HTTP::Daemon
#File::Listing
#Test::RequiresInternet
#Test::Fatal
#libwww-perl

#Insert optional GLADE dependency here
#wget http://ftp.gnome.org/pub/GNOME/sources/glade3/3.8/ for gtk2
#wget http://ftp.gnome.org/pub/GNOME/sources/glade/3.20/ for gtk3
#https://glade.gnome.org/

#libxfce4ui
wget http://archive.xfce.org/src/xfce/libxfce4ui/4.12/libxfce4ui-4.12.1.tar.bz2 -O \
  libxfce4ui-4.12.1.tar.bz2

mkdir libxfce4ui && tar xf libxfce4ui-*.tar.* -C libxfce4ui --strip-components 1
cd libxfce4ui

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
     --sysconfdir=/etc \
     --libdir=/usr/lib64 \
     --disable-gtk-doc

make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install 

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libxfce4ui

#Exo
wget http://archive.xfce.org/src/xfce/exo/0.12/exo-0.12.2.tar.bz2 -O \
  exo-0.12.2.tar.bz2

mkdir exo && tar xf exo-*.tar.* -C exo --strip-components 1
cd exo

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
     --sysconfdir=/etc \
     --libdir=/usr/lib64 \
     --disable-gtk-doc

make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install 

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf exo

#Garcon
wget http://archive.xfce.org/src/xfce/garcon/0.6/garcon-0.6.1.tar.bz2 -O \
  garcon-0.6.1.tar.bz2

mkdir garcon && tar xf garcon-*.tar.* -C garcon --strip-components 1
cd garcon

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
     --sysconfdir=/etc \
     --libdir=/usr/lib64 \
     --disable-gtk-doc

make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install 

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf garcon

#gtk-xfce-engine
wget http://archive.xfce.org/src/xfce/gtk-xfce-engine/3.2/gtk-xfce-engine-3.2.0.tar.bz2 -O \
gtk-xfce-engine-3.2.0.tar.bz2

mkdir gtk-xfce-engine && tar xf gtk-xfce-engine-*.tar.* -C gtk-xfce-engine --strip-components 1
cd gtk-xfce-engine

sed -i 's/\xd6/\xc3\x96/' gtk-3.0/xfce_style_types.h

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
     --sysconfdir=/etc \
     --libdir=/usr/lib64 \
     --disable-gtk-doc

make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gtk-xfce-engine

#libwnk
wget http://ftp.gnome.org/pub/gnome/sources/libwnck/2.30/libwnck-2.30.7.tar.xz -O \
    libwnck-2.30.7.tar.xz
    
ln -sfv /usr/bin/python3.7 /usr/bin/python
ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python3.7

mkdir libwnck && tar xf libwnck-*.tar.* -C libwnck --strip-components 1
cd libwnck

CC="gcc ${BUILD64}"   CXX="g++ ${BUILD64}" USE_ARCH=64    \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} PYTHON=/usr/bin/python3.7 ./configure --prefix=/usr    \
  --libdir=/usr/lib64 --sysconfdir=/etc --disable-static \
  --program-suffix=-1
  
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PYTHON=/usr/bin/python3.7 GETTEXT_PACKAGE=libwnck-1 LIBDIR=/usr/lib64 PREFIX=/usr
sudo make PYTHON=/usr/bin/python3.7 GETTEXT_PACKAGE=libwnck-1 LIBDIR=/usr/lib64 PREFIX=/usr install

unset PYTHON
unlink /usr/bin/python
unlink /usr/bin/python-config

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libwnck

#iso-codes 
wget https://pkg-isocodes.alioth.debian.org/downloads/iso-codes-3.79.tar.xz -O \
	iso-codes-3.79.tar.xz 
mkdir iso-codes && tar xf iso-codes-*.tar.* -C iso-codes --strip-components 1 
cd iso-codes 

sed -i '/^LN_S/s/s/sfvn/' */Makefile 

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \ 
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
	--libdir=/usr/lib64
 
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr 

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install 

unset PYTHON
unlink /usr/bin/python
unlink /usr/bin/python-config

cd ${CLFSSOURCES}/xc/xfce4 
checkBuiltPackage 
sudo rm -rf

#libxklavier
wget  https://people.freedesktop.org/~svu/libxklavier-5.4.tar.bz2 -O \
    libxklavier-5.4.tar.bz2
    
ln -sfv /usr/bin/python3.7 /usr/bin/python
ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python3.7

mkdir libxklavier && tar xf libxklavier-*.tar.* -C libxklavier --strip-components 1
cd libxklavier
    
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 PYTHON=/usr/bin/python3.7 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr --libdir=/usr/lib64 \
    --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PYTHON=/usr/bin/python3.7 make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PYTHON=/usr/bin/python PREFIX=/usr install

unset PYTHON
unlink /usr/bin/python
unlink /usr/bin/python-config

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libxklavier

#xfce4-dev-tools
git clone https://github.com/xfce-mirror/xfce4-dev-tools
cd xfce4-dev-tools

sh autogen.sh
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --libdir=/usr/lib64 
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install
cd ${CLFSSOURCES}/xc/xfce4

checkBuiltPackage

sudo rm -rf xfce4-dev-tools

#xfce4-panel
wget http://archive.xfce.org/src/xfce/xfce4-panel/4.12/xfce4-panel-4.12.2.tar.bz2 -O \
  xfce4-panel-4.12.2.tar.bz2
  
mkdir xfce4-panel && tar xf xfce4-panel-*.tar.* -C xfce4-panel --strip-components 1
cd xfce4-panel

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64    \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr    \
  --libdir=/usr/lib64 --sysconfdir=/etc --disable-static \
  --disable-gtk-doc --enable-gtk3
  
make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-panel

#libcroco
wget http://ftp.gnome.org/pub/gnome/sources/libcroco/0.6/libcroco-0.6.12.tar.xz -O \
    libcroco-0.6.12.tar.xz

mkdir libcroco && tar xf libcroco-*.tar.* -C libcroco --strip-components 1
cd libcroco

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libcroco

#Vala
wget http://ftp.gnome.org/pub/gnome/sources/vala/0.40/vala-0.40.3.tar.xz -O \
    vala-0.40.3.tar.xz

mkdir vala && tar xf vala-*.tar.* -C vala --strip-components 1
cd vala

sed -i '115d; 121,137d; 139,140d'  configure.ac 
sed -i '/valadoc/d' Makefile.am                 
ACLOCAL= autoreconf -fiv  

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf vala

  GNU nano 2.9.3                                                                                                                    /xfce4_experiemental.sh                                                                                                                     Modified  

#rustc
wget https://static.rust-lang.org/dist/rustc-1.25.0-src.tar.gz -O \
        rustc-1.25.0-src.tar.gz

sudo ln -sfv /usr/bin/python3.7 /usr/bin/python
sudo ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python3.7

CC="gcc"
CXX="g++"
export CC="gcc"
export CXX="g++"

sudo ln -sfv /usr/bin/gcc /usr/bin/cc
sudo ln -sfv /usr/bin/g++ /usr/bin/c++

mkdir rustc && tar xf rustc-*.tar.* -C rustc --strip-components 1
cd rustc

rm config.toml.example

cat <<EOF > config.toml

[llvm]
targets = "X86"
ninja = true

[build]
# install cargo as well as rust
extended = true
docs = false

[install]
prefix = "/usr"
sysconfdir = "/etc"
docdir = "share/doc/rustc-1.25.0"
libdir = "/usr/lib64"

[rust]
default-linker = "gcc"
channel = "stable"
rpath = false

EOF

./x.py build

checkBuiltPackage 

sudo bash -c 'PYTHON=/usr/bin/python3.7 cc="/usr/bin/cc" CC="/usr/bin/cc" \
	RUSTFLAGS="$RUSTFLAGS -C link-args=-lffi" \
	CXX="/usr/bin/c++" cxx="/usr/bin/c++" ./x.py build'

sudo bash -c 'PYTHON=/usr/bin/python3.7 cc="/usr/bin/cc" CC="/usr/bin/cc" \
	RUSTFLAGS="$RUSTFLAGS -C link-args=-lffi" \
	CXX="/usr/bin/c++" cxx="/usr/bin/c++" \
	DESTDIR=${PWD}/install  ./x.py install'

sudo chown -R root:root install

sudo cp -a install/* /

checkBuiltPackage

unset PYTHON
unlink /usr/bin/python
unlink /usr/bin/python-config
sudo unlink /usr/bin/cc
sudo unlink /usr/bin/g++ /usr/bin/c++

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf rustc


CXX="g++ ${BUILD64}" 
CC="gcc ${BUILD64}"
export CXX="g++ ${BUILD64}" 
export CC="gcc ${BUILD64}"

#librsvg
wget http://ftp.gnome.org/pub/gnome/sources/librsvg/2.42/librsvg-2.42.2.tar.xz -O \
    librsvg-2.42.2.tar.xz

mkdir librsvg && tar xf librsvg-*.tar.* -C librsvg --strip-components 1
cd librsvg

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --enable-vala

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf librsvg

#xfce4-xkb-plugin
wget http://archive.xfce.org/src/panel-plugins/xfce4-xkb-plugin/0.7/xfce4-xkb-plugin-0.7.1.tar.bz2 -O \
  xfce4-xkb-plugin-0.7.1.tar.bz2

mkdir xfce4-xkb-plugin && tar xf xfce4-xkb-plugin-*.tar.* -C xfce4-xkb-plugin --strip-components 1
cd xfce4-xkb-plugin

sed -e 's|xfce4/panel-plugins|xfce4/panel/plugins|' \
    -i panel-plugin/{Makefile.in,xkb-plugin.desktop.in.in} 

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64    \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr  \
  --libdir=/usr/lib64 --libexecdir=/usr/lib64 --disable-static \
  --disable-debug
  
make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-xkb-plugin

#XML::NamespaceSupport
wget http://search.cpan.org/CPAN/authors/id/P/PE/PERIGRIN/XML-NamespaceSupport-1.12.tar.gz -O \
	XML-NamespaceSupport-1.12.tar.gz

mkdir XML-NamespaceSupport && tar xf XML-NamespaceSupport-*.tar.* -C XML-NamespaceSupport --strip-components 1
cd XML-NamespaceSupport

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
#make test
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf XML-NamespaceSupport

#XML::SAX::Base
wget http://search.cpan.org/CPAN/authors/id/G/GR/GRANTM/XML-SAX-Base-1.09.tar.gz -O \
	XML-SAX-Base-1.09.tar.gz

mkdir XML-SAX-Base && tar xf XML-SAX-Base-*.tar.* -C XML-SAX-Base --strip-components 1
cd XML-SAX-Base

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
#make test
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf XML-SAX-Base*

#XML::SAX
wget https://cpan.metacpan.org/authors/id/G/GR/GRANTM/XML-SAX-1.00.tar.gz -O \
	XML-SAX-1.00.tar.gz

mkdir XML-SAX && tar xf XML-SAX-*.tar.* -C XML-SAX --strip-components 1
cd XML-SAX

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
#make test
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf XML-SAX

#XML::SAX::Expat
wget http://search.cpan.org/CPAN/authors/id/B/BJ/BJOERN/XML-SAX-Expat-0.51.tar.gz -O \
	XML-SAX-Expat-0.51.tar.gz

mkdir XML-SAX-Expat && tar xf XML-SAX-Expat-*.tar.* -C XML-SAX-Expat --strip-components 1
cd XML-SAX-Expat

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
#make test
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf XML-SAX-Expat

#XML::LibXML
wget https://cpan.metacpan.org/authors/id/S/SH/SHLOMIF/XML-LibXML-2.0132.tar.gz -O \
	XML-LibXML-2.0132.tar.gz

mkdir XML-LibXML && tar xf XML-LibXML-*.tar.* -C XML-LibXML --strip-components 1
cd XML-LibXML

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
#make test
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf XML-LibXML

#XML::Simple
wget https://www.cpan.org/authors/id/G/GR/GRANTM/XML-Simple-2.25.tar.gz -O \
    XML-Simple-2.25.tar.gz

mkdir XML-Simple && tar xf XML-Simple-*.tar.* -C XML-Simple --strip-components 1
cd XML-Simple

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
#make test
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf XML-Simple

#icon-naming-utils
wget http://tango.freedesktop.org/releases/icon-naming-utils-0.8.90.tar.bz2 -O \
	icon-naming-utils-0.8.90.tar.bz2

mkdir icon-naming-utils && tar xf icon-naming-utils-*.tar.* -C icon-naming-utils --strip-components 1
cd icon-naming-utils

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64    \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr  \
  --libdir=/usr/lib64
 
make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf icon-naming-utils

#gnome-icon-theme
wget http://ftp.gnome.org/pub/gnome/sources/gnome-icon-theme/3.12/gnome-icon-theme-3.12.0.tar.xz -O \
    gnome-icon-theme-3.12.0.tar.xz

mkdir gnome-icon-theme && tar xf gnome-icon-theme-*.tar.* -C gnome-icon-theme --strip-components 1
cd gnome-icon-theme

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 

sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gnome-icon-theme

#libudev

#libgudev
wget http://ftp.gnome.org/pub/gnome/sources/libgudev/232/libgudev-232.tar.xz -O \
    libgudev-232.tar.xz

mkdir libgudev && tar xf libgudev-*.tar.* -C libgudev --strip-components 1
cd libgudev

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --disable-umockdev

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libgudev

#libgpg-error
wget ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.32.tar.bz2 -O \
    libgpg-error-1.32.tar.bz2
    
mkdir libgpgerror && tar xf libgpg-error-*.tar.* -C libgpgerror --strip-components 1
cd libgpgerror

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr --libdir=/usr/lib64
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -r libgpgerror

#libgcrypt
wget https://www.gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.8.3.tar.bz2 -O \
    libgcrypt-1.8.3.tar.bz2
    
mkdir libgcrypt && tar xf libgcrypt-*.tar.* -C libgcrypt --strip-components 1
cd libgcrypt

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr --libdir=/usr/lib64
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -r libgcrypt

#libtasn1
wget http://ftp.gnu.org/gnu/libtasn1/libtasn1-4.13.tar.gz -O \
    libtasn1-4.13.tar.gz

mkdir libtasn1 && tar xf libtasn1-*.tar.* -C libtasn1 --strip-components 1
cd libtasn1

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -r libtasn1

#p11-kit
wget https://github.com/p11-glue/p11-kit/releases/download/0.23.12/p11-kit-0.23.12.tar.gz -O \
    p11-kit-0.23.12.tar.gz
    
mkdir p11-kit && tar xf p11-kit-*.tar.* -C p11-kit --strip-components 1
cd p11-kit

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static \
    --sysconfdir=/etc \
    --with-trust-paths=/etc/pki/anchors
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

if [ -e /usr/lib/libnssckbi.so ]; then
  sudo  readlink /usr/lib/libnssckbi.so ||
  sudo rm -v /usr/lib/libnssckbi.so    &&
  sudo ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so
fi

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -r p11-kit

#libsecret
wget http://ftp.gnome.org/pub/gnome/sources/libsecret/0.18/libsecret-0.18.6.tar.xz -O \
    libsecret-0.18.6.tar.xz

mkdir libsecret && tar xf libsecret-*.tar.* -C libsecret --strip-components 1
cd libsecret

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
  --libdir=/usr/lib64 --disable-gtk-doc --disable-manpages

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libsecret

#libwebp
wget http://downloads.webmproject.org/releases/webp/libwebp-1.0.0.tar.gz -O \
    libwebp-1.0.0.tar.gz

mkdir libwebp && tar xf libwebp-*.tar.* -C libwebp --strip-components 1
cd libwebp

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
  --libdir=/usr/lib64 \
  --enable-libwebpmux     \
  --enable-libwebpdemux   \
  --enable-libwebpdecoder \
  --enable-libwebpextras  \
  --enable-swap-16bit-csp \

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libwebp

#sqlite
wget hhttps://sqlite.org/2018/sqlite-autoconf-3240000.tar.gz -O \
    sqlite-autoconf-3240000.tar.gz

mkdir sqlite-autoconf && tar xf sqlite-autoconf-*.tar.* -C sqlite-autoconf --strip-components 1
cd sqlite-autoconf

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
            --disable-static        \
            --libdir=/usr/lib64     \
            CFLAGS="-g -O2 \
	        -DSQLITE_ENABLE_FTS4=1                \
            -DSQLITE_ENABLE_COLUMN_METADATA=1     \
            -DSQLITE_ENABLE_UNLOCK_NOTIFY=1       \
            -DSQLITE_SECURE_DELETE=1              \
	        -DSQLITE_ENABLE_FTS3_TOKENIZER=1      \
            -DSQLITE_ENABLE_DBSTAT_VTAB=1" &&

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf sqlite-autoconf

#libunistring
wget https://ftp.gnu.org/gnu/libunistring/libunistring-0.9.10.tar.xz -O \
	libunistring-0.9.10.tar.xz

mkdir libunistring && tar xf libunistring-*.tar.* -C libunistring --strip-components 1
cd libunistring

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static \
   --docdir=/usr/share/doc/libunistring-0.9.10

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libunistring

#libidn2
wget https://ftp.gnu.org/gnu/libidn/libidn2-2.0.4.tar.gz -O \
	libidn2-2.0.4.tar.gz

mkdir libidn2 && tar xf libidn2-*.tar.* -C libidn2 --strip-components 1
cd libidn2

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install


cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libidn2

#libidn
wget https://ftp.gnu.org/gnu/libidn/libidn-1.35.tar.gz -O \
    libidn-1.35.tar.gz

mkdir libidn && tar xf libidn-*.tar.* -C libidn --strip-components 1
cd libidn

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install


cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libidn

#GnuTLS
wget https://www.gnupg.org/ftp/gcrypt/gnutls/v3.5/gnutls-3.5.19.tar.xz -O \
    gnutls-3.5.19.tar.xz
    
mkdir gnutls && tar xf gnutls-*.tar.* -C gnutls --strip-components 1
cd gnutls

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static \
   --with-default-trust-store-pkcs11="pkcs11:" \
   --with-default-trust-store-file=/etc/ssl/ca-bundle.crt \
   --disable-gtk-doc \
   --enable-openssl-compatibility \
   --with-included-unistring
   
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gnutls

#glib-networking
wget http://ftp.gnome.org/pub/gnome/sources/glib-networking/2.56/glib-networking-2.56.1.tar.xz -O \
    glib-networking-2.56.1.tar.xz

mkdir glibnet && tar xf glib-networking-*.tar.* -C glibnet --strip-components 1
cd glibnet

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} meson --prefix=/usr \
   --libdir=/usr/lib64 --disable-static \
   #--without-ca-certificates 
   -Dlibproxy_support=false \
    -Dca_certificates_path=/etc/ssl/ca-bundle.crt
      
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ninja LIBDIR=/usr/lib64 PREFIX=/usr
ninja test 
checkBuiltPackage

sudo ninja LIBDIR=/usr/lib64 PREFIX=/usr install

sudo bash -c 'cat > /etc/profile.d/gio.sh << "EOF"
# Begin gio.sh

export GIO_USE_TLS=gnutls-pkcs11

# End gio.sh
EOF'

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -rf glibnet

#libnotify
wget http://ftp.gnome.org/pub/gnome/sources/libnotify/0.7/libnotify-0.7.7.tar.xz -O \
    libnotify-0.7.7.tar.xz

mkdir libnotify && tar xf libnotify-*.tar.* -C libnotify --strip-components 1
cd libnotify

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libnotify

#libsoup
wget http://ftp.gnome.org/pub/gnome/sources/libsoup/2.62/libsoup-2.62.2.tar.xz -O \
    libsoup-2.62.2.tar.xz

mkdir libsoup && tar xf libsoup-*.tar.* -C libsoup --strip-components 1
cd libsoup

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static 

sed -i 's/test/#test/g' Makefile*
#remove pund symbols in lines 427 and 428
#nano -c Makefile

sudo ln -sfv /usr/bin/python3.7 /usr/bin/python

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
make check 
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install
sudo unlink /usr/bin/python
sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libsoup

#libxslt
wget http://xmlsoft.org/sources/libxslt-1.1.32.tar.gz -O \
    libxslt-1.1.32.tar.gz 

mkdir libxslt && tar xf libxslt-*.tar.* -C libxslt --strip-components 1
cd libxslt

sed -i s/3000/5000/ libxslt/transform.c doc/xsltproc.{1,xml}

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --disable-static \
   --libdir=/usr/lib64 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libxslt

#GCR
wget http://ftp.gnome.org/pub/gnome/sources/gcr/3.28/gcr-3.28.0.tar.xz -O \
    gcr-3.28.0.tar.xz
    
mkdir gcr && tar xf gcr-*.tar.* -C gcr --strip-components 1
cd gcr

sed -i -r 's:"(/desktop):"/org/gnome\1:' schema/*.xml

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static \
    --without-gtk-doc \
    --sysconfdir=/etc
    
sed -i 's/test/#test/g' Makefile*
 
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
make -k check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gcr

#Gvfs
wget http://ftp.gnome.org/pub/gnome/sources/gvfs/1.36/gvfs-1.36.0.tar.xz -O \
	gvfs-1.36.0.tar.xz#

#You need to recompile udev with this patch in order
#For Gvfs to support gphoto2
#wget https://sourceforge.net/p/gphoto/patches/_discuss/thread/9180a667/9902/attachment/libgphoto2.udev-136.patch -O \
#	libgphoto2.udev-136.patch

mkdir gvfs && tar xf gvfs-*.tar.* -C gvfs --strip-components 1
cd gvfs

LD_LIB_PATH="/usr/lib64" LIBRARY_PATH="/usr/lib64" CPPFLAGS="-I/usr/include" \
LD_LIBRARY_PATH="/usr/lib64" CC="gcc ${BUILD64} -L/usr/lib64 -lacl" \
CXX="g++ ${BUILD64} -lacl" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} meson --prefix=/usr \
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
      -Dfuse=false      \
      -Dgphoto2=false   \
      -Dafc=false       \
      -Dbluray=false    \
      -Dnfs=false       \
      -Dmtp=false       \
      -Dsmb=false       \
      -Dtmpfilesdir=no  \
      -Dlogind=false    \
      -Ddnssd=false     \
      -Dgoa=false       \
      -Dgoogle=false    \
      -Dsystemduserunitdir=no \
      -Dstatic=false   \
      -Dshared=yes     \
      -Ddocumentation=false \
      -Dgtkdoc=false \
    --sysconfdir=/etc  \
   
sudo ln -sfv /usr/lib64/libacl.so /lib64/
sudo ln -sfv /usr/lib64/libattr.so /lib64/
    
LD_LIB_PATH="/usr/lib64" LIBRARY_PATH="/usr/lib64" CPPFLAGS="-I/usr/include" \
LD_LIBRARY_PATH="/usr/lib64" CC="gcc ${BUILD64} -L/usr/lib64 -lacl" \
CXX="g++ ${BUILD64} -lacl" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ninja PREFIX=/usr LIBDIR=/usr/lib64

sudo ninja PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gvfs

#NSPR
wget https://archive.mozilla.org/pub/nspr/releases/v4.19/src/nspr-4.19.tar.gz -O \
    nspr-4.19.tar.gz

mkdir nspr && tar xf nspr-*.tar.* -C nspr --strip-components 1
cd nspr

cd nspr                                                     &&
sed -ri 's#^(RELEASE_BINS =).*#\1#' pr/src/misc/Makefile.in &&
sed -i 's#$(LIBRARY) ##'            config/rules.mk         &&

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --with-mozilla \
   --with-pthreads \
   --enable-64bit

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage

echo " "
echo "checking if /usr/include/pratom.h was installed..."
ls /usr/include | grep pratom.h
echo "... should be shown in output one line above. Mozjs 17.0.0 will fail otherwise."
checkBuiltPackage

sudo rm -rf nspr

#NSS
wget https://archive.mozilla.org/pub/security/nss/releases/NSS_3_38_RTM/src/nss-3.38.tar.gz -O \
    nss-3.38.tar.gz
    
wget http://www.linuxfromscratch.org/patches/blfs/svn/nss-3.38-standalone-1.patch -O \
    NSS-3.38-standalone-1.patch
    
mkdir nss && tar xf nss-*.tar.* -C nss --strip-components 1
cd nss

patch -Np1 -i ../NSS-3.38-standalone-1.patch 
cd nss

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make -j1 BUILD_OPT=1 \
  NSPR_INCLUDE_DIR=/usr/include/nspr  \
  USE_SYSTEM_ZLIB=1                   \
  ZLIB_LIBS=-lz                       \
  NSS_ENABLE_WERROR=0                 \
  LIBDIR=/usr/lib64                   \
  PREFIX=/usr                         \
  $([ $(uname -m) = x86_64 ] && echo USE_64=1) \
  $([ -f /usr/include/sqlite3.h ] && echo NSS_USE_SYSTEM_SQLITE=1)
  
cd ../dist

sudo install -v -m755 Linux*/lib/*.so              /usr/lib64           
sudo install -v -m644 Linux*/lib/{*.chk,libcrmf.a} /usr/lib64            

sudo install -v -m755 -d                           /usr/include/nss      
sudo cp -v -RL {public,private}/nss/*              /usr/include/nss      
sudo chmod -v 644                                  /usr/include/nss/*    

sudo install -v -m755 Linux*/bin/{certutil,nss-config,pk12util} /usr/bin 

sudo install -v -m644 Linux*/lib/pkgconfig/nss.pc  /usr/lib64/pkgconfig

if [ -e /usr/lib64/libp11-kit.so ]; then
  sudo readlink /usr/lib64/libnssckbi.so ||  sudo rm -v /usr/lib64/libnssckbi.so
  sudo ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib64/libnssckbi.so
fi

sh ${CLFSSOURCES}/make-ca.sh-* --force

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf nss

#js17
#wget wget http://ftp.mozilla.org/pub/mozilla.org/js/mozjs17.0.0.tar.gz -O \
#  mozjs17.0.0.tar.gz
#
#mkdir mozjs && tar xf mozjs*.tar.* -C mozjs --strip-components 1
#cd mozjs
#cd js/src
#
#sudo ln -sfv /usr/bin/python2.7 /usr/bin/python
#sudo ln -sfv /usr/bin/python2.7-config /usr/bin/python-config
#export PYTHON=/usr/bin/python
#
#sed -i 's/(defined\((@TEMPLATE_FILE)\))/\1/' config/milestone.pl
#
#CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
#PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} \
#PYTHON=/usr/bin/python ./configure --prefix=/usr --libdir=/usr/lib64 \
#  --enable-readline --enable-threadsafe \
#  --with-system-ffi --with-system-nspr  
#
##Iso C++ can't compare pointer to Integer
##First element of array is seen as pointer
##So to make it a real value I just ficed it
##by derefferencing the pointer and compare THAT to '\0' (NULL)
#sed -i 's/value\[0\] == /\*value\[0\] == /' shell/jsoptparse.cpp
#
#CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 
#PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64
#
#sudo make PREFIX=/usr LIBDIR=/usr/lib64 install
#
#sudo find /usr/include/js-17.0/         \
#     /usr/lib64/libmozjs-17.0.a         \
#     /usr/lib64/pkgconfig/mozjs-17.0.pc \
#     -type f -exec chmod -v 644 {} \;#
#
#unset PYTHON
#sudo unlink /usr/bin/python
#sudo unlink /usr/bin/python-config
#
#cd ${CLFSSOURCES}/xc/xfce4
#checkBuiltPackage
#sudo rm -rf mozjs

#js-52.2.1gnome1
wget http://ftp.gnome.org/pub/gnome/teams/releng/tarballs-needing-help/mozjs/mozjs-52.2.1gnome1.tar.gz -O \
    mozjs-52.2.1gnome1.tar.gz

mkdir mozjs && tar xf mozjs-*.tar.* -C mozjs --strip-components 1
cd mozjs
cd js/src

sudo ln -sfv /usr/bin/python3.7 /usr/bin/python
sudo ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python3.7

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} \
PYTHON=/usr/bin/python3.7 ./configure --prefix=/usr \
    --with-intl-api     \
    --with-system-zlib  \
    --with-system-nspr  \
    --with-system-icu   \
    --enable-threadsafe \
    --enable-readline
  

sudo unlink /usr/bin/python
sudo unlink /usr/bin/python-config
unset PYTHON

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf mozjs

#polkit 113
wget http://www.freedesktop.org/software/polkit/releases/polkit-0.114.tar.gz -O \
  polkit-0.114.tar.gz
  
sudo ln -sfv /usr/bin/python3.7 /usr/bin/python
sudo ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python3.7
  
mkdir polkit && tar xf polkit-*.tar.* -C polkit --strip-components 1
cd polkit

sudo mkdir /etc/polkit-1
sudo groupadd -fg 27 polkitd 
sudo useradd -c "PolicyKit Daemon Owner" -d /etc/polkit-1 -u 27 \
        -g polkitd -s /bin/false polkitd

echo " "
echo "Were polkitd group and user created successfully?"

checkBuiltPackage

sed -e '/JS_ReportWarningUTF8/s/,/, "%s",/'  \
        -i  src/polkitbackend/polkitbackendjsauthority.cpp

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} PYTHON=/usr/bin/python3.7 ./configure --prefix=/usr \
            --sysconfdir=/etc    \
            --libdir=/usr/lib64  \
            --localstatedir=/var \
            --disable-static     \
            --disable-man-pages  \
            --disable-gtk-doc    \
            #--with-pam           \
            --enable-libsystemd-login=no \
            --enable-libelogind=no       \
            --with-authfw=shadow

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo chown root:root /usr/lib/polkit-1/polkit-agent-helper-1
sudo chown root:root /usr/bin/pkexec
sudo chmod 4755 /usr/lib/polkit-1/polkit-agent-helper-1
sudo chmod 4755 /usr/bin/pkexec
sudo chown -Rv polkitd /etc/polkit-1/rules.d
sudo chown -Rv polkitd /usr/share/polkit-1/rules.d
sudo chmod 700 /etc/polkit-1/rules.d
sudo chmod 700 /usr/share/polkit-1/rules.d

sudo bash -c 'cat > /etc/pam.d/polkit-1 << "EOF"
# Begin /etc/pam.d/polkit-1
auth     include        system-auth
account  include        system-account
password include        system-password
session  include        system-session
# End /etc/pam.d/polkit-1
EOF'

sudo unlink /usr/bin/python
sudo unlink /usr/bin/python-config
unset PYTHON

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf polkit

#polkit-gnome
wget http://ftp.gnome.org/pub/gnome/sources/polkit-gnome/0.105/polkit-gnome-0.105.tar.xz -O \
	polkit-gnome-0.105.tar.xz

mkdir polkit-gnome && tar xf polkit-gnome-*.tar.* -C polkit-gnome --strip-components 1
cd polkit-gnome	

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr --libdir=/usr/lib64
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

sudo mkdir -p /etc/xdg/autostart &&
sudo bash -c 'cat > /etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop << "EOF"
[Desktop Entry]
Name=PolicyKit Authentication Agent
Comment=PolicyKit Authentication Agent
Exec=/usr/libexec/polkit-gnome-authentication-agent-1
Terminal=false
Type=Application
Categories=
NoDisplay=true
OnlyShowIn=GNOME;XFCE;Unity;
AutostartCondition=GNOME3 unless-session gnome
EOF'

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gnome-polkit

#libatasmart
wget http://0pointer.de/public/libatasmart-0.19.tar.xz -O \
    libatasmart-0.19.tar.xz

mkdir libatasmart && tar xf libatasmart-*.tar.* -C libatasmart --strip-components 1
cd libatasmart

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
    --disable-static

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce
checkBuiltPackage
sudo rm -rf libatasmart

#libbytesize
wget https://github.com/storaged-project/libbytesize/releases/download/1.3/libbytesize-1.3.tar.gz -O \
    libbytesize-1.3.tar.gz

mkdir libbytesize && tar xf libbytesize-*.tar.* -C libbytesize --strip-components 1
cd libbytesize

sh autogen.sh

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
    --disable-static

sed -i 's/docs/#docs/' Makefile*

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libbytesize

#LVM2
wget ftp://sources.redhat.com/pub/lvm2/releases/LVM2.2.02.177.tgz -O \
	LVM2.2.02.177.tgz

mkdir LVM2 && tar xf LVM2*.tgz -C LVM2 --strip-components 1
cd LVM2

SAVEPATH=$PATH PATH=$PATH:/sbin:/usr/sbin \
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
	--libdir=/usr/lib64 \
	--disable-static    \
    	--exec-prefix=      \
    	--enable-applib     \
    	--enable-cmdlib     \
    	--enable-pkgconfig  \
    	--enable-udev_sync
	
sudo cp /usr/include/blkid/blkid.h /usr/include/
    
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

PATH=$SAVEPATH                 
unset SAVEPATH

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

sudo make -C tools install_dmsetup_dynamic 
sudo make -C udev  install                 
sudo make -C libdm install

sudo mv /usr/lib/pkgconfig/devmapper.pc ${PKG_CONFIG_PATH64}/
sudo sudo mv /usr/lib/libdevmapper.so /usr/lib64/

rm /usr/include/blkid

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf LVM2

#parted
wget http://ftp.gnu.org/gnu/parted/parted-3.2.tar.xz -O \
    parted-3.2.tar.xz

#wget http://www.linuxfromscratch.org/patches/blfs/svn/parted-3.2-devmapper-1.patch -O \
#   Parted-3.2-devmapper-1.patch

mkdir parted && tar xf parted-*.tar.* -C parted --strip-components 1
cd parted

#patch -Np1 -i ../Parted-3.2-devmapper-1.patch

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
    --disable-static

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf parted

#dmraid
wget http://people.redhat.com/~heinzm/sw/dmraid/src/dmraid-current.tar.bz2 -O \
    dmraid-current.tar.bz2

mkdir dmraid && tar xf dmraid-*.tar.* -C dmraid --strip-components 3
cd dmraid

sudo cp -rv include/dmraid /usr/inlude/

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf dmraid

#mdadm
wget http://www.kernel.org/pub/linux/utils/raid/mdadm/mdadm-4.0.tar.xz -O \
    mdadm-4.0.tar.xz

mkdir mdadm && tar xf mdadm-*.tar.* -C mdadm --strip-components 1
cd mdadm

#Fix for GCC 7.1 and higher
sed 's@-Werror@@' -i Makefile

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf mdadm

#LZO
wget http://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz -O \
    lzo-2.10.tar.gz

mkdir lzo && tar xf lzo-*.tar.* -C lzo --strip-components 1
cd lzo

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
    --disable-static \
    --enable-shared \
    --docdir=/usr/share/doc/lzo-2.10

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf lzo

#btrfs-progs
wget https://www.kernel.org/pub/linux/kernel/people/kdave/btrfs-progs/btrfs-progs-v4.16.1.tar.xz -O \
    btrfs-progs-v4.16.1.tar.xz

mkdir btrfs-progs && tar xf btrfs-progs-*.tar.* -C btrfs-progs --strip-components 1
cd btrfs-progs

sed -i '40,107 s/\.gz//g' Documentation/Makefile.in 

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/lib64 \
    --bindir=/bin  \
    --disable-static \
    --disable-documentation \
    --disable-zstd

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/lib64

make fssum &&

sed -i '/found/s/^/: #/' tests/convert-tests.sh &&

mv tests/mkfs-tests/013-reserved-1M-for-single/test.sh{,.broken} 
mv tests/convert-tests/010-reiserfs-basic/test.sh{,.broken}      
mv tests/convert-tests/011-reiserfs-delete-all-rollback/test.sh{,.broken} 
mv tests/misc-tests/025-zstd-compression/test.sh{,.broken}       
mv tests/fuzz-tests/003-multi-check-unmounted/test.sh{,.broken}  
mv tests/fuzz-tests/009-simple-zero-log/test.sh{,.broken}

#pushd tests
#   sudo ./fsck-tests.sh
#   sudo ./mkfs-tests.sh
#   sudo ./convert-tests.sh
#   sudo ./misc-tests.sh
#   sudo ./cli-tests.sh
#   sudo ./fuzz-tests.sh
#popd

sudo make PREFIX=/usr LIBDIR=/lib64 install



sudo ln -sfv ../../lib/$(readlink /lib/libbtrfs.so) /usr/lib/libbtrfs.so 
sudo ln -sfv ../../lib/$(readlink /lib/libbtrfsutil.so) /usr/lib/libbtrfsutil.so 
sudo rm -fv /lib/libbtrfs.{a,so} /lib/libbtrfsutil.{a,so} 
sudo mv -v /bin/{mkfs,fsck}.btrfs /sbin

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf btrfs-progs

#libassuan
wget https://www.gnupg.org/ftp/gcrypt/libassuan/libassuan-2.5.1.tar.bz2 -O \
    libassuan-2.5.1.tar.bz2
    
mkdir libassuan && tar xf libassuan-*.tar.* -C libassuan --strip-components 1
cd libassuan

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -r libassuan

#GPGME
wget https://www.gnupg.org/ftp/gcrypt/gpgme/gpgme-1.11.1.tar.bz2 -O \
	gpgme-1.11.1.tar.bz2

mkdir gpgme && tar xf gpgme-*.tar.* -C gpgme --strip-components 1
cd gpgme

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
	--libdir=/usr/lib64 \
	--disable-static \
	--disable-gpg-test

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gpgme

#SWIG
wget http://downloads.sourceforge.net/swig/swig-3.0.12.tar.gz -O \
	swig-3.0.12.tar.gz

mkdir swig && tar xf swig-*.tar.* -C swig --strip-components 1
cd swig

sed -i 's/\$(PERL5_SCRIPT/-I. &/' Examples/Makefile.in &&
sed -i 's/\$command 2/-I. &/' Examples/test-suite/perl5/run-perl-test.pl

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
	--libdir=/usr/lib64 \
	--disable-static \
	--without-clisp   \
	--without-maximum-compile-warnings

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

make -k check TCL_INCLUDE= GOGCC=true
PY3=1 make check-python-examples
PY3=1 make check-python-test-suite

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo cp -rv  /usr/lib/python2.7/ /usr/lib64/
sudo cp -rv  /usr/lib/python3.7/ /usr/lib64/

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -rf swig

#cryptsetup
wget https://www.kernel.org/pub/linux/utils/cryptsetup/v2.0/cryptsetup-2.0.3.tar.xz -O \
	cryptsetup-2.0.3.tar.xz

mkdir cryptsetup && tar xf cryptsetup-*.tar.* -C cryptsetup --strip-components 1
cd cryptsetup

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
	--disable-static \
	--with-crypto_backend=openssl

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf cryptsetup

#volume_key
wget https://releases.pagure.org/volume_key/volume_key-0.3.11.tar.xz -O \
	volume_key-0.3.11.tar.xz

mkdir volume_key && tar xf volume_key-*.tar.* -C volume_key --strip-components 1
cd volume_key

export PYTHON=/usr/bin/python3.7
sudo ln -sfv /usr/bin/python3.7 /usr/bin/python

sed -i 's/$(PYTHON_VERSION)/3.7/' Makefile*
sed -i 's/\/lib\/python3.7/\/lib64\/python3.7/' Makefile*
sed -i 's/\/lib6464\/python3.7/\/lib64\/python3.7/' Makefile*
sed -i 's/<Python.h>/\"\/usr\/include\/python3.7m\/Python.h\"/' python/volume_key_wrap.c
#sed -i '/config.h/d' lib/libvolume_key.h

autoreconf -fiv

PYTHON=/usr/bin/python3.7 \
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
	--libdir=/usr/lib64 \
	--disable-static

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo unlink /usr/bin/python
unset PYTHON

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf volume_key

#libblockdev
wget https://github.com/storaged-project/libblockdev/releases/download/2.17-1/libblockdev-2.17.tar.gz -O \
    libblockdev-2.17.tar.gz

sudo cp /usr/include/blkid/blkid.h /usr/include
sudo ln -sfv /usr/bin/python3.7 /usr/bin/python
sudo ln -sfv /usr/bin/python3.7-config /usr/bin/python-config
export PYTHON=/usr/bin/python3.7

mkdir libblockdev && tar xf libblockdev-*.tar.* -C libblockdev --strip-components 1
cd libblockdev

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
    --disable-static \
    --with-python3   \
    --without-gtk-doc \
    --without-nvdimm  \
    --without-dm 

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sed -i 's/docs/#docs/' Makefile*

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libblockdev

#UDisks
wget https://github.com/storaged-project/udisks/releases/download/udisks-2.7.6/udisks-2.7.6.tar.bz2 -O \
	udisks-2.7.6.tar.bz2

mkdir udisks && tar xf udisks-*.tar.* -C udisks --strip-components 1
cd udisks	

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --libdir=/usr/lib64	\
    --libexecdir=/usr/lib64 \
    --disable-static    \
    --sysconfdir=/etc	\
    --localstatedir=/var \
    --disable-gtk-doc	\
    --disable-gtk-doc-pdf \
    --disable-gtk-doc-html \
    --disable-man 	\
    --enable-shared 	\
    --enable-btrfs 	\
    --enable-lvm2 	\
    --enable-lvmcache	\
    --enable-polkit	\
    --disable-tests \
 	--disable-logind \
	--with-systemdsystemunitdir=no \
	--with-udevdir=/lib64/udev

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf udisks

#libexif
wget http://downloads.sourceforge.net/libexif/libexif-0.6.21.tar.bz2 -O \
	libexif-0.6.21.tar.bz2

mkdir libexif && tar xf libexif-*.tar.* -C libexif --strip-components 1
cd libexif

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
    --with-doc-dir=/usr/share/doc/libexif-0.6.21 \
	--disable-static

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libexif

#gstreamer
wget https://gstreamer.freedesktop.org/src/gstreamer/gstreamer-1.14.1.tar.xz -O \
    gstreamer-1.14.1.tar.xz
    
mkdir gstreamer && tar xf gstreamer-*.tar.* -C gstreamer --strip-components 1
cd gstreamer

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --with-package-name="GStreamer 1.14.1 CBLFS" \
   --with-package-origin="http://www.linuxfromscratch.org/blfs/view/svn/" 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo rm -rf /usr/bin/gst-* /usr/{lib,libexec}/gstreamer-1.0

make check
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gstreamer

#gst-plugins-base
wget https://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-1.14.1.tar.xz -O \
    gst-plugins-base-1.14.1.tar.xz

mkdir gstplgbase && tar xf gst-plugins-base-*.tar.* -C gstplgbase --strip-components 1
cd gstplgbase

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --with-package-name="GStreamer 1.14.1 CBLFS" \
   --with-package-origin="http://www.linuxfromscratch.org/blfs/view/svn/" 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64

make check
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gstplgbase

#gst-plugins-good
wget https://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-1.14.1.tar.xz -O \
    gst-plugins-good-1.14.1.tar.xz

mkdir gstplggood && tar xf gst-plugins-good-*.tar.* -C gstplggood --strip-components 1
cd gstplggood

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --with-package-name="GStreamer 1.14.1 CBLFS" \
   --with-package-origin="http://www.linuxfromscratch.org/blfs/view/svn/" 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64

make check
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo unlink /usr/bin/python
sudo unlink /usr/bin/python-config
unset PYTHON

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gstplggood

#libgsf
wget http://ftp.gnome.org/pub/gnome/sources/libgsf/1.14/libgsf-1.14.43.tar.xz -O \
  libgsf-1.14.43.tar.xz

mkdir libgsf && tar xf libgsf-*.tar.* -C libgsf --strip-components 1
cd libgsf

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static \
     --disable-gtk-doc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libgsf

#littleCMS2
wget http://downloads.sourceforge.net/lcms/lcms2-2.9.tar.gz -O \
    lcms2-2.9.tar.gz

mkdir lcms2 && tar xf lcms2-*.tar.* -C lcms2 --strip-components 1
cd lcms2

sed -i '/AX_APPEND/s/^/#/' configure.ac
autoreconf -fiv

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf lcms2

#OpenJPEG
wget https://github.com/uclouvain/openjpeg/archive/v2.3.0/openjpeg-2.3.0.tar.gz -O \
    openjpeg-2.3.0.tar.gz
    
mkdir openjpeg && tar xf openjpeg-*.tar.* -C openjpeg --strip-components 1
cd openjpeg

autoreconf -f -i

mkdir -v build
cd build

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} \
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
    -DMAKE_INSTALL_LIBDIR=/usr/lib64

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo bash -c 'pushd ../doc &&
  for man in man/man?/* ; do
      install -v -D -m 644 $man /usr/share/$man
  done 
popd'

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf openjpeg

#Cairo
wget http://cairographics.org/releases/cairo-1.14.12.tar.xz -O \
    cairo-1.14.12.tar.xz

mkdir cairo && tar xf cairo-*.tar.* -C cairo --strip-components 1
cd cairo

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static \
     --enable-xlib-xcb \
     --enable-gl \
     --enable-tee

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf cairo

#poppler-glib 
wget https://poppler.freedesktop.org/poppler-0.65.0.tar.xz -O \
    poppler-0.65.0.tar.xz
    
wget http://poppler.freedesktop.org/poppler-data-0.4.9.tar.gz -O \
    Poppler-data-0.4.9.tar.gz

mkdir poppler && tar xf poppler-*.tar.* -C poppler --strip-components 1
cd poppler

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} -DCMAKE_BUILD_TYPE=Release   \
       -DCMAKE_INSTALL_PREFIX=/usr  \
       -DCMAKE_INSTALL_SYSCONFDIR=/etc  \
       -DTESTDATADIR=$PWD/testfiles \
       -DENABLE_CMYK=ON             \
       -DENABLE_XPDF_HEADERS=ON     \
       -DENABLE_SHARED=ON \
       -DDISABLE_STATIC=ON

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

mkdir poppler-data
tar -xf ../Poppler-data-*.tar.gz -C poppler-data --strip-components 1 
cd poppler-data

sudo make LIBDIR=/usr/lib64 prefix=/usr install

sudo install -v -m755 -d           /usr/share/doc/poppler-0.65.0
sudo cp -vr ../glib/reference/html /usr/share/doc/poppler-0.65.0

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf poppler

#sgml-common
wget http://anduin.linuxfromscratch.org/BLFS/sgml-common/sgml-common-0.6.3.tgz -O \
    sgml-common-0.6.3.tgz

wget http://www.linuxfromscratch.org/patches/blfs/svn/sgml-common-0.6.3-manpage-1.patch -O \
    Sgml-common-0.6.3-manpage-1.patch 

mkdir sgml-common && tar xf sgml-common-*.tgz -C sgml-common --strip-components 1
cd sgml-common

patch -Np1 -i ../Sgml-common-0.6.3-manpage-1.patch

autoreconf -f -i

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --sysconfdir=/etc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make docdir=/usr/share/doc install &&

sudo install-catalog --add /etc/sgml/sgml-ent.cat \
    /usr/share/sgml/sgml-iso-entities-8879.1986/catalog &&

sudo install-catalog --add /etc/sgml/sgml-docbook.cat \
    /etc/sgml/sgml-ent.cat

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf sgml-common

#Unzip
wget http://downloads.sourceforge.net/infozip/unzip60.tar.gz -O \
    unzip60.tar.gz

mkdir unzip && tar xf unzip*.tar.* -C unzip --strip-components 1
cd unzip

sed -i 's/CC = cc#/CC = gcc#/' unix/Makefile

CC="gcc ${BUILD64}" \
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64 -f unix/Makefile generic
sudo make prefix=/usr libdir=/usr/lib64 -f unix/Makefile install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf unzip

sudo chown -Rv overflyer ${CLFSSOURCES}
cd ${CLFSSOURCES}/xc/xfce4

#docbook-xml
wget http://www.docbook.org/xml/4.5/docbook-xml-4.5.zip -O \
    docbook-xml-4.5.zip

unzip docbook-xml-*.zip

sudo install -v -d -m755 /usr/share/xml/docbook/xml-dtd-4.5
sudo install -v -d -m755 /etc/xml
sudo chown -R root:root .
sudo cp -v -af catalog.xml docbook.cat *.dtd ent/ *.mod /usr/share/xml/docbook/xml-dtd-4.5

if [ ! -e /etc/xml/docbook ]; then
    sudo xmlcatalog --noout --create /etc/xml/docbook
fi

sudo xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML V4.5//EN" \
    "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd" \
    /etc/xml/docbook 
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML CALS Table Model V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/calstblx.dtd" \
    /etc/xml/docbook 
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//DTD XML Exchange Table Model 19990315//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/soextblx.dtd" \
    /etc/xml/docbook 
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Information Pool V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbpoolx.mod" \
    /etc/xml/docbook 
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Document Hierarchy V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbhierx.mod" \
    /etc/xml/docbook 
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML HTML Tables V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/htmltblx.mod" \
    /etc/xml/docbook 
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Notations V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbnotnx.mod" \
    /etc/xml/docbook 
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Character Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbcentx.mod" \
    /etc/xml/docbook 
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Additional General Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbgenent.mod" \
    /etc/xml/docbook 
sudo xmlcatalog --noout --add "rewriteSystem" \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook 
sudo xmlcatalog --noout --add "rewriteURI" \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook

if [ ! -e /etc/xml/catalog ]; then
    sudo xmlcatalog --noout --create /etc/xml/catalog
fi 

sudo xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//ENTITIES DocBook XML" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog 
sudo xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//DTD DocBook XML" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog 
sudo xmlcatalog --noout --add "delegateSystem" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog 
sudo xmlcatalog --noout --add "delegateURI" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog

for DTDVERSION in 4.1.2 4.2 4.3 4.4
do
  sudo xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML V$DTDVERSION//EN" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/docbookx.dtd" \
    /etc/xml/docbook
  sudo xmlcatalog --noout --add "rewriteSystem" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook
  sudo xmlcatalog --noout --add "rewriteURI" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook
  sudo xmlcatalog --noout --add "delegateSystem" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
  sudo xmlcatalog --noout --add "delegateURI" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
done

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage

sudo chown -Rv overflyer ${CLFSSOURCES}

#docbook-xsl
wget https://github.com/docbook/xslt10-stylesheets/releases/download/release/1.79.2/docbook-xsl-1.79.2.tar.bz2 -O \
    docbook-xsl-1.79.2.tar.bz2

wget http://www.linuxfromscratch.org/patches/blfs/svn/docbook-xsl-1.79.2-stack_fix-1.patch -O \
	Docbook-xsl-1.79.2-stack_fix-1.patch

mkdir docbook-xsl && tar xf docbook-xsl-*.tar.* -C docbook-xsl --strip-components 1
cd docbook-xsl

patch -Np1 -i ../docbook-xsl-1.79.2-stack_fix-1.patch

sudo install -v -m755 -d /usr/share/xml/docbook/xsl-stylesheets-1.79.2 

sudo cp -v -R VERSION assembly common eclipse epub epub3 extensions fo  \
         highlighting html htmlhelp images javahelp lib manpages params  \
         profiling roundtrip slides template tests tools webhelp website \
         xhtml xhtml-1_1 xhtml5                                          \
         /usr/share/xml/docbook/xsl-stylesheets-1.79.2

sudo ln -s VERSION /usr/share/xml/docbook/xsl-stylesheets-1.79.2/VERSION.xsl 

sudo install -v -m644 -D README \
                    /usr/share/doc/docbook-xsl-1.79.2/README.txt 
sudo install -v -m644    RELEASE-NOTES* NEWS* \
                    /usr/share/doc/docbook-xsl-1.79.2

if [ ! -d /etc/xml ]; then 
	sudo install -v -m755 -d /etc/xml; 
fi 

if [ ! -f /etc/xml/catalog ]; then
    sudo xmlcatalog --noout --create /etc/xml/catalog
fi 

sudo xmlcatalog --noout --add "rewriteSystem" \
           "http://docbook.sourceforge.net/release/xsl/1.79.2" \
           "/usr/share/xml/docbook/xsl-stylesheets-1.79.2" \
    /etc/xml/catalog 

sudo xmlcatalog --noout --add "rewriteURI" \
           "http://docbook.sourceforge.net/release/xsl/1.79.2" \
           "/usr/share/xml/docbook/xsl-stylesheets-1.79.2" \
    /etc/xml/catalog 

sudo xmlcatalog --noout --add "rewriteSystem" \
           "http://docbook.sourceforge.net/release/xsl/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-1.79.2" \
    /etc/xml/catalog 

sudo xmlcatalog --noout --add "rewriteURI" \
           "http://docbook.sourceforge.net/release/xsl/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-1.79.2" \
    /etc/xml/catalog

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf docbook-xsl

sudo chown -Rv overflyer ${CLFSSOURCES}

#itstool
wget http://files.itstool.org/itstool/itstool-2.0.4.tar.bz2 -O \
    itstool-2.0.2.tar.bz2
    
wget http://www.linuxfromscratch.org/patches/blfs/svn/itstool-2.0.4-segfault-1.patch -O \
	itstool-2.0.4-segfault-1.patch

mkdir itstool && tar xf itstool-*.tar.* -C itstool --strip-components 1
cd itstool
patch -Np1 -i ../itstool-2.0.4-segfault-1.patch

sed -i 's/python \- \&/python3.6 \- \&/' configure

export PYTHON=/usr/bin/python3.7
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PYTHON=/usr/bin/python3.7 ./configure --prefix=/usr 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr 
sudo make PREFIX=/usr install

unset PYTHON

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -rf itstool

#gtk-doc
wget http://ftp.gnome.org/pub/gnome/sources/gtk-doc/1.28/gtk-doc-1.28.tar.xz -O \
    gtk-doc-1.28.tar.xz

sudo ln -sfv /usr/bin/python3.7 /usr/bin/python
sudo ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python3.7


mkdir gtk-doc && tar xf gtk-doc-*.tar.* -C gtk-doc --strip-components 1
cd gtk-doc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PYTHON=/usr/bin/python ./configure --prefix=/usr \
    --libdir=/usr/lib64 --enable-shared --disable-static \
    --with-xml-catalog=/etc/xml/catalog --sysconfdir=/etc --datarootdir=/usr/share

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gtk-doc

#tumbler
wget http://archive.xfce.org/src/xfce/tumbler/0.2/tumbler-0.2.1.tar.bz2 -O \
        tumbler-0.2.1.tar.bz2

mkdir tumbler && tar xf tumbler-*.tar.* -C tumbler --strip-components 1
cd tumbler

sed -i 's/docs/#docs/g' Makefile*

PYTHON=/usr/bin/python PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64

PYTHON=/usr/bin/python PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PYTHON=/usr/bin/python PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf tumbler

#Thunar
wget http://archive.xfce.org/src/xfce/thunar/1.7/Thunar-1.7.0.tar.bz2 -O \
	Thunar-1.7.0.tar.bz2
	
mkdir Thunar && tar xf Thunar-*.tar.* -C Thunar --strip-components 1
cd Thunar

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
	PYTHON=/usr/bin/python ./configure --prefix=/usr \
    	--libdir=/usr/lib64 --sysconfdir=/etc \
    	--docdir=/usr/share/doc/Thunar-1.7.0

#remove building of docs subfolder caquse it fails
sed -i 's/^[[:space:]]\(docs\)[[:space:]]\{8\}[[:punct:]]//g' Makefile*
sed -i '522d'

PYTHON=/usr/bin/python PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make PYTHON=/usr/bin/python LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf Thunar

#thunar-volman
wget http://archive.xfce.org/src/xfce/thunar-volman/0.8/thunar-volman-0.8.1.tar.bz2 -O \
	thunar-volman-0.8.1.tar.bz2

mkdir thunar-volman && tar xf thunar-volman-*.tar.* -C thunar-volman --strip-components 1
cd thunar-volman

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf thunar-volman

#xfce-appfinder
wget http://archive.xfce.org/src/xfce/xfce4-appfinder/4.12/xfce4-appfinder-4.12.0.tar.bz2 -O \
	xfce4-appfinder-4.12.0.tar.bz2

mkdir xfce4-appfinder && tar xf xfce4-appfinder-*.tar.* -C xfce4-appfinder --strip-components 1
cd xfce4-appfinder

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-appfinder

#libusb
wget https://github.com//libusb/libusb/releases/download/v1.0.22/libusb-1.0.22.tar.bz2 -O \
    libusb-1.0.22.tar.bz2

mkdir libusb && tar xf libusb-*.tar.* -C libusb --strip-components 1
cd libusb

sed -i "s/^PROJECT_LOGO/#&/" doc/doxygen.cfg.in

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make -j1 PREFIX=/usr LIBDIR=/usr/lib64
sudo make -j1 PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libusb

#libgusb
wget https://people.freedesktop.org/~hughsient/releases/libgusb-0.3.0.tar.xz -O \
    libgusb-0.3.0.tar.xz

mkdir libgusb && tar xf libgusb-*.tar.* -C libgusb --strip-components 1
cd libgusb

mkdir build
cd    build 

ln -sfv /usr/bin/python3.7 /usr/bin/python
ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python3.7

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" meson --prefix=/usr \
   --libdir=/usr/lib64  -Ddocs=false

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make -j1 PREFIX=/usr LIBDIR=/usr/lib64 \
ninja PREFIX=/usr LIBDIR=/usr/lib64 install

sudo ninja install

unset PYTHON
unlink /usr/bin/python
unlink /usr/bin/python-config

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libgusb

#UPower
wget https://upower.freedesktop.org/releases/upower-0.99.7.tar.xz -O \
	upower-0.99.7.tar.xz

mkdir upower && tar xf upower-*.tar.* -C upower --strip-components 1
cd upower

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --sysconfdir=/etc    \
    --localstatedir=/var \
    --enable-deprecated  \
    --disable-static \
    --disable-gtk-doc

sed -i 's/doc/#doc/' Makefile*

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf upower



#valgrind
wget https://sourceware.org/ftp/valgrind/valgrind-3.13.0.tar.bz2 -O \
	valgrind-3.13.0.tar.bz2

mkdir valgrind && tar xf valgrind-*.tar.* -C valgrind --strip-components 1
cd valgrind

sed -i 's|/doc/valgrind||' docs/Makefile.in 

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 --datadir=/usr/share/doc/valgrind-3.13.0

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf valgrind

#xfsprogs
wget https://www.kernel.org/pub/linux/utils/fs/xfs/xfsprogs/xfsprogs-4.16.1.tar.xz -O \
	xfsprogs-4.16.1.tar.xz
	
mkdir xfsprogs && tar xf xfsprogs-*.tar.* -C xfsprogs --strip-components 1
cd xfsprogs

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} \
CC="gcc ${BUILD64}"     \
USE_ARCH=64             \
CXX="g++ ${BUILD64}"    \
make DEBUG=-DNDEBUG     \
     INSTALL_USER=root  \
     INSTALL_GROUP=root \
     PREFIX=/usr        \
     LIBDIR=/usr/lib64  \
     LOCAL_CONFIGURE_OPTIONS="--enable-readline"

sudo make PKG_DOC_DIR=/usr/share/doc/xfsprogs-4.16.1 install    
sudo make PKG_DOC_DIR=/usr/share/doc/xfsprogs-4.16.1 install-dev

sudo rm -rfv /usr/lib/libhandle.a                               
sudo rm -rfv /lib/libhandle.{a,la,so}                           
sudo ln -sfv ../../lib/libhandle.so.1 /usr/lib/libhandle.so     
sudo sed -i "s@libdir='/lib@libdir='/usr/lib@" /usr/lib/libhandle.la

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfsprogs

#sg3_utils
wget http://sg.danny.cz/sg/p/sg3_utils-1.42.tar.xz -O \
	sg3_utils-1.42.tar.xz

mkdir sg3_utils && tar xf sg3_utils-*.tar.* -C sg3_utils --strip-components 1
cd sg3_utils

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf sg3_utils

#xfce4-power-manager
wget http://archive.xfce.org/src/xfce/xfce4-power-manager/1.6/xfce4-power-manager-1.6.1.tar.bz2 -O \
	xfce4-power-manager-1.6.1.tar.bz2

mkdir xfce4-power-manager && tar xf xfce4-power-manager-*.tar.* -C xfce4-power-manager --strip-components 1
cd xfce4-power-manager

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --sysconfdir=/etc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-power-manager

#lxde-icon-theme
wget https://downloads.sourceforge.net/lxde/lxde-icon-theme-0.5.1.tar.xz -O \
    lxde-icon-theme-0.5.1.tar.xz

mkdir lxde-icon-theme && tar xf lxde-icon-theme-*.tar.* -C lxde-icon-theme --strip-components 1
cd lxde-icon-theme

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 

sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install
sudo gtk-update-icon-cache -qf /usr/share/icons/nuoveXT2

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf lxde-icon-theme

#libogg
wget http://downloads.xiph.org/releases/ogg/libogg-1.3.3.tar.xz -O \
    libogg-1.3.3.tar.xz

mkdir libogg && tar xf libogg-*.tar.* -C libogg --strip-components 1
cd libogg

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --docdir=/usr/share/doc/libogg-1.3.3

make check
checkBuiltPackage

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libogg

#libvorbis
wget http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.6.tar.xz -O \
    libvorbis-1.3.6.tar.xz

mkdir libvorbis && tar xf libvorbis-*.tar.* -C libvorbis --strip-components 1
cd libvorbis

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --enable-docs=no

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install
sudo install -v -m644 doc/Vorbis* /usr/share/doc/libvorbis-1.3.6

ldconfig 

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libvorbis

#Alsa-Libs
wget ftp://ftp.alsa-project.org/pub/lib/alsa-lib-1.1.6.tar.bz2 -O \
    alsa-lib-1.1.6.tar.bz2

sudo ln -sfv /usr/bin/python2.7 /usr/bin/python
sudo ln -sfv /usr/bin/python2.7-config /usr/bin/python-config
export PYTHON=/usr/bin/python

mkdir alsa-lib && tar xf alsa-lib-*.tar.* -C alsa-lib --strip-components 1
cd alsa-lib

PYTHON=/usr/bin/python PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
make check
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo unlink /usr/bin/python
sudo unlink /usr/bin/python-config
unset PYTHON

sudo bash -c 'install -v -d -m755 /usr/share/doc/alsa-lib-1.1.6/html/search &&
install -v -m644 doc/doxygen/html/*.* /usr/share/doc/alsa-lib-1.1.6/html &&
install -v -m644 doc/doxygen/html/search/* /usr/share/doc/alsa-lib-1.1.6/html/search'

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf alsa-lib

#libcanberra
wget http://0pointer.de/lennart/projects/libcanberra/libcanberra-0.30.tar.xz -O \
    libcanberra-0.30.tar.xz

mkdir libcanberra && tar xf libcanberra-*.tar.* -C libcanberra --strip-components 1
cd libcanberra

intltoolize-prepare --force
autoconf
automake

cp ${CLFSSOURCES}/libcanberra-0.30-removedoc-nopulseaudio.patch .

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --disable-oss \
   --disable-gtk-doc \
   --disable-gtk-doc-html \
   --disable-gtk-doc-pdf \
   --with-html-dir=no \
   --with-systemdsystemunitdir=no

patch -Np0 -i libcanberra-0.30-removedoc-nopulseaudio.patch

checkBuiltPackage

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libcanberra

#xfce4-settings
wget http://archive.xfce.org/src/xfce/xfce4-settings/4.12/xfce4-settings-4.12.4.tar.bz2 -O \
	xfce4-settings-4.12.4.tar.bz2

mkdir xfce4-settings && tar xf xfce4-settings-*.tar.* -C xfce4-settings --strip-components 1
cd xfce4-settings

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --sysconfdir=/etc 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-settings

#Xfdesktop
wget http://archive.xfce.org/src/xfce/xfdesktop/4.12/xfdesktop-4.12.4.tar.bz2 -O \
	xfdesktop-4.12.4.tar.bz2

mkdir xfdesktop && tar xf xfdesktop-*.tar.* -C xfdesktop --strip-components 1
cd xfdesktop

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfdesktop

#Xfwm4
wget http://archive.xfce.org/src/xfce/xfwm4/4.12/xfwm4-4.12.5.tar.bz2 -O \
	xfwm4-4.12.5.tar.bz2

mkdir xfwm4 && tar xf xfwm4-*.tar.* -C xfwm4 --strip-components 1
cd xfwm4

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --disable-compositor \
     --libdir=/usr/lib64 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfwm4

#xfce4-session
wget http://archive.xfce.org/src/xfce/xfce4-session/4.12/xfce4-session-4.12.1.tar.bz2 -O \
	xfce4-session-4.12.1.tar.bz2

mkdir xfce4-session && tar xf xfce4-session-*.tar.* -C xfce4-session --strip-components 1
cd xfce4-session

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --sysconfdir=/etc \
     --disable-legacy-sm

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

sudo update-desktop-database 
sudo update-mime-database /usr/share/mime

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-session

#cat > ~/.xinitrc << "EOF"
#ck-launch-session dbus-launch --exit-with-session startxfce4
#EOF

cat > /home/overflyer/.xinitrc << "EOF"
#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

if [[ -f ~/.extend.xinitrc ]];then
	. ~/.extend.xinitrc
else
	DEFAULT_SESSION=xfce4-session
fi

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

get_session(){
	local dbus_args=(--sh-syntax --exit-with-session)
	case $1 in
		awesome) dbus_args+=(awesome) ;;
		bspwm) dbus_args+=(bspwm-session) ;;
		budgie) dbus_args+=(budgie-desktop) ;;
		cinnamon) dbus_args+=(cinnamon-session) ;;
		deepin) dbus_args+=(startdde) ;;
		enlightenment) dbus_args+=(enlightenment_start) ;;
		fluxbox) dbus_args+=(startfluxbox) ;;
		gnome) dbus_args+=(gnome-session) ;;
		i3|i3wm) dbus_args+=(i3 --shmlog-size 0) ;;
		jwm) dbus_args+=(jwm) ;;
		kde) dbus_args+=(startkde) ;;
		lxde) dbus_args+=(startlxde) ;;
		lxqt) dbus_args+=(lxqt-session) ;;
		mate) dbus_args+=(mate-session) ;;
		xfce) dbus_args+=(xfce4-session) ;;
		openbox) dbus_args+=(openbox-session) ;;
		*) dbus_args+=($DEFAULT_SESSION) ;;
	esac

	echo "dbus-launch ${dbus_args[*]}"
}

exec $(get_session)


# twm &
# xclock -geometry 50x50-1+1 &
# xterm -geometry 80x50+494+51 &
# xterm -geometry 80x20+494-0 &
#exec xterm -geometry 80x66+0+0 -name login
EOF

## Xfce4 Applications ##

#gtksourceview3

#mousepad

#vte needs pcre2
#PCRE2
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre2-10.31.tar.bz2 -O \
    pcre2-10.31.tar.bz2

mkdir pcre2 && tar xf pcre2-*.tar.* -C pcre2 --strip-components 1
cd pcre2

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
     --docdir=/usr/share/doc/pcre2-10.31        \
            --enable-unicode                    \
            --enable-pcre2-16                   \
            --enable-pcre2-32                   \
            --enable-pcre2grep-libz             \
            --enable-pcre2grep-libbz2           \
            --enable-pcre2test-libreadline      \
            --disable-static                    \
	    --enable-jit                        \
            --libdir=/usr/lib64

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf pcre2

#vte
wget http://ftp.gnome.org/pub/gnome/sources/vte/0.52/vte-0.52.0.tar.xz -O \
    vte-0.52.0.tar.xz

mkdir vte && tar xf vte-*.tar.* -C vte --strip-components 1
cd vte

sudo ln -sfv /usr/bin/python3.7 /usr/bin/python
sudo ln -sfv /usr/bin/python3.7m-config /usr/bin/python-config
export PYTHON=/usr/bin/python3.7

cp -v /sources/vte_makefile*_removedoc_0.50.patch .

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} \
PYTHON=/usr/bin/python ./configure --prefix=/usr \
    --disable-static \
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
    --enable-introspection \
    --disable-gtk-doc \
    --disable-gtk-doc-html \
    --disable-gtk-doc-pdf

patch -Np0 -i vte_makefiles_removedoc_0.50.patch

checkBuiltPackage

make PREFIX=/usr PYTHON=/usr/bin/python LIBDIR=/usr/lib64

sudo make PREFIX=/usr PYTHON=/usr/bin/python LIBDIR=/usr/lib64 install

unset PYTHON
sudo unlink /usr/bin/python
sudo unlink /usr/bin/python-config

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf vte

#xfce4-terminal
wget http://archive.xfce.org/src/apps/xfce4-terminal/0.8/xfce4-terminal-0.8.7.4.tar.bz2 -O \
	xfce4-terminal-0.8.7.4.tar.bz2

mkdir xfce4-terminal && tar xf xfce4-terminal-*.tar.* -C xfce4-terminal --strip-components 1
cd xfce4-terminal

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --libdir=/usr/lib64 

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-terminal

#ristretto
wget http://archive.xfce.org/src/apps/ristretto/0.8/ristretto-0.8.3.tar.bz2 -O \
	ristretto-0.8.3.tar.bz2

mkdir ristretto && tar xf ristretto-*.tar.* -C ristretto --strip-components 1
cd ristretto

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --libdir=/usr/lib64 

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf ristretto

#xfce-notifyd
wget http://archive.xfce.org/src/apps/xfce4-notifyd/0.4/xfce4-notifyd-0.4.2.tar.bz2 -O \
	xfce4-notifyd-0.4.2.tar.bz2

mkdir xfce4-notifyd && tar xf xfce4-notifyd-*.tar.* -C xfce4-notifyd --strip-components 1
cd xfce4-notifyd

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --libdir=/usr/lib64 

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

notify-send -i info Information "Hi ${USER}, This is a Test"

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-notifyd

sudo chown -Rv overflyer /home/overflyer
