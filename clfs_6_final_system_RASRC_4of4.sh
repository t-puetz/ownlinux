#!/bin/bash

#Building the final CLFS System
PREFIX=/usr
LIBDIR32=${PREFIX}/lib
LIBDIR64=${PREFIX}/lib64
CLFS=/
CLFSSOURCES=/sources
CLFSTOOLS=/tools
MAKEFLAGS="-j$(nproc)"
BUILD32="-m32"
BUILD64="-m64"
CLFS_TARGET32="i686-pc-linux-gnu"

export BUILD32="-m32"
export BUILD64="-m64"

export CLFS_TARGET32="i686-pc-linux-gnu"

cat >> ${CLFS}/root/.bash_profile << EOF
export BUILD32="${BUILD32}"
export BUILD64="${BUILD64}"
export CLFS_TARGET32="${CLFS_TARGET32}"
EOF

function get_glibc_ver() {
   local glibc_ver=$(ls ${CLFSSOURCES} | grep 'glibc' | grep 'tar' | sed 's/glibc\|glibc-//' | sed 's/.tar.*//')
   echo "${glibc_ver}"
}

function get_gcc_ver() {
   local glibc_ver=$(ls ${CLFSSOURCES} | grep 'gcc' | grep 'tar' | sed 's/gcc\|gcc-//' | sed 's/.tar.*//')
   echo "${glibc_ver}"
}

function extract_pkg() {
  local filename_prefix=$1
  local dirname=$(echo ${filename_prefix} | sed 's/-//g')

  if [[ -d ${dirname} ]]; then
    rm -rf ${dirname}
  fi

  mkdir ${dirname} && tar xf ${filename_prefix}*.tar.* -C ${dirname} --strip-components 1
  cd ${dirname}
}

function get_pkg_ver() {
  local pkg_name=$1
  local pkg_ver=$(ls ${CLFSSOURCES} | grep ${pkg_name} | grep tar | sed "s/${pkg_name}\|${pkg_name}-//" | sed \
      's/.tar.*//' | head -n 1 | sed -E 's/\([[:punct:]][[:digit:]]?\)//g')

  echo "${pkg_ver}"

}

function conv_meta_to_real_pkg_name() {
  local meta_name=$1
  local real_name=$(echo ${meta_name} | sed 's/temp_\|_x86\|_x64\|_headers//')
  local real_name=$(echo ${real_name} | sed 's/temp_\|_x86\|_x64\|_headers//')
  local real_name=$(echo ${real_name} | sed 's/_1\|__1\|_2\|__2//')

  echo "${real_name}"
}

function checkBuiltPackage() {
echo 
echo "Is everything looking alright?: [Y/N]"
while read -n1 -r -p "[Y/N]   " && [[ $REPLY != q ]]; do
  case $REPLY in
    Y) break 1;;
    N) echo "$EXIT"
       echo "Fix it!"
       exit 1;;
    *) echo " Try again. Type y or n";;
  esac
done
echo 
}

declare -a finalsys_pkg_arr=()
finalsys_pkg_arr=(mount_efi_part libpng_x86 libpng_x64 which freetype_no_harfbuzz_x86 freetype_no_harfbuzz_x64
  harfbuzz_x86 harfbuzz_x64 freetype_x86 freetype_x64 popt_x86 popt_x64 dosfstools efivar efibootmgr 
  gnu-efi unifont goofiboot curl git openssh gptfdisk lynx)

