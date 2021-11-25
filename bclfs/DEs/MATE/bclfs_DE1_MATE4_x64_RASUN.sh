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
CLFSHOME=/home
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

#libgtop 
wget http://ftp.gnome.org/pub/gnome/sources/libgtop/2.36/libgtop-2.36.0.tar.xz -O \
    libgtop-2.36.0.tar.xz

mkdir libgtop && tar xf libgtop-*.tar.* -C libgtop --strip-components 1
cd libgtop

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --disable-static \
    --libdir=/usr/lib64
    
make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libgtop

#mate-utils
#git clone https://github.com/mate-desktop/mate-utils
#cd mate-utils
#
#intltool-prepare
#intltoolize --force
#cp -rv /usr/share/aclocal/*.m4 m4/
#
#echo "How did intltoolize perform? "
#checkBuiltPackage
#
#CPPFLAGS="-I/usr/include" LDFLAGS="-L/usr/lib64"  \
#PYTHON="/usr/bin/python2" PYTHONPATH="/usr/lib64/python2.7" \
#PYTHONHOME="/usr/lib64/python2.7" PYTHON_INCLUDES="/usr/include/python2.7" \
#ACLOCAL_FLAG=/usr/share/aclocal/ CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
#USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr\
#    --libdir=/usr/lib64 \
#    --sysconfdir=/etc \
#    --localstatedir=/var \
#    --bindir=/usr/bin \
#    --sbindir=/usr/sbin --disable-gtk-doc &&
#    
##Deactivate building of baobab because it will fail
##Because itstool will throw error
##Baobab can show size of directory trees in percentage
#Let's see later if this tool was essential...hope not
#sed -i 's/baobab/#baobab/' Makefile*
#   
#PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
#sudo make LIBDIR=/usr/lib64 PREFIX=/usr install
#
#cd ${CLFSSOURCES}/xc/mate
#checkBuiltPackage
#sudo rm -rf mate-utils

#PCRE2

#vte

#mate-terminal
git clone https://github.com/mate-desktop/mate-terminal
cd mate-terminal

