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
echo ""Y
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
mkdir -pv cd ${CLFSSOURCES}/xc/mate
cd ${CLFSSOURCES}/xc/mate

#We will only do 64-bit builds in this script

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 
USE_ARCH=64 
CXX="g++ ${BUILD64}" 
CC="gcc ${BUILD64}"

export PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 
export USE_ARCH=64 
export CXX="g++ ${BUILD64}" 
export CC="gcc ${BUILD64}"

sudo ln -sfv /usr/bin/python2.7 /usr/bin/python
sudo ln -sfv /usr/bin/python2.7-config /usr/bin/python-config
export PYTHON=/usr/bin/python

libical
wget https://github.com/libical/libical/releases/download/v3.0.2/libical-3.0.2.tar.gz -O \
    libical-3.0.2.tar.gz

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
sudo install -vdm755 /usr/share/doc/libical-3.0.2/html &&
sudo cp -vr apidocs/html/* /usr/share/doc/libical-3.0.2/html

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libical

#BlueZ
wget http://www.kernel.org/pub/linux/bluetooth/bluez-5.48.tar.xz -O \
    bluez-5.48.tar.xz

wget http://www.linuxfromscratch.org/patches/blfs/svn/bluez-5.48-obexd_without_systemd-1.patch -O \
    Bluez-5.48-obexd_without_systemd-1.patch

mkdir bluez && tar xf bluez-*.tar.* -C bluez --strip-components 1
cd bluez

patch -Np1 -i ../Bluez-5.48-obexd_without_systemd-1.patch

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

cd ${CLFSSOURCES}
checkBuiltPackage
sudo rm -rf bluez

#Alsa-Libs
wget ftp://ftp.alsa-project.org/pub/lib/alsa-lib-1.1.5.tar.bz2 -O \
    alsa-lib-1.1.5.tar.bz2

mkdir alsa-lib && tar xf alsa-lib-*.tar.* -C alsa-lib --strip-components 1
cd alsa-lib

PYTHON=/usr/bin/python PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
make check
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf alsa-lib

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

#alsa-plugins
wget ftp://ftp.alsa-project.org/pub/plugins/alsa-plugins-1.1.5.tar.bz2 -O \
  alsa-plugins-1.1.5.tar.bz2

mkdir alsa-plugins && tar xf alsa-plugins-*.tar.* -C alsa-plugins --strip-components 1
cd alsa-plugins

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf alsa-plugins

#alsa-utils
wget ftp://ftp.alsa-project.org/pub/utils/alsa-utils-1.1.5.tar.bz2 -O \
  alsa-utils-1.1.5.tar.bz2

mkdir alsa-utils && tar xf alsa-utils-*.tar.* -C alsa-utils --strip-components 1
cd alsa-utils

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-alsaconf \
   --disable-bat   \
   --with-curses=ncursesw \
   --with-systemdsystemunitdir=no \
   --disable-xmlto --disable-rst2man \
   --with-asound-state-dir=/var/lib64/alsa \
   --with-udev-rules-dir=/etc/udev/rules.d

#Remove all signs of Manpage install in Makefile* and alsactl/Makefile*

nano alsactl/Makefile

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo alsactl -L store
usermod -a -G audio overflyer

#add openRC alsa script

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf alsa-utils

#alsa-tools
wget ftp://ftp.alsa-project.org/pub/tools/alsa-tools-1.1.5.tar.bz2 -O \
  alsa-tools-1.1.5.tar.bz2

mkdir alsa-tools && tar xf alsa-tools-*.tar.* -C alsa-tools --strip-components 1
cd alsa-tools

sudo rm -rf qlo10k1 Makefile gitcompile

for tool in *
do
  case $tool in
    seq )
      tool_dir=seq/sbiload
    ;;
    * )
      tool_dir=$tool
    ;;
  esac

  pushd $tool_dir
    ./configure --prefix=/usr --libdir=/usr/lib64
    PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
    sudo make PREFIX=/usr LIBDIR=/usr/lib64 install
    sudo /sbin/ldconfig
  popd

done
unset tool tool_dir

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf alsa-tools

#alsa-firmware
wget ftp://ftp.alsa-project.org/pub/firmware/alsa-firmware-1.0.29.tar.bz2 -O \
  alsa-firmware-1.0.29.tar.bz2

mkdir alsa-firmware && tar xf alsa-firmware-*.tar.* -C alsa-firmware --strip-components 1
cd alsa-firmware

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf alsa-firmware

alsa-oss
wget ftp://ftp.alsa-project.org/pub/oss-lib/alsa-oss-1.0.28.tar.bz2 -O \
  alsa-oss-1.0.28.tar.bz2

mkdir alsa-oss && tar xf alsa-oss-*.tar.* -C alsa-oss --strip-components 1
cd alsa-oss

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
  --libdir=/usr/lib64 --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf alsa-oss

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

#PulseAudio
wget https://www.freedesktop.org/software/pulseaudio/releases/pulseaudio-11.1.tar.xz -O \
    pulseaudio-11.1.tar.xz

wget http://www.linuxfromscratch.org/patches/blfs/svn/pulseaudio-11.1-glibc_2.27_fix-1.patch -O \
    pulseaudio-11.1-glibc_2.27_fix-1.patch

mkdir pulseaudio && tar xf pulseaudio-*.tar.* -C pulseaudio --strip-components 1
cd pulseaudio

patch -Np1 -i ../pulseaudio-11.1-glibc_2.27_fix-1.patch

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
            --disable-static \
            --libdir=/usr/lib64 \
            --localstatedir=/var \
            --disable-bluez4     \
            --disable-rpath \
            --disable-systemd-daemon \
            --disable-systemd-login \
            --disable-systemd-journal \
            --enable-bluez5

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr

make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

sudo rm /etc/dbus-1/system.d/pulseaudio-system.conf
sudo install -dm755 /etc/pulse
sudo cp -v src/default.pa /etc/pulse
sudo sed -i '/load-module module-console-kit/s/^/#/' /etc/pulse/default.pa

sudo rc-service alsasound zap
sudo rc-service alsasound start
sudo rc-service alsasound restart
pulseaudio --start

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf pulseaudio

#Pavucontrol
git clone https://github.com/pulseaudio/pavucontrol
cd pavucontrol

intltool-prepare

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" sh bootstrap.sh --prefix=/usr \
  --libdir=/usr/lib64

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
  --libdir=/usr/lib64 --disable-lynx

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf pavucontrol

sudo unlink /usr/bin/python
sudo unlink /usr/bin/python-config
unset PYTHON
