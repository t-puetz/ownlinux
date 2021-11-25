#!/bin/bash

#Building the final CLFS System
PREFIX=${PREFIX}
LIBDIR32=${PREFIX}/lib
LIBDIR64=${PREFIX}/lib64
CLFS=/
CLFSSOURCES=/sources
CLFSTOOLS=/tools
MAKEFLAGS="-j$(expr $(nproc) - 1)"
BUILD32="-m32"
BUILD64="-m64"
CLFS_TARGET32="i686-pc-linux-gnu"
PKG_CONFIG_PATH32=/usr/lib/pkgconfig
PKG_CONFIG_PATH32=/usr/lib64/pkgconfig

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
  
  if [[ ${dirname} == "ca_certs" ]]; then
    ${dirname} == $(ls "${CLFSSOURCES}" | grep 'Make-CA-' | sed 's/-0.8.tar.*//g')
  fi
  
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
  local real_name=$(echo ${meta_name} | sed 's/_ssl\|temp_\|_x86\|_x64\|_headers//')
  local real_name=$(echo ${real_name} | sed 's/_no\|temp_\|_x86\|_x64\|_headers//')
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

finalsys_pkg_arr=(libtool_x86 libtool_x64 gdbm_x86 gdbm_x64 gperf_x86 gperf_x64 expat_x86 expat_x64 inetutils perl_x86 
  perl_x64 xml_parser_x86 xml_parser_x64 intltool_x64 autoconf automake xz_x86 xz_x64 kmod_x86 kmod_x64 gettext_x86 
  gettext_x64 libelf_x86 libelf_x64 lbffi_x86 libffi_x64 openssl wget_no_ssl ca_certs wget python3 ninja meson procps-ng_x86 
  procps-ng_x64 e2fsprogs_x86 e2fsprogs_x64 coreutils check diffutils gawk findutils groff less gzip iproute2 iputils kbd 
  libpipeline_x86 libpipeline_x64 make patch sysklogd eudev_x86 eudev_x64 util-linux man-db tar texinfo vim nano cpio strip 
  diffutils set_username cracklib Linux-PAM shadow sudo add_user_sudoers autoload_pkg_conf_vars) 

