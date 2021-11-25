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
  USE_ARCH=64 CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" ./configure $XORG_CONFIG64
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
export PKG_CONFIG_PATH=/usr/lib64/pkgconfig
export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig
export ACLOCAL="aclocal -I $XORG_PREFIX/share/aclocal"

mkdir -pv ${CLFSSOURCES}/xc

cd ${CLFSSOURCES}
cd ${CLFSSOURCES/xc}

#Add this point you COULD install Linux-PAM
echo "Add this point you COULD install Linux-PAM. Run bclfs_2 script for that."
checkBuiltPackage 

cd ${CLFSSOURCES}/xc

export XORG_PREFIX="/usr"
export XORG_CONFIG64="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var \
  --libdir=$XORG_PREFIX/lib64"

XORG_PREFIX="/usr"
XORG_CONFIG64="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var \
  --libdir=$XORG_PREFIX/lib64"

#Xorg Apps
cat > app-7.md5 << "EOF"
3b9b79fa0f9928161f4bad94273de7ae  iceauth-1.0.8.tar.bz2
c4a3664e08e5a47c120ff9263ee2f20c  luit-1.1.1.tar.bz2
18c429148c96c2079edda922a2b67632  mkfontdir-1.0.7.tar.bz2
987c438e79f5ddb84a9c5726a1610819  mkfontscale-1.1.3.tar.bz2
e475167a892b589da23edf8edf8c942d  sessreg-1.1.1.tar.bz2
2c47a1b8e268df73963c4eb2316b1a89  setxkbmap-1.3.1.tar.bz2
3a93d9f0859de5d8b65a68a125d48f6a  smproxy-1.0.6.tar.bz2
f0b24e4d8beb622a419e8431e1c03cd7  x11perf-1.6.0.tar.bz2
f3f76cb10f69b571c43893ea6a634aa4  xauth-1.0.10.tar.bz2
d50cf135af04436b9456a5ab7dcf7971  xbacklight-1.2.2.tar.bz2
9956d751ea3ae4538c3ebd07f70736a0  xcmsdb-1.0.5.tar.bz2
b58a87e6cd7145c70346adad551dba48  xcursorgen-1.0.6.tar.bz2
8809037bd48599af55dad81c508b6b39  xdpyinfo-1.3.2.tar.bz2
480e63cd365f03eb2515a6527d5f4ca6  xdriinfo-1.0.6.tar.bz2
249bdde90f01c0d861af52dc8fec379e  xev-1.2.2.tar.bz2
90b4305157c2b966d5180e2ee61262be  xgamma-1.0.6.tar.bz2
f5d490738b148cb7f2fe760f40f92516  xhost-1.0.7.tar.bz2
6a889412eff2e3c1c6bb19146f6fe84c  xinput-1.6.2.tar.bz2
12610df19df2af3797f2c130ee2bce97  xkbcomp-1.4.2.tar.bz2
c747faf1f78f5a5962419f8bdd066501  xkbevd-1.1.4.tar.bz2
502b14843f610af977dffc6cbf2102d5  xkbutils-1.0.4.tar.bz2
938177e4472c346cf031c1aefd8934fc  xkill-1.0.5.tar.bz2
5dcb6e6c4b28c8d7aeb45257f5a72a7d  xlsatoms-1.1.2.tar.bz2
4fa92377e0ddc137cd226a7a87b6b29a  xlsclients-1.1.4.tar.bz2
e50ffae17eeb3943079620cb78f5ce0b  xmessage-1.0.5.tar.bz2
723f02d3a5f98450554556205f0a9497  xmodmap-1.0.9.tar.bz2
eaac255076ea351fd08d76025788d9f9  xpr-1.0.5.tar.bz2
4becb3ddc4674d741487189e4ce3d0b6  xprop-1.2.3.tar.bz2
ebffac98021b8f1dc71da0c1918e9b57  xrandr-1.5.0.tar.bz2
96f9423eab4d0641c70848d665737d2e  xrdb-1.1.1.tar.bz2
c56fa4adbeed1ee5173f464a4c4a61a6  xrefresh-1.0.6.tar.bz2
70ea7bc7bacf1a124b1692605883f620  xset-1.2.4.tar.bz2
5fe769c8777a6e873ed1305e4ce2c353  xsetroot-1.1.2.tar.bz2
558360176b718dee3c39bc0648c0d10c  xvinfo-1.1.3.tar.bz2
11794a8eba6d295a192a8975287fd947  xwd-1.0.7.tar.bz2
9a505b91ae7160bbdec360968d060c83  xwininfo-1.1.4.tar.bz2
79972093bb0766fcd0223b2bd6d11932  xwud-1.0.5.tar.bz2
EOF

