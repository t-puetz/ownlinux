#!/bin/bash

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

#Building the final CLFS System
CLFS=/
CLFSSOURCES=/sources
CLFSTOOLS=/tools
MAKEFLAGS="-j$(nproc)"
BUILD32="-m32"
BUILD64="-m64"
CLFS_TARGET32="i686-pc-linux-gnu"

export CLFS=/
export CLFSUSER=clfs
export CLFSSOURCES=/sources
export MAKEFLAGS="-j$(nproc)"
export BUILD32="-m32"
export BUILD64="-m64"
export CLFS_TARGET32="i686-pc-linux-gnu"

cd ${CLFSSOURCES}


#Chapter 9
#Starting with test suite packages

cd ${CLFSSOURCES}

#Tcl
mkdir tcl && tar xf tcl*.tar.* -C tcl --strip-components 1
cd tcl
cd unix

CC="gcc ${BUILD64}" ./configure \
    --prefix=/tools \
    --libdir=/tools/lib64

make
make install
make install-private-headers
ln -sv tclsh8.6 /tools/bin/tclsh

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf tcl

#Expect
mkdir expect && tar xf expect*.tar.* -C expect --strip-components 1
cd expect

CC="gcc ${BUILD64}" \
./configure \
    --prefix=/tools \
    --with-tcl=/tools/lib64 \
    --with-tclinclude=/tools/include \
    --libdir=/tools/lib64

make
make SCRIPTS="" install

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf expect

#DejaGNU
mkdir dejagnu && tar xf dejagnu-*.tar.* -C dejagnu --strip-components 1
cd dejagnu

./configure \
    --prefix=/tools

make install

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf dejagnu

#Chapter 10
#Installing the basic system software

cd ${CLFSSOURCES}

#Starting with Chapter 10.4
#Temporary-Perl
mkdir perl && tar xf perl-*.tar.* -C perl --strip-components 1
cd perl
sed -i 's@/usr/include@/tools/include@g' ext/Errno/Errno_pm.PL

./configure.gnu \
    --prefix=/tools \
    -Dcc="gcc ${BUILD32}"

make
make install
ln -sfv /tools/bin/perl /usr/bin

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf perl

#Linux headers
mkdir linux && tar xf linux-*.tar.* -C linux --strip-components 1
cd linux

#Man Pages
mkdir man-pages && tar xf man-pages-*.tar.* -C man-pages --strip-components 1
cd man-pages

make install

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf man-pages

#m4
mkdir m4 && tar xf m4-*.tar.* -C m4 --strip-components 1
cd m4

cp -rv ${CLFSSOURCES}/gnulib/lib/freadahead.* lib/
cp -rv ${CLFSSOURCES}/gnulib/lib/fseeko.* lib/

cd lib

cp -v ${CLFSSOURCES}/gnulib-freadahead-header-define-ioinbackup-findutils.patch .
patch -Np0 -i gnulib-freadahead-header-define-ioinbackup-findutils.patch

sed -i 's/__GNU_LIBRARY__ == 1/__GNU_LIBRARY__ == 6/g' freadahead.c

cd ..

CC="gcc ${BUILD64}" ./configure \
    --prefix=/usr

make
make check
make install

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf m4

#bison
mkdir bison && tar xf bison-*.tar.* -C bison --strip-components 1
cd bison

CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" \
./configure \
    --prefix=/usr \
    --docdir=/usr/share/doc/bison-3.0.4

make
make check
make install

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf bison

#bison
mkdir bison && tar xf bison-*.tar.* -C bison --strip-components 1
cd bison

CC="gcc ${BUILD64}" \
CXX="g++ ${BUILD64}" \
./configure \
    --prefix=/usr \
    --libdir=/usr/lib64 \
    --docdir=/usr/share/doc/bison-3.0.4

make
make check
make install

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf bison


#Glibc 32-bit
mkdir glibc && tar xf glibc-*.tar.* -C glibc --strip-components 1
cd glibc

patch -Np1 -i ../glibc-2.2*-fhs-1.patch

