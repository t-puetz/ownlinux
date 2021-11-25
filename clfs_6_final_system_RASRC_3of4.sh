#!/bin/bash

#Building the final CLFS System
PREFIX=${PREFIX}
LIBDIR32=${PREFIX}/lib
LIBDIR64=${PREFIX}/lib64

CLFSTOOLS=/tools
CLFS=/
CLFSSOURCES=/sources
MAKEFLAGS="-j$(expr $(nproc) - 1)"
BUILD32="-m32"
BUILD64="-m64"
CLFS_TARGET32="i686-pc-linux-gnu"
PKG_CONFIG_PATH32=/usr/lib/pkgconfig
PKG_CONFIG_PATH64=/usr/lib64/pkgconfig

export BUILD32="-m32"
export BUILD64="-m64"

export CLFS_TARGET32="i686-pc-linux-gnu"

cat >> ${CLFS}/root/.bash_profile << EOF
export BUILD32="${BUILD32}"
export BUILD64="${BUILD64}"
export CLFS_TARGET32="${CLFS_TARGET32}"
EOF

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

DISTRONAME="CLFS-SVN-x86_64"
MAKE_RC_ARGS="BRANDING=${DISTRONAME} MKSELINUX=no MKPAM=pam LIBNAME=lib64
  MKGPKGCONFIG=yes MKSTATICLIBS=no
  LIBMODE=0644 SHLIBDIR=/usr/lib64
  LIBEXECDIR=/usr/lib64/openrc
  MKTERMCAP=ncurses MKSYSVINIT=no
  BINDIR=/usr/bin SBINDIR=/usr/bin
  SYSCONFDIR=/etc PREFIX=/usr
  MKBASHCOMP=yes MKNET=yes"

cd ${CLFSSOURCES}

#Openrc
mkdir openrc && tar xf openrc-0*.tar.* -C openrc --strip-components 1
cd openrc

sed -i 's:0444:0644:' mk/sys.mk

install -dm644 /etc/logrotate.d

#explicitely declare CC=gcc -m64 in the following two files
sed -i 's/${CC}/gcc -m64/' mk/lib.mk
sed -i 's/${CC}/gcc -m64/' mk/cc.mk

CC="gcc ${BUILD64}" LIBDIR=/usr/lib64 make ${MAKE_RC_ARGS}
CC="gcc ${BUILD64}" LIBDIR=/usr/lib64 make ${MAKE_RC_ARGS} install

sed -e 's/#unicode="NO"/unicode="YES"/' \
     -e 's/#rc_logger="NO"/rc_logger="YES"/' \
     -e 's/#rc_parallel="NO"/rc_parallel="YES"/' \
     -i "/etc/rc.conf"

sed -e 's|#baud=""|baud="38400"|' \
        -e 's|#term_type="linux"|term_type="linux"|' \
        -e 's|#agetty_options=""|agetty_options=""|' \
        -i /etc/conf.d/agetty

for num in 1 2 3 4 5 6;do
        cp -v /etc/conf.d/agetty /etc/conf.d/agetty.tty$num
        ln -sfv /etc/init.d/agetty /etc/init.d/agetty.tty$num
        ln -sfv /etc/init.d/agetty.tty$num /etc/runlevels/default/agetty.tty$num
done

groupadd uucp
usermod -a -G uucp root

install -m755 -d /usr/share/licenses/openrc
install -m644 LICENSE AUTHORS /usr/share/licenses/openrc/

ln -sfv /usr/bin/openrc-init /sbin/init

#Install udev, udev-trigger and kmod-static-nodes openRC scripts
#Udev scripts are probably the ONLY really crucial ones
#Also install a big collection of other openrc services
cd ${CLFSSOURCES}
#mkdir -pv etc/init.d
#cd etc/init.d
checkBuiltPackage
cp -v ${CLFSSOURCES}/openrc-service-collection.tar.xz .
tar xf openrc-service-collection.tar.xz
checkBuiltPackage
cd ${CLFSSOURCES}

mv etc/init.d/* /etc/init.d/
checkBuiltPackage
rm -rf etc/

sed -i 's/\/sbin\/openrc/\/usr\/bin\/openrc/g' /etc/init.d/udev*
sed -i 's/\/usr\/bin\/udev/\/sbin\/udev/g' /etc/init.d/udev*
chown -Rv root:root /etc/init.d
chown -Rv root:root /etc/runlevels

rc-update add udev sysinit
rc-update add udev-trigger sysinit
rc-update add udev-settle sysinit
rc-update add kmod-static-nodes sysinit

rc-service udev start
rc-service udev-trigger start
rc-service kmod-static-nodes start

cat > /etc/logrotate.d/openrc << "EOF"
/var/log/rc.log {
  compress
  rotate 4
  weekly
  missingok
  notifempty
}
EOF

ldconfig

cat > /usr/bin/shutdown << "EOF"
#!/bin/sh
shutdown_arg=
while getopts :akrhPHfFnct: opt; do
        case "$opt" in
                a) ;;
                k) ;;
                r) shutdown_arg=--reboot ;;
                h) shutdown_arg=--halt ;;
                P) shutdown_arg=--poweroff ;;
                H) shutdown_arg=--halt ;;
                f) ;;
                F) ;;
                n) ;;
                c) ;;
                t) ;;
                [?]) printf "%s\n" "${0##*/}: invalid command line option" >&2
                exit 1
                ;;
        esac
done
shift $((OPTIND-1))

if [ -z "${shutdown_arg}" ]; then
        shutdown_arg=--single
fi

echo /usr/bin/openrc-shutdown ${shutdown_arg} "$@"
exec /usr/bin/openrc-shutdown ${shutdown_arg} "$@"
EOF

cat > /usr/bin/reboot << "EOF"
#!/bin/sh

option_arg=
poweroff_arg=
while getopts :nwdfhik opt; do
        case "$opt" in
                n) ;;
                w) poweroff_arg=--write-only ;;
                d) option_arg=--no-write ;;
                f) ;;
                h) ;;
                i) ;;
                k) poweroff_arg=--kexec ;;
                [?]) printf "%s\n" "${0##*/}: invalid command line option" >&2
                exit 1
                ;;
        esac
done
shift $((OPTIND-1))

if [ -z "${poweroff_arg}" ]; then
        poweroff_arg=--reboot
fi

exec /usr/bin/openrc-shutdown ${option_arg} ${poweroff_arg} "$@"
EOF


cat > /usr/bin/halt << "EOF"
#!/bin/sh
option_arg=
poweroff_arg=
while getopts :nwdfiph opt; do
        case "$opt" in
                n) ;;
                w) poweroff_arg=--write-only ;;
                d) option_arg=--no-write ;;
                f) ;;
                i) ;;
                p) poweroff_arg=--poweroff ;;
                [?]) printf "%s\n" "${0##*/}: invalid command line option" >&2
                exit 1
                ;;
        esac
done
shift $((OPTIND-1))

if [ -z "${poweroff_arg}" ]; then
        poweroff_arg=--poweroff
fi

exec /usr/bin/openrc-shutdown ${option_arg} ${poweroff_arg} "$@"
EOF

chmod +x /usr/bin/{reboot,shutdown}

ln -sfv /sbin/agetty /usr/bin/
ln -sfv /sbin/sulogin /usr/bin/
ln -sfv /sbin/nologin /usr/bin/
ln -sfv /sbin/halt /usr/bin/

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

cd ${CLFS}