echo ${finalsys_pkg_arr[*]}

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

    echo "Let's build and install ${finalsys_pkg_arr[${count}]}"
    echo "Real package name is: ${pkg_name}"
    echo "Version ${pkg_ver}"
    echo "Glibc version: ${glibc_ver}"

    checkBuiltPackage

    cd ${CLFSSOURCES}

    if [[ ${finalsys_pkg_arr[${count}]} == "libtool_x86" ]]; then
      extract_pkg ${pkg_name}-
    
      echo "lt_cv_sys_dlsearch_path='/lib /usr/lib /usr/local/lib /opt/lib'" > config.cache

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      CC="gcc ${BUILD32}" ./configure --prefix=${PREFIX} \
        --cache-file=config.cache
      
      checkBuiltPackage
      make LDEMULATION=elf_i386 check
      checkBuiltPackage
      make install
      checkBuiltPackage
      mv -v /usr/bin/libtool{,-32}
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "libtool_x64" ]]; then
      extract_pkg ${pkg_name}-   
    
      echo "lt_cv_sys_dlsearch_path='/lib64 /usr/lib64 /usr/local/lib64 /opt/lib64'" > config.cache

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64} \
        --cache-file=config.cache
    
      checkBuiltPackage
      make
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install

      mv -v /usr/bin/libtool{,-64}
      ln -sv multiarch_wrapper /usr/bin/libtool
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "gdbm_x86" ]]; then
      extract_pkg ${pkg_name}- 
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      CC="gcc ${BUILD32}" ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR32} \
        --disable-static \
        --enable-libgdbm-compat
      
      checkBuiltPackage
      make
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install
    
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "gdbm_x64" ]]; then
      extract_pkg ${pkg_name}- 
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
        --disable-static \
        --enable-libgdbm-compat \
        --libdir=${LIBDIR64}
        
        checkBuiltPackage
        make
        checkBuiltPackage
        make check
        checkBuiltPackage
        make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "gperf_x86" ]]; then
      extract_pkg ${pkg_name}- 
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      USE_ARCH=32 GCC="gcc ${BUILD32}"\
      CXX="g++ ${BUILD32}" ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR32}

      PREFIX=${PREFIX} LIBDIR=${LIBDIR32} make
      make -j1 check
      PREFIX=${PREFIX} LIBDIR=${LIBDIR32} make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "gperf_x64" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 GCC="gcc ${BUILD64}"\
      CXX="g++ ${BUILD64}" ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64}
      
      checkBuiltPackage
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make
      checkBuiltPackage
      make -j1 check
      checkBuiltPackage
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make install

      install -m644 -v doc/gperf.{dvi,ps,pdf} /usr/share/doc/${pkg_name}-${pkg_ver}
      pushd /usr/share/info 
      rm -v dir
      checkBuiltPackage

      for FILENAME in *; do
        install-info $FILENAME dir 2>/dev/null
      done 
      popd
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "expat_x86" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i 's|usr/bin/env |bin/|' run.sh.in

      USE_ARCH=32 PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}"
      CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR32} \
        --disable-static \
        --enable-shared
        
        checkBuiltPackage
        make LIBDIR=${LIBDIR64} PREFIX=${PREFIX}
        checkBuiltPackage
        make check
        checkBuiltPackage
        make LIBDIR=${LIBDIR64} PREFIX=${PREFIX} install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "expat_x64" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i 's|usr/bin/env |bin/|' run.sh.in

      USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"
      CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64} \
        --disable-static \
        --enable-shared \
        --docdir=/usr/share/doc/${pkg_name}-${pkg_ver}

      checkBuiltPackage
      make LIBDIR=${LIBDIR64} PREFIX=${PREFIX}
      checkBuiltPackage
      make check
      checkBuiltPackage
      make LIBDIR=${LIBDIR64} PREFIX=${PREFIX} install
      checkBuiltPackage
      
      install -v -m755 -d /usr/share/doc/${pkg_name}-${pkg_ver}
      install -v -m644 doc/*.{html,png,css} /usr/share/doc/${pkg_name}-${pkg_ver}
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "inetutils" ]]; then
      extract_pkg ${pkg_name}-
    
    
      USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"
      CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" ./configure --prefix=${PREFIX} \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "perl_x86" ]]; then
      extract_pkg ${pkg_name}-
    
      export BUILD_ZLIB=False
      export BUILD_BZIP2=0

      echo "127.0.0.1 localhost $(hostname)" > /etc/hosts

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      ./configure.gnu --prefix=${PREFIX} \
        -Dvendorprefix=/usr \
        -Dman1dir=/usr/share/man/man1 \
        -Dman3dir=/usr/share/man/man3 \
	    -Dlibpth="/lib /usr/lib" \
        -Dpager="/bin/less -isR" \
        -Dcc="gcc ${BUILD32}" \
        -Dusethreads \
        -Duseshrplib

      checkBuiltPackage
      make
      checkBuiltPackage
      make -k test
      checkBuiltPackage
      make install
      unset BUILD_ZLIB BUILD_BZIP2

     mv -v /usr/bin/perl{,-32}
     mv -v /usr/bin/perl${pkg_ver}{,-32}
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "perl_x64" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i -e '/^BUILD_ZLIB/s/True/False/' \
        -e '/^INCLUDE/s,\./zlib-src,/usr/include,' \
        -e '/^LIB/s,\./zlib-src,/usr/lib64,' \
       cpan/Compress-Raw-Zlib/config.in

      export BUILD_ZLIB=False
      export BUILD_BZIP2=0

      patch -Np1 -i ../perl-5.26.0-Configure_multilib-1.patch

      echo 'installstyle="lib64/perl5"' >> hints/linux.sh

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      ./configure.gnu --prefix=${PREFIX} \
        -Dvendorprefix=/usr \
        -Dman1dir=/usr/share/man/man1 \
        -Dman3dir=/usr/share/man/man3 \
        -Dpager="/bin/less -isR" \
        -Dlibpth="/lib64 /usr/lib64" \
        -Dcc="gcc ${BUILD64}" \
        -Dusethreads \
	    -Duseshrplib
      
      checkBuiltPackage
      make
      checkBuiltPackage
      make -k test
      checkBuiltPackage
      make install
      unset BUILD_ZLIB BUILD_BZIP2

      mv -v /usr/bin/perl{,-64}
      mv -v /usr/bin/perl${pkg_ver}{,-64}

      ln -sv multiarch_wrapper /usr/bin/perl
      ln -sv multiarch_wrapper /usr/bin/perl${pkg_ver}
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "xml_parser_x86" ]]; then
      extract_pkg ${pkg_name}-
    
      USE_ARCH=32 PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" perl Makefile.PL
      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR32}
      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR32} test
      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR32} install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "xml_parser_x64" ]]; then
      extract_pkg ${pkg_name}-
    
      USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" perl Makefile.PL
      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64}
      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64} test
      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64} install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "intltool_x64" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i 's:\\\${:\\\$\\{:' intltool-update.in

      #patch -Np1 -i ../intltool-0.51.0-perl-5.22-compatibility.patch
      checkBuiltPackage

      USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64}  
        
      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64}
      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64} check
      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64} install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "autoconf" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX}

      checkBuiltPackage
      make
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "automake" ]]; then
      extract_pkg ${pkg_name}-
    
      #patch -Np1 -i ../automake-1.15-perl_5_26-1.patch

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
        --docdir=/usr/share/doc/${pkg_name}-${pkg_ver}

      checkBuiltPackage
      make 
      checkBuiltPackage
      make -j4 check
      checkBuiltPackage
      make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "xz_x86" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      CC="gcc ${BUILD32}" ./configure --prefix=${PREFIX} 

      checkBuiltPackage
      make
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install

      mv -v /usr/lib/liblzma.so.* /lib
      ln -sfv ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "xz_x64" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64} \
        --docdir=/usr/share/doc/${pkg_name}-${pkg_ver}

      checkBuiltPackage
      make
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install

      mv -v /usr/bin/{xz,lzma,lzcat,unlzma,unxz,xzcat} /bin

      mv -v /usr/lib64/liblzma.so.* /lib64
      ln -sfv ../../lib64/$(readlink /usr/lib64/liblzma.so) /usr/lib64/liblzma.so
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "kmod_x86" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      USE_ARCH=32 CC="gcc ${BUILD32}" ./configure --prefix=${PREFIX} \
        --bindir=/bin \
        --sysconfdir=/etc \
        --with-rootlibdir=/lib \
        --libdir=${LIBDIR32} \
        --with-zlib \
        --with-xz
      
      checkBuiltPackage
      make
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "kmod_x64" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
        --bindir=/bin \
        --sysconfdir=/etc \
        --with-rootlibdir=/lib64 \
        --libdir=${LIBDIR64} \
        --with-zlib \
        --with-xz

      checkBuiltPackage
      make
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install

      for target in depmod insmod lsmod modinfo modprobe rmmod; do
        ln -sfv ../bin/kmod /sbin/$target
      done

      ln -sfv kmod /bin/lsmod
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "gettext_x86" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i '/^TESTS =/d' gettext-runtime/tests/Makefile.in &&
      sed -i 's/test-lock..EXEEXT.//' gettext-tools/gnulib-tests/Makefile.in

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" \
      ./configure --prefix=${PREFIX} \
	    --libdir=${LIBDIR32} \
	    --disable-static
        
      checkBuiltPackage
      make
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install
        
    elif [[ ${finalsys_pkg_arr[${count}]} == "gettext_x64" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i '/^TESTS =/d' gettext-runtime/tests/Makefile.in &&
      sed -i 's/test-lock..EXEEXT.//' gettext-tools/gnulib-tests/Makefile.in

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
      ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64} \
	    --disable-static \
        --docdir=/usr/share/doc/${pkg_name}-${pkg_ver}

      checkBuiltPackage
      make
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install

      chmod -v 0755 /usr/lib/preloadable_libintl.so
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "libelf_x86" ]]; then
      extract_pkg ${pkg_name}-
    
      USE_ARCH=32 PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      CC="gcc ${BUILD32}" ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR32} \
        --disable-static

      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR32}
      checkBuiltPackage
      make -C libelf install PREFIX=${PREFIX} LIBDIR=${LIBDIR32}
      checkBuiltPackage
      install -vm644 config/libelf.pc /usr/lib/pkgconfig
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "libelf_x64" ]]; then
      extract_pkg ${pkg_name}-
    
      USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64} \
        --disable-static

     checkBuiltPackage
     make PREFIX=${PREFIX} LIBDIR=${LIBDIR64}
     checkBuiltPackage
     make -C libelf install PREFIX=${PREFIX} LIBDIR=${LIBDIR64}
     checkBuiltPackage
     install -vm644 config/libelf.pc /usr/lib64/pkgconfig
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "libffi_x86" ]]; then
      extract_pkg ${pkg_name}-
        
      sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' \
        -i include/Makefile.in

      sed -e '/^includedir/ s/=.*$/=@includedir@/' \
        -e 's/^Cflags: -I${includedir}/Cflags:/' \
        -i libffi.pc.in

      USE_ARCH=32 PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      CC="gcc ${BUILD32}" ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR32} \
        --disable-static \
	    --with-gcc-arch=native

      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR32}
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install
   
    elif [[ ${finalsys_pkg_arr[${count}]} == "libffi_x64" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' \
        -i include/Makefile.in

      sed -e '/^includedir/ s/=.*$/=@includedir@/' \
         -e 's/^Cflags: -I${includedir}/Cflags:/' \
         -i libffi.pc.in

      USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64} \
        --disable-static \
	    --with-gcc-arch=native

      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64}
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "openssl" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} USE_ARCH=64 CC="gcc ${BUILD64}" \
	    ./config --prefix=${PREFIX}         \
          --openssldir=/etc/ssl      \
          --libdir=lib64             \
          shared                     \
          zlib-dynamic
          
      checkBuiltPackage
      PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} USE_ARCH=64 CC="gcc ${BUILD64}" make
      checkBuiltPackage
      make test
      checkBuiltPackage

      sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
   
      PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} USE_ARCH=64 CC="gcc ${BUILD64}" \
      MANDIR=/usr/share/man MANSUFFIX=ssl PERL=/usr/bin/perl make install

      cp -v -r certs /etc/ssl
      mv -v /usr/share/doc/openssl /usr/share/doc/${pkg_name}-${pkg_ver}h
      cp -vfr doc/* /usr/share/doc/${pkg_name}-${pkg_ver}h
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "wget_no_ssl" ]]; then
      extract_pkg ${pkg_name}-
       
     PKG_CONFIG_PATH="/usr/lib64/pkgconfig" \
     USE_ARCH=64 CC="gcc ${BUILD64}"
       ./configure --prefix=${PREFIX}   \
         --sysconfdir=/etc       \
         --without-ssl           \
         --without-openssl

      checkBuiltPackage
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make
      checkBuiltPackage
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make install
      checkBuiltPackage
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "ca_certs" ]]; then
      extract_pkg ${pkg_name}-    
      
      if [[ -f root.crt ]]; then
        rm -f root.crt
      fi
      
      if [[ -f class3.crt ]]; then
        rm -f class3.crt
      fi
      
      install -vdm755 /etc/ssl/local
      wget http://www.cacert.org/certs/root.crt
      wget http://www.cacert.org/certs/class3.crt
      openssl x509 -in root.crt -text -fingerprint -setalias "CAcert Class 1 root" \
        -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
        > /etc/ssl/local/CAcert_Class_1_root.pem
      openssl x509 -in class3.crt -text -fingerprint -setalias "CAcert Class 3 root" \
        -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
        > /etc/ssl/local/CAcert_Class_3_root.pem
        
      checkBuiltPackage
      make install

      /usr/sbin/make-ca -g -f
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "wget" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" USE_ARCH=64 CC="gcc ${BUILD64}" \
      USE_ARCH=64 CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX}   \
        --sysconfdir=/etc       \
        --with-ssl=openssl
      
      checkBuiltPackage
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make
      checkBuiltPackage
      PREFIX=${PREFIX} LIBDIR=${LIBDIR64} make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "python3" ]]; then
      extract_pkg ${pkg_name}-
    
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
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=${PREFIX} \
        --enable-shared     \
        --libdir=${LIBDIR64} \
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
      PLATLIBDIR=${LIBDIR64} make

      checkBuiltPackage

      PYTHONPATH=/usr/lib64/python3.7/ \
      PLATLIBDIR=${LIBDIR64} make altinstall

      cp -rv /usr/lib/python3.7/ /usr/lib64/
      rm -rf /usr/lib/python3.7/

      chmod -v 755 /usr/lib64/libpython3.7m.so
      chmod -v 755 /usr/lib64/libpython3.so

      ln -svf /usr/lib64/libpython3.7m.so /usr/lib64/libpython3.7.so
      ln -svf /usr/lib64/libpython3.7m.so.1.0 /usr/lib64/libpython3.7.so.1.0
      ln -sfv /usr/bin/python3.7 /usr/bin/python3

      ldconfig
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "ninja" ]]; then
      extract_pkg ${pkg_name}-
    
      export NINJAJOBS=4
      patch -Np1 -i ../ninja-1.8.2-add_NINJAJOBS_var-1.patch

      checkBuiltPackage

      CXX="g++ ${BUILD64}" USE_ARCH=64 CC="gcc ${BUILD64}" PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  \
      python3 configure.py --bootstrap
      checkBuiltPackage

      CXX="g++ ${BUILD64}" USE_ARCH=64 CC="gcc ${BUILD64}" PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      python3 configure.py
      checkBuiltPackage
      ./ninja ninja_test
      ./ninja_test --gtest_filter=-SubprocessTest.SetWithLots
      
      checkBuiltPackage
      
      install -vm755 ninja /usr/bin/
      install -vDm644 misc/ninja.vim /usr/share/vim/vim80/syntax/ninja.vim
      install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
      install -vDm644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "meson" ]]; then
      extract_pkg ${pkg_name}-
    
      CXX="g++ ${BUILD64}" USE_ARCH=64 CC="gcc ${BUILD64}" PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      python3 setup.py build
      checkBuiltPackage
      
      python3 setup.py install --verbose --prefix=${PREFIX} --install-lib=/usr/lib64/python3.7/site-packages --optimize=1
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "procps-ng_x86" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      CC="gcc ${BUILD32}" ./configure --prefix=${PREFIX} \
        --exec-prefix= \
        --libdir=${LIBDIR32} \
        --disable-static \
        --disable-kill
        
      checkBuiltPackage
      make
      checkBuiltPackage
      sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
      sed -i '/set tty/d' testsuite/pkill.test/pkill.exp
      rm testsuite/pgrep.test/pgrep.exp
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install

      mv -v /usr/lib/libprocps.so.* /lib
      ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "procps-ng_x64" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure \
        --prefix=${PREFIX} \
        --exec-prefix= \
        --libdir=${LIBDIR64} \
        --docdir=/usr/share/doc/${pkg_name}-${pkg_ver}ng-3.3.15 \
        --disable-kill \
        --disable-static

      checkBuiltPackage
      make
      checkBuiltPackage
      sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
      sed -i '/set tty/d' testsuite/pkill.test/pkill.exp
      rm testsuite/pgrep.test/pgrep.exp
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install

      mv -v /usr/lib64/libprocps.so.* /lib64
      ln -sfv ../../lib64/$(readlink /usr/lib64/libprocps.so) /usr/lib64/libprocps.so.so
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "e2fsprogs_x86" ]]; then
      extract_pkg ${pkg_name}-
    
      mkdir -v build
      cd build

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      CC="gcc ${BUILD32}" \
        ../configure --prefix=${PREFIX} \
          --bindir=/bin \
          --with-root-prefix="" \
          --enable-elf-shlibs \
          --disable-libblkid \
          --disable-libuuid \
          --disable-fsck \
          --disable-uuidd

      checkBuiltPackage
      make
      checkBuiltPackage
      ln -sfv /tools/lib/lib{blk,uu}id.so.1 lib
      make LD_LIBRARY_PATH=/tools/lib check
      checkBuiltPackage
      make libs
      make install-libs
      checkBuiltPackage
      chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "e2fsprogs_x64" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i '/libdir.*=.*\/lib/s@/lib@/lib64@g' configure

      mkdir -v build
      cd build

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" \
      ../configure --prefix=${PREFIX} \
        --bindir=/bin \
        --with-root-prefix="" \
        --enable-elf-shlibs \
        --disable-libblkid \
        --disable-libuuid \
        --disable-fsck \
        --disable-uuidd

      checkBuiltPackage
      make
      checkBuiltPackage
      ln -sfv /tools/lib64/lib{blk,uu}id.so.1 lib64
      make LD_LIBRARY_PATH=/tools/lib64 check
      checkBuiltPackage
      make install
      make install-libs
      chmod -v u+w /usr/lib64/{libcom_err,libe2p,libext2fs,libss}.a
      checkBuiltPackage

      makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
      install -v -m644 doc/com_err.info /usr/share/info
      install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

    
    elif [[ ${finalsys_pkg_arr[${count}]} == "coreutils" ]]; then
      extract_pkg ${pkg_name}-
    
      patch -Np1 -i ../coreutils-8.30-i18n-1.patch
      sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk

      autoreconf -fiv
      FORCE_UNSAFE_CONFIGURE=1 \
      CC="gcc ${BUILD64}" \
      ./configure --prefix=${PREFIX} \
        --enable-no-install-program=kill,uptime \
        --enable-install-program=hostname
      
      checkBuiltPackage
      FORCE_UNSAFE_CONFIGURE=1 make
      checkBuiltPackage
      
      make NON_ROOT_USERNAME=nobody check-root
      echo "dummy:x:1000:nobody" >> /etc/group
      chown -Rv nobody .

      su nobody -s /bin/bash -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"
      checkBuiltPackage
      sed -i '/dummy/d' /etc/group

      checkBuiltPackage
      make install

      mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
      mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
      mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
      mv -v /usr/bin/chroot /usr/sbin
      mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
      sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
      cp -v /usr/bin/{head,sleep,nice} /bin
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "check" ]]; then
      extract_pkg ${pkg_name}-
    
      ./configure --prefix=${PREFIX} \
         --build=${CLFS_HOST} \
         --host=${CLFS_TARGET} \
         --libdir=${LIBDIR64}
         
       checkBuiltPackage
       make
       checkBuiltPackage
       make check
       checkBuiltPackage
       make install

       sed -i '1 s/tools/usr/' /usr/bin/checkmk
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "diffutils" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i 's:= @mkdir_p@:= /bin/mkdir -p:' po/Makefile.in.in

      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
        gl_cv_func_getopt_gnu=yes
      checkBuiltPackage
      
      #Concerning the last line above
      #Needed for version 3.6 with glibc 2.26
      #Probably can be ommited again for later diffutil versions
      #https://patchwork.ozlabs.org/patch/809145/

      sed -i 's@\(^#define DEFAULT_EDITOR_PROGRAM \).*@\1"vi"@' lib/config.h

      checkBuiltPackage
      make
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "gawk" ]]; then
      extract_pkg ${pkg_name}-    
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
        --libexecdir=/usr/lib64 \
        --libdir=${LIBDIR64}

      checkBuiltPackage
      make
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install

      mkdir -v /usr/share/doc/${pkg_name}-${pkg_ver}
      cp -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/${pkg_name}-${pkg_ver}
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "findutils" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in

      sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
      sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
      echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
        --libexecdir=/usr/lib64/ \
        --libdir=${LIBDIR64} \
        --localstatedir=/var/lib64/locate

      checkBuiltPackage
      make
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install

      mv -v /usr/bin/find /bin
      sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "groff" ]]; then
      extract_pkg ${pkg_name}-
    
      USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      PAGE=A4 CC="gcc ${BUILD64}" \
      CXX="g++ ${BUILD64}" ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64}
        
      checkBuiltPackage
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make -j1 PREFIX=${PREFIX} LIBDIR=${LIBDIR64}
      checkBuiltPackage
      make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "less" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
        --sysconfdir=/etc

      make
      make install
      mv -v /usr/bin/less /bin
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "gzip" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
      echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
        --bindir=/bin

      make
      make PERL=perl-64 check
      checkBuiltPackage
      make install

      mv -v /bin/{gzexe,uncompress,gzip} /usr/bin
      mv -v /bin/z{egrep,cmp,diff,fgrep,force,grep,less,more,new} /usr/bin
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "iproute2" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i '/ARPD/d' Makefile
      sed -i 's/arpd.8//' man/man8/Makefile
      sed -i '/tc-simple/s@tc-skbmod.8 @@' man/man8/Makefile
      rm -v doc/arpd.sgml
      sed -i 's/m_ipt.o//' tc/Makefile
 
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"

      make CC="gcc ${BUILD64}" PREFIX=${PREFIX} LIBDIR=${LIBDIR64}
      make LIBDIR=${LIBDIR64} PREFIX=${PREFIX} install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "iputils" ]]; then
      extract_pkg ${pkg_name}-
    
      patch -Np1 -i ../iputils-s20150815-build-1.patch

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      make CC="gcc ${BUILD64}" USE_CAP=no \
      TARGETS="clockdiff ping rdisc tracepath tracepath6 traceroute6"

      install -v -m755 ping /bin
      install -v -m755 clockdiff /usr/bin
      install -v -m755 rdisc /usr/bin
      install -v -m755 tracepath /usr/bin
      install -v -m755 trace{path,route}6 /usr/bin
      install -v -m644 doc/*.8 /usr/share/man/man8
      
      ln -sv ping /bin/ping4
      ln -sv ping /bin/ping6
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "kbd" ]]; then
      extract_pkg ${pkg_name}-
    
      patch -Np1 -i ../kbd-2.0.4-backspace-1.patch

      sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
      sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" PKG_CONFIG_PATH="/tools/lib64/pkgconfig" \
      ./configure --prefix=${PREFIX} \
        --disable-vlock \
        --enable-optional-progs

      make
      make check
      checkBuiltPackage
      make install

      mv -v /usr/bin/{dumpkeys,kbd_mode,loadkeys,setfont} /bin

      mkdir -v /usr/share/doc/${pkg_name}-${pkg_ver}
      cp -R -v docs/doc/* /usr/share/doc/${pkg_name}-${pkg_ver}
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "libpipeline_x86" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      USE_ARCH=32 CC="gcc ${BUILD32}" \
      ./configure --prefix=${PREFIX} \
	    --libdir=${LIBDIR32}
        
      checkBuiltPackage
      make
      checkBuiltPackage
      make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "libpipeline_x64" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 CC="gcc ${BUILD64}" \
      ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64}
        
      checkBuiltPackage
      make
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "make" ]]; then
      extract_pkg ${pkg_name}-
	
      sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
      #patch -Np1 -i ../glibc227_make_compat_alloc.patch
      autoreconf -f -i

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX}
      
      checkBuiltPackage
      make
      checkBuiltPackage
      make PERL5LIB=$PWD/tests/ check
      checkBuiltPackage
      make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "patch" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 CC="gcc ${BUILD64}" ./configure \
        --prefix=${PREFIX} --libdir=${LIBDIR64}

      make
      make check
      checkBuiltPackage
      make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "sysklogd" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
      sed -i 's/union wait/int/' syslogd.c

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 CC="gcc ${BUILD64}" make
      checkBuiltPackage
      make BINDIR=/sbin install
      checkBuiltPackage
      
      touch  /etc/syslog.conf
      echo "# Begin /etc/syslog.conf" > /etc/syslog.conf
      echo "auth,authpriv.* -/var/log/auth.log" >> /etc/syslog.conf
      echo "*.*;auth,authpriv.none -/var/log/sys.log" >> /etc/syslog.conf
      echo "daemon.* -/var/log/daemon.log" >> /etc/syslog.conf
      echo "kern.* -/var/log/kern.log" >> /etc/syslog.conf
      echo "mail.* -/var/log/mail.log" >> /etc/syslog.conf
      echo "user.* -/var/log/user.log" >> /etc/syslog.conf
      echo "*.emerg *" >> /etc/syslog.conf
      echo "# End /etc/syslog.conf" >> /etc/syslog.conf
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "eudev_x86" ]]; then
      extract_pkg ${pkg_name}-
    
      touch config.cache 
      echo "HAVE_BLKID=1" > config.cache
      echo "BLKID_LIBS=\"-lblkid\"" >> config.cache
      echo "BLKID_CFLAGS=\"-I/tools/include\"" >> config.cache

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
      USE_ARCH=32 CC="gcc ${BUILD32}" ./configure --prefix=${PREFIX} \
        --sysconfdir=/etc      \
        --with-rootprefix=""    \
        --libexecdir=/lib      \
        --enable-split-usr     \
        --libdir=${LIBDIR32}      \
        --with-rootlibdir=/lib \
        --sbindir=/sbin        \
        --bindir=/sbin         \
        --disable-static       \
        --config-cache          \
        --enable-rule_generator
      
      checkBuiltPackage
      LIBRARY_PATH=/tools/lib make
      mkdir -pv /lib/udev/rules.d
      mkdir -pv /etc/udev/rules.d
      checkBuiltPackage
      LD_LIBRARY_PATH=/tools/lib make check
      checkBuiltPackage
      make install
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "eudev_x64" ]]; then
      extract_pkg ${pkg_name}-
    
      touch config.cache 
      echo "HAVE_BLKID=1" > config.cache
      echo "BLKID_LIBS=\"-lblkid\"" >> config.cache
      echo "BLKID_CFLAGS=\"-I/tools/include\"" >> config.cache

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
        --sysconfdir=/etc \
        --with-rootprefix="" \
        --libexecdir=/lib64 \
        --enable-split-usr \
        --libdir=${LIBDIR64} \
        --with-rootlibdir=/lib64 \
        --sbindir=/sbin \
        --bindir=/sbin \
        --disable-static \
        --config-cache \
        --enable-manpages \
        --enable-rule_generator \
        --with-firmware-path=/lib/firmware
      
      checkBuiltPackage
      LIBRARY_PATH=/tools/lib64 make
      mkdir -pv /lib64/udev/rules.d
      mkdir -pv /etc/udev/rules.d
      make LD_LIBRARY_PATH=/tools/lib64 check
      checkBuiltPackage
      make LD_LIBRARY_PATH=/tools/lib64 install
      install -dv /lib/firmware

      echo "# dummy, so that network is once again on eth*" > /etc/udev/rules.d/80-net-name-slot.rules

      LD_LIBRARY_PATH=/tools/lib64 udevadm hwdb --update
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "util-linux" ]]; then
      extract_pkg ${pkg_name}-
    
      mkdir -pv /var/lib/hwclock
      rm -vf /usr/include/{blkid,libmount,uuid}

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 CC="gcc ${BUILD64}" ./configure ADJTIME_PATH=/var/lib/hwclock/adjtime \
        --libdir=/lib64 \
        --enable-write \
        --docdir=/usr/share/doc/${pkg_name}-${pkg_ver}linux-2.32.1 \
        --disable-chfn-chsh  \
        --disable-login      \
        --disable-nologin    \
        --disable-su         \
        --disable-setpriv    \
        --disable-runuser    \
        --disable-pylibmount \
        --disable-static     \
        --without-python     \
        --without-systemd    \
        --without-systemdsystemunitdir
        
      checkBuiltPackage
      LIBDIR=${LIBDIR64} PREFIX=${PREFIX} make
      checkBuiltPackage
      chown -Rv nobody .
      su nobody -s /bin/bash -c "PATH=$PATH make -k check"
      checkBuiltPackage

      LIBDIR=${LIBDIR64} PREFIX=${PREFIX}  make install
      mv -v /usr/bin/logger /bin
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "man-db" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 CC="gcc ${BUILD64}" \
      ./configure --prefix=${PREFIX} \
        --libexecdir=/usr/lib64 \
        --docdir=/usr/share/doc/${pkg_name}-${pkg_ver}db-2.8.4 \
        --sysconfdir=/etc \
        --libdir=${LIBDIR64} \
        --disable-setuid \
        --enable-cache-owner=bin \
        --with-browser=/usr/bin/lynx \
        --with-vgrind=/usr/bin/vgrind \
        --with-grap=/usr/bin/grap \
        --with-systemdtmpfilesdir=
        
      checkBuiltPackage
      make
      checkBuiltPackage
      make check
      checkBuiltPackage
      make install

    elif [[ ${finalsys_pkg_arr[${count}]} == "tar" ]]; then    
      extract_pkg ${pkg_name}-
    
      FORCE_UNSAFE_CONFIGURE=1 CC="gcc ${BUILD64}" \
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 \
      ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64} \
        --bindir=/bin \
        --libexecdir=/usr/sbin

      LIBDIR=${LIBDIR64} PREFIX=${PREFIX} make
      make check
      checkBuiltPackage
      LIBDIR=${LIBDIR64} PREFIX=${PREFIX} make install
      make -C doc install-html docdir=/usr/share/doc/${pkg_name}-${pkg_ver}
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "texinfo" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i '5481,5485 s/({/(\\{/' tp/Texinfo/Parser.pm

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      USE_ARCH=64 PERL=/usr/bin/perl-64 \
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
	    --disable-static \
        --libdir=${LIBDIR64} \
        gl_cv_func_getopt_gnu=yes
        checkBuiltPackage

      #Concerning the last line above
      #Needed for version 3.6 with glibc 2.26
      #Probably can be ommited again for later diffutil versions
      #https://patchwork.ozlabs.org/patch/809145/

      LIBDIR=${LIBDIR64} PREFIX=${PREFIX} make 
      checkBuiltPackage
      LIBDIR=${LIBDIR64} PREFIX=${PREFIX} make install
      checkBuiltPackage
      LIBDIR=${LIBDIR64} PREFIX=${PREFIX} make TEXMF=/usr/share/texmf install-tex
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "vim" ]]; then
      extract_pkg ${pkg_name}-
    
      #patch -Np1 -i ../vim-8.0-branch_update-1.patch

      echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
      ./configure --prefix=${PREFIX}
      checkBuiltPackage
     
      make
      checkBuiltPackage
      make -j1 test &> vim-test.log
      checkBuiltPackage
      make install
      checkBuiltPackage
      
      ln -sv vim /usr/bin/vi
      for L in  /usr/share/man/{,*/}man1/vim.1; do
        ln -sv vim.1 $(dirname $L)/vi.1
      done

      ln -sv ../vim/vim81/doc /usr/share/doc/${pkg_name}-${pkg_ver}

      touch /etc/vimrc 
      echo "\" Begin /etc/vimrc" > /etc/vimrc
      echo "" >> /etc/vimrc
      echo "\" Ensure defaults are set before customizing settings, not after" >> /etc/vimr
      echo "source $VIMRUNTIME/defaults.vim" >> /etc/vimrc
      echo "let skip_defaults_vim=1" >> /etc/vimrc
      echo "" >> /etc/vimrc
      echo "set nocompatible" >> /etc/vimrc
      echo "set backspace=2" >> /etc/vimrc
      echo "set mouse-=a" >> /etc/vimrc
      echo "syntax on" >> /etc/vimrc
      echo "if (&term == \"xterm\") || (&term == \"putty}\")" >> /etc/vimrc
      echo "  set background=dark" >> /etc/vimrc
      echo "endif" >> /etc/vimrc
      echo "" >> /etc/vimrc
      echo "\" End /etc/vimrc" >> /etc/vimrc
          
    elif [[ ${finalsys_pkg_arr[${count}]} == "nano" ]]; then
      extract_pkg ${pkg_name}-
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" ./configure \
        --prefix=${PREFIX} \
        --libdir=${LIBDIR64}
        
      checkBuiltPackage
      make
      checkBuiltPackage
      make install
      checkBuiltPackage
      
      touch /etc/nanorc
      echo "set autoindent" > /etc/nanorc
      echo "set const" >> /etc/nanorc
      echo "set fill 72" >> /etc/nanorc
      echo "set historylog" >> /etc/nanorc
      echo "set multibuffer" >> /etc/nanorc
      echo "set nohelp" >> /etc/nanorc
      echo "set regexp" >> /etc/nanorc
      echo "set smooth" >> /etc/nanorc
      echo "set suspend" >> /etc/nanorc
      
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "cpio" ]]; then
      extract_pkg ${pkg_name}-    
    
      PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
      CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
      ./configure --prefix=${PREFIX} \
        --bindir=/bin \
        --enable-mt   \
        --with-rmt=/usr/libexec/rmt
        
      checkBuiltPackage
      make
      checkBuiltPackage
      makeinfo --html            -o doc/html      doc/cpio.texi
      makeinfo --html --no-split -o doc/cpio.html doc/cpio.texi
      makeinfo --plaintext       -o doc/cpio.txt  doc/cpio.texi
      checkBuiltPackage
      make install
      checkBuiltPackage
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "strip" ]]; then
    
      #Done
      #Let's strip debugging symbols
      #First place the debugging symbols for selected libraries in separate files. 
      #This debugging information is needed if running regression tests that use valgrind or gdb later in BLFS.

	  save_lib="ld-2.28.so libc-2.28.so libpthread-2.28.so libthread_db-1.0.so"
      cd /lib

      for LIB in $save_lib; do
        objcopy --only-keep-debug $LIB $LIB.dbg 
        strip --strip-unneeded $LIB
        objcopy --add-gnu-debuglink=$LIB.dbg $LIB 
      done    

      save_usrlib="libquadmath.so.0.0.0 libstdc++.so.6.0.25
             libmpx.so.2.0.1 libmpxwrappers.so.2.0.1 libitm.so.1.0.0
             libatomic.so.1.2.0" 

      cd /usr/lib

      for LIB in $save_usrlib; do
        objcopy --only-keep-debug $LIB $LIB.dbg
        strip --strip-unneeded $LIB
        objcopy --add-gnu-debuglink=$LIB.dbg $LIB
      done

      unset LIB save_lib save_usrlib
        
    elif [[ ${finalsys_pkg_arr[${count}]} == "set_username" ]]; then
    
      myusername=$(cat /clfs-system.config | grep username | sed 's/username=//g')
      YOURUSERNAME=$myusername
      export YOURUSERNAME

      cd ${CLFSSOURCES}
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "cracklib" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i '/skipping/d' util/packer.c

      CC="gcc ${BUILD64}" USE_ARCH=64 ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64} --disable-static --with-default-dict=/lib64/cracklib/pw_dict 
  
      sed -i 's@prefix}/lib@&64@g' dicts/Makefile doc/Makefile lib/Makefile \
         m4/Makefile Makefile python/Makefile util/Makefile 
     
      checkBuiltPackage
     
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64}
      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64} install 
      checkBuiltPackage
      
      mv -v /usr/lib64/libcrack.so.* /lib64
      ln -sfv ../../lib64/$(readlink /usr/lib64/libcrack.so) /usr/lib64/libcrack.so

      install -v -m644 -D    ../cracklib-words-2.9.6.gz \
                         /usr/share/dict/cracklib-words.gz     

      gunzip -v                /usr/share/dict/cracklib-words.gz     
      ln -v -sf cracklib-words /usr/share/dict/words                 
      echo $(hostname) >>      /usr/share/dict/cracklib-extra-words  
      install -v -m755 -d      /lib64/cracklib                         

      create-cracklib-dict     /usr/share/dict/cracklib-words \
                         /usr/share/dict/cracklib-extra-words
                         
      make test
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "Linux-PAM" ]]; then
      extract_pkg ${pkg_name}-
    
      #autoreconf -fiv
      #./autogen.sh

      CC="gcc ${BUILD64}" ./configure --sbindir=/lib64/security \
            --prefix=${PREFIX}                    \
            --sysconfdir=/etc                \
            --libdir=${LIBDIR64}              \
            --disable-regenerate-docu        \
            --enable-securedir=/lib64/security \
            --docdir=/usr/share/doc/${pkg_name}-${pkg_ver}
      
      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64}
      checkBuiltPackage

      install -v -m755 -d /etc/pam.d 

      touch /etc/pam.d/other
      echo "auth     required       pam_deny.so" > /etc/pam.d/other
      echo "account  required       pam_deny.so" >> /etc/pam.d/other
      echo "password required       pam_deny.so" >> /etc/pam.d/other
      echo "session  required       pam_deny.so" >> /etc/pam.d/other
      
      checkBuiltPackage

      make check
      checkBuiltPackage
      
      if [[ -d /etc/pam.d ]]; then
        rm -fv /etc/pam.d/*
      fi
      
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64} install 
      chmod -v 4755 /sbin/unix_chkpwd 
      
      checkBuiltPackage

      for file in pam pam_misc pamc
      do
        mv -v /usr/lib64/lib${file}.so.* /lib64 
        ln -sfv ../../lib64/$(readlink /usr/lib64/lib${file}.so) /usr/lib64/lib${file}.so
      done

      install -vdm755 /etc/pam.d 
      
      checkBuiltPackage
      
      touch /etc/pam.d/system-account
      echo "# Begin /etc/pam.d/system-account" > /etc/pam.d/system-account
      echo "" >> /etc/pam.d/system-account
      echo "account   required    pam_unix.so" > /etc/pam.d/system-account
      echo "" >> /etc/pam.d/system-account
      echo "# End /etc/pam.d/system-account" > /etc/pam.d/system-account
      
      checkBuiltPackage

      touch /etc/pam.d/system-auth  
      echo "# Begin /etc/pam.d/system-auth" > /etc/pam.d/system-auth
      echo "" >> /etc/pam.d/system-auth
      echo "auth      required    pam_unix.so" >> /etc/pam.d/system-auth
      echo "" >> /etc/pam.d/system-auth
      echo "# End /etc/pam.d/system-auth" >> /etc/pam.d/system-auth
      
      checkBuiltPackage
      
      touch /etc/pam.d/system-session 
      echo "# Begin /etc/pam.d/system-session" > /etc/pam.d/system-session
      echo "" >> /etc/pam.d/system-session
      echo "session   required    pam_unix.so" >> /etc/pam.d/system-session
      echo "" >> /etc/pam.d/system-session
      echo "# End /etc/pam.d/system-session" >> /etc/pam.d/system-session
      
      checkBuiltPackage

      touch /etc/pam.d/system-password
      echo "# Begin /etc/pam.d/system-password" > /etc/pam.d/system-password
      echo "" >> /etc/pam.d/system-password
      echo "# check new passwords for strength (man pam_cracklib)" >> /etc/pam.d/system-password
      echo "password  required    pam_cracklib.so   type=Linux retry=3 difok=5 \\" >> /etc/pam.d/system-password
      echo "                                  difignore=23 minlen=9 dcredit=1 \\" >> /etc/pam.d/system-password
      echo "                                  ucredit=1 lcredit=1 ocredit=1 \\" >> /etc/pam.d/system-password
      echo "                                  dictpath=/lib64/cracklib/pw_dict" >> /etc/pam.d/system-password
      echo "# use sha512 hash for encryption, use shadow, and use the" >> /etc/pam.d/system-password
      echo "# authentication token (chosen password) set by pam_cracklib" >> /etc/pam.d/system-password
      echo "# above (or any previous modules)" >> /etc/pam.d/system-password
      echo "password  required    pam_unix.so       sha512 shadow use_authtok" >> /etc/pam.d/system-password
      echo "" >> /etc/pam.d/system-password
      echo "# End /etc/pam.d/system-password" >> /etc/pam.d/system-password
      
      checkBuiltPackage
      
      touch /etc/pam.d/other
      echo "# Begin /etc/pam.d/other" > /etc/pam.d/other
      echo "" >> /etc/pam.d/other
      echo "auth        required        pam_warn.so" >> /etc/pam.d/other
      echo "auth        required        pam_deny.so" >> /etc/pam.d/other
      echo "account     required        pam_warn.so" >> /etc/pam.d/other
      echo "account     required        pam_deny.so" >> /etc/pam.d/other
      echo "password    required        pam_warn.so" >> /etc/pam.d/other
      echo "password    required        pam_deny.so" >> /etc/pam.d/other
      echo "session     required        pam_warn.so" >> /etc/pam.d/other
      echo "session     required        pam_deny.so" >> /etc/pam.d/other
      echo "" >> /etc/pam.d/other
      echo "# End /etc/pam.d/other" >> /etc/pam.d/other
      
      sed -i 's@DICTPATH.*@DICTPATH\t/lib64/cracklib/pw_dict@' etc/login.defs
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "shadow" ]]; then
      extract_pkg ${pkg_name}-
    
      sed -i 's/groups$(EXEEXT) //' src/Makefile.in 

      find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \; 
      find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \; 
      find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \; 

      sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
        -e 's@/var/spool/mail@/var/mail@' etc/login.defs 

      sed -i 's/1000/999/' etc/useradd   
      
      checkBuiltPackage

      CC="gcc ${BUILD64}" ./configure --sysconfdir=/etc \
        --with-group-name-max-length=32 \
        --with-libpam \
        --with-libcrack \
        --without-audit \
        --without-selinux
        
      checkBuiltPackage
      make 
      checkBuiltPackage
      make install
      checkBuiltPackage

      #sed -i /etc/login.defs \
      #    -e 's@#\(ENCRYPT_METHOD \).*@\1SHA512@' \
      #    -e 's@/var/spool/mail@/var/mail@'
      #
      #sed -i 's/yes/no/' /etc/default/useradd

      mv -v /usr/bin/passwd /bin

      touch /var/log/{fail,last}log
      chgrp -v utmp /var/log/{fail,last}log
      chmod -v 664 /var/log/{fail,last}log

      install -v -m644 /etc/login.defs /etc/login.defs.orig 
      
      checkBuiltPackage
      
      for FUNCTION in FAIL_DELAY         \
                FAILLOG_ENAB             \
                LASTLOG_ENAB             \
                MAIL_CHECK_ENAB          \
                OBSCURE_CHECKS_ENAB      \
                PORTTIME_CHECKS_ENAB     \
                QUOTAS_ENAB              \
                CONSOLE MOTD_FILE        \
                FTMP_FILE NOLOGINS_FILE  \
                ENV_HZ PASS_MIN_LEN      \
                SU_WHEEL_ONLY            \
                CRACKLIB_DICTPATH        \
                PASS_CHANGE_TRIES        \
                PASS_ALWAYS_WARN         \
                CHFN_AUTH ENCRYPT_METHOD \
                ENVIRON_FILE
      do
        sed -i "s/^${FUNCTION}/# &/" /etc/login.defs
      done
      
      checkBuiltPackage

      touch /etc/pam.d/login 
      echo "# Begin /etc/pam.d/login" > /etc/pam.d/login 
      echo "" >> /etc/pam.d/login
      echo "# Set failure delay before next prompt to 3 seconds" >> /etc/pam.d/login
      echo "auth      optional    pam_faildelay.so  delay=3000000" >> /etc/pam.d/login
      echo "" >> /etc/pam.d/login
      echo "# Check to make sure that the user is allowed to login" >> /etc/pam.d/login
      echo "auth      requisite   pam_nologin.so" >> /etc/pam.d/login
      echo "" >> /etc/pam.d/login
      echo "# Check to make sure that root is allowed to login" >> /etc/pam.d/login
      echo "# Disabled by default. You will need to create /etc/securetty" >> /etc/pam.d/login
      echo "# file for this module to function. See man 5 securetty." >> /etc/pam.d/login
      echo "#auth      required    pam_securetty.so" >> /etc/pam.d/login
      echo "" >> /etc/pam.d/login
      echo "# Additional group memberships - disabled by default" >> /etc/pam.d/login
      echo "#auth      optional    pam_group.so" >> /etc/pam.d/login
      echo "" >> /etc/pam.d/login
      echo "# include the default auth settings" >> /etc/pam.d/login
      echo "auth      include     system-auth" >> /etc/pam.d/login
      echo "" >> /etc/pam.d/login
      echo "# check access for the user" >> /etc/pam.d/login
      echo "account   required    pam_access.so" >> /etc/pam.d/login
      echo "" >> /etc/pam.d/login
      echo "# include the default account settings" >> /etc/pam.d/login
      echo "account   include     system-account" >> /etc/pam.d/login
      echo "" >> /etc/pam.d/login
      echo "# Set default environment variables for the user" >> /etc/pam.d/login
      echo "session   required    pam_env.so" >> /etc/pam.d/login
      echo "" >> /etc/pam.d/login
      echo "# Set resource limits for the user" >> /etc/pam.d/login
      echo "session   required    pam_limits.so" >> /etc/pam.d/login
      echo "" >> /etc/pam.d/login
      echo "# Display date of last login - Disabled by default" >> /etc/pam.d/login
      echo "#session   optional    pam_lastlog.so" >> /etc/pam.d/login
      echo "" >> /etc/pam.d/login
      echo "# Display the message of the day - Disabled by default" >> /etc/pam.d/login
      echo "#session   optional    pam_motd.so" >> /etc/pam.d/login
      echo "" >> /etc/pam.d/login
      echo "# Check user's mail - Disabled by default" >> /etc/pam.d/login
      echo "#session   optional    pam_mail.so      standard quiet" >> /etc/pam.d/login
      echo "" >> /etc/pam.d/login
      echo "# include the default session and password settings" >> /etc/pam.d/login
      echo "session   include     system-session" >> /etc/pam.d/login
      echo "password  include     system-password" >> /etc/pam.d/login
      echo "" >> /etc/pam.d/login
      echo "# End /etc/pam.d/login" >> /etc/pam.d/login
      
      checkBuiltPackage
      
      touch /etc/pam.d/passwd 
      echo "# Begin /etc/pam.d/passwd" > /etc/pam.d/passwd 
      echo "" >> /etc/pam.d/passwd 
      echo "password  include     system-password" >> /etc/pam.d/passwd
      echo "" >> /etc/pam.d/passwd
      echo "# End /etc/pam.d/passwd" >> /etc/pam.d/passwd
      
      checkBuiltPackage
      
      touch /etc/pam.d/su
      echo "# Begin /etc/pam.d/su" > /etc/pam.d/su
      echo "" >> /etc/pam.d/su
      echo "# always allow root" >> /etc/pam.d/su
      echo "auth      sufficient  pam_rootok.so" >> /etc/pam.d/su
      echo "auth      include     system-auth" >> /etc/pam.d/su
      echo "" >> /etc/pam.d/su
      echo "# include the default account settings" >> /etc/pam.d/su
      echo "account   include     system-account" >> /etc/pam.d/su
      echo "" >> /etc/pam.d/su
      echo "# Set default environment variables for the service user" >> /etc/pam.d/su
      echo "session   required    pam_env.so" >> /etc/pam.d/su
      echo "" >> /etc/pam.d/su
      echo "# include system session defaults" >> /etc/pam.d/su
      echo "session   include     system-session" >> /etc/pam.d/su
      echo "" >> /etc/pam.d/su
      echo "# End /etc/pam.d/su" >> /etc/pam.d/su
      
      checkBuiltPackage
      
      touch /etc/pam.d/chage 
      echo "# Begin /etc/pam.d/chage" > /etc/pam.d/chage
      echo "" >> /etc/pam.d/chage
      echo "# always allow root" >> /etc/pam.d/chage
      echo "auth      sufficient  pam_rootok.so" >> /etc/pam.d/chage
      echo "" >> /etc/pam.d/chage
      echo "# include system defaults for auth account and session" >> /etc/pam.d/chage
      echo "auth      include     system-auth" >> /etc/pam.d/chage
      echo "account   include     system-account" >> /etc/pam.d/chage
      echo "session   include     system-session" >> /etc/pam.d/chage
      echo "" >> /etc/pam.d/chage
      echo "# Always permit for authentication updates" >> /etc/pam.d/chage
      echo "password  required    pam_permit.so" >> /etc/pam.d/chage
      echo "" >> /etc/pam.d/chage
      echo "# End /etc/pam.d/chage" >> /etc/pam.d/chage
      
      checkBuiltPackage
      
      for PROGRAM in chfn chgpasswd chpasswd chsh groupadd groupdel \
               groupmems groupmod newusers useradd userdel usermod
      do
        install -v -m644 /etc/pam.d/chage /etc/pam.d/${PROGRAM}
        sed -i "s/chage/$PROGRAM/" /etc/pam.d/${PROGRAM}
      done
      
      checkBuiltPackage

      [ -f /etc/login.access ] && mv -v /etc/login.access{,.NOUSE}
      [ -f /etc/limits ] && mv -v /etc/limits{,.NOUSE}
      
      checkBuiltPackage

      pwconv
      grpconv
      passwd root
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "sudo" ]]; then
      extract_pkg ${pkg_name}-
    
      CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} \
        --libdir=${LIBDIR64} \
        --libexecdir=/usr/lib64 \
        --with-secure-path  \
        --with-all-insults \
        --with-env-editor  \
        --docdir=/usr/share/doc/${pkg_name}-${pkg_ver} \
        --with-passprompt="[sudo] password for %p: "
        
      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64}
      checkBuiltPackage
      make PREFIX=${PREFIX} LIBDIR=${LIBDIR64} install

      ln -sfv libsudo_util.so.0.0.0 /usr/lib64/sudo/libsudo_util.so.0
      checkBuiltPackage
      
      touch /etc/pam.d/sudo 
      echo "# Begin /etc/pam.d/sudo" > /etc/pam.d/sudo 
      echo "" >> /etc/pam.d/sudo
      echo "# include the default auth settings" >> /etc/pam.d/sudo
      echo "auth      include     system-auth" >> /etc/pam.d/sudo
      echo "" >> /etc/pam.d/sudo
      echo "# include the default account settings" >> /etc/pam.d/sudo
      echo "account   include     system-account" >> /etc/pam.d/sudo
      echo "" >> /etc/pam.d/sudo
      echo "# Set default environment variables for the service user" >> /etc/pam.d/sudo
      echo "session   required    pam_env.so" >> /etc/pam.d/sudo
      echo "" >> /etc/pam.d/sudo
      echo "# include system session defaults" >> /etc/pam.d/sudo
      echo "session   include     system-session" >> /etc/pam.d/sudo
      echo "" >> /etc/pam.d/sudo
      echo "# End /etc/pam.d/sudo" >> /etc/pam.d/sudo

      chmod -v 644 /etc/pam.d/sudo
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "add_user_sudoers" ]]; then
    
      #Add the final regular user
      groupadd users
      groupadd storage
      groupadd power
      useradd -g users -G wheel,storage,power -m -s /bin/bash $YOURUSERNAME
      checkBuiltPackage
      passwd $YOURUSERNAME
    
      #User should uncomment first line containing wheel now
      visudo
    
    elif [[ ${finalsys_pkg_arr[${count}]} == "autoload_pkg_conf_vars" ]]; then
    
      #Get PKG_CONFIG_PATH to be loaded up automagically for both users
      #Easier for later building of packages
      touch /home/$YOURUSERNAME/.bashrc 
      echo "export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig" >> /home/$YOURUSERNAME/.bashrc 
      echo "export PKG_CONFIG_PATH32=/usr/lib/pkgconfig" >> /home/$YOURUSERNAME/.bashrc 
      
      touch /root/.bashrc 
      echo "export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig" >> /root/.bashrc 
      echo "export PKG_CONFIG_PATH32=/usr/lib/pkgconfig" >> /root/.bashrc       
    
    fi

    cd ${CLFSSOURCES}
    checkBuiltPackage
    rm -rf ${pkg_name}
    count=$(expr ${count} + 1)

done
}

build_pkg

cd ${CLFS}