cp -rv /usr/share/aclocal/*.m4 m4/

CPPFLAGS="-I/usr/include" LDFLAGS="-L/usr/lib64"  \
PYTHON="/usr/bin/python2" PYTHONPATH="/usr/lib64/python2.7" \
PYTHONHOME="/usr/lib64/python2.7" PYTHON_INCLUDES="/usr/include/python2.7" \
ACLOCAL_FLAG=/usr/share/aclocal/ CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr\
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin --disable-gtk-doc &&

sed -i 's/HELP_DIR/#HELP_DIR/' Makefile Makefile.in
sed -i 's/help/#help/' Makefile Makefile.in Makefile.am
  
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}
checkBuiltPackage
sudo rm -rf mate-terminal

#iso-codes

#libxklavier

#libmatekbd
git clone https://github.com/mate-desktop/libmatekbd
cd libmatekbd

cp -rv /usr/share/aclocal/*.m4 m4/

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr\
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --disable-static --enable-shared &&
  
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libmatekbd

#json-c
git clone https://github.com/json-c/json-c    
cd json-c

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr --libdir=/usr/lib64 \
    --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make -j1 LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}
checkBuiltPackage
sudo rm -rf json-c

#FLAC
wget http://downloads.xiph.org/releases/flac/flac-1.3.2.tar.xz -O \
    flac-1.3.2.tar.xz

mkdir flac && tar xf flac-*.tar.* -C flac --strip-components 1
cd flac

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr --libdir=/usr/lib64 \
    --disable-static --disable-thorough-tests
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf flac

#libsndfile
wget http://www.mega-nerd.com/libsndfile/files/libsndfile-1.0.28.tar.gz -O \
    libsndfile-1.0.28.tar.gz

mkdir libsndfile && tar xf libsndfile-*.tar.* -C libsndfile --strip-components 1
cd libsndfile

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr --libdir=/usr/lib64 \
    --disable-static 
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libsndfile

#libcap
wget https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.25.tar.xz -O \
    libcap-2.25.tar.xz
    
mkdir libcap && tar xf libcap-*.tar.* -C libcap --strip-components 1
cd libcap

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64 -C pam_cap

sudo install -v -m755 pam_cap/pam_cap.so /lib64/security &&
sudo install -v -m644 pam_cap/capability.conf /etc/security

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libcap

#speex
wget http://downloads.xiph.org/releases/speex/speex-1.2rc2.tar.gz -O \
    Speex-1.2rc2.tar.gz

mkdir speex && tar xf Speex-*.tar.* -C speex --strip-components 1
cd speex

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/speex-1.2rc2  
            --libdir=/usr/lib64
            
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf speex        

#speexdsp
wget http://downloads.xiph.org/releases/speex/speexdsp-1.2rc3.tar.gz -O \
    speexdsp-1.2rc3.tar.gz
    
mkdir speexdsp && tar xf speexdsp-*.tar.* -C speexdsp --strip-components 1
cd speexdsp

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/speex-1.2rc2  
            --libdir=/usr/lib64
            
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install       

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf speexdsp

#libical
wget https://github.com/libical/libical/releases/download/v2.0.0/libical-2.0.0.tar.gz -O \
    libical-2.0.0.tar.gz

mkdir libical && tar xf libical-*.tar.* -C libical --strip-components 1
cd libical

mkdir build 
cd build 

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} cmake -DCMAKE_INSTALL_PREFIX=/usr      \
      -DCMAKE_BUILD_TYPE=Release       \
      -DSHARED_ONLY=yes                \
      -LIBRARY_OUTPUT_PATH=/usr/lib64  \
      -DLIB_DIR=/usr/lib64 .. &&

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install       
sudo install -vdm755 /usr/share/doc/libical-2.0.0/html &&
sudo cp -vr apidocs/html/* /usr/share/doc/libical-2.0.0/html

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libical

#BlueZ
wget http://www.kernel.org/pub/linux/bluetooth/bluez-5.45.tar.xz -O \
    bluez-5.45.tar.xz

wget http://www.linuxfromscratch.org/patches/blfs/svn/bluez-5.45-obexd_without_systemd-1.patch -O \
    Bluez-5.45-obexd_without_systemd-1.patch

mkdir bluez && tar xf bluez-*.tar.* -C bluez --strip-components 1
cd bluez

patch -Np1 -i ../Bluez-5.45-obexd_without_systemd-1.patch

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr    \
            --disable-static \
            --enable-shared \
            --sysconfdir=/etc    \
            --localstatedir=/var  \
            --enable-library   \
            --disable-systemd  \
            --libdir=/usr/lib64

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install    

sudo ln -svf ../libexec/bluetooth/bluetoothd /usr/sbin
sudo install -v -dm755 /etc/bluetooth &&
sudo install -v -m644 src/main.conf /etc/bluetooth/main.conf

sudo bash -c 'cat > /etc/bluetooth/rfcomm.conf << "EOF"
# Start rfcomm.conf
# Set up the RFCOMM configuration of the Bluetooth subsystem in the Linux kernel.
# Use one line per command
# See the rfcomm man page for options

# End of rfcomm.conf
EOF'

sudo bash -c 'cat > /etc/bluetooth/uart.conf << "EOF"
# Start uart.conf
# Attach serial devices via UART HCI to BlueZ stack
# Use one line per device
# See the hciattach man page for options

# End of uart.conf
EOF'

cd ${CLFSSOURCES}/blfs-bootscripts

sudo make install-bluetooth

cd ${CLFSSOURCES}
checkBuiltPackage
sudo rm -rf bluez

#gconf
wget http://ftp.gnome.org/pub/gnome/sources/GConf/3.2/GConf-3.2.6.tar.xz -O \
    GConf-3.2.6.tar.xz

mkdir gconf && tar xf GConf-*.tar.* -C gconf --strip-components 1
cd gconf

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
            --disable-static \
            --enable-shared \
            --sysconfdir=/etc  \
            --disable-orbit \
            --libdir=/usr/lib64

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install    
sudo ln -s gconf.xml.defaults /etc/gconf/gconf.xml.system

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf gconf

#SBC
wget http://www.kernel.org/pub/linux/bluetooth/sbc-1.3.tar.xz -O \
    sbc-1.3.tar.xz

mkdir sbc && tar xf sbc-*.tar.* -C sbc --strip-components 1
cd sbc

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
            --disable-static \
            --disable-tester \
            --libdir=/usr/lib64

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install    

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf sbc

#Install all alsa packages except oss and PulseAudio!
sh bclfs_DESKTOP_goodies_sound_x64_RASUN_sound.sh

#libmatemixer
git clone https://github.com/mate-desktop/libmatemixer
cd libmatemixer

sudo cp -rv /usr/share/aclocal/*.m4 m4/

ACLOCAL_FLAG=/usr/share/aclocal/ CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr\
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin --disable-gtk-doc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libmatemixer

#NSS

#mate-setting-daemon
git clone https://github.com/mate-desktop/mate-settings-daemon
cd mate-settings-daemon

sudo cp -rv /usr/share/aclocal/*.m4 m4/

ACLOCAL_FLAG=/usr/share/aclocal/ CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr\
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --enable-pulse

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf mate-settings-daemon

#mate-media
git clone https://github.com/mate-desktop/mate-media
cd mate-media

sudo cp -rv /usr/share/aclocal/*.m4 m4/

ACLOCAL_FLAG=/usr/share/aclocal/ CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr\
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf mate-media

#mate-screensaver
wget https://github.com/mate-desktop/mate-screensaver/archive/v1.18.1.tar.gz -O \
    mate-screensaver-1.18.1.tar.gz

mkdir mate-screensaver && tar xf mate-screensaver-*.tar.* -C mate-screensaver --strip-components 1
cd mate-screensaver

sudo cp -rv /usr/share/aclocal/*.m4 m4/

ACLOCAL_FLAG=/usr/share/aclocal/ CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} sh autogen.sh --prefix=/usr\
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

sudo mkdir /usr/share/mate-screensaver
sudo cp -rv data/* /usr/share/mate-screensaver

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf mate-screensaver
