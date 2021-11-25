#!/bin/bash

#Building the final CLFS System

function checkBuiltPackage () {
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

CLFS=/
CLFSSOURCES=/sources
MAKEFLAGS="-j$(nproc)"
BUILD32="-m32"
BUILD64="-m64"
CLFS_TARGET32="i686-pc-linux-gnu"
PKG_CONFIG_PATH32=/usr/lib/pkgconfig
PKG_CONFIG_PATH64=/usr/lib64/pkgconfig

export CLFS=/
export CLFSSOURCES=/sources
export MAKEFLAGS="-j$(nproc)"
export BUILD32="-m32"
export BUILD64="-m64"
export CLFS_TARGET32="i686-pc-linux-gnu"
export PKG_CONFIG_PATH32=/usr/lib/pkgconfig
export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig
cd ${CLFSSOURCES}

#haveged
mkdir haveged && tar xf haveged-*.tar.* -C haveged --strip-components 1
cd haveged

./configure --prefix=/usr          \
            --libdir=/usr/lib64

make
make install

mkdir -pv    /usr/share/doc/haveged-1.9.2
cp -v README /usr/share/doc/haveged-1.9.2

rc-update add haveged default
rc-service haveged start

cd ${CLFSSOURCES}
#checkBuiltPackage
rm -rf haveged


#OpenSSL 64-bit
mkdir openssl && tar xf openssl-*.tar.* -C openssl --strip-components 1
cd openssl

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} USE_ARCH=64 CC="gcc ${BUILD64}" ./config --prefix=/usr \
         --openssldir=/etc/ssl      \
         --libdir=lib64             \
         shared                     \
         zlib-dynamic

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} USE_ARCH=64 CC="gcc ${BUILD64}" make 
#checkBuiltPackage
#make  test
#checkBuiltPackage

sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} USE_ARCH=64 CC="gcc ${BUILD64}" \
MANDIR=/usr/share/man MANSUFFIX=ssl PERL=/usr/bin/perl make install

cp -v -r certs /etc/ssl
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.0h
cp -vfr doc/* /usr/share/doc/openssl-1.1.0h

cd ${CLFSSOURCES}
#checkBuiltPackage
rm -rf openssl

#Wget
mkdir wget && tar xf wget-*.tar.* -C wget --strip-components 1
cd wget

PKG_CONFIG_PATH="/usr/lib64/pkgconfig" \
USE_ARCH=64 CC="gcc ${BUILD64}"
./configure --prefix=/usr   \
    --sysconfdir=/etc       \
    --without-ssl           \
    --without-openssl

PREFIX=/usr LIBDIR=/usr/lib64 make
PREFIX=/usr LIBDIR=/usr/lib64 make install

cd ${CLFSSOURCES}
#checkBuiltPackage
rm -rf wget

#Install CA Certificates
mkdir Make-CA && tar xf Make-CA-*.tar.* -C Make-CA --strip-components 1
cd $(ls | grep 'Make-CA-' | sed 's/-0.8.tar.*//g')

rm -rf root.crt
rm -rf class3.crt

install -vdm755 /etc/ssl/local
wget http://www.cacert.org/certs/root.crt
wget http://www.cacert.org/certs/class3.crt
openssl x509 -in root.crt -text -fingerprint -setalias "CAcert Class 1 root" \
        -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
        > /etc/ssl/local/CAcert_Class_1_root.pem
openssl x509 -in class3.crt -text -fingerprint -setalias "CAcert Class 3 root" \
        -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
        > /etc/ssl/local/CAcert_Class_3_root.pem

make install

/usr/sbin/make-ca -g -f

cd ${CLFSSOURCES}
#checkBuiltPackage
rm -rf $(ls | grep 'Make-CA-' | sed 's/-0.8.tar.*//g')


#Wget
mkdir wget && tar xf wget-*.tar.* -C wget --strip-components 1
cd wget

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" USE_ARCH=64 CC="gcc ${BUILD64}" \
USE_ARCH=64 CC="gcc ${BUILD64}" ./configure --prefix=/usr   \
    --sysconfdir=/etc       \
    --with-ssl=openssl

PREFIX=/usr LIBDIR=/usr/lib64 make
PREFIX=/usr LIBDIR=/usr/lib64 make install

cd ${CLFSSOURCES}
#checkBuiltPackage
rm -rf wget


#Curl
wget https://curl.haxx.se/download/curl-7.60.0.tar.xz --no-check-certificate -O \
  curl-7.60.0.tar.xz

mkdir curl && tar xf curl-*.tar.* -C curl --strip-components 1
cd curl

CC="gcc ${BUILD64}" USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"

  ./configure --prefix=/usr \
  --libdir=/usr/lib64 \
  --disable-static \
  --enable-threaded-resolver \
  --with-ca-path=/etc/ssl/certs \
  --with-ca-bundle=/etc/ssl/ca-bundle.crt