mkdir app
cd app

grep -v '^#' ../app-7.md5 | awk '{print $2}' | wget -i- -c \
    -B https://www.x.org/pub/individual/app/ &&
md5sum -c ../app-7.md5

export PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"

for package in $(grep -v '^#' ../app-7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir
     case $packagedir in
       luit-[0-9]* )
         sed -i -e "/D_XOPEN/s/5/6/" configure
       ;;
     esac
            
    PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
    USE_ARCH=64 CC="gcc ${BUILD64}" \
    CXX="g++ ${BUILD64}" ./configure $XORG_CONFIG64 &&
    
     make PREFIX=/usr LIBDIR=/usr/lib64
     sudo make PREFIX=/usr LIBDIR=/usr/lib64 install
     #checkBuiltPackage
  popd
  rm -rf $packagedir
done

sudo rm -f $XORG_PREFIX/bin/xkeystone

cd ${CLFSSOURCES}/xc

#xcursor-themes 64-bit
wget https://www.x.org/pub/individual/data/xcursor-themes-1.0.5.tar.bz2 -O \
  xcursor-themes-1.0.5.tar.bz2 
  
mkdir xcursor-themes && tar xf xcursor-themes-*.tar.* -C xcursor-themes --strip-components 1
cd xcursor-themes
 
buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xcursor-themes

#Xorg Fonts
cat > font-7.md5 << "EOF"
23756dab809f9ec5011bb27fb2c3c7d6  font-util-1.3.1.tar.bz2
0f2d6546d514c5cc4ecf78a60657a5c1  encodings-1.0.4.tar.bz2
6d25f64796fef34b53b439c2e9efa562  font-alias-1.0.3.tar.bz2
fcf24554c348df3c689b91596d7f9971  font-adobe-utopia-type1-1.0.4.tar.bz2
e8ca58ea0d3726b94fe9f2c17344be60  font-bh-ttf-1.0.3.tar.bz2
53ed9a42388b7ebb689bdfc374f96a22  font-bh-type1-1.0.3.tar.bz2
bfb2593d2102585f45daa960f43cb3c4  font-ibm-type1-1.0.3.tar.bz2
6306c808f7d7e7d660dfb3859f9091d2  font-misc-ethiopic-1.0.3.tar.bz2
3eeb3fb44690b477d510bbd8f86cf5aa  font-xfree86-type1-1.0.4.tar.bz2
EOF

mkdir font
cd font

grep -v '^#' ../font-7.md5 | awk '{print $2}' | wget -i- -c \
    -B https://www.x.org/pub/individual/font/ &&
md5sum -c ../font-7.md5

export PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"

