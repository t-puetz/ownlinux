#!/bin/bash

#Declaration
declare -a tools_pkg_arr

#Variables
PREFIX=/tools
LIBDIR=${PREFIX}/lib64
CLFS=/mnt/clfs
CLFSUSER=clfs
CLFSHOME=${CLFS}/home
CLFSSOURCES=${CLFS}/sources
CLFSTOOLS=${CLFS}/tools
CLFSCROSSTOOLS=${CLFS}/cross-tools
CLFS_HOST=$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')
CLFS_TARGET="x86_64-unknown-linux-gnu"
CLFS_TARGET32="i686-pc-linux-gnu"
BUILD32="-m32"
BUILD64="-m64"
MAKEFLAGS="-j$(expr $(nproc) - 1)"
HOME=${HOME}
TERM=${TERM}
PS1='\u:\w\$ '
LC_ALL=POSIX
PATH=/cross-tools/bin:/bin:/usr/bin

CC="${CLFS_TARGET}-gcc ${BUILD64}"
CXX="${CLFS_TARGET}-g++ ${BUILD64}"
AR="${CLFS_TARGET}-ar"
AS="${CLFS_TARGET}-as"
RANLIB="${CLFS_TARGET}-ranlib"
LD="${CLFS_TARGET}-ld"
STRIP="${CLFS_TARGET}-strip"

source functions_ownlinux_pre_chroot_c3.sh unsetfcts
source functions_ownlinux_pre_chroot_c3.sh exportfcts

tools_pkg_arr=(binutils gcc tcl expect dejagnu m4 
  ncurses bash bison bzip2 coreutils diffutils file findutils gawk 
  gettext grep gzip make patch temp_perl sed tar texinfo util-linux xz nano)

