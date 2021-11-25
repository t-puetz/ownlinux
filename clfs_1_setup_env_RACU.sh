#!/bin/bash

CLFS=/mnt/clfs
HOME=${HOME}
TERM=${TERM}
PS1='\u:\w\$ '
LC_ALL=POSIX
PATH=/cross-tools/bin:/bin:/usr/bin
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

unset CFLAGS CXXFLAGS PKG_CONFIG_PATH

cat > ~/.bash_profile << "EOF"
exec env -i HOME=${HOME} TERM=${TERM} PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022
CLFS=/mnt/clfs
LC_ALL=POSIX
PATH=/cross-tools/bin:/bin:/usr/bin
export CLFS LC_ALL PATH
unset CFLAGS CXXFLAGS PKG_CONFIG_PATH
EOF

cat >> ~/.bashrc << EOF
export CLFS_HOST="${CLFS_HOST}"
export CLFS_TARGET="${CLFS_TARGET}"
export CLFS_TARGET32="${CLFS_TARGET32}"
export BUILD32="${BUILD32}"
export BUILD64="${BUILD64}"
export CLFS=/mnt/clfs
export CLFSHOME=/mnt/clfs/home
export CLFSSOURCES=/mnt/clfs/sources
export CLFSTOOLS=/mnt/clfs/tools
export CLFSCROSSTOOLS=/mnt/clfs/cross-tools
export CLFSUSER=clfs
EOF

printf "\n"
printf "Variables have been exported\n"
printf "~/.bash_profile has been sourced\”"
printf "Continue with Script #2\n"
printf "Maybe execute env first and check if everything looks good\n"
printf "\n"

source ~/.bash_profile
