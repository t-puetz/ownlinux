#!/bin/bash

#Building the final CLFS System
PREFIX=/usr
LIBDIR32=${PREFIX}/lib
LIBDIR64=${PREFIX}/lib64
CLFS=/
CLFSSOURCES=/sources
CLFSTOOLS=/tools
MAKEFLAGS="-j$(expr $(nproc) - 1)"
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
	local glibc_ver=$(/tools/bin/ldd --version | head -n 1 |awk '{print $4}')
	printf "${glibc_ver}"
}

function get_gcc_ver() {
	local glibc_ver=$(ls ${CLFSSOURCES} | grep 'gcc' | grep 'tar' | sed 's/gcc\|gcc-//' | awk '{print $9}' | sed 's/.tar.*//')
	printf "${glibc_ver}"
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
	local pkg_ver=$(ls ${CLFSSOURCES} | egrep ^${pkg_name} | grep tar | sed "s/${pkg_name}\|${pkg_name}-//" | sed \
	  's/.tar.*//' | head -n 1 | sed -E 's/\([[:punct:]][[:digit:]]?\)//g')

	printf "${pkg_ver}"
}

function conv_meta_to_real_pkg_name() {
	local meta_name=$1
	local real_name=$(echo ${meta_name} | sed 's/temp_\|_x86\|_x64\|_headers//')
	local real_name=$(echo ${real_name} | sed 's/temp_\|_x86\|_x64\|_headers//')
	local real_name=$(echo ${real_name} | sed 's/_1\|__1\|_2\|__2//')

	printf "${real_name}"
}

function checkBuiltPackage() {
	printf "\n"
	printf "Is everything looking alright?: [Y/N]\n"
	while read -n1 -r -p "[Y/N]   " && [[ $REPLY != q ]]; do
		case $REPLY in
			Y) break 1;;
			N) printf "$EXIT\n"
			  printf "Fix it!\n"
			  exit 1;;
			*) printf " Try again. Type y or n\”";;
		esac
	done
	printf "\n" 
}

declare -a finalsys_pkg_arr=()

function isToolchainAdjustedAlready() {
	printf "\n"
	printf "Was the toolchain adjusted already? It maybe was if you already ran this script once.: [Y/N]\n"
	printf "If you run this script for the FIRST time you MUST hit N!!!\n"
	while read -n1 -r -p "[Y/N]   " && [[ $REPLY != q ]]; do
		case $REPLY in
			Y) fill_arr_alt=1
			  break 1;;
			N) fill_arr_alt=0 
			  break 1;;
			*) printf " Try again. Type y or n\n";;
		esac
	done
	printf "\n"
}

if [[ ${fill_arr_alt} == 1 ]]; then
	finalsys_pkg_arr=(texinfo gmp_x86 gmp_x64 mpfr_x86 mpfr_x64 mpc_x64 mpc_x86 zlib_x64 zlib_x86 flex_x64 
	flex_x86 binutils gcc multiarch_wrapper attr_x64 attr_x86 acl_x64 acl_x86 libcap_x86 libcap_x64 sed
	pkg-config-lite ncurses_x86 ncurses_x64 shadow util_linux_x86 util_linux_x64_1 procps-ng_x86 procps-ng_x64 e2fsprogs_x86 
	e2fsprogs_x64 coreutils iana-etc libtool_x86 libtool_x64 iproute2 bzip2_x86 bzip2_x64 gdbm_x86 gdbm_x64 perl_x86 
	perl_x64 readline_x86 readline_x64 autoconf automake bash)
else
	finalsys_pkg_arr=(temp_perl_x86 rsync linux_headers man-pages m4 bison_x86 bison_x64 glibc_x86 glibc_x64  
    adjust_toolchain texinfo gmp_x64 gmp_x86 mpfr_x64 mpfr_x86 mpc_x64 mpc_x86 zlib_x64 zlib_x86 flex_x86 
    flex_x64 gcc multiarch_wrapper attr_x64 attr_x86 acl_x64 acl_x86 libcap_x86 libcap_x64 sed pkg-config-lite
	ncurses_x86 ncurses_x64 shadow util_linux_x86 util_linux_x64_1 procps-ng_x86 procps-ng_x64 e2fsprogs_x86 
    e2fsprogs_x64 coreutils iana-etc libtool_x86 libtool_x64 iproute2 bzip2_x86 bzip2_x64 gdbm_x86 gdbm_x64
    perl_x86 perl_x64 readline_x86 readline_x64 autoconf automake bash) 
fi

