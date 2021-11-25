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

export CLFS=/
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

#We left off installing mate-desktop
#Now we continue ligpgerror

#libgpg-error

#libgcrypt

#libtasn1

#p11-kit

#libassuan

#libksba
wget ftp://ftp.gnupg.org/gcrypt/libksba/libksba-1.3.5.tar.bz2 -O \
    libksba-1.3.5.tar.bz2
    
mkdir libksba && tar xf libksba-*.tar.* -C libksba --strip-components 1
cd libksba

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
rm -r libksba

#npth
wget ftp://ftp.gnupg.org/gcrypt/npth/npth-1.5.tar.bz2 -O \
    npth-1.5.tar.bz2

mkdir npth && tar xf npth-*.tar.* -C npth --strip-components 1
cd npth

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
rm -r npth

#pinentry
wget ftp://ftp.gnupg.org/gcrypt/pinentry/pinentry-1.1.0.tar.bz2 -O \
    pinentry-1.1.0.tar.bz2

mkdir pinentry && tar xf pinentry-*.tar.* -C pinentry --strip-components 1
cd pinentry

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static \
    --enable-pinentry-tty \
    --enable-pinentry-gnome3=yes \
    --enable-pinentry-gtk2=yes     
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
rm -r pinentry

#XSLTPROC

#GCR

#gnome-common
wget http://ftp.gnome.org/pub/GNOME/sources/gnome-common/3.18/gnome-common-3.18.0.tar.xz -O \
    gnome-common-3.18.0.tar.xz

mkdir gnome-common && tar xf gnome-common-*.tar.* -C gnome-common --strip-components 1
cd gnome-common

ACLOCAL_FLAG=/usr/share/aclocal/ CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr\
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin 
    
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf gnome-common

#libgnome-keyring (for gnome-keyring-1) FINALLY FOUND IT
wget https://github.com/GNOME/libgnome-keyring/archive/3.12.0.tar.gz -O \
  libgnome-keyring-3.12.0.tar.gz
  
mkdir libgnome-keyring && tar xf libgnome-keyring-*.tar.* -C libgnome-keyring  --strip-components 1
cd libgnome-keyring

autoreconf
intltoolize --force 

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} \
ACLOCAL_FLAGS=/usr/share/aclocal  sh autogen.sh

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} \
ACLOCAL_FLAGS=/usr/share/aclocal ./configure --prefix=/usr \
  --libdir=/usr/lib64 \
  --disable-static    

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libgnome-keyring

#gnome-keyring
wget https://github.com/GNOME/gnome-keyring/archive/3.28.0.1.tar.gz -O \
    gnome-keyring-3.28.0.1.tar.xz

mkdir gnome-keyring && tar xf gnome-keyring-*.tar.* -C gnome-keyring --strip-components 1
cd gnome-keyring
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static \
    --sysconfdir=/etc \
    --with-pam-dir=/lib64/security \
    --disable-doc
    
#Let's fix an annoying problem with docbook.xsl
#Delete all lines in Makefile and docs/Makefile.am
#Where docbook.xsl download URL
#is assigned to XSLTPROC_XSL
#Instead export it in this script
#and assign it the hardcoded path of anything containing html/docbook.xsl on you system
#It is most likely to be found somewhere in /usr/share/xml ...
#Also for paranoia reasons put the value assignment to XSLTPROC_XSL in front of the make command
#This method was tested to work!!!!!!

export XSLTPROC_XSL=/usr/share/xml/docbook/xsl-stylesheets-1.79.1/html/docbook.xsl

sed -i 's/XSLTPROC_XSL = \\//' Makefile docs/Makefile.am
sed -i 's/http\:\/\/docbook.sourceforge.net\/release\/xsl\/current\/manpages\/docbook.xsl//' Makefile docs/Makefile.am

XSLTPROC_XSL=/usr/share/xml/docbook/xsl-stylesheets-1.79.1/html/docbook.xsl \
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr

#Leave this disabled - it WILL fail!
#make check
#checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf gnome-keyring

#dbus-glib

#mate-session-manager
git clone https://github.com/mate-desktop/mate-session-manager
cd mate-session-manager

