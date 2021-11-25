##!/bin/bash

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

export CLFS=/
export CLFSUSER=clfs
export CLFSSOURCES=/sources
export MAKEFLAGS="-j$(nproc)"
export BUILD32="-m32"
export BUILD64="-m64"
export CLFS_TARGET32="i686-pc-linux-gnu"

cd ${CLFSSOURCES}

#libuv
wget https://dist.libuv.org/dist/v1.19.2/libuv-v1.19.2.tar.gz -O \
    libuv-v1.19.2.tar.gz

mkdir libuv && tar xf libuv-*.tar.* -C libuv --strip-components 1
cd libuv

sh autogen.sh

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libuv

#libarchive
wget http://www.libarchive.org/downloads/libarchive-3.3.2.tar.gz -O \
    libarchive-3.3.2.tar.gz

mkdir libarchive && tar xf libarchive-*.tar.* -C libarchive --strip-components 1
cd libarchive

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf libarchive

#CMake
wget http://www.cmake.org/files/v3.10/cmake-3.10.2.tar.gz -O \
    cmake-3.10.2.tar.gz

mkdir cmake && tar xf cmake-*.tar.* -C cmake --strip-components 1
cd cmake

#sed -i '/CMAKE_USE_LIBUV 1/s/1/0/' CMakeLists.txt
#sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./bootstrap --prefix=/usr \
            --system-libs        \
            --mandir=/share/man  \
            --no-system-jsoncpp  \
            --no-system-librhash \
            --docdir=/share/doc/cmake-3.10.2

#bin/ctest -O cmake-3.10.2-test.log
#checkBuiltPackage

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/mate
checkBuiltPackage
sudo rm -rf cmake

wget http://releases.llvm.org/6.0.0/llvm-6.0.0.src.tar.xz
wget http://releases.llvm.org/6.0.0/cfe-6.0.0.src.tar.xz
wget http://releases.llvm.org/6.0.0/compiler-rt-6.0.0.src.tar.xz

mkdir llvm && tar xf llvm-6*.src.tar.* -C llvm --strip-components 1
cd llvm

tar -xf ../cfe-6.0.*.src.tar.xz -C tools &&
tar -xf ../compiler-rt-6.0.*.src.tar.xz -C projects &&

mv tools/cfe-6.0.*.src tools/clang &&
mv projects/compiler-rt-6.0.*.src projects/compiler-rt

mkdir -v build
cd       build

CC="gcc -m64" CXX="g++ -m64"                \
cmake -DCMAKE_INSTALL_PREFIX=/usr           \
      -DLLVM_ENABLE_FFI=ON                  \
      -DCMAKE_BUILD_TYPE=Release            \
      -DLLVM_BUILD_LLVM_DYLIB=ON            \
      -DLLVM_TARGETS_TO_BUILD="host;AMDGPU" \
      -Wno-dev ..                           &&

make
make install

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf llvm