for package in $(grep -v '^#' ../font-7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir
  PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
  USE_ARCH=64 \
  CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" ./configure $XORG_CONFIG64 &&
  make PREFIX=/usr &&
  sudo make PREFIX=/usr install
  popd
  rm -rf $packagedir
done

install -v -d -m755 /usr/share/fonts
ln -svfn $XORG_PREFIX/share/fonts/X11/OTF /usr/share/fonts/X11-OTF
ln -svfn $XORG_PREFIX/share/fonts/X11/TTF /usr/share/fonts/X11-TTF

cd ${CLFSSOURCES}/xc
cd ${CLFSSOURCES}

#XML::Parser (Perl module) 64-bit
wget http://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.44.tar.gz -O \
  XML-Parser-2.44.tar.gz
  
mkdir xmlparser && tar xf XML-Parser-*.tar.* -C xmlparser --strip-components 1
cd xmlparser

USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" perl Makefile.PL

make PREFIX=/usr LIBDIR=/usr/lib64

make PREFIX=/usr LIBDIR=/usr/lib64 test
checkBuiltPackage
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf xmlparser

#REMEMBER
#Escape all { or }
#In intltool-update
#When there is a regex ${<something>}
#Lines 1065, 1222-1226, 1993-1996

#intltool 64-bit
wget https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz -O \
  intltool-0.51.0.tar.gz
  
mkdir intltool && tar xf intltool-*.tar.* -C intltool --strip-components 1
cd intltool

patch -Np1 -i ../intltool-0.51.0-perl-5.22-compatibility.patch

checkBuiltPackage

USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" ./configure --prefix=/usr \
  --libdir=/usr/lib64

make PREFIX=/usr LIBDIR=/usr/lib64

make PREFIX=/usr LIBDIR=/usr/lib64 check
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf intltool

cd ${CLFSSOURCES}/xc

#XKeyboardConfig 64-bit
wget https://www.x.org/pub/individual/data/xkeyboard-config/xkeyboard-config-2.24.tar.bz2 -O \
  xkeyboard-config-2.24.tar.bz2
  
mkdir xkeyboard-config && tar xf xkeyboard-config-*.tar.* -C xkeyboard-config --strip-components 1
cd xkeyboard-config

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
USE_ARCH=64 \
CC="gcc ${BUILD64}" \
CXX="g++ ${BUILD64}" ./configure $XORG_CONFIG64 \
    --with-xkb-rules-symlink=xorg 
    
make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xkeyboard-config

#libepoxy 64-bit
wget https://github.com/anholt/libepoxy/releases/download/1.5.2/libepoxy-1.5.2.tar.xz -O \
  libepoxy-1.5.2.tar.xz
  
mkdir libepoxy && tar xf libepoxy-*.tar.* -C libepoxy --strip-components 1
cd libepoxy

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
USE_ARCH=64 CC="gcc ${BUILD64}" \
CXX="g++ ${BUILD64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64
    
make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libepoxy

#Pixman 64-bit
wget http://cairographics.org/releases/pixman-0.34.0.tar.gz -O \
  pixman-0.34.0.tar.gz
  
mkdir pixman && tar xf pixman-*.tar.* -C pixman --strip-components 1
cd pixman

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
USE_ARCH=64 CC="gcc ${BUILD64}" \
CXX="g++ ${BUILD64}" ./configure --prefix=/usr \
  --disable-static \
  --libdir=/usr/lib64 \
  --disable-gtk
  
make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf pixman

#nettle
wget https://ftp.gnu.org/gnu/nettle/nettle-3.4.tar.gz -O \
    nettle-3.4.tar.gz

mkdir nettle && tar xf nettle-*.tar.* -C nettle --strip-components 1
cd nettle

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static 
   
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install
sudo chmod   -v   755 /usr/lib64/lib{hogweed,nettle}.so
sudo install -v -m755 -d /usr/share/doc/nettle-3.4
sudo install -v -m644 nettle.html /usr/share/doc/nettle-3.4

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
rm -rf nettle

#Xorg Server 64-bit
wget https://www.x.org/pub/individual/xserver/xorg-server-1.20.0.tar.bz2 -O \
  xorg-server-1.20.0.tar.bz2 
  
mkdir xorg-server && tar xf xorg-server-*.tar.* -C xorg-server --strip-components 1
cd xorg-server

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
USE_ARCH=64 \
CC="gcc ${BUILD64}" \
CXX="g++ ${BUILD64}" ./configure $XORG_CONFIG64 \
           --enable-glamor          \
           --enable-install-setuid  \
           --enable-suid-wrapper    \
           --disable-systemd-logind \
           --with-xkb-output=/var/lib/xkb 
           
make PREFIX=/usr LIBDIR=/usr/lib64
sudo ldconfig

make check
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install
sudo mkdir -pv /etc/X11/xorg.conf.d

sudo bash -c 'cat >> /etc/sysconfig/createfiles << "EOF"
/tmp/.ICE-unix dir 1777 root root
/tmp/.X11-unix dir 1777 root root
EOF'

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xorg-server

#Xorg Drivers
#http://www.linuxfromscratch.org/blfs/view/svn/x/x7driver.html
#Check there if you want synaptips, wacom, nouveau, Intel or AMD drivers!

cd ${CLFSSOURCES}

#pcitutils 64-bit
wget https://www.kernel.org/pub/software/utils/pciutils/pciutils-3.6.1.tar.xz -O \
  pciutils-3.6.1.tar.xz

mkdir pciutils && tar xf pciutils-*.tar.* -C pciutils --strip-components 1
cd pciutils

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
USE_ARCH=64 \
CC="gcc ${BUILD64}" \
CXX="g++ ${BUILD64}" make PREFIX=/usr \
     SHAREDIR=/usr/share/hwdata \
     LIBDIR=/usr/lib64          \
     SHARED=yes

sudo make PREFIX=/usr        \
     SHAREDIR=/usr/share/hwdata \
     LIBDIR=/usr/lib64          \
     SHARED=yes                 \
     install install-lib       

sudo chmod -v 755 /usr/lib64/libpci.so

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf xorg-server

cd ${CLFSSOURCES}/xc

#mtdev 64-bit
wget http://bitmath.org/code/mtdev/mtdev-1.1.5.tar.bz2 -O \
  mtdev-1.1.5.tar.bz2
  
mkdir mtdev && tar xf mtdev-*.tar.* -C mtdev --strip-components 1
cd mtdev

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
USE_ARCH=64 \
CC="gcc ${BUILD64}" \
CXX="g++ ${BUILD64}" ./configure --prefix=/usr \
  --disable-static \
  --libdir=/usr/lib64 &&
  
make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf mtdev

#libevdev 64-bit
wget https://www.freedesktop.org/software/libevdev/libevdev-1.5.9.tar.xz -O \
  libevdev-1.5.9.tar.xz
  
mkdir libevdev && tar xf libevdev-*.tar.* -C libevdev --strip-components 1
cd libevdev

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libevdev

#Xorg Evdev Driver 64-bit
wget https://www.x.org/pub/individual/driver/xf86-input-evdev-2.10.5.tar.bz2 -O \
  xf86-input-evdev-2.10.5.tar.bz2
  
mkdir xf86-input-evdev && tar xf xf86-input-evdev-*.tar.* -C xf86-input-evdev --strip-components 1
cd xf86-input-evdev

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xf86-input-evdev

#libinput 64-bit
wget https://www.freedesktop.org/software/libinput/libinput-1.11.3.tar.xz -O \
    libinput-1.11.3.tar.xz
    
mkdir libinput && tar xf libinput-*.tar.* -C libinput --strip-components 1
cd libinput

mkdir build 
cd    build 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
USE_ARCH=64 \
CC="gcc ${BUILD64}" \
CXX="g++ ${BUILD64}"  \
meson --prefix=$XORG_PREFIX \
      --libdir=/usr/lib64 \
      -Dudev-dir=/lib64/udev  \
      -Ddebug-gui=false     \
      -Dtests=false         \
      -Ddocumentation=false \
      -Dlibwacom=false      \
      ..                    &&
ninja LIBDIR=/usr/lib64
sudo ninja install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libinput

#Xorg Fbdev Driver 64-bit
wget https://www.x.org/pub/individual/driver/xf86-video-fbdev-0.5.0.tar.bz2 -O \
    xf86-video-fbdev-0.5.0.tar.bz2

mkdir xf86vidfbdev && tar xf xf86-video-fbdev-*.tar.* -C xf86vidfbdev --strip-components 1
cd xf86vidfbdev

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xf86vidfbdev

#Nouveau 64-bit
wget https://www.x.org/pub/individual/driver/xf86-video-nouveau-1.0.15.tar.bz2 -O \
    xf86-video-nouveau-1.0.15.tar.bz2

mkdir xf86-video-nouveau && tar xf xf86-video-nouveau-*.tar.* -C xf86-video-nouveau --strip-components 1
cd xf86-video-nouveau

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xf86-video-nouveau

#AMDGRPU Driver x64
wget https://www.x.org/pub/individual/driver/xf86-video-amdgpu-18.0.1.tar.bz2 -O \
    xf86-video-amdgpu-18.0.1.tar.bz2

mkdir xf86-video-amdgpu && tar xf xf86-video-amdgpu-*.tar.* -C xf86-video-amdgpu --strip-components 1
cd xf86-video-amdgpu

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xf86-video-amdgpu

#Intel GPU Driver x64
wget http://anduin.linuxfromscratch.org/BLFS/xf86-video-intel/xf86-video-intel-20180223.tar.xz -O \
    xf86-video-intel-20180223.tar.xz

mkdir xf86-video-intel && tar xf xf86-video-intel-*.tar.* -C xf86-video-intel --strip-components 1
cd xf86-video-intel

./autogen.sh $XORG_CONFIG     \
            --enable-kms-only \
            --enable-uxa      \
            --mandir=/usr/share/man &&
make
make install
mv -v /usr/share/man/man4/intel-virtual-output.4 \
      /usr/share/man/man1/intel-virtual-output.1 &&
      
sed -i '/\.TH/s/4/1/' /usr/share/man/man1/intel-virtual-output.1


cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xf86-video-intel

#twm 64-bit
wget https://www.x.org/pub/individual/app/twm-1.0.10.tar.bz2 -O \
  twm-1.0.10.tar.bz2
  
mkdir twm && tar xf twm-*.tar.* -C twm --strip-components 1
cd twm

sed -i -e '/^rcdir =/s,^\(rcdir = \).*,\1/etc/X11/app-defaults,' src/Makefile.in

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf twm

USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}"

