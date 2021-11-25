#!/bin/bash

#Declarations
declare -a cx_tools_pkg_arr

#Variables
PREFIX=/cross-tools
TOOLSDIR=/tools

CLFS=/mnt/clfs
CLFSUSER=clfs
CLFSHOME=${CLFS}/home
CLFSSOURCES=${CLFS}/sources
CLFS_HOST=$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')
CLFS_TARGET="x86_64-unknown-linux-gnu"
CLFS_TARGET32="i686-pc-linux-gnu"

BUILD32="-m32"
BUILD64="-m64"
MAKEFLAGS="-j$(nproc)"

source functions_ownlinux_pre_chroot_c2.sh unsetfcts 
source functions_ownlinux_pre_chroot_c2.sh exportfcts 

cx_tools_pkg_arr=(file linux_headers m4 ncurses pkg-config-lite gmp mpfr 
  mpc cx_binutils gcc_static glibc_x86 glibc_x64 gcc_final)
	
function build_pkg() {
local count=0
for pkg in ${cx_tools_pkg_arr[*]}
do
	local pkg_name=$(conv_meta_to_real_pkg_name_c2 ${cx_tools_pkg_arr[${count}]})
	local pkg_ver=$(get_pkg_ver_c2 ${pkg_name})

	printf "===========================\n"
	printf "\n"
	printf "Let's build and install ${pkg_name} / meta name: ${cx_tools_pkg_arr[${count}]}\n"
	printf "Version ${pkg_ver}\n"
	printf "\n"
	printf "===========================\n"
	
	
	checkBuiltPackage

	cd ${CLFSSOURCES}

	if [[ ${cx_tools_pkg_arr[${count}]} == "file" ]] || [[ ${cx_tools_pkg_arr[${count}]} == "m4" ]]; then
		extract_pkg_c2 ${pkg_name}-
	
	if [[ ${pkg_name} == "m4" ]]; then
		sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
		echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
	fi
	
	./configure --prefix=${PREFIX} 
	checkBuiltPackage 
	make 
	make install
	elif [[ ${cx_tools_pkg_arr[${count}]} == "linux_headers" ]]; then
		extract_pkg_c2 ${pkg_name}-

		make mrproper
		make ARCH=x86_64 headers_check
		checkBuiltPackage 
		make ARCH=x86_64 INSTALL_HDR_PATH=${TOOLSDIR} headers_install
	elif [[ ${cx_tools_pkg_arr[${count}]} == "ncurses" ]]; then
		extract_pkg_c2 ${pkg_name}-

		./configure --prefix=${PREFIX} --without-debug 
		checkBuiltPackage
		make -C include 
		make -C progs tic 
		checkBuiltPackage
		install -v -m755 progs/tic ${PREFIX}/bin
	elif [[ ${cx_tools_pkg_arr[${count}]} == pkg-config-lite  ]]; then
		extract_pkg_c2 ${pkg_name}-

		./configure --prefix=${PREFIX} --host=${CLFS_TARGET} \
		  --with-pc-path=${TOOLSDIR}/lib64/pkgconfig:${TOOLSDIR}/share/pkgconfig 
          
		checkBuiltPackage 
		make 
		checkBuiltPackage 
		make install
	elif [[ ${cx_tools_pkg_arr[${count}]} == "gmp" ]]; then
		extract_pkg_c2 ${pkg_name}-

		./configure --prefix=${PREFIX} --enable-cxx --disable-static 
		checkBuiltPackage
		make 
		checkBuiltPackage 
		make install
	elif [[ ${cx_tools_pkg_arr[${count}]} == "mpfr" ]]; then
		extract_pkg_c2 ${pkg_name}-

		LDFLAGS="-Wl,-rpath,/cross-tools/lib" ./configure --prefix=${PREFIX} --with-gmp=${PREFIX} \
	          --disable-static 
		checkBuiltPackage
		make 
		checkBuiltPackage 
		make install
	elif [[ ${cx_tools_pkg_arr[${count}]} == "mpc" ]]; then
		extract_pkg_c2 ${pkg_name}-

		LDFLAGS="-Wl,-rpath,/cross-tools/lib" ./configure --prefix=${PREFIX} --with-gmp=${PREFIX} \
		  --with-mpfr=${PREFIX} --disable-static
		checkBuiltPackage 
		make  
		checkBuiltPackage 
		make install
	elif [[ ${cx_tools_pkg_arr[${count}]} == "cx_binutils" ]]; then
		extract_pkg_c2 ${pkg_name}-
	
		mkdir -v ../${pkg_name}-build
		cd ../${pkg_name}-build

		AR=ar AS=as ../${pkg_name}/configure --prefix=${PREFIX} \
		  --host=${CLFS_HOST} \
		  --target=${CLFS_TARGET} \
		  --with-sysroot=${CLFS} \
		  --with-lib-path=${TOOLSDIR}/lib:${TOOLSDIR}/lib64 \
		  --disable-nls \
		  --disable-static \
		  --enable-64-bit-bfd \
		  --enable-gold=yes \
		  --enable-plugins \
		  --enable-threads \
		  --disable-werror 
 
		checkBuiltPackage
		make 
		checkBuiltPackage 
		make install
	
		cd ${CLFSSOURCES}
		rm -rf ${pkg_name}-build
	elif [[ ${cx_tools_pkg_arr[${count}]} == "gcc_static"  ]]; then
		extract_pkg_c2 ${pkg_name}-

		patch -Np1 -i ../gcc-*-specs-1.patch
		checkBuiltPackage
	
		echo -en '\n#undef STANDARD_STARTFILE_PREFIX_1\n#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"\n' >> gcc/config/linux.h
		echo -en '\n#undef STANDARD_STARTFILE_PREFIX_2\n#define STANDARD_STARTFILE_PREFIX_2 ""\n' >> gcc/config/linux.h
		touch ${TOOLSDIR}/include/limits.h

		mkdir -v ../${pkg_name}-build
		cd ../${pkg_name}-build

		AR=ar LDFLAGS="-Wl,-rpath,/cross-tools/lib" \
		../${pkg_name}/configure --prefix=${PREFIX} \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_HOST} \
		  --target=${CLFS_TARGET} \
		  --with-sysroot=${CLFS} \
		  --with-local-prefix=${TOOLSDIR} \
		  --with-native-system-header-dir=${TOOLSDIR}/include \
		  --disable-shared \
		  --with-mpfr=${PREFIX} \
		  --with-gmp=${PREFIX} \
		  --with-mpc=${PREFIX} \
		  --without-headers \
		  --with-newlib \
		  --disable-decimal-float \
		  --disable-libgomp \
		  --disable-libssp \
		  --disable-libatomic \
		  --disable-libitm \
		  --disable-libsanitizer \
		  --disable-libquadmath \
		  --disable-libvtv \
		  --disable-libcilkrts \
		  --disable-libstdc++-v3 \
		  --disable-threads \
		  --enable-languages=c \
		  --with-glibc-version=2.28 

		checkBuiltPackage
		make all-gcc all-target-libgcc 
		checkBuiltPackage 
		make install-gcc install-target-libgcc
	
		cd ${CLFSSOURCES}
		rm -rf ${pkg_name}-build

	elif [[ ${cx_tools_pkg_arr[${count}]} == "glibc_x86" ]]; then
		extract_pkg_c2 ${pkg_name}-
	
		mkdir -v ../${pkg_name}-build
		cd ../${pkg_name}-build

		BUILD_CC="gcc" CC="${CLFS_TARGET}-gcc ${BUILD32}" \
		AR="${CLFS_TARGET}-ar" RANLIB="${CLFS_TARGET}-ranlib" \
		../${pkg_name}/configure --prefix=${TOOLSDIR} \
		  --host=${CLFS_TARGET32} \
		  --build=${CLFS_HOST} \
		  --enable-kernel=4.0 \
		  --libdir=${TOOLSDIR}/lib \
		  --with-binutils=${PREFIX}/bin \
		  --with-headers=${TOOLSDIR}/include \
		  --enable-obsolete-rpc 
          
		checkBuiltPackage
		make 
		checkBuiltPackage 
		make install

		cd ${CLFSSOURCES}
		rm -rf ${pkg_name}-build

	elif [[ ${cx_tools_pkg_arr[${count}]} == "glibc_x64" ]]; then
		extract_pkg_c2 ${pkg_name}-
	
		mkdir -v ../glibc-build
		cd ../glibc-build

		BUILD_CC="gcc" CC="${CLFS_TARGET}-gcc ${BUILD64}" \
		  AR="${CLFS_TARGET}-ar" RANLIB="${CLFS_TARGET}-ranlib" \
		  ../${pkg_name}/configure --prefix=${TOOLSDIR} \
		  --host=${CLFS_TARGET} \
		  --build=${CLFS_HOST} \
		  --libdir=${TOOLSDIR}/lib64 \
		  --enable-kernel=4.0 \
		  --with-binutils=${PREFIX}/bin \
		  --with-headers=${TOOLSDIR}/include \
		  --enable-obsolete-rpc \
		  libc_cv_slibdir=${TOOLSDIR}/lib64 
          
		checkBuiltPackage
		make 
		checkBuiltPackage 
		make install

		cd ${CLFSSOURCES}
		rm -rf ${pkg_name}-build
	
	elif [[ ${cx_tools_pkg_arr[${count}]} == "gcc_final" ]]; then
		extract_pkg_c2 ${pkg_name}-

		patch -Np1 -i ../gcc-*-specs-1.patch
		checkBuiltPackage
	
		echo -en '\n#undef STANDARD_STARTFILE_PREFIX_1\n#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"\n' >> gcc/config/linux.h
		echo -en '\n#undef STANDARD_STARTFILE_PREFIX_2\n#define STANDARD_STARTFILE_PREFIX_2 ""\n' >> gcc/config/linux.h
	
		mkdir -v ../${pkg_name}-build
		cd ../${pkg_name}-build

		AR=ar LDFLAGS="-Wl,-rpath,/cross-tools/lib" \
		../${pkg_name}/configure --prefix=${PREFIX} \
		  --build=${CLFS_HOST} \
		  --target=${CLFS_TARGET} \
		  --host=${CLFS_HOST} \
		  --with-sysroot=${CLFS} \
		  --with-local-prefix=${TOOLSDIR} \
		  --with-native-system-header-dir=${TOOLSDIR}/include \
		  --disable-static \
		  --enable-languages=c,c++ \
		  --with-mpc=${PREFIX} \
		  --with-mpfr=${PREFIX} \
		  --with-gmp=${PREFIX} 

		checkBuiltPackage
		make AS_FOR_TARGET="${CLFS_TARGET}-as" LD_FOR_TARGET="${CLFS_TARGET}-ld" 
		checkBuiltPackage 
		make install
	
		cd ${CLFSSOURCES}
		rm -rf ${pkg_name}-build
	fi

	cd ${CLFSSOURCES}
	checkBuiltPackage
	rm -rf ${pkg_name}
	count=$(expr ${count} + 1)