ACLOCAL_FLAG=/usr/share/aclocal/ CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr \
   --libdir=/usr/lib64 --sysconfdir=/etc --disable-static \
   --localstatedir=/var --bindir=/usr/bin --sbindir=/usr/sbin \
   --disable-docbook-docs

sed -i 's/HELP_DIR/#HELP_DIR/' Makefile Makefile.in
sed -i 's/help/#help/' Makefile*
sed -i 's/doc/#doc/' Makefile*

XSLTPROC_XSL=/usr/share/xml/docbook/xsl-stylesheets-1.79.1/html/docbook.xsl \
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

#sudo mkdir /usr/share/mate-session-manager
#sudo cp -rv data/* /usr/share/mate-session-manager

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf mate-session-manager

#nettle

#GnuTLS

#gsettings-desktop-schemas
wget http://ftp.gnome.org/pub/gnome/sources/gsettings-desktop-schemas/3.24/gsettings-desktop-schemas-3.24.1.tar.xz -O \
    gsettings-desktop-schemas-3.24.1.tar.xz
    
mkdir gsetdeskschemas && tar xf gsettings-desktop-schemas-*.tar.* -C gsetdeskschemas --strip-components 1
cd gsetdeskschemas

sed -i -r 's:"(/system):"/org/gnome\1:g' schemas/*.in

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf gsetdeskschemas

#libarchive

#libuv

#OPTIONAL: LLVM script: contains libarchive and libuv

#CMake

#libproxy
wget https://github.com/libproxy/libproxy/archive/0.4.15.tar.gz -O \
    libproxy-0.4.15.tar.gz

mkdir libproxy && tar xf libproxy-*.tar.* -C libproxy --strip-components 1
cd libproxy

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr \
   --libdir=/usr/lib64 --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libproxy

#glib-networking

#libsoup

#libmateweather
git clone https://github.com/mate-desktop/libmateweather
cd libmateweather

  ACLOCAL_FLAG=/usr/share/aclocal/ CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr \
   --libdir=/usr/lib64 --sysconfdir=/etc --disable-static \
   --localstatedir=/var --bindir=/usr/bin --sbindir=/usr/sbin \
   --enable-dependency-tracking

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libmateweather

#libwnk

#mate-menus
git clone https://github.com/mate-desktop/mate-menus
cd mate-menus

LIBSOUP_LIBS=/usr/lib64 \
  ACLOCAL_FLAG=/usr/share/aclocal/ CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr \
   --libdir=/usr/lib64 --sysconfdir=/etc --disable-static \
   --localstatedir=/var --bindir=/usr/bin --sbindir=/usr/sbin \

#YOU NEED PYTHON 2.7 FOR PYTHON BINDING!!!

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install
  
cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf mate-menus

#notification-daemon
wget http://ftp.gnome.org/pub/gnome/sources/notification-daemon/3.20/notification-daemon-3.20.0.tar.xz -O \
    notification-daemon-3.20.0.tar.xz

mkdir notificationdaemon && tar xf notification-daemon-*.tar.* -C notificationdaemon --strip-components 1
cd notificationdaemon

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

pgrep -l notification-da &&
notify-send -i info Information "Hi ${USER}, This is a Test"

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf notificationdaemon

#Zip 
wget http://downloads.sourceforge.net/infozip/zip30.tar.gz -O \
    zip30.tar.gz

mkdir zip && tar xf zip*.tar.* -C zip --strip-components 1
cd zip

sed -i 's/CC = cc#/CC = gcc#/' unix/Makefile

CC="gcc ${BUILD64}" \
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64 -f unix/Makefile generic_gcc
sudo make prefix=/usr MANDIR=/usr/share/man/man1 LIBDIR=/usr/lib64 -f unix/Makefile install

sudo mv /usr/local/bin/* /usr/bin/

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf zip

#autoconf2.13
wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.13.tar.gz -O \
    autoconf-2.13.tar.gz

wget http://www.linuxfromscratch.org/patches/blfs/svn/autoconf-2.13-consolidated_fixes-1.patch -O \
    Autoconf-2.13-consolidated_fixes-1.patch

mkdir autoconf && tar xf autoconf-*.tar.* -C autoconf --strip-components 1
cd autoconf

patch -Np1 -i ../Autoconf-2.13-consolidated_fixes-1.patch

mv -v autoconf.texi autoconf213.texi                     
rm -v autoconf.info       

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static --program-suffix=2.13 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

sudo install -v -m644 autoconf213.info /usr/share/info &&
sudo install-info --info-dir=/usr/share/info autoconf213.info

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf autoconf

#libqmi (recommended for ModemManager)
wget http://www.freedesktop.org/software/libqmi/libqmi-1.20.0.tar.xz -O \
    libqmi-1.20.0.tar.xz

mkdir libqmi && tar xf libqmi-*.tar.* -C libqmi --strip-components 1
cd libqmi

sudo ln -sfv /usr/bin/python3.6 /usr/bin/python

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr  \
            --libdir=/usr/lib64 \
            --sysconfdir=/etc    \
            --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

sudo unlink sudo ln -sfv /usr/bin/python

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libqmi

#libmbim (recommended for ModemManager)
wget http://www.freedesktop.org/software/libmbim/libmbim-1.16.0.tar.xz -O \
    libmbim-1.16.0.tar.xz

mkdir libmbim && tar xf libmbim-*.tar.* -C libmbim --strip-components 1
cd libmbim

sudo ln -sfv /usr/bin/python3.6 /usr/bin/python

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr  \
            --libdir=/usr/lib64 \
            --sysconfdir=/etc    \
            --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

sudo unlink sudo ln -sfv /usr/bin/python

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libmbim

#ModemManager
wget http://www.freedesktop.org/software/ModemManager/ModemManager-1.6.12.tar.xz -O \
    ModemManager-1.6.12.tar.xz

mkdir ModemManager && tar xf ModemManager-*.tar.* -C ModemManager --strip-components 1
cd ModemManager

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr  \
            --libdir=/usr/lib64 \
            --sysconfdir=/etc    \
            --localstatedir=/var \
            --enable-more-warnings=no \
            --disable-static  \
            --disable-gtk-doc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf ModemManager

#libdaemon
wget http://0pointer.de/lennart/projects/libdaemon/libdaemon-0.14.tar.gz -O \
    libdaemon-0.14.tar.gz

mkdir libdaemon && tar xf libdaemon-*.tar.* -C libdaemon --strip-components 1
cd libdaemon

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
  --libdir=/usr/lib64 --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make docdir=/usr/share/doc/libdaemon-0.14 LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libdaemon

#GTK2

#Pixman 64-bit

#libglade
wget http://ftp.gnome.org/pub/gnome/sources/libglade/2.6/libglade-2.6.4.tar.bz2 -O \
    libglade-2.6.4.tar.bz2

mkdir libglade && tar xf libglade-*.tar.* -C libglade --strip-components 1
cd libglade

sed -i '/DG_DISABLE_DEPRECATED/d' glade/Makefile.in 

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
  --libdir=/usr/lib64 --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libglade

#PyCairo2
wget https://github.com/pygobject/pycairo/archive/v1.16.3.tar.gz -O \
    pycairo-1.16.3.tar.gz

mkdir pycairo && tar xf pycairo-*.tar.* -C pycairo --strip-components 1
cd pycairo

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} LIBDIR=/usr/lib64 PREFIX=/usr python2.7 setup.py build  
sudo bash -c 'PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} python2.7 setup.py install --verbose --prefix=/usr/lib64 \
  --install-lib=/usr/lib64/python2.7/site-packages --optimize=1'

checkBuiltPackage

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} LIBDIR=/usr/lib64 PREFIX=/usr python3.6 setup.py build
sudo bash -c 'export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig && PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} \
  python3.6 setup.py install --verbose --prefix=/usr/lib64 \
   --install-lib=/usr/lib64/python3.6/site-packages --optimize=1'

sudo mv -v /usr/lib64/lib/pkgconfig/* /usr/lib64/pkgconfig/ 
sudo sudo rm -rf /usr/lib64/lib

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf pycairo

#PyGObject2
wget http://ftp.gnome.org/pub/gnome/sources/pygobject/2.28/pygobject-2.28.7.tar.xz -O \
    pygobject-2.28.6.tar.xz

mkdir pygobject && tar xf pygobject-2*.tar.* -C pygobject --strip-components 1
cd pygobject

export PYTHON=/usr/bin/python2.7
export PYTHONPATH=/usr/lib64/python2.7
export PYTHONHOME=/usr/lib64/python2.7
export PYTHON_INCLUDES="/usr/include/python2.7"
export CPPFLAGS="-I"${PYTHON_INCLUDES}""

PYTHON=/usr/bin/python2.7 \
PYTHONPATH=/usr/lib64/python2.7 \
PYTHONHOME=/usr/lib64/python2.7 \
PYTHON_INCLUDES="/usr/include/python2.7" \
CPPFLAGS="-I"${PYTHON_INCLUDES}"" CC="gcc ${BUILD64}" \
CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
  --libdir=/usr/lib64 --disable-introspection --disable-docs

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

unset PYTHON PYTHONHOME PYTHONPATH PYTHON_INCLUDES CPPFLAGS

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf pygobject

#PyGObject3
wget http://ftp.gnome.org/pub/gnome/sources/pygobject/3.26/pygobject-3.26.1.tar.xz -O \
    pygobject-3.26.1.tar.xz

mkdir pygobject3 && tar xf pygobject-3*.tar.* -C pygobject3 --strip-components 1
cd pygobject3

mkdir python2 &&
pushd python2 &&

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ../configure --prefix=/usr \
    --with-python=/usr/bin/python2.7 --libdir=/usr/lib64 &&
make PREFIX=/usr LIBDIR=/usr/lib64 &&
popd

sudo make PREFIX=/usr LIBDIR=/usr/lib64 -C python2 install

mkdir python3 &&
pushd python3 &&

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ../configure --prefix=/usr \
    --with-python=/usr/bin/python3.6 --libdir=/usr/lib64 &&
make PREFIX=/usr LIBDIR=/usr/lib64 &&
popd

sudo make PREFIX=/usr LIBDIR=/usr/lib64 -C python3 install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf pygobject3

#DbusPy
wget http://dbus.freedesktop.org/releases/dbus-python/dbus-python-1.2.6.tar.gz -O \
    dbus-python-1.2.6.tar.gz

mkdir dbus-python && tar xf dbus-python-*.tar.* -C dbus-python --strip-components 1
cd dbus-python

mkdir python2 &&
pushd python2 &&
PYTHON=/usr/bin/python2.7     \
 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ../configure --prefix=/usr \
 --libdir=/usr/lib64 --docdir=/usr/share/doc/dbus-python-1.2.4 &&
make PREFIX=/usr LIBDIR=/usr/lib64 &&
popd

sudo make PREFIX=/usr LIBDIR=/usr/lib64 -C python2 install

mkdir python3 &&
pushd python3 &&
sudo ln -sfv /usr/bin/python3.6m-config /usr/bin/python-config
PYTHON=/usr/bin/python3.6 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64}  ../configure --prefix=/usr --libdir=/usr/lib64 &&
make PREFIX=/usr LIBDIR=/usr/lib64 &&
popd

sudo unlink /usr/bin/python-config
sudo make PREFIX=/usr LIBDIR=/usr/lib64 -C python3 install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf dbus-python

#Avahi
wget https://github.com/lathiat/avahi/releases/download/v0.7/avahi-0.7.tar.gz -O \
    avahi-0.7.tar.gz

mkdir avahi && tar xf avahi-*.tar.* -C avahi --strip-components 1
cd avahi

wget https://github.com/lathiat/avahi/releases/download/v0.7/avahi-0.7.tar.gz -O \
    avahi-0.7.tar.gz

sudo groupadd -fg 84 avahi 
sudo useradd -c "Avahi Daemon Owner" -d /var/run/avahi-daemon -u 84 \
        -g avahi -s /bin/false avahi

sudo groupadd -fg 86 netdev

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
            --sysconfdir=/etc    \
            --localstatedir=/var \
            --libdir=/usr/lib64  \
            --disable-static     \
            --disable-mono       \
            --disable-monodoc    \
            --disable-qt3        \
            --disable-qt4        \
            --disable-qt5        \
            --enable-core-docs   \
            --with-distro=none   \
            --with-systemdsystemunitdir=no \
            --disable-systemd \
            --enable-python \
            --enable-gtk3   \
            --enable-gtk2 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
export PYTHON=/usr/bin/python2.7
sudo make PYTHON=/usr/bin/python2.7 LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/blfs-bootscripts
sudo make install-avahi

sed -i 's/loadproc/start_daemon/' /etc/rc.d/init.d/avahi
sed -i 's/load_info_msg/echo/' /etc/rc.d/init.d/avahi
sed -i 's/\/lib\//\/lib64\//' /etc/rc.d/init.d/avahi

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf avahi

#add avahi openRC script

#GeoCLue
wget http://www.freedesktop.org/software/geoclue/releases/2.4/geoclue-2.4.7.tar.xz -O \
    geoclue-2.4.7.tar.xz

mkdir geoclue && tar xf geoclue-*.tar.* -C geoclue --strip-components 1
cd geoclue

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
  --sysconfdir=/etc --libdir=/usr/lib64 --disable-modem-gps-source \
  --disable-3g-source

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf geoclue

#Aspell
wget https://ftp.gnu.org/gnu/aspell/aspell-0.60.6.1.tar.gz -O \
    aspell-0.60.6.1.tar.gz

mkdir aspell && tar xf aspell-*.tar.* -C aspell --strip-components 1
cd aspell

sed -i '/ top.do_check ==/s/top.do_check/*&/' modules/filter/tex.cpp &&
sed -i '/word ==/s/word/*&/'                  prog/check_funs.cpp

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
  --libdir=/usr/lib64

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

sudo ln -svfn aspell-0.60 /usr/lib64/aspell 
sudo install -v -m755 -d /usr/share/doc/aspell-0.60.6.1/aspell{,-dev}.html

sudo install -v -m644 manual/aspell.html/* \
    /usr/share/doc/aspell-0.60.6.1/aspell.html

sudo install -v -m644 manual/aspell-dev.html/* \
    /usr/share/doc/aspell-0.60.6.1/aspell-dev.html

sudo install -v -m 755 scripts/ispell /usr/bin/
sudo install -v -m 755 scripts/spell /usr/bin/

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf aspell

#enchant
wget https://github.com/AbiWord/enchant/releases/download/v2.2.3/enchant-2.2.3.tar.gz -O \
    enchant-2.2.3.tar.gz
    
mkdir enchant && tar xf enchant-*.tar.* -C enchant --strip-components 1
cd enchant

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
  --libdir=/usr/lib64

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf enchant

#libsecret

#libwebp

#Ruby
wget https://cache.ruby-lang.org/pub/ruby/2.5/ruby-2.5.0.tar.gz -O \
    ruby-2.5.0.tar.xz 

mkdir ruby && tar xf ruby-*.tar.* -C ruby --strip-components 1
cd ruby

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
  --libdir=/usr/lib64 \
  --enable-shared \
  --docdir=/usr/share/doc/ruby-2.5.0
  
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install 

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf ruby

#libnotify

#Hyphen
wget https://netix.dl.sourceforge.net/project/hunspell/Hyphen/2.8/hyphen-2.8.8.tar.gz -O \
    hyphen-2.8.8.tar.gz

mkdir hyphen && tar xf hyphen-*.tar.* -C hyphen --strip-components 1
cd hyphen

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf hyphen

#WebKitGTK
wget https://webkitgtk.org/releases/webkitgtk-2.18.6.tar.xz -O \
    webkitgtk-2.18.6.tar.xz

mkdir webkitgtk && tar xf webkitgtk-*.tar.* -C webkitgtk --strip-components 1
cd webkitgtk
       
mkdir -vp build
cd        build

LIBS_PATH=-L./usr/lib64 INC_PATH=-I./usr/include/ \
      LD_LIB_PATH=/usr/lib64 LD_LIBRARY_PATH=/usr/lib64 \
      CFLAGS=-Wno-expansion-to-defined  \
      CXXFLAGS=-Wno-expansion-to-defined \
      CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
      USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} \
      LIBRARY_PATH=/usr/lib64 cmake -DCMAKE_BUILD_TYPE=Release  \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_SKIP_RPATH=ON       \
      -DPORT=GTK                  \
      -DLIB_INSTALL_DIR=/usr/lib64  \
      -DUSE_LIBHYPHEN=ON         \
      -DENABLE_MINIBROWSER=ON     \
      -Wno-dev .. &&

LIBS_PATH=-L./usr/lib64 INC_PATH=-I./usr/include/ \
      LD_LIB_PATH=/usr/lib64 LD_LIBRARY_PATH=/usr/lib64 \
      CFLAGS=-Wno-expansion-to-defined  \
      CXXFLAGS=-Wno-expansion-to-defined \
      CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
      PREFIX=/usr LIBDIR=/usr/lib64 \
      USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} \
      LIBRARY_PATH=/usr/lib64 make
      
LIBS_PATH=-L./usr/lib64 INC_PATH=-I./usr/include/ \
      LD_LIB_PATH=/usr/lib64 LD_LIBRARY_PATH=/usr/lib64 \
      CFLAGS=-Wno-expansion-to-defined  \
      CXXFLAGS=-Wno-expansion-to-defined \
      CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
      PREFIX=/usr LIBDIR=/usr/lib64 \
      USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} \
      LIBRARY_PATH=/usr/lib64 sudo make install
            
cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf webkitgtk

#yelp-xsl
wget http://ftp.gnome.org/pub/gnome/sources/yelp-xsl/3.20/yelp-xsl-3.20.1.tar.xz -O \
    yelp-xsl-3.20.1.tar.xz

mkdir yelp-xsl && tar xf yelp-xsl-*.tar.* -C yelp-xsl --strip-components 1
cd yelp-xsl

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr --libdir=/usr/lib64

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install


sudo install -vdm755 /usr/share/gtk-doc/html/webkit{2,dom}gtk-4.0 &&
sudo install -vm644  ../Documentation/webkit2gtk-4.0/html/*   \
                /usr/share/gtk-doc/html/webkit2gtk-4.0       &&
sudo install -vm644  ../Documentation/webkitdomgtk-4.0/html/* \
                /usr/share/gtk-doc/html/webkitdomgtk-4.0

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf yelp-xsl

#Yelp
wget http://ftp.gnome.org/pub/gnome/sources/yelp/3.26/yelp-3.26.0.tar.xz -O \
    Yelp-3.26.0.tar.xz

mkdir yelp && tar xf Yelp-*.tar.* -C yelp --strip-components 1
cd yelp

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
  --libdir=/usr/lib64 \
  --disable-static \
  --disable-gtk-doc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install
sudo update-desktop-database
sudo libtool --finish /usr/lib64/yelp/web-extensions
sudo libtool --finish /usr/lib64/
ldconfig

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf yelp

#yelp-tools
wget https://github.com/GNOME/yelp-tools/archive/3.28.0.tar.gz -O \
    yelp-tools-3.28.0.tar.gz

mkdir yelp-tools && tar xf yelp-tools-*.tar.* -C yelp-tools --strip-components 1
cd yelp-tools

ACLOCAL_FLAG=/usr/share/aclocal/ CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr \
   --libdir=/usr/lib64 --sysconfdir=/etc \
   --localstatedir=/var --bindir=/usr/bin --sbindir=/usr/sbin 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf yelp

#mate-panel
git clone https://github.com/mate-desktop/mate-panel
cd mate-panel

cp -rv /usr/share/aclocal/*.m4 m4/

CPPFLAGS="-I/usr/include" LDFLAGS="-L/usr/lib64"  \
PYTHON="/usr/bin/python2.7" PYTHONPATH="/usr/lib64/python2.7" \
PYTHONHOME="/usr/lib64/python2.7" PYTHON_INCLUDES="/usr/include/python2.7" \
ACLOCAL_FLAG="/usr/share/aclocal/" LIBSOUP_LIBS=/usr/lib64   \
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr \
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --disable-gtk-doc 
    
#Deactivate building of the help subdir because it will fail
sed -i 's/HELP_DIR/#HELP_DIR/' Makefile Makefile.in
sed -i 's/help/#help/' Makefile Makefile.in Makefile.am
   
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install
 
cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf mate-panel