#xterm 64-bit
wget http://invisible-mirror.net/archives/xterm/xterm-333.tgz -O \
  xterm-333.tgz
  
mkdir xterm && tar xf xterm-*.tgz -C xterm --strip-components 1
cd xterm

sed -i '/v0/{n;s/new:/new:kb=^?:/}' termcap
printf '\tkbs=\\177,\n' >> terminfo

TERMINFO=/usr/share/terminfo \
./configure $XORG_CONFIG     \
    --with-app-defaults=/etc/X11/app-defaults

make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install 
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install-ti

sudo bash -c 'cat >> /etc/X11/app-defaults/XTerm << "EOF"
*VT100*locale: true
*VT100*faceName: Monospace
*VT100*faceSize: 10
*backarrowKeyIsErase: true
*ptyInitialErase: true
EOF'

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xterm

#xclock 64-bit
wget https://www.x.org/pub/individual/app/xclock-1.0.7.tar.bz2 -O \
  xclock-1.0.7.tar.bz2

mkdir xclock && tar xf xclock-*.tar.* -C xclock --strip-components 1
cd xclock

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xclock

#xinit 64-bit
wget https://www.x.org/pub/individual/app/xinit-1.4.0.tar.bz2 -O \
  xinit-1.4.0.tar.bz2

