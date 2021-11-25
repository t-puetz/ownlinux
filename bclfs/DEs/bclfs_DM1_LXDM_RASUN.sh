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
XORG_PREFIX=/usr

export CLFS=/
export CLFSSOURCES=/sources
export MAKEFLAGS="-j$(nproc)"
export BUILD32="-m32"
export BUILD64="-m64"
export CLFS_TARGET32="i686-pc-linux-gnu"
export PKG_CONFIG_PATH=/usr/lib64/pkgconfig
export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig
export XORG_PREFIX=/usr

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

#lxdm
wget http://downloads.sourceforge.net/lxdm/lxdm-0.5.3.tar.xz -O \
  lxdm-0.5.3.tar.xz
  
mkdir lxdm && tar xf lxdm-*.tar.* -C lxdm --strip-components 1
cd lxdm

cat > pam/lxdm << "EOF"
# Begin /etc/pam.d/lxdm

auth     requisite      pam_nologin.so
auth     required       pam_env.so
auth     include        system-auth

account  include        system-account

password include        system-password

session  required       pam_limits.so
session  include        system-session

# End /etc/pam.d/lxdm
EOF

sed -i 's:sysconfig/i18n:profile.d/i18n.sh:g' data/lxdm.in &&
sed -i 's:/etc/xprofile:/etc/profile:g' data/Xsession &&
sed -e 's/^bg/#&/'        \
    -e '/reset=1/ s/# //' \
    -e 's/logou$/logout/' \
    -e "/arg=/a arg=$XORG_PREFIX/bin/X" \
    -i data/lxdm.conf.in

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
    --with-pam \
    --with-systemdsystemunitdir=no

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
rm -rf lxdm

#add openrc-displaymanager service scripts
xdmrc_url=https://raw.githubusercontent.com/gentoo/gentoo/master
xdm_rc_xdmconf=${xdmrc_url}/x11-base/xorg-server/files/xdm.confd-4
xdm_rc_xdminit=${xdmrc_url}/x11-base/xorg-server/files/xdm-setup.initd-1
xdm_rc_xdmsetup_init=${xdmrc_url}/x11-base/xorg-server/files/xdm.initd-11
xdm_rc_startdm=${xdmrc_url}//x11-apps/xinit/files/startDM.sh

sudo wget ${xdm_rc_xdmconf} -P /etc/conf.d/ 
sudo wget ${xdm_rc_xdminit} -P /etc/init.d/
sudo wget ${xdm_rc_xdmsetup_init} -P /etc/init.d/
sudo wget ${xdm_rc_startdm} -P /etc/X11/ 
sudo chmod +x /etc/X11/startDM.sh

sudo mv /etc/conf.d/xdm.confd-4 /etc/conf.d/xdm
sudo mv /etc/init.d/xdm.initd-11 /etc/init.d/xdm
sudo mv /etc/init.d/xdm-setup.initd-1 /etc/init.d/xdm

sudo chmod 755 /etc/init.d/xdm
sudo sed -i 's/DISPLAYMANAGER="xdm"/DISPLAYMANAGER="lxdm"/g' /etc/conf.d/xdm
sudo sed -i 's/\/sbin\/openrc-run/\/usr\/bin\/openrc-run/g' /etc/init.d/xdm*