function build_pkg() {
local count=0
for pkg in ${finalsys_pkg_arr[*]}
do
   local pkg_name=$(conv_meta_to_real_pkg_name ${finalsys_pkg_arr[${count}]})
    local pkg_ver=$(get_pkg_ver ${pkg_name})
    local glibc_ver=$(get_glibc_ver)
    local glibc_ver_major=$(echo ${glibc_ver} | cut -d'.' -f 1)
    local glibc_ver_minor=$(echo ${glibc_ver} | cut -d'.' -f 2)
    local gcc_ver=$(get_gcc_ver)
    glibc_ver_ge_2point28=$(test ${glibc_ver_major} -eq 2 && test ${glibc_ver_minor} -ge 28)
    glibc_ver_ge_2point26=$(test ${glibc_ver_major} -eq 2 && test ${glibc_ver_minor} -ge 26)
    local glibc_needs_isl_patch=$(test $(get_pkg_ver isl) == "0.20")

    echo "Let's build and install ${finalsys_pkg_arr[${count}]}"
    echo "Real package name is: ${pkg_name}"
    echo "Version ${pkg_ver}"
    echo "Glibc version: ${glibc_ver}"
    echo "isl version: $(get_pkg_ver isl)"
    checkBuiltPackage

    cd ${CLFSSOURCES}

    if [[ ${finalsys_pkg_arr[${count}]} == "mount_efi_part" ]]; then
      #Mount efi boot partition
echo ""
echo "Let's check if your efivars are mounted or not"
ls /sys/firmware/efi

checkBuiltPackage

espdevice=$(cat /clfs-system.config | grep "espdev" | sed 's/espdev=//g')

mkdir -pv /boot/efi
mount -vt vfat $espdevice /boot/efi

checkBuiltPackage

cd ${CLFSSOURCES}
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "libpng_x86" ]]; then
      extract_pkg ${pkg_name}-
      
      gzip -cd ../libpng-1.6.29-apng.patch.gz | patch -p0

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      USE_ARCH=32 \
      LIBS=-lpthread CC="gcc ${BUILD32}" ./configure \
      --prefix=${PREFIX} \
      --disable-static \
      --libdir=${LIBDIR32}

      PREFIX=/usr LIBDIR=/usr/lib make
      PREFIX=/usr LIBDIR=/usr/lib make install

      mv -v /usr/bin/libpng12-config{,-32} 
      ln -sfv libpng12-config-32 /usr/bin/libpng-config-32
      ln -sfv multiarch_wrapper /usr/bin/libpng12-config 
      ln -sfv multiarch_wrapper /usr/bin/libpng-config
        
    elif [[ ${finalsys_pkg_arr[${count}]} == "libpng_x64" ]]; then
      extract_pkg ${pkg_name}- 
      
      gzip -cd ../${pkg_name}-${pkg_ver}-apng.patch.gz | patch -p0

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 \
      LIBS=-lpthread CC="gcc ${BUILD64}" ./configure \
      --prefix=${PREFIX} \
      --disable-static \
      --libdir=${LIBDIR64}

      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make install

      mv -v /usr/bin/libpng12-config{,-64}
      ln -sfv libpng12-config-64 /usr/bin/libpng-config-64
      ln -sfv multiarch_wrapper /usr/bin/libpng-config
      ln -sfv multiarch_wrapper /usr/bin/libpng12-config
      mkdir -v /usr/share/doc/${pkg_name}-${pkg_ver} 
      cp -v README libpng-manual.txt /usr/share/doc/${pkg_name}-${pkg_ver}
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "which" ]]; then
      extract_pkg ${pkg_name}-
      
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX}  \
          --libdir=${LIBDIR64}

      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make install
      
    elif [[ ${finalsys_pkg_arr[${count}]} == "freetype_no_harfbuzz_x86" ]]; then
      extract_pkg ${pkg_name}-
      
      sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg

      sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
          -i include/freetype/config/ftoption.h 

      sed -i -r 's:.*(#.*BYTE.*) .*:\1:' include/freetype/config/ftoption.h

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      USE_ARCH=32 \
      CC="gcc ${BUILD32}" ./configure --prefix=${PREFIX} \
      --disable-static \
      --libdir=${LIBDIR32} \
      --without-harfbuzz

      PREFIX=${PREFIX} LIBDIR=${LIBDIR32} make
      PREFIX=${PREFIX} LIBDIR=${LIBDIR32} make install

      mv -v /usr/bin/freetype-config{,-32}
      
    elif [[ ${finalsys_pkg_arr[${count}]} == "freetype_no_harfbuzz_x64" ]]; then
      extract_pkg ${pkg_name}-
      
      sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg

      sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
          -i include/freetype/config/ftoption.h 

      sed -i -r 's:.*(#.*BYTE.*) .*:\1:' include/freetype/config/ftoption.h

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
      --disable-static \
      --libdir=${LIBDIR64} \
      --without-harfbuzz

      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make install
      
      mv -v /usr/bin/freetype-config{,-64}
      ln -sf multiarch_wrapper /usr/bin/freetype-config
      
      install -v -m755 -d /usr/share/doc/${pkg_name}-${pkg_ver}
      cp -v -R docs/* /usr/share/doc/${pkg_name}-${pkg_ver}

      install -v -m755 -d /usr/share/doc/${pkg_name}-${pkg_ver}
      cp -v -R docs/*     /usr/share/doc/${pkg_name}-${pkg_ver}
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "harfbuzz_x86" ]]; then
      extract_pkg ${pkg_name}-
      
      autoreconf -fiv
      ./autogen.sh

      LIBDIR=/usr/lib USE_ARCH=32 PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      CXX="g++ ${BUILD32}" CC="gcc ${BUILD32}" \
      ./configure --prefix=${PREFIX} --libdir=${LIBDIR32}
      PREFIX=${PREFIX} LIBDIR=${LIBDIR32} make 
      PREFIX=${PREFIX} LIBDIR=${LIBDIR32} make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "harfbuzz_x64" ]]; then
      extract_pkg ${pkg_name}-
      
      autoreconf -fiv
      ./autogen.sh

      LIBDIR=/usr/lib64 USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CXX="g++ ${BUILD64}" CC="gcc ${BUILD64}" \
      ./configure --prefix=${PREFIX} --libdir=${LIBDIR64}
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make 
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "freetype_x86" ]]; then
      extract_pkg ${pkg_name}-
      
      sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg

      sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
          -i include/freetype/config/ftoption.h 

      sed -i -r 's:.*(#.*BYTE.*) .*:\1:' include/freetype/config/ftoption.h

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      USE_ARCH=32 \
      CC="gcc ${BUILD32}" ./configure \
      --prefix=${PREFIX} \
      --disable-static \
      --libdir=${LIBDIR32}

      PREFIX=${PREFIX} LIBDIR=${LIBDIR32} make
      PREFIX=${PREFIX} LIBDIR=${LIBDIR32} make install
      mv -v /usr/bin/freetype-config{,-32}
      
    elif [[ ${finalsys_pkg_arr[${count}]} == "freetype_x64" ]]; then
      extract_pkg ${pkg_name}-
      
      sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg

      sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
          -i include/freetype/config/ftoption.h 

      sed -i -r 's:.*(#.*BYTE.*) .*:\1:' include/freetype/config/ftoption.h

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 \
      CC="gcc ${BUILD64}" ./configure \
      --prefix=${PREFIX} \
      --disable-static \
      --libdir=${LIBDIR64}

      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make install

      mv -v /usr/bin/freetype-config{,-64}
      ln -sf multiarch_wrapper /usr/bin/freetype-config
      
    elif [[ ${finalsys_pkg_arr[${count}]} == "popt_x86" ]]; then
      extract_pkg ${pkg_name}-
      
      USE_ARCH=32 CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" \
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      ./configure --prefix=${PREFIX} --libdir=${LIBDIR32} &&
      make

      sed -i "s@\(^libdir='\).*@\1/usr/lib'@g" libpopt.la &&
      sed -i "s@\(^libdir='\).*@\1/usr/lib'@g" .libs/libpopt.lai &&
      make usrlibdir=${LIBDIR32} install

      mv popt.pc ${LIBDIR32}/pkgconfig
      
      
    elif [[ ${finalsys_pkg_arr[${count}]} == "popt_x64" ]]; then
      extract_pkg ${pkg_name}-
      
      USE_ARCH=64 CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64} 
      PREFIX=${PREFIX} usrlibdir=${LIBDIR64} PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make

      sed -i "s@\(^libdir='\).*@\1/usr/lib64'@g" libpopt.la
      sed -i "s@\(^libdir='\).*@\1/usr/lib64'@g" .libs/libpopt.lai
      make usrlibdir=${LIBDIR64} PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} install

      mv popt.pc ${LIBDIR64}/pkgconfig
      
    elif [[ ${finalsys_pkg_arr[${count}]} == "dosfstools" ]]; then
      extract_pkg ${pkg_name}-
      
      CC="gcc ${BUILD64}" PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} \
      USE_ARCH=64 \
      ./configure --prefix=${PREFIX} --libdir=${LIBDIR64} \
          --sbindir=${PREFIX}/bin \
          --mandir=/usr/share/man \
          --docdir=/usr/share/doc

      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} SBINDIR=${PREFIX}/bin MANDIR=${PREFIX}/share/man \
      DOCDIR=${PREFIX}/share/doc make
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} SBINDIR=${PREFIX}/bin MANDIR=${PREFIX}/share/man \
      DOCDIR=${PREFIX}/share/doc make install

      PKG_CONFIG_PATH=""
      
    elif [[ ${finalsys_pkg_arr[${count}]} == "efivar" ]]; then
      extract_pkg ${pkg_name}-
      
      sed -i 's/?= cc/?= gcc/g' Make.defaults

      CC="gcc ${BUILD64}" PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} USE_ARCH=64 CC="gcc -m64" LIBDIR=${LIBDIR64} PREFIX=${PREFIX} make
      CC="gcc ${BUILD64}" PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} USE_ARCH=64 CC="gcc -m64" LIBDIR=${LIBDIR64} PREFIX=${PREFIX} make install

      cd src/test
      make tester
      install -v -D -m0755 tester ${PREFIX}/bin/efivar-tester
      
    elif [[ ${finalsys_pkg_arr[${count}]} == "efibootmgr" ]]; then
      extract_pkg ${pkg_name}-
      
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" EFIDIR=/boot/efi \
      make USE_ARCH=64 LIBDIR=${LIBDIR64} \
      bindir=${PREFIX}/bin mandir=${PREFIX}/share/man \
      CC="gcc ${BUILD64}" CXX="g++"${BUILD64} \
      includedir=${PREFIX}/include

      install -v -D -m0755 src/efibootmgr ${PREFIX}/sbin/efibootmgr
      install -v -D -m0644 src/efibootmgr.8 \
        ${PREFIX}/share/man/man8/efibootmgr.8
      install -v -D -m0644 src/efibootdump.8 \
        ${PREFIX}/share/man/man8/efibootdump.8
      
    elif [[ ${finalsys_pkg_arr[${count}]} == "gnu-efi" ]]; then
      extract_pkg ${pkg_name}-
      
      sed -i "s#-Werror##g" Make.defaults
      ARCH=x86_64 make PREFIX=${PREFIX} LIBDIR=${LIBDIR64}
      ARCH=x86_64 make PREFIX=${PREFIX} LIBDIR=${LIBDIR64} install

    
    elif [[ ${finalsys_pkg_arr[${count}]} == "unifont" ]]; then
      extract_pkg ${pkg_name}-
      
      mkdir -pv ${PREFIX}/share/fonts/unifont
      gunzip -c ${CLFSSOURCES}/unifont-*.pcf.gz > ${PREFIX}/share/fonts/unifont/unifont.pcf

      
    elif [[ ${finalsys_pkg_arr[${count}]} == "goofiboot" ]]; then
      extract_pkg ${pkg_name}-
      
      sh autogen.sh
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 CC="gcc ${BUILD64}" \
      CXX="g++ ${BUILD64}"  \
      ./configure --prefix=${PREFIX} \
          --libdir=${LIBDIR64} \
          --includedir=${PREFIX}/include \
          --sbindir=${PREFIX}/bin

      sed -i ':a;$!{N;ba};s/.*#include[^\n]*/&\n#include <sys\/sysmacros.h>/' \
         src/setup/setup.c

      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make
      PREFIX=${PREFIX} LIBDIR=/${LIBDIR64} make install

      mount -o remount,rw ${CLFS}/sys/firmware/efi/efivars/
      goofiboot --path=/boot/efi install 
      mount -o remount,ro ${CLFS}/sys/firmware/efi/efivars/

      
    elif [[ ${finalsys_pkg_arr[${count}]} == "curl" ]]; then
      extract_pkg ${pkg_name}-
      
      wget https://curl.haxx.se/download/curl-7.60.0.tar.xz --no-check-certificate -O \
      curl-7.60.0.tar.xz

      CC="gcc ${BUILD64}" USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"
      
        ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64} \
        --disable-static \
        --enable-threaded-resolver \
        --with-ca-path=/etc/ssl/certs \
        --with-ca-bundle=/etc/ssl/ca-bundle.crt

      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make install

      find docs \( -name Makefile\* \
                -o -name \*.1       \
                -o -name \*.3 \)    \
                -exec rm {} \;      
                
      install -v -d -m755 ${PREFIX}/share/doc/${pkg_name}-${pkg_ver}
      cp -v -R docs/*     ${PREFIX}/share/doc/${pkg_name}-${pkg_ver}
      
    elif [[ ${finalsys_pkg_arr[${count}]} == "git" ]]; then
      extract_pkg ${pkg_name}-
      
      autoconf

      USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
         --libexecdir=${LIBDIR64} \
         --sysconfdir=/etc  \
         --with-gitconfig=/etc/gitconfig

      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make install

      
    elif [[ ${finalsys_pkg_arr[${count}]} == "openssh" ]]; then
      extract_pkg ${pkg_name}-
    
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
      USE_ARCH=64 CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX}    \
                  --sysconfdir=/etc/ssh             \
                  --libdir=${LIBDIR64}               \
                  --with-md5-passwords              \
                  --with-privsep-path=/var/lib/sshd \
                  --with-pam

      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make install
      
      install -v -m755    contrib/ssh-copy-id /usr/bin
      
      install -v -m644    contrib/ssh-copy-id.1 \
                          ${PREFIX}/share/man/man1
      install -v -m755 -d ${PREFIX}/share/doc/${pkg_name}-${pkg_ver}
      install -v -m644    INSTALL LICENCE OVERVIEW README* \
                    ${PREFIX}/share/doc/${pkg_name}-${pkg_ver}

      echo "PermitRootLogin no" >> /etc/ssh/sshd_config

      sed 's@d/login@d/sshd@g' /etc/pam.d/login > /etc/pam.d/sshd 
      chmod 644 /etc/pam.d/sshd 
      echo "UsePAM yes" >> /etc/ssh/sshd_config

      # IN STALL OPENRC SSHD SERVICE #
      
      rc-update add sshd default
      rc-service sshd start
      
      ################################
      
    elif [[ ${finalsys_pkg_arr[${count}]} == "gptfdisk" ]]; then
      extract_pkg ${pkg_name}-

      wget https://downloads.sourceforge.net/gptfdisk/gptfdisk-1.0.4.tar.gz -O \
        gptfdisk-1.0.4.tar.gz

      wget http://www.linuxfromscratch.org/patches/blfs/svn/gptfdisk-1.0.4-convenience-1.patch -O \
        gptfdisk-1.0.4-convenience-1.patch 

      patch -Np1 -i ../gptfdisk-1.0.4-convenience-1.patch

      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64} POPT=1
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64} POPT=1 install
      cp -v {gdisk,cgdisk,sgdisk,fixparts} /sbin

    elif [[ ${finalsys_pkg_arr[${count}]} == "lynx" ]]; then
      extract_pkg ${pkg_name}-
    
      wget http://invisible-mirror.net/archives/lynx/tarballs/lynx2.8.9rel.1.tar.bz2 -O \
        lynx2.8.9rel.1.tar.bz2

      ./configure --prefix=${PREFIX}            \
                  --sysconfdir=/etc/lynx \
                  --libdir=${LIBDIR64}    \
                  --datadir=/usr/share/doc/lynx-2.8.9rel.1 \
                  --with-zlib            \
                  --with-bzlib           \
                  --with-ssl             \
                  --with-screen=ncursesw \
                  --enable-locale-charset 

      PREFIX=${PREFIX}  LIBDIR=${LIBDIR64} make
      PREFIX=${PREFIX}  LIBDIR=${LIBDIR64} make install-full
      chgrp -v -R root ${PREFIX}/share/doc/${pkg_name}-${pkg_ver}/lynx_doc
    
    fi    

    cd ${CLFSSOURCES}
    checkBuiltPackage
    rm -rf ${pkg_name}
    count=$(expr ${count} + 1)

done
}

#Install packages needed for UEFI-Boot if we had a
#System without any bootloader installed at all
#I choose goofiboot a fork of gummiboot

#===================================================
#All our kernel files later need to go to /boot/efi
#===================================================
#Useful manuals that show how to do UEFI-Boot
#and how to configure the Kernel
#http://www.linuxfromscratch.org/~krejzi/basic-kernel.txt 
#http://www.linuxfromscratch.org/hints/downloads/files/lfs-uefi-20170207.txt
#===================================================

build_pkg

efibootmgr

cd ${CLFS}