mkdir xinit && tar xf xinit-*.tar.* -C xinit --strip-components 1
cd xinit

sed -e '/$serverargs $vtarg/ s/serverargs/: #&/' \
    -i startx.cpp

USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
CC="gcc ${BUILD64}" \
CXX="g++ ${BUILD64}" ./configure $XORG_CONFIG64 \
    --with-xinitdir=/etc/X11/app-defaults 
    
make PREFIX=/usr LIBDIR=/usr/lib64 
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install
sudo ldconfig

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xinit

#DejaVu Fonts
wget https://netcologne.dl.sourceforge.net/project/dejavu/dejavu/2.37/dejavu-fonts-ttf-2.37.tar.bz2 -O \
  dejavu-fonts-ttf-2.37.tar.bz2

mkdir dejavu-fonts && tar xf dejavu-fonts-*.tar.* -C dejavu-fonts --strip-components 1
cd dejavu-fonts

sudo mkdir /etc/fonts
sudo mkdir /etc/fonts/conf.d
sudo mkdir /etc/fonts/conf.avail
sudo mkdir -pv /usr/share/fonts/TTF

sudo cp -v fontconfig/* /etc/fonts/conf.avail
sudo cp -v fontconfig/* /etc/fonts/conf.d
sudo cp -v ttf/* /usr/share/fonts/TTF

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf dejavu-fonts

sudo bash -c 'cat > /etc/X11/xorg.conf.d/xkb-defaults.conf << "EOF"
Section "InputClass"
    Identifier "XKB Defaults"
    MatchIsKeyboard "yes"
    Option "XkbLayout" "de"
    Option "XkbOptions" "terminate:ctrl_alt_bksp"
EndSection
EOF'

sudo usermod -a -G video overflyer
sudo usermod -a -G audio overflyer

sudo cp -v ${CLFSSOURCES}/.xinitrc /home/overflyer/

#I will not install Xorg legacy
#If you want to
#Go to http://www.linuxfromscratch.org/blfs/view/svn/x/x7legacy.html