isToolchainAdjustedAlready

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

	printf "Let's build and install ${finalsys_pkg_arr[${count}]}\n"
	printf "Real package name is: ${pkg_name}\n"
	printf "Version ${pkg_ver}\n"
	printf "Glibc version: ${glibc_ver}\n"
	checkBuiltPackage

	cd ${CLFSSOURCES}

	if [[ ${finalsys_pkg_arr[${count}]} == "linux_headers" ]]; then
		extract_pkg ${pkg_name}-

		make mrproper 
		checkBuiltPackage
		make INSTALL_HDR_PATH=/usr headers_install 
		checkBuiltPackage
		find /usr/include -name .install -or -name ..install.cmd | xargs rm -fv
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "man-pages" ]]; then
		extract_pkg ${pkg_name}-
	
		make install
	elif [[ ${finalsys_pkg_arr[${count}]} == "m4" ]]; then
		extract_pkg ${pkg_name}-
	
		if [[ ${glibc_ver_ge_2point28} == 0 ]]; then
			sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
			echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
		fi
	
		checkBuiltPackage
	
		CC="gcc ${BUILD64}" PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
		  ./configure --prefix=/usr 
	
		checkBuiltPackage
		make 
		checkBuiltPackage
		make check 
		checkBuiltPackage
		make install
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "temp_perl_x86" ]]; then
		extract_pkg ${pkg_name}-
	
		sed -i 's@/usr/include@/tools/include@g' ext/Errno/Errno_pm.PL

		./configure.gnu --prefix=/tools -Dcc="gcc ${BUILD32}" 
		checkBuiltPackage
		make 
		checkBuiltPackage
		make install 
		checkBuiltPackage
		ln -sfv /tools/bin/perl /usr/bin
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "bison_x86" ]]; then
		extract_pkg ${pkg_name}-
	
		CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" \
		  ./configure --prefix=${PREFIX} --libdir=${LIBDIR32} 
	
		checkBuiltPackage
		make 
		checkBuiltPackage
		make check 
		checkBuiltPackage
		make install
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "bison_x64" ]]; then
		extract_pkg ${pkg_name}-
	
		CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
		./configure --prefix=${PREFIX} --libdir=${LIBDIR64} \
		  --docdir=/usr/share/doc/${pkg_name}-${pkg_ver} 
	
		checkBuiltPackage
		make 
		checkBuiltPackage
		make check 
		checkBuiltPackage
		make install 
		checkBuiltPackage
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "glibc_x86" ]]; then
		extract_pkg ${pkg_name}-

		patch -Np1 -i ../glibc-2.2*-fhs-1.patch

		rm -rf /usr/include/limits.h

		LINKER=$(readelf -l /tools/bin/bash | sed -n 's@.*interpret.*/tools\(.*\)]$@\1@p')
		sed -i "s|libs -o|libs -L${LIBDIR32} -Wl,-dynamic-linker=${LINKER} -o|" \
		scripts/test-installation.pl
		unset LINKER

		mkdir -v ../${pkg_name}-build
		cd ../${pkg_name}-build

		CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" \
		../${pkg_name}/configure --prefix=${PREFIX} \
		  --enable-kernel=4.0 \
		  --libexecdir=${LIBDIR32}/${pkg_name} \
		  --libdir=${LIBDIR32} \
		  --host=${CLFS_TARGET32} \
		  --enable-stack-protector=strong \
		  --disable-werror \
		  libc_cv_slibdir=/lib
	
		checkBuiltPackage

		make 
		checkBuiltPackage
		sed -i '/cross-compiling/s@ifeq@ifneq@g' ../${pkg_name}/localedata/Makefile
		make check 
		checkBuiltPackage
		touch /etc/ld.so.conf
		make install 
		checkBuiltPackage
		rm -v /usr/include/rpcsvc/*.x
	
		cd ${CLFSSOURCES}
		rm -rf glibc-build
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "glibc_x64" ]]; then
		extract_pkg ${pkg_name}-
 
		patch -Np1 -i ../glibc-2.2*-fhs-1.patch

		rm -rf /usr/include/limits.h
	
		patch -Np1 -i ../glibc-2.2*-fhs-1.patch

		LINKER=$(readelf -l /tools/bin/bash | sed -n 's@.*interpret.*/tools\(.*\)]$@\1@p')
		sed -i "s|libs -o|libs -L${LIBDIR64} -Wl,-dynamic-linker=${LINKER} -o|" \
		scripts/test-installation.pl
		unset LINKER

		echo "libc_cv_slibdir=/lib64" >> config.cache

		mkdir -v ../${pkg_name}-build
		cd ../${pkg_name}-build
	
		checkBuiltPackage

		CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
		../${pkg_name}/configure --prefix=${PREFIX} \
		--enable-kernel=4.0 \
		--libexecdir=${LIBDIR64}/${pkg_name} \
		--libdir=${LIBDIR64} \
		--enable-stack-protector=strong \
		--cache-file=config.cache \
		--disable-werror
	
		checkBuiltPackage
		make 
		checkBuiltPackage
		make check 
		checkBuiltPackage
		make install 
		rm -v /usr/include/rpcsvc/*.x
		checkBuiltPackage

		cp -v ../${pkg_name}/nscd/nscd.conf /etc/nscd.conf
		mkdir -pv /var/cache/nscd
	
		mkdir -pv ${LIBDIR32}/locale
		make localedata/install-locales

		touch /etc/nsswitch.conf
		echo "# Begin /etc/nsswitch.conf" > /etc/nsswitch.conf

		echo "passwd: files" >> /etc/nsswitch.conf
		echo "group: files" >> /etc/nsswitch.conf
		echo "shadow: files" >> /etc/nsswitch.conf

		echo "hosts: files dns" >> /etc/nsswitch.conf
		echo "networks: files" >> /etc/nsswitch.conf

		echo "protocols: files" >> /etc/nsswitch.conf
		echo "services: files" >> /etc/nsswitch.conf
		echo "ethers: files" >> /etc/nsswitch.conf
		echo "rpc: files" >> /etc/nsswitch.conf

		echo "# End /etc/nsswitch.conf" >> /etc/nsswitch.conf
	
		tar -xf ../tzdata20*.tar.*
	
		checkBuiltPackage

		ZONEINFO=/usr/share/zoneinfo
		mkdir -pv $ZONEINFO/{posix,right}

		for tz in etcetera southamerica northamerica europe africa antarctica \
		  asia australasia backward pacificnew systemv
		do
			zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
			zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
			zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
		done

		cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
		zic -d $ZONEINFO -p America/New_York
		unset ZONEINFO

		tzselect
	
		echo
		echo "Chose your timezone in a format such as Europe/Berlin"
		echo

		read tzone

		ln -sfv /usr/share/zoneinfo/${tzone} /etc/localtime
	
		checkBuiltPackage

		touch /etc/ld.so.conf
		echo "# Begin /etc/ld.so.conf" > /etc/ld.so.conf

		echo "/lib" >> /etc/ld.so.conf
		echo "/lib64" >> /etc/ld.so.conf
		echo "${LIBDIR32}" >> /etc/ld.so.conf
		echo "${LIBDIR64}" >> /etc/ld.so.conf
		echo "/usr/local/lib" >> /etc/ld.so.conf
		echo "/usr/local/lib64" >> /etc/ld.so.conf
		echo "/opt/lib" >> /etc/ld.so.conf
		echo "/opt/lib64" >> /etc/ld.so.conf

		echo "# End /etc/ld.so.conf" >> /etc/ld.so.conf

		mkdir -pv /etc/ld.so.conf.d
	
		cd ${CLFSSOURCES}
		rm -rf glibc-build
	
	elif [[ ${pkg_name} == "adjust_toolchain" ]]; then
	
		#Adjusting the toolchain
		gcc -dumpspecs | \
		perl -p -e 's@/tools/lib/ld@/lib/ld@g;' \
		-e 's@/tools/lib64/ld@/lib64/ld@g;' \
		-e 's@\*startfile_prefix_spec:\n@$_${LIBDIR32}/ @g;' > \
		$(dirname $(gcc --print-libgcc-file-name))/specs

		echo 'int main(){}' > dummy.c
		gcc ${BUILD32} dummy.c
		readelf -l a.out | grep ': /lib'

		checkBuiltPackage

		echo 'main(){}' > dummy.c
		gcc ${BUILD64} dummy.c
		readelf -l a.out | grep ': /lib'

		rm -v dummy.c a.out
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "zlib_x86" ]]; then
		extract_pkg ${pkg_name}-
	
		CC="gcc -isystem /usr/include ${BUILD32}" \
		  CXX="g++ -isystem /usr/include ${BUILD32}" \
		  LDFLAGS="-Wl,-rpath-link,${LIBDIR32}:/lib ${BUILD32}" \
		  ./configure --prefix=${PREFIX} 
	
		checkBuiltPackage
	
		make
		checkBuiltPackage
		make check
		checkBuiltPackage
		make install
		checkBuiltPackage

		mv -v ${LIBDIR32}/libz.so.* /lib
		ln -sfv ../../lib/$(readlink ${LIBDIR32}/libz.so) ${LIBDIR32}/libz.so

	elif [[ ${finalsys_pkg_arr[${count}]} == "zlib_x64" ]]; then
		extract_pkg ${pkg_name}-
	
		CC="gcc -isystem /usr/include ${BUILD64}" \
		  CXX="g++ -isystem /usr/include ${BUILD64}" \
		  LDFLAGS="-Wl,-rpath-link,${LIBDIR64}:/lib64 ${BUILD64}" \
		  ./configure --prefix=${PREFIX} --libdir=${LIBDIR64} 
	
		checkBuiltPackage
	
		make
		checkBuiltPackage
		make check
		checkBuiltPackage
		make install
		checkBuiltPackage

		mv -v ${LIBDIR64}/libz.so.* /lib64
		ln -sfv ../../lib64/$(readlink ${LIBDIR64}/libz.so) ${LIBDIR64}/libz.so

	elif [[ ${finalsys_pkg_arr[${count}]} == "file_x86" ]]; then
		extract_pkg ${pkg_name}-
	
		CC="gcc ${BUILD32}" \
		./configure --prefix=${PREFIX}

		make
		checkBuiltPackage
		make check
		checkBuiltPackage
		make install
		checkBuiltPackage
	elif [[ ${finalsys_pkg_arr[${count}]} == "file_x64" ]]; then
		extract_pkg ${pkg_name}-
	
		CC="gcc ${BUILD32}" \
		  ./configure --prefix=${PREFIX}
	
		checkBuiltPackage
		make
		checkBuiltPackage
		make install
		checkBuiltPackage
	elif [[ ${finalsys_pkg_arr[${count}]} == "flex_x64" ]]; then
		extract_pkg ${pkg_name}-
	
		CC="gcc ${BUILD64}" \
		  ./configure --prefix=${PREFIX} --libdir=${LIBDIR64} \
		  --docdir=/usr/share/doc/${pkg_name}-${pkg_ver}
	
		checkBuiltPackage
		make
		checkBuiltPackage
		make install
		checkBuiltPackage 
	elif [[ ${finalsys_pkg_arr[${count}]} == "flex_x64" ]]; then
		extract_pkg ${pkg_name}-
	
		CC="gcc ${BUILD64}" \
		  ./configure --prefix=/usr --libdir=${LIBDIR64}

		make
		checkBuiltPackage
		make check
		checkBuiltPackage
		make install
		checkBuiltPackage
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "ncurses_x86" ]]; then
		extract_pkg ${pkg_name}-
	
		sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in

		CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" \
		  ./configure --prefix=/usr \
		  --libdir=${LIBDIR32} \
		  --with-shared \
		  --without-normal \
		  --without-debug \
	 	  --enable-widec \
		  --enable-pc-files
	
		checkBuiltPackage

		make
		checkBuiltPackage
		make install
		checkBuiltPackage
	
		mv -v /usr/bin/ncursesw6-config{,-32}
		mv -v ${LIBDIR32}/libncursesw.so.* /lib
		ln -svf ../../lib/$(readlink ${LIBDIR32}/libncursesw.so) ${LIBDIR32}/libncursesw.so

		for lib in ncurses form panel menu
		do
			rm -vf                    ${LIBDIR32}/lib${lib}.so
			echo "INPUT(-l${lib}w)" > ${LIBDIR32}/lib${lib}.so
			ln -sfv ${lib}w.pc        ${LIBDIR32}/pkgconfig/${lib}.pc
		done

		rm -vf                     ${LIBDIR32}/libcursesw.so
		echo "INPUT(-lncursesw)" > ${LIBDIR32}/libcursesw.so
		ln -sfv libncurses.so      ${LIBDIR32}/libcurses.so

		ln -sfv libncurses++w.a ${LIBDIR32}/libncurses++.a
		ln -sfv ncursesw6-config-32 /usr/bin/ncurses6-config-
	
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "ncurses_x64" ]]; then
		extract_pkg ${pkg_name}-
	
		sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in

		CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
		  ./configure --prefix=/usr \
		  --without-normal \
		  --libdir=${LIBDIR64} \
		  --with-shared \
		  --without-debug \
		  --enable-widec \
		  --enable-pc-files \
		  --with-pkg-config-libdir=${LIBDIR64}/pkgconfig
	
		checkBuiltPackage    
		make
		checkBuiltPackage
		make install
		checkBuiltPackage

		mv -v /usr/bin/ncursesw6-config{,-64}
		ln -svf multiarch_wrapper /usr/bin/ncursesw6-config
		mv -v ${LIBDIR64}/libncursesw.so.* /lib64
		ln -svf ../../lib64/$(readlink ${LIBDIR64}/libncursesw.so) ${LIBDIR64}/libncursesw.so

		for lib in ncurses form panel menu
		do
			rm -vf                    ${LIBDIR64}/lib${lib}.so
			echo "INPUT(-l${lib}w)" > ${LIBDIR64}/lib${lib}.so
			ln -sfv ${lib}w.pc        ${LIBDIR64}/pkgconfig/${lib}.pc
		done

		ln -sfv libncurses++w.a ${LIBDIR64}/libncurses++.a
		ln -sfv ncursesw6-config-64 /usr/bin/ncurses6-config-64
		ln -sfv ncursesw6-config /usr/bin/ncurses6-config

		rm -vf                     ${LIBDIR64}/libcursesw.so
		echo "INPUT(-lncursesw)" > ${LIBDIR64}/libcursesw.so
		ln -sfv libncurses.so      ${LIBDIR64}/libcurses.so

		mkdir -v       /usr/share/doc/${pkg_name}-${pkg_ver}
		cp -v -R doc/* /usr/share/doc/${pkg_name}-${pkg_ver}      
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "readline_x86" ]]; then
		extract_pkg ${pkg_name}-
	
		sed -i '/MV.*old/d' Makefile.in
		sed -i '/{OLDSUFF}/c:' support/shlib-install

		patch -Np1 -i ../readline-7.0-branch_update-1.patch
		checkBuiltPackage

		sed -i '/MV.*old/d' Makefile.in
		sed -i '/{OLDSUFF}/c:' support/shlib-install

		CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" \
		  ./configure --prefix=/usr --libdir=/lib
	
		checkBuiltPackage
		make SHLIB_LIBS="-L/tools/lib -lncursesw"
		checkBuiltPackage
		make SHLIB_LIBS="-L/tools/lib -lncursesw" install
		checkBuiltPackage

		mv -v ${LIBDIR32}/lib{readline,history}.so.* /lib
		chmod -v u+w /lib/lib{readline,history}.so.*
		ln -sfv ../../lib/$(readlink ${LIBDIR32}/libreadline.so) ${LIBDIR32}/libreadline.so
		ln -sfv ../../lib/$(readlink ${LIBDIR32}/libhistory.so ) ${LIBDIR32}/libhistory.so
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "readline_x64" ]]; then
		extract_pkg ${pkg_name}-
	
		patch -Np1 -i ../readline-7.0-branch_update-1.patch
		checkBuiltPackage
	
		sed -i '/MV.*old/d' Makefile.in
		sed -i '/{OLDSUFF}/c:' support/shlib-install
	
		CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
		  ./configure --prefix=/usr \
		  --libdir=/lib64 \
		  --docdir=/usr/share/doc/readline-7.0
	
		checkBuiltPackage
		make SHLIB_LIBS="-L/tools/lib64 -lncursesw"
		checkBuiltPackage
		make SHLIB_LIBS="-L/tools/lib64 -lncursesw" install
		checkBuiltPackage
	
		mv -v ${LIBDIR64}/lib{readline,history}.so.* /lib64
		chmod -v u+w /lib64/lib{readline,history}.so.*
		ln -sfv ../../lib64/$(readlink ${LIBDIR32}/libreadline.so) ${LIBDIR64}/libreadline.so
		ln -sfv ../../lib64/$(readlink ${LIBDIR32}/libhistory.so ) ${LIBDIR64}/libhistory.so
	
		install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-7.0 
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "texinfo" ]]; then
		extract_pkg ${pkg_name}-
	
		sed -i '5481,5485 s/({/(\\{/' tp/Texinfo/Parser.pm

		USE_ARCH=64 PERL=/usr/bin/perl-64 CC="gcc ${BUILD64}" \
		  ./configure --prefix=/usr \
		  --disable-static \
		  --libdir=${LIBDIR64} \
		  gl_cv_func_getopt_gnu=yes
	
		checkBuiltPackage
	
		#Concerning the last line above
		#Needed for version 3.6 with glibc 2.26
		#Probably can be ommited again for later diffutil versions
		#https://patchwork.ozlabs.org/patch/809145/
	
		LIBDIR=${LIBDIR64} PREFIX=/usr make 
		checkBuiltPackage
		LIBDIR=${LIBDIR64} PREFIX=/usr make install
		checkBuiltPackage
		LIBDIR=${LIBDIR64} PREFIX=/usr make TEXMF=/usr/share/texmf install-tex
		checkBuiltPackage
	
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "bc" ]]; then
		extract_pkg ${pkg_name}-
	
		touch bc/fix-libmath_h 
		echo "#! /bin/bash" > bc/fix-libmath_h 
		echo "sed -e '1   s/^/{"/' -e     's/$/",/' -e '2,$ s/^/\"/' -e '$ d' -i libmath.h" >> bc/fix-libmath_h
		echo "sed -e '$ s/$/0}/' -i libmath.h" >> bc/fix-libmath_h
	
	
		ln -sv /tools/lib64/libncursesw.so.6 ${LIBDIR64}/libncursesw.so.6
		ln -sfv libncurses.so.6 ${LIBDIR64}/libncurses.so
		sed -i -e '/flex/s/as_fn_error/: ;; # &/' configure
	
		CC="gcc ${BUILD64}" ./configure --prefix=/usr \
		  --with-readline \
		  --mandir=/usr/share/man \
		  --infodir=/usr/share/info
	
		make
		echo "quit" | ./bc/bc -l Test/checklib.b
		checkBuiltPackage
		make install
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "binutils" ]]; then
		extract_pkg ${pkg_name}- 
	
		expect -c "spawn ls"
		checkBuiltPackage
	
		mkdir -v ../${pkg_name}-build
		cd ../${pkg_name}-build
	
		CC="gcc -isystem /usr/include ${BUILD64}" \
		  LDFLAGS="-Wl,-rpath-link,${LIBDIR64}:/lib64:${LIBDIR32}:/lib ${BUILD64}" \
		  ../${pkg_name}/configure --prefix=${PREFIX} \
		  --enable-shared \
		  --enable-64-bit-bfd \
		  --libdir=${LIBDIR64} \
		  --enable-gold=yes \
		  --enable-ld=default \
		  --enable-plugins \
		  --with-system-zlib 
          
		checkBuiltPackage
		make tooldir=${PREFIX}
		checkBuiltPackage
		make check
		checkBuiltPackage
		make tooldir=${PREFIX} install
	
		cd ${CLFSSOURCES}
		rm -rf ${pkg_name}-build

	elif [[ ${finalsys_pkg_arr[${count}]} == "gmp_x86" ]]; then
		extract_pkg ${pkg_name}-
	
		CC="gcc -isystem /usr/include ${BUILD32}" \
		  CXX="g++ -isystem /usr/include ${BUILD32}" \
		  LDFLAGS="-Wl,-rpath-link,${LIBDIR32}:/lib ${BUILD32}" \
		  ABI=32 ./configure --prefix=${PREFIX} --enable-cxx \
		  --libdir=${LIBDIR32}
	
		  checkBuiltPackage
		  make
		  checkBuiltPackage
		  make check
		  checkBuiltPackage
	
		  make install
		  mv -v /usr/include/gmp{,-32}.h

	elif [[ ${finalsys_pkg_arr[${count}]} == "gmp_x64" ]]; then
		extract_pkg ${pkg_name}-
	
		CC="gcc -isystem /usr/include ${BUILD64}" \
		  CXX="g++ -isystem /usr/include ${BUILD64}" \
		  LDFLAGS="-Wl,-rpath-link,${LIBDIR64}:/lib64 ${BUILD64}" \
		  ./configure --prefix=${PREFIX} \
		  --libdir=${LIBDIR64} \
		  --enable-cxx \
		  --docdir=${PREFIX}/share/doc/${pkg_name}-${pkg_ver}
	
		checkBuiltPackage
		make
		checkBuiltPackage
		make html
		checkBuiltPackage
		make check
		checkBuiltPackage
		make install
		checkBuiltPackage
		make install-html
		checkBuiltPackage
	
		mv -v /usr/include/gmp{,-64}.h
	
		echo "/* gmp.h - Stub Header  */" > /usr/include/gmp.h 
		echo "#ifndef __STUB__GMP_H__" >> /usr/include/gmp.h
		echo "#define __STUB__GMP_H__" >> /usr/include/gmp.h
		echo "#if defined(__x86_64__) || \\" >> /usr/include/gmp.h
		echo "  defined(__sparc64__) || \\" >> /usr/include/gmp.h
		echo "  defined(__arch64__) || \\" >> /usr/include/gmp.h
		echo "  defined(__powerpc64__) || \\" >> /usr/include/gmp.h
		echo "  defined (__s390x__)" >> /usr/include/gmp.h
		echo "# include \"gmp-64.h\"" >> /usr/include/gmp.h
		echo "#else" >> /usr/include/gmp.h
		echo "# include \"gmp-32.h\"" >> /usr/include/gmp.h
		echo "#endif" >> /usr/include/gmp.h
		echo "#endif /* __STUB__GMP_H__ */" >> /usr/include/gmp.h

	elif [[ ${finalsys_pkg_arr[${count}]} == "mpfr_x86" ]]; then
		extract_pkg ${pkg_name}-
	
		PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
		CC="gcc -isystem /usr/include ${BUILD32}" \
		LDFLAGS="-Wl,-rpath-link,${LIBDIR32}:/lib ${BUILD32}" \
		./configure --prefix=${PREFIX} --libdir=${LIBDIR32} \
		--host=${CLFS_TARGET32}  
	
		checkBuiltPackage
		make
		checkBuiltPackage
		make html
		checkBuiltPackage
		make check
		checkBuiltPackage 
		make install
		checkBuiltPackage
		make install-html
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "mpfr_x64" ]]; then
		extract_pkg ${pkg_name}-
	
		PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
		CC="gcc -isystem /usr/include ${BUILD64}" \
		LDFLAGS="-Wl,-rpath-link,${LIBDIR64}:/lib64 ${BUILD64}" \
		./configure --prefix=/usr --libdir=${LIBDIR64} \
		  --docdir=${PREFIX}/share/doc/${pkg_name}-${pkg_ver} 
	
		checkBuiltPackage
		make
		checkBuiltPackage
		make html
		checkBuiltPackage
		make check
		checkBuiltPackage 
		make install
		checkBuiltPackage
		make install-html
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "mpc_x86" ]]; then
		extract_pkg ${pkg_name}-
	
		PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
		CC="gcc -isystem /usr/include ${BUILD32}" \
		LDFLAGS="-Wl,-rpath-link,${LIBDIR32}:/lib ${BUILD32}" \
		./configure --prefix=${PREFIX} --libdir=${LIBDIR32} \
		  --host=${CLFS_TARGET32} --libdir=${LIBDIR32}
	
		checkBuiltPackage
		make
		checkBuiltPackage
		make check
		checkBuiltPackage 
		make install
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "mpc_x64" ]]; then
		extract_pkg ${pkg_name}-
	
		PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
		CC="gcc -isystem /usr/include ${BUILD64}" \
		LDFLAGS="-Wl,-rpath-link,${LIBDIR64}:/lib64 ${BUILD64}" \
		./configure --prefix=${PREFIX} --libdir=${LIBDIR64} \
		  --docdir=${PREFIX}/share/doc/${pkg_name}-${pkg_ver}          
	
		checkBuiltPackage
		make 
		checkBuiltPackage
		make html
		checkBuiltPackage
		make check
		checkBuiltPackage 
		make install
		checkBuiltPackage
		make install-html
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "gcc" ]]; then
		extract_pkg ${pkg_name}-
	
		sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in

		mkdir -v ../${pkg_name}-build
		cd ../${pkg_name}-build
	
		SED=sed CC="gcc -isystem /usr/include ${BUILD64}" \
		  CXX="g++ -isystem /usr/include ${BUILD64}" \
		  LDFLAGS="-Wl,-rpath-link,${LIBDIR64}:/lib64:${LIBDIR32}:/lib" \
		  ../${pkg_name}/configure \
		  --prefix=${PREFIX} \
		  --libdir=${LIBDIR64} \
		  --libexecdir=${PREFIX}/lib64 \
		  --enable-languages=c,c++ \
		  --with-system-zlib \
          --disable-bootstrap
	
		checkBuiltPackage
		make
		checkBuiltPackage
		ulimit -s 32768
		make -k check
		../${pkg_name}/contrib/test_summary
		checkBuiltPackage
	
		make install
		checkBuiltPackage
		ln -sv ../usr/bin/cpp /lib
		ln -sv gcc /usr/bin/cc
		install -v -dm755 ${LIBDIR32}/bfd-plugins
		ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/${gcc_ver}/liblto_plugin.so \
		${LIBDIR32}/bfd-plugins/
		mkdir -pv /usr/share/gdb/auto-load${LIBDIR32}
		mv -v ${LIBDIR32}/*gdb.py /usr/share/gdb/auto-load${LIBDIR32}
		mv -v ${LIBDIR32}/libstdc++*gdb.py /usr/share/gdb/auto-load${LIBDIR32}
		mv -v ${LIBDIR64}/libstdc++*gdb.py /usr/share/gdb/auto-load${LIBDIR64}
	
		cd ${CLFSSOURCES}
		rm -rf ${pkg_name}-build
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "multiarch_wrapper" ]]; then
		#Creating a multiarch wrapper

		cat > multiarch_wrapper.c <<-EOF
		#define _GNU_SOURCE

		#include <errno.h>
		#include <stdio.h>
		#include <stdlib.h>
		#include <sys/types.h>
		#include <sys/wait.h>
		#include <unistd.h>

		#ifndef DEF_SUFFIX
		#  define DEF_SUFFIX "64"
		#endif

		int main(int argc, char **argv)
		{
		  char *filename;
		  char *suffix;

		  if(!(suffix = getenv("USE_ARCH")))
		    if(!(suffix = getenv("BUILDENV")))
		      suffix = DEF_SUFFIX;

		  if (asprintf(&filename, "%s-%s", argv[0], suffix) < 0) {
		    perror(argv[0]);
		    return -1;
		  }

		  int status = EXIT_FAILURE;
		  pid_t pid = fork();

		  if (pid == 0) {
		    execvp(filename, argv);
		    perror(filename);
		  } else if (pid < 0) {
		    perror(argv[0]);
		  } else {
		    if (waitpid(pid, &status, 0) != pid) {
		      status = EXIT_FAILURE;
		      perror(argv[0]);
		    } else {
		      status = WEXITSTATUS(status);
		    }
		  }

          free(filename);

          return status;
        }

		EOF
		
		gcc ${BUILD64} multiarch_wrapper.c -o /usr/bin/multiarch_wrapper
		checkBuiltPackage

		echo 'echo "32bit Version"' > test-32
		echo 'echo "64bit Version"' > test-64
		chmod -v 755 test-32 test-64
		ln -sv /usr/bin/multiarch_wrapper test

		checkBuiltPackage

		USE_ARCH=32 ./test
		USE_ARCH=64 ./test

		checkBuiltPackage

		rm -v multiarch_wrapper.c test{,-32,-64}
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "bzip2_x86" ]]; then
		extract_pkg ${pkg_name}-
		patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch

		sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
		sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

		make -f Makefile-libbz2_so CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}"
		make clean
		make CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" libbz2.a
		make CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" check
		checkBuiltPackage
	
		cp -v bzip2-shared /bin/bzip2
		cp -av libbz2.so* /lib
		ln -sv ../../lib/libbz2.so.1.0 ${LIBDIR32}/libbz2.so

	elif [[ ${finalsys_pkg_arr[${count}]} == "bzip2_x86" ]]; then
		extract_pkg ${pkg_name}-
		patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch

		sed -i -e 's:ln -s -f $(PREFIX)/bin/:ln -s :' Makefile
		sed -i 's@X)/man@X)/share/man@g' ./Makefile
		sed -i 's@/lib\(/\| \|$\)@/lib64\1@g' Makefile

		make -f Makefile-libbz2_so CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}"
		make clean
		make CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}"
		make CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" PREFIX=/usr install

		cp -v bzip2-shared /bin/bzip2
		cp -av libbz2.so* /lib64
		ln -sv ../../lib64/libbz2.so.1.0 ${LIBDIR64}/libbz2.so
		rm -v /usr/bin/{bunzip2,bzcat,bzip2}
		ln -sv bzip2 /bin/bunzip2
		ln -sv bzip2 /bin/bzcat
		elif [[ ${finalsys_pkg_arr[${count}]} == "pkg-config-lite" ]]; then
		extract_pkg ${pkg_name}-

		USE_ARCH=64 CXX="g++ ${BUILD64}" CC="gcc ${BUILD64}" ./configure \
		  --prefix=/usr \
		  --docdir=/usr/share/doc/pkg-config-0.28-1 \
		  --with-pc-path=/usr/share/pkgconfig \
		  --libdir=${LIBDIR64} \

		make 
		make check
		checkBuiltPackage
		make install

		export PKG_CONFIG_PATH32="${LIBDIR32}/pkgconfig"
		export PKG_CONFIG_PATH64="${LIBDIR64}/pkgconfig"

		echo 'export PKG_CONFIG_PATH32=\"${PKG_CONFIG_PATH32}\"' >> /root/.bash_profile
		echo 'export PKG_CONFIG_PATH64=\"${PKG_CONFIG_PATH64}\"' >> /root/.bash_profile        
	
		PKG_CONFIG_PATH32="${LIBDIR32}/pkgconfig"
		PKG_CONFIG_PATH64="${LIBDIR64}/pkgconfig"
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "attr_x86" ]]; then  
		extract_pkg ${pkg_name}-
	
		CC="gcc ${BUILD32}" \
		  ./configure --prefix=/usr \
		  --libdir=/lib --libexecdir=${LIBDIR32}
	
		checkBuiltPackage
	 	make PREFIX=/usr LIBDIR=/lib
		checkBuiltPackage
		make tests
		checkBuiltPackage
		make PREFIX=/usr LIBDIR=/lib install install-dev install-lib

		ln -sfv ../../lib/$(readlink /lib/libattr.so) ${LIBDIR32}/libattr.so
		rm -v /lib/libattr.so

		chmod 755 -v /lib/libattr.so.1.1.0
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "attr_x64" ]]; then
		extract_pkg ${pkg_name}-

		sed -i -e "/SUBDIRS/s|man[25]||g" man/Makefile
		sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
		sed -i '87s/{/\\{/' test/run

		CC="gcc ${BUILD64}" \
		  ./configure --prefix=/usr \
		  --libdir=/lib64 \
		  --libexecdir=${LIBDIR64} \
		  --docdir=/usr/share/doc/${pkg_name}-${pkg_ver}
	
		checkBuiltPackage
		make PREFIX=/usr LIBDIR=/lib64
		checkBuiltPackage
		make tests
		checkBuiltPackage
		make PREFIX=/usr LIBDIR=/lib64 install install-dev install-lib

		ln -sfv ../../lib64/$(readlink /lib64/libattr.so) ${LIBDIR64}/libattr.so
		rm -v /lib64/libattr.so

		chmod 755 -v /lib64/libattr.so.1.1.0    

	elif [[ ${finalsys_pkg_arr[${count}]} == "acl_x86" ]]; then
		extract_pkg ${pkg_name}-
	
		CC="gcc ${BUILD32}" \
		  ./configure --prefix=/usr \
		  --libdir=/lib \
		  --libexecdir=${LIBDIR32}
		  --bindir=/bin
	
		checkBuiltPackage
		make PREFIX=/usr LIBDIR=/lib
		checkBuiltPackage
		make tests
		checkBuiltPackage
		make PREFIX=/usr LIBDIR=/lib install install-dev install-lib

		ln -sfv ../../lib/$(readlink /lib/libacl.so) ${LIBDIR32}/libacl.so
		rm -v /lib/libacl.so

		chmod 755 -v /lib/libacl.so.*
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "acl_x64" ]]; then    
		extract_pkg ${pkg_name}-
	
		CC="gcc ${BUILD64}" \
		./configure --prefix=/usr \
		--libdir=/lib64 \
		--libexecdir=${LIBDIR64}
		--bindir=/bin \
		--docdir=/usr/share/doc/${pkg_name}-${pkg_ver}
	
		checkBuiltPackage
		make PREFIX=/usr LIBDIR=/lib64
		checkBuiltPackage
		make tests
		checkBuiltPackage
		make PREFIX=/usr LIBDIR=/lib64 install install-dev install-lib

		ln -sfv ../../lib64/$(readlink /lib64/libacl.so) ${LIBDIR64}/libacl.so
		rm -v /lib64/libacl.so

		chmod 755 -v /lib64/libacl.so.1.1.0
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "libcap_x86" ]]; then
		extract_pkg ${pkg_name}-
	
		sed -i '/install.*STALIBNAME/d' libcap/Makefile

		make CC="gcc ${BUILD32}"
		make RAISE_SETFCAP=no lib=lib install
		chmod -v 755 /lib/libcap.so*
		ln -sfv ../../lib/$(readlink /lib/libcap.so) ${LIBDIR32}/libcap.so
		rm -v /lib/libcap.so
		mv -v /lib/libcap.a ${LIBDIR32}
	elif [[ ${finalsys_pkg_arr[${count}]} == "libcap_x64" ]]; then
		extract_pkg ${pkg_name}-

		sed -i '/install.*STALIBNAME/d' libcap/Makefile

		make CC="gcc ${BUILD64}"
		make RAISE_SETFCAP=no lib=lib64 install
		chmod -v 755 /lib64/libcap.so*
		ln -sfv ../../lib64/$(readlink /lib64/libcap.so) ${LIBDIR64}/libcap.so
		rm -v /lib64/libcap.so
		mv -v /lib64/libcap.a ${LIBDIR64}
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "sed" ]]; then
		extract_pkg ${pkg_name}-
	
		sed -i 's/usr/tools/'                 build-aux/help2man
		sed -i 's/testsuite.panic-tests.sh//' Makefile.in

		CC="gcc ${BUILD64}" ./configure \
		  --prefix=/usr \
		  --bindir=/bin \
		  --docdir=/usr/share/doc/${pkg_name}-${pkg_ver}
	
		checkBuiltPackage
		make
		checkBuiltPackage
		make html
		checkBuiltPackage
		make check
		checkBuiltPackage

		make install
		install -d -m755           /usr/share/doc/${pkg_name}-${pkg_ver}
		install -m644 doc/sed.html /usr/share/doc/${pkg_name}-${pkg_ver}
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "shadow" ]]; then  
		extract_pkg ${pkg_name}-
	
		sed -i 's@\(DICTPATH.\).*@\1/lib/cracklib/pw_dict@' etc/login.defs
		sed -i src/Makefile.in -e 's/groups$(EXEEXT) //'

		find man -name Makefile.in -exec sed -i -e 's/man1\/groups\.1 //' \
		-e 's/man3\/getspnam\.3 //' \
		-e 's/man5\/passwd\.5 //' '{}' \;

		sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
		-e 's@/var/spool/mail@/var/mail@' etc/login.defs

		sed -i 's/1000/999/' etc/useradd

		PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} \
		  CC="gcc ${BUILD64}" CXX="${BUILD64}" \
		  ./configure --sysconfdir=/etc \
		  --with-group-name-max-length=32 \
		  --with-libcrack \
		  --without-libpam
	
		checkBuiltPackage
		make PREFIX=/usr LIBDIR=${LIBDIR64}
		checkBuiltPackage
		make  PREFIX=/usr LIBDIR=${LIBDIR64} install

		sed -i /etc/login.defs \
		  -e 's@#\(ENCRYPT_METHOD \).*@\1SHA512@' \
		  -e 's@/var/spool/mail@/var/mail@'

		mv -v /usr/bin/passwd /bin
		touch /var/log/{fail,last}log
		chgrp -v utmp /var/log/{fail,last}log
		chmod -v 664 /var/log/{fail,last}log
	
		checkBuiltPackage
	
		echo "Transfering group and user data into encrypted shadow file..."
	
		pwconv
		grpconv
	
		checkBuiltPackage

		echo 
		echo "At this point shadow installation is finished."
		echo "Please choose a password for your root user:"
		echo 
		echo "root password: " passwd root
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "psmisc" ]]; then
		extract_pkg ${pkg_name}-
	
		PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
		  CC="gcc ${BUILD64}" ./configure --prefix=/usr
	
		checkBuiltPackage
		make
		checkBuiltPackage
		make install
		checkBuiltPackage
		mv -v /usr/bin/fuser /bin
		mv -v /usr/bin/killall /bin
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "iana-etc" ]]; then
		extract_pkg ${pkg_name}-
		#xzcat ../iana-etc-2.30-numbers_update-20140202-2.patch.xz | patch -Np1 -i -

		make PREFIX=/usr LIBDIR=${LIBDIR64}
		checkBuiltPackage
		make PREFIX=/usr LIBDIR=${LIBDIR64} install
		
	elif [[ ${finalsys_pkg_arr[${count}]} == "flex_x86" ]]; then
		extract_pkg ${pkg_name}-
	
		sed -i "/math.h/a #include <malloc.h>" src/flexdef.h

		HELP2MAN=/tools/bin/true \
		  CC="gcc ${BUILD32}" ./configure --prefix=/usr \
		  --docdir=/usr/share/doc/${pkg_name}-${pkg-ver}
	
		checkBuiltPackage
		make
		checkBuiltPackage
		make check
		checkBuiltPackage
		make install
		checkBuiltPackage
	
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "flex_x64" ]]; then
		extract_pkg ${pkg_name}-
	
		sed -i "/math.h/a #include <malloc.h>" src/flexdef.h

		HELP2MAN=/tools/bin/true \
		  CC="gcc ${BUILD64}" ./configure --prefix=/usr \
		  --libdir=${LIBDIR64} 
	
		checkBuiltPackage
		make
		checkBuiltPackage
		make check
		checkBuiltPackage
		make install

		ln -sv flex /usr/bin/lex
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "grep" ]]; then
		extract_pkg ${pkg_name}-
	
		PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
		  CC="gcc ${BUILD64}" ./configure --prefix=/usr --bindir=/bin
	
		checkBuiltPackage
		make
		checkBuiltPackage
		make check
		checkBuiltPackage
		make install
	
	
	elif [[ ${finalsys_pkg_arr[${count}]} == "bash" ]]; then
		extract_pkg ${pkg_name}-
	
		patch -Np1 -i ../bash-4.4-branch_update-1.patch

		sed -i "/ac_cv_rl_libdir/s@/lib@&64@" configure

		PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
		  CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
		  ./configure --prefix=/usr \
		  --without-bash-malloc \
		  --with-installed-readline \
		  --docdir=/usr/share/doc/${pkg_name}-${pkg_ver}
	
		checkBuiltPackage
		make
		checkBuiltPackage
		make tests
		checkBuiltPackage
		make install
		mv -v /usr/bin/bash /bin
	
	fi    

	cd ${CLFSSOURCES}
	checkBuiltPackage
	rm -rf ${pkg_name}
	count=$(expr ${count} + 1)

done
}

build_pkg

printf "\n"
printf "If everything went fine we will now be\n"
printf "using our new native bash shell!\n"
printf "If you noticed errors, cancel and recompile.\n"
printf "\n"

cd ${CLFS}

exec /bin/bash --login +h