PREFIX=/usr LIBDIR=/usr/lib64 make
PREFIX=/usr LIBDIR=/usr/lib64 make install

find docs \( -name Makefile\* \
          -o -name \*.1       \
          -o -name \*.3 \)    \
          -exec rm {} \;      &&
install -v -d -m755 /usr/share/doc/curl-7.59.0 &&
cp -v -R docs/*     /usr/share/doc/curl-7.59.0

cd ${CLFSSOURCES}
#checkBuiltPackage
rm -rf curl

#Git
mkdir git && tar xf git-*.tar.* -C git --strip-components 1
cd git

autoconf

USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
CC="gcc ${BUILD64}" ./configure --prefix=/usr \
   --libexecdir=/usr/lib64 \
   --sysconfdir=/etc  \
   --with-gitconfig=/etc/gitconfig

PREFIX=/usr LIBDIR=/usr/lib64 make
PREFIX=/usr LIBDIR=/usr/lib64 make install

cd ${CLFSSOURCES}
#checkBuiltPackage
rm -rf git

#openSSH
mkdir openssh && tar xf openssh-7.7p1.tar.gz -C openssh --strip-components 1
cd openssh

install  -v -m700 -d /var/lib/sshd
chown    -v root:sys /var/lib/sshd

groupadd -g 50 sshd
useradd  -c 'sshd PrivSep' \
         -d /var/lib/sshd  \
         -g sshd           \
         -s /bin/false     \
         -u 50 sshd

patch -Np1 -i ../openssh-7.7p1-openssl-1.1.0-1.patch

#PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
CC="gcc ${BUILD64}" USE_ARCH=64 CXX="g++ ${BUILD64}" \
USE_ARCH=64 CC="gcc ${BUILD64}" ./configure --prefix=/usr    \
            --sysconfdir=/etc/ssh             \
            --libdir=/usr/lib64               \
            --with-md5-passwords              \
            --with-privsep-path=/var/lib/sshd \
            --with-pam

PREFIX=/usr LIBDIR=/usr/lib64 make
PREFIX=/usr LIBDIR=/usr/lib64 make install

install -v -m755    contrib/ssh-copy-id /usr/bin

install -v -m644    contrib/ssh-copy-id.1 \
                    /usr/share/man/man1
install -v -m755 -d /usr/share/doc/openssh-7.7p1
install -v -m644    INSTALL LICENCE OVERVIEW README* \
                    /usr/share/doc/openssh-7.7p1

echo "PermitRootLogin no" >> /etc/ssh/sshd_config

sed 's@d/login@d/sshd@g' /etc/pam.d/login > /etc/pam.d/sshd &&
chmod 644 /etc/pam.d/sshd &&
echo "UsePAM yes" >> /etc/ssh/sshd_config

cd ${CLFSSOURCES}
#checkBuiltPackage
rm -rf openssh

# IN STALL OPENRC SSHD SERVICE #

rc-update add sshd default
rc-service sshd start

################################

#gptfdisk
wget https://downloads.sourceforge.net/gptfdisk/gptfdisk-1.0.4.tar.gz -O \
  gptfdisk-1.0.4.tar.gz

wget http://www.linuxfromscratch.org/patches/blfs/svn/gptfdisk-1.0.4-convenience-1.patch -O \
  gptfdisk-1.0.4-convenience-1.patch 

mkdir gptfdisk && tar xf gptfdisk-*.tar.* -C gptfdisk --strip-components 1
cd gptfdisk

patch -Np1 -i ../gptfdisk-1.0.4-convenience-1.patch

make PREFIX=/usr LIBDIR=/usr/lib64 POPT=1
make PREFIX=/usr LIBDIR=/usr/lib64 POPT=1 install
cp -v {gdisk,cgdisk,sgdisk,fixparts} /sbin

cd ${CLFSSOURCES}
#checkBuiltPackage
rm -rf gptfdisk

#Lynx
wget http://invisible-mirror.net/archives/lynx/tarballs/lynx2.8.9rel.1.tar.bz2 -O \
  lynx2.8.9rel.1.tar.bz2

mkdir lynx && tar xf lynx*.tar.* -C lynx --strip-components 1
cd lynx


./configure --prefix=/usr          \
            --sysconfdir=/etc/lynx \
            --libdir=/usr/lib64    \
            --datadir=/usr/share/doc/lynx-2.8.9rel.1 \
            --with-zlib            \
            --with-bzlib           \
            --with-ssl             \
            --with-screen=ncursesw \
            --enable-locale-charset &&

PREFIX=/usr LIBDIR=/usr/lib64 make
PREFIX=/usr LIBDIR=/usr/lib64 make install-full
chgrp -v -R root /usr/share/doc/lynx-2.8.9rel.1/lynx_doc

cd ${CLFSSOURCES}
#checkBuiltPackage
rm -rf lynx