function build_pkg() {
local count=0
for pkg in ${tools_pkg_arr[*]}
do
	local pkg_name=$(conv_meta_to_real_pkg_name_c3 ${tools_pkg_arr[${count}]})
	local pkg_ver=$(get_pkg_ver_c3 ${pkg_name})
	
	echo "==========================="
	echo
	echo "Let's build and install ${pkg_name} / meta name: ${tools_pkg_arr[${count}]}"
	echo "Version ${pkg_ver}"
	echo
	echo "==========================="
	
	checkBuiltPackage

	cd ${CLFSSOURCES}

	if [[ ${tools_pkg_arr[${count}]} = "m4" ]]; then
		extract_pkg_c3 ${pkg_name}-
	
		sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
		echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

		./configure --prefix=${PREFIX} 
		checkBuiltPackage  
		make 
		make install
	
	elif  [[ ${tools_pkg_arr[${count}]} == "check" ]] || [[ ${tools_pkg_arr[${count}]} == "gawk" ]] || \
	[[ ${tools_pkg_arr[${count}]} == "tar" ]] || [[ ${tools_pkg_arr[${count}]} == "xz" ]]; then
		extract_pkg_c3 ${pkg_name}-

	if [[ ${tools_pkg_arr[${count}]} == "texinfo" ]]; then
		sed -i '5481,5485 s/({/(\\{/' tp/Texinfo/Parser.pm  
	fi
	
		./configure --prefix=${PREFIX} \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET} \
		  --libdir=${LIBDIR} 
		checkBuiltPackage  
		make  
		checkBuiltPackage  
		make install

	elif [[ ${tools_pkg_arr[${count}]} == "make" ]]; then
		extract_pkg_c3 ${pkg_name}-

		sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
		checkBuiltPackage

		./configure --prefix=${PREFIX} \
		  --without-guile \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET} \
		  --libdir=${LIBDIR} \
		  --without-guile
		checkBuiltPackage  
		make  
		checkBuiltPackage  
		make install

	elif [[ ${tools_pkg_arr[${count}]} == "patch" ]] || [[ ${tools_pkg_arr[${count}]} == "sed" ]]; then
		extract_pkg_c3 ${pkg_name}-

		./configure --prefix=${PREFIX} \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET} \
		  --libdir=${LIBDIR}
		checkBuiltPackage
		make
		checkBuiltPackage
		make install
	
	elif [[ ${tools_pkg_arr[${count}]} == "autoconf" ]]; then
		extract_pkg_c3 ${pkg_name}-

		./configure --prefix=${PREFIX} \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET} \
		  --libdir=${LIBDIR} 
		checkBuiltPackage  
		make  
		checkBuiltPackage  
		make install

	elif [[ ${tools_pkg_arr[${count}]} == "binutils" ]]; then
		extract_pkg_c3 ${pkg_name}-

		mkdir -v ../${pkg_name}-build
		cd ../${pkg_name}-build

		../${pkg_name}/configure --prefix=${PREFIX} \
		  --libdir=${LIBDIR} \
		  --with-lib-path=${LIBDIR}:${PREFIX}/lib \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET} \
		  --target=${CLFS_TARGET} \
		  --with-sysroot=$CLFS \
		  --disable-nls \
		  --enable-shared \
		  --enable-64-bit-bfd \
		  --enable-gold=yes \
		  --enable-plugins \
		  --with-system-zlib \
		  --enable-threads  

		checkBuiltPackage 
		make  
		checkBuiltPackage  
		make install

		cd ${CLFSSOURCES}
		rm -rf ${pkg_name}-build
	elif [[ ${tools_pkg_arr[${count}]} == "gcc" ]]; then
		extract_pkg_c3 ${pkg_name}-
	
		tar -xf ../mpfr-*.tar.xz
		mv -v mpfr-* mpfr
		tar -xf ../gmp-*.tar.xz
		mv -v gmp-* gmp
		tar -xf ../mpc-*.tar.gz
		mv -v mpc-* mpc
		checkBuiltPackage
	
	
		patch -Np1 -i ../gcc-*-specs-1.patch
		checkBuiltPackage 

		echo -en '\n#undef STANDARD_STARTFILE_PREFIX_1\n#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"\n' >> gcc/config/linux.h
		echo -en '\n#undef STANDARD_STARTFILE_PREFIX_2\n#define STANDARD_STARTFILE_PREFIX_2 ""\n' >> gcc/config/linux.h

		cp -v gcc/Makefile.in{,.orig}
		sed 's@\./fixinc\.sh@-c true@' gcc/Makefile.in.orig > gcc/Makefile.in


		case $(uname -m) in
			x86_64)
			sed -e '/m64=/s/lib64/lib/' \
			  -i.orig gcc/config/i386/t-linux64
			;;
		esac

		mkdir -v ../gcc-build
		cd ../gcc-build

		../${pkg_name}/configure --prefix=${PREFIX}      \
		  --libdir=${LIBDIR}                             \
		  --build=${CLFS_HOST}                           \
		  --host=${CLFS_TARGET}                          \
		  --target=${CLFS_TARGET}                        \
		  --with-local-prefix=${PREFIX}                  \
		  --enable-languages=c,c++                       \
		  --disable-nls                                  \
		  --disable-shared                               \
		  --disable-multilib                             \
		  --disable-decimal-float                        \
		  --disable-threads                              \
		  --disable-libatomic                            \
		  --disable-libgomp                              \
		  --disable-libquadmath                          \
		  --disable-libssp                               \
		  --disable-libvtv                               \
		  --disable-libstdcxx                            \
		  --disable-libstdcxx-ch                         \
		  --with-native-system-header-dir=${PREFIX}/include \
		  --enable-install-libiberty 
	
		checkBuiltPackage 
		make AS_FOR_TARGET="${AS}" LD_FOR_TARGET="${LD}" 
		checkBuiltPackage  
		make install

		cd ${CLFSSOURCES}
		rm -rf ${pkg_name}-build
	elif [[ ${tools_pkg_arr[${count}]} == "ncurses" ]]; then
		extract_pkg_c3 ${pkg_name}-

		sed -i s/mawk// configure

		./configure --prefix=${PREFIX} \
		  --with-shared \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET} \
		  --without-debug \
		  --without-ada \
		  --enable-overwrite \
		  --enable-widec \
		  --with-build-cc=gcc \
		  --libdir=${LIBDIR} 

		checkBuiltPackage 
		make  
		checkBuiltPackage 
		make install
	
		if [[ -f /tools/lib/libncurses.so ]]; then
			unlink /tools/lib/libncurses.so
		fi

		ln -sfv libncursesw.so /tools/lib/libncurses.so

	elif [[ ${tools_pkg_arr[${count}]} == "bash" ]]; then
		extract_pkg_c3 ${pkg_name}-

		./configure --prefix=${PREFIX} \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET} \
		  --without-bash-malloc  

		checkBuiltPackage  
		make  
		checkBuiltPackage  
		make install

		ln -sfv /tools/bin/bash /tools/bin/sh

	elif [[ ${tools_pkg_arr[${count}]} == "bison" ]]; then
		extract_pkg_c3 ${pkg_name}-

		./configure --prefix=${PREFIX}  
		checkBuiltPackage 
		make  
		checkBuiltPackage 
		make install
	
	elif [[ ${tools_pkg_arr[${count}]} == "bzip2" ]]; then
		extract_pkg_c3 ${pkg_name}-

		#Bzip2's default Makefile target automatically runs the test suite as well. 
		#We need to remove the tests since they won't work on a multi-architecture build, and change the default lib path to lib64

		cp -v Makefile{,.orig}
		sed -e 's@^\(all:.*\) test@\1@g' \
		  -e 's@/lib\(/\| \|$\)@/lib64\1@g' Makefile.orig > Makefile

		make CC="${CC}" AR="${AR}" RANLIB="${RANLIB}" 
		checkBuiltPackage 
		make PREFIX=${PREFIX} install

	elif [[ ${tools_pkg_arr[${count}]} == "coreutils" ]]; then
		extract_pkg_c3 ${pkg_name}-

		#patch -Np1 -i ../coreutils-8.30-i18n-1.patch
		#checkBuiltPackage
		#sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk

		#autoreconf -fiv

		./configure --prefix=${PREFIX} \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET} \
		  --enable-install-program=hostname 

		checkBuiltPackage 
		make 
		checkBuiltPackage 
		make install
	elif [[ ${tools_pkg_arr[${count}]} == "diffutils" ]]; then
		extract_pkg_c3 ${pkg_name}-

		./configure --prefix=/${PREFIX} --build=${CLFS_HOST} \
		--host=${CLFS_TARGET} 
		checkBuiltPackage

		make  
		checkBuiltPackage  
		make install
	
	elif [[ ${tools_pkg_arr[${count}]} == "file" ]]; then
		extract_pkg_c3 ${pkg_name}-

		./configure --prefix=${PREFIX} \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET} 
	
		checkBuiltPackage 
		make  
		checkBuiltPackage 
		make install
	
	elif [[ ${tools_pkg_arr[${count}]} == "findutils" ]]; then
		extract_pkg_c3 ${pkg_name}-

		sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
		sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
		echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h

		./configure --prefix=${PREFIX} \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET} 
	
		checkBuiltPackage  
		make  
		checkBuiltPackage  
		make install

	elif [[ ${tools_pkg_arr[${count}]} == "gettext" ]]; then
		extract_pkg_c3 ${pkg_name}-

		./configure --prefix=${PREFIX} \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET} \
		  --disable-shared  
	
		checkBuiltPackage 
		make
		checkBuiltPackage 
	
		cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} ${PREFIX}/bin

	elif [[ ${tools_pkg_arr[${count}]} == "grep" ]]; then
		extract_pkg_c3 ${pkg_name}-

		./configure --prefix=${PREFIX} \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET} \
		  --without-included-regex  

		checkBuiltPackage 
		make  
		checkBuiltPackage  
		make install

	elif [[ ${tools_pkg_arr[${count}]} == "gzip" ]]; then
		extract_pkg_c3 ${pkg_name}-

		./configure --prefix=${PREFIX} \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET} 

		checkBuiltPackage 
		make  
		checkBuiltPackage 
		make install
	
	elif [[ ${tools_pkg_arr[${count}]} == "texinfo" ]]; then
		extract_pkg_c3 ${pkg_name}-
	
		./configure --prefix=/tools \
		  --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET}      
	
	elif [[ ${tools_pkg_arr[${count}]} == "util-linux" ]]; then
		extract_pkg_c3 ${pkg_name}-

		NCURSESW6_CONFIG=" " \
		NCURSES6_CONFIG=" " \
		NCURSESW5_CONFIG=" " \
		NCURSES5_CONFIG=" " \
		./configure --prefix=${PREFIX} \
		--build=${CLFS_HOST} \
		--host=${CLFS_TARGET} \
		--libdir=${PREFIX}/lib64 \
		--datarootdir=${PREFIX}/share \
		--bindir=${PREFIX}/bin \
		--sbindir=${PREFIX}/sbin \
		--disable-makeinstall-chown \
		--disable-makeinstall-setuid \
		--disable-nologin \
		--without-python \
		--without-systemdsystemunitdir 
	
		checkBuiltPackage 
		make prefix=${PREFIX} libdir=${LIBDIR}  
		checkBuiltPackage  
		make prefix=${PREFIX} libdir=${LIBDIR} install
	elif [[ ${tools_pkg_arr[${count}]} == "temp_perl" ]]; then 
	
		checkBuiltPackage
		local pkg_name=$(echo ${pkg_name} | sed 's/temp_//')
		local pkg_ver=$(ls ${CLFSSOURCES} | grep ${pkg_name} | grep tar | sed "s/${pkg_name}\|${pkg_name}-//" | sed \
		  's/.tar.*//')

		extract_pkg_c3 ${pkg_name}-

		sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth

		make

		cp -v perl cpan/podlators/scripts/pod2man /tools/bin
		mkdir -pv /tools/lib/perl5/5.30.0
		cp -Rv lib/* /tools/lib/perl5/5.30.0

	elif [[ ${tools_pkg_arr[${count}]} == "tcl" ]]; then
		extract_pkg_c3 ${pkg_name}
		cd unix

		CC="gcc ${BUILD64}" ./configure --prefix=${PREFIX} --libdir=${LIBDIR} 

		checkBuiltPackage
		make  
		checkBuiltPackage 
		make install  
		checkBuiltPackage 
		chmod -v u+w /tools/lib/libtcl8.6.so
		make install-private-headers  
		checkBuiltPackage 
		ln -sv tclsh8.6 ${PREFIX}/bin/tclsh
	
	elif [[ ${tools_pkg_arr[${count}]} == "expect" ]]; then
		extract_pkg_c3 ${pkg_name}

		cp -v configure{,.orig}
		sed 's:/usr/local/bin:/bin:' configure.orig > configure
	
		CC="gcc ${BUILD64}" \
		./configure --prefix=${PREFIX} \
		  --with-tcl=${LIBDIR} \
		  --with-tclinclude=${PREFIX}/include \
		  --libdir=${LIBDIR}  

		checkBuiltPackage 
		make  
		checkBuiltPackage 
		make test 
		checkBuiltPackage  
		make SCRIPTS="" install

	elif [[ ${tools_pkg_arr[${count}]} == "dejagnu" ]]; then
		extract_pkg_c3 ${pkg_name}-
	
		./configure --prefix=${PREFIX} \
		  --libdir=${LIBDIR}

		checkBuiltPackage  
		make
		checkBuiltPackage  
		make install
		checkBuiltPackage  
	
	elif [[ ${tools_pkg_arr[${count}]} == "nano" ]]; then    
		extract_pkg_c3 ${pkg_name}-
 
		./configure --prefix=${PREFIX} --libdir=${PREFIX}/lib64 \
		  --enable-utf8 --sysconfdir=${PREFIX}/etc \
		  --build=${CLFS_HOST} --disable-libmagic --host=${CLFS_TARGET} 

		checkBuiltPackage 
		make 
		checkBuiltPackage 
		make install
	
	elif [[ ${tools_pkg_arr[${count}]} == "vim" ]]; then
		extract_pkg_c3 ${pkg_name}-

		touch src/auto/config.cache
		echo "vim_cv_getcwd_broken=no" > src/auto/config.cache
		echo "vim_cv_memmove_handles_overlap=yes" >> src/auto/config.cache
		echo "vim_cv_stat_ignores_slash=no" >> src/auto/config.cache
		echo "vim_cv_terminfo=yes" >> src/auto/config.cache
		echo "vim_cv_toupper_broken=no" >> src/auto/config.cache
		echo "vim_cv_tty_group=world" >> src/auto/config.cache
		echo "vim_cv_tgent=zero" >> src/auto/config.cache
		echo "vim_cv_tgetent=zero" >> src/auto/config.cache
	
		echo '#define SYS_VIMRC_FILE "/tools/etc/vimrc"' >> src/feature.h
	
		./configure --build=${CLFS_HOST} \
		  --host=${CLFS_TARGET} \
		  --prefix=${PREFIX} \
		  --enable-gui=no \
		  --disable-gtktest \
		  --disable-xim \
		  --disable-gpm \
		  --without-x \
		  --disable-netbeans \
		  --with-tlib=ncurses \
		  --cache-file=src/auto/config.cache 

		checkBuiltPackage  
		make  
		checkBuiltPackage  
		cd src
		make -j1 install

		touch /tools/etc/vimrc
		echo "\" Begin /tools/etc/vimrc" > /tools/etc/vimrc
		echo "set nocompatible" >> /tools/etc/vimrc
		echo "set backspace=2" >> /tools/etc/vimrc
		echo "set ruler" >> /tools/etc/vimrc
		echo "syntax on" >> /tools/etc/vimrc
		echo "\" End of /tools/etc/vimrc" >> /tools/etc/vimrc

		ln -sv /tools/bin/vim /tools/bin/vi
		ln -sv /tools/bin/bash /tools/bin/sh
	fi

	cd ${CLFSSOURCES}
	checkBuiltPackage
	rm -rf ${pkg_name}
	count=$(expr ${count} + 1)
done
}

printf "Let's build the temporary system\n"
printf "It will contain the toolchain that will be used to build our final system\n"
printf "The temporary system's toolchain in turn is compiled by the cross compile toolchain\n"
printf "we build in the script before.\n"

printf "\n"
echo "Before we start let's check our environment\n"

env
checkBuiltPackage

build_pkg

#Echoing out some stuff to help you chose boot or chroot option

printf "Echoing out some stuff to help you chose boot or chroot option\n"
printf "\n"
printf "Executing /tools/lib/libc.so.6 ...\n"
printf "\n"
/tools/lib/libc.so.6
printf "\n"
printf "Executing /tools/lib64/libc.so.6 ...\n"
printf
/tools/lib64/libc.so.6
printf "\n"
printf "Executing /tools/bin/gcc -v ...\n"
/tools/bin/gcc -v
printf "\n"

printf "\n"
printf "If all 3 commands output reasonable messages without errors\n"
printf "You can chroot\n"
printf "However, you ONLY chroot if your TARGET architecture is the same as your SOURCE!\n"

printf "\n"

printf "The temporary system is done\n"
printf "If there were no errors continue\n"
printf "\n"
printf "Exit as CLFS back into your host's ROOT shell\n"
printf "Execute Script #4\n"
printf "Execute Script #5 inside CHROOT with BASH NOT SH!!!\n"

cd 
source functions_ownlinux_pre_chroot_c3.sh unsetfcts