LINKER=$(readelf -l /tools/bin/bash | sed -n 's@.*interpret.*/tools\(.*\)]$@\1@p')
sed -i "s|libs -o|libs -L/usr/lib -Wl,-dynamic-linker=${LINKER} -o|" \
  scripts/test-installation.pl
  
unset LINKER

mkdir -v ../glibc-build
cd ../glibc-build

CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" \
../glibc/configure \
    --prefix=/usr \
    --enable-kernel=4.9 \
    --libexecdir=/usr/lib/glibc \
    --host=${CLFS_TARGET32} \
    --enable-stack-protector=strong \
    --enable-obsolete-rpc

make
sed -i '/cross-compiling/s@ifeq@ifneq@g' ../glibc/localedata/Makefile
make check
touch /etc/ld.so.conf
make install
rm -v /usr/include/rpcsvc/*.x

cd ${CLFSSOURCES} 
checkBuiltPackage 
rm -rf glibc
rm -rf glibc-build 

#Glibc 64-bit
mkdir glibc && tar xf glibc-*.tar.* -C glibc --strip-components 1
cd glibc

patch -Np1 -i ../glibc-2.2*-fhs-1.patch

LINKER=$(readelf -l /tools/bin/bash | sed -n 's@.*interpret.*/tools\(.*\)]$@\1@p')
sed -i "s|libs -o|libs -L/usr/lib64 -Wl,-dynamic-linker=${LINKER} -o|" \
  scripts/test-installation.pl
unset LINKER

echo "libc_cv_slibdir=/lib64" >> config.cache

case $(uname -m) in
    i?86)    GCC_INCDIR=/usr/lib/gcc/$(uname -m)-pc-linux-gnu/7.3.0/include
            ln -sfv ld-linux.so.2 /lib/ld-lsb.so.3
    ;;
    x86_64) GCC_INCDIR=/usr/lib/gcc/x86_64-pc-linux-gnu/7.3.0/include
            ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
    ;;
esac

rm -f /usr/include/limits.h

mkdir -v ../glibc-build
cd ../glibc-build


CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
../glibc/configure \
    --prefix=/usr \
    --enable-kernel=4.9 \
    --libexecdir=/usr/lib64/glibc \
    --libdir=/usr/lib64 \
    --enable-obsolete-rpc \
    --enable-stack-protector=strong \
    --cache-file=config.cache

unset GCC_INCDIR

make 
make check
checkBuiltPackage 

make install &&
rm -v /usr/include/rpcsvc/*.x

cp -v ../glibc/nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd

make localedata/install-locales

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../tzdata20*.tar.*

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
    zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO

tzselect

cp -v /usr/share/zoneinfo/Europe/Berlin \
    /etc/localtime

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf

/lib
/lib64
/usr/lib
/usr/lib64
/usr/local/lib
/usr/local/lib64
/opt/lib
/opt/lib64

# End /etc/ld.so.conf
EOF

mkdir -pv /etc/ld.so.conf.d

cd ${CLFSSOURCES} 
checkBuiltPackage 
rm -rf glibc
rm -rf glibc-build 

#Adjusting the toolchain
gcc -dumpspecs | \
perl -p -e 's@/tools/lib/ld@/lib/ld@g;' \
     -e 's@/tools/lib64/ld@/lib64/ld@g;' \
     -e 's@\*startfile_prefix_spec:\n@$_/usr/lib/ @g;' > \
     $(dirname $(gcc --print-libgcc-file-name))/specs

echo 'int main(){}' > dummy.c
gcc ${BUILD32} dummy.c
readelf -l a.out | grep ': /lib'

checkBuiltPackage 

echo 'main(){}' > dummy.c
gcc ${BUILD64} dummy.c
readelf -l a.out | grep ': /lib'

rm -v dummy.c a.out

cd ${CLFS}

echo " "
echo "After adjusting it is a good point to take a breath..."
echo "Smaller scripts makes seeing errors easier for you"
echo "and maintenance easier for me ;)"
echo "Execute script 6b next!"
echo " "