done
}

printf "\n"
printf "Lets start building the Cross Compile Tools\n"
printf "\n"
printf "First check your environment setup\n"
printf "Are all essential variables there\n"
printf "With the right values as described on\n"
printf "http://clfs.org/view/sysvinit/x86_64/final-preps/settingenvironment.html\n"
printf "and\n"
printf "http://clfs.org/view/sysvinit/x86_64/final-preps/variables.html\n"


cat >> ~/.bashrc << EOF
export CLFS_HOST="${CLFS_HOST}"
export CLFS_TARGET="${CLFS_TARGET}"
export CLFS_TARGET32="${CLFS_TARGET32}"
export BUILD32="${BUILD32}"
export BUILD64="${BUILD64}"
EOF

printf "\n"
env
checkBuiltPackage
printf "\n"
printf "\n"

build_pkg

printf "\n"
echo "Setting variables neccessary to create the temporary system...\n"

export CC="${CLFS_TARGET}-gcc ${BUILD64}"
export CXX="${CLFS_TARGET}-g++ ${BUILD64}"
export AR="${CLFS_TARGET}-ar"
export AS="${CLFS_TARGET}-as"
export RANLIB="${CLFS_TARGET}-ranlib"
export LD="${CLFS_TARGET}-ld"
export STRIP="${CLFS_TARGET}-strip"

echo export CC=\""${CC}\"" >> ~/.bashrc
echo export CXX=\""${CXX}\"" >> ~/.bashrc
echo export AR=\""${AR}\"" >> ~/.bashrc
echo export AS=\""${AS}\"" >> ~/.bashrc
echo export RANLIB=\""${RANLIB}\"" >> ~/.bashrc
echo export LD=\""${LD}\"" >> ~/.bashrc
echo export STRIP=\""${STRIP}\"" >> ~/.bashrc

printf "\n"
printf "Done!"
printf "\n"

printf "Cross compile tools are finished\n"
printf "If there were no errors continue\n"
printf "With Script #3 that will build the temporary system\n"
printf "\n"

cd
source functions_ownlinux_pre_chroot_c2.sh unsetfcts 
