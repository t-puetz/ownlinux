#/bin/bash

function checkSanity() {
echo
echo "Does your system fullfil the requirements to build CLFS?: [Y/N]"
echo
while read -n1 -r -p "" && [[ $REPLY != q ]]; do
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

#=======================
#RUN AS HOST'S root
#=======================

printf "\033c"

# Simple script to list version numbers of critical development tools

echo
bash meta/version-check.sh 2>errors.log &&
[ -s errors.log ] && echo -e "\nThe following packages could not be found:\n$(cat errors.log)"
echo

checkSanity

echo

printf "\033c"

echo "Starting interactive setting of vital variables through user input..."
echo
echo "Here is the output of lsblk"
echo "This should help you with chosing partitions"

echo
lsblk
echo

echo "What drive do you want to be your ESP (UEFI boot) partition? Type in form of [/dev/sdX]. Make no typos. There is no failsafe, yet!"
echo
read clfsespdev
printf "\033c"

echo
lsblk
echo

echo "What drive do you want to be your ROOT partition? Type in form of [/dev/sdX]. Make no typos. There is no failsafe, yet!"
echo

read clfsrootdev
printf "\033c"

echo
lsblk
echo

echo "Your CLFS ROOT partition is $clfsrootdev. It will be mounted to /mnt/clfs"
echo
echo

echo "What drive do you want to be your HOME partition? Type in form of /dev/sdX. Make no typos. There is no failsafe, yet!"
echo "If you just press ENTER I will ONLY use the ROOT partition!"

echo
read clfshomedev
printf "\033c"

echo "Your CLFS HOME partition is $clfshomedev. It will be mounted to /mnt/clfs/home"
echo
echo

echo "Chose whether or not your home partition should be formatted. The root partition will be formatted no matter what!"
echo

read clfsformathomedev
printf "\033c"

echo "Chose whether or not your ESP (UEFI boot) partition should be formatted. The root partition will be formatted no matter what!"
echo

read clfsformatespdev
printf "\033c"

echo
echo "Choose the FILE SYSTEM for your HOME partition. Both drives will be formatted with it. For now only [ext4] will be supported."
echo

read clfsfilesystem

if [[ $clfsfilesystem != "ext4" ]]; then
        echo "Filesystems other than ext4 are not supported for now! Exiting..."
        exit;
fi

printf "\033c"

echo "You chose to format $clfshomedev and $clfsrootdev with $clfsfilesystem."
echo

echo "What kernel version do you want tot use? Type"
echo "  o <major>.<minor> version if the kernel version was initially released, e.g. 4.15 OR"
echo "  o <major>.<minor>.<patch> for a regular release, e.g. 4.15.3 OR"
echo "  o <major>.<minor>.<patch>-<rc> for a release candidate, e.g. 4.17-rc2 OR"
echo "  o just literally type git to get the latest kernel from github."
echo
echo "Do not go lower than version 4.14.32!"
echo
read kernelver

kernelmajor=$(echo $kernelver | cut -d'.' -f1)
kernelminor=$(echo $kernelver | cut -d'.' -f2 | sed 's/-rc[0-9]//g')
kernelpatch=$(echo $kernelver | cut -d'.' -f3)
kernelrcver=$(echo $kernelver | cut -d'-' -f2)

if [[ -z "${kernelver##*-rc*}" ]]; then
  kernelrcver=$(echo ${kernelver} | cut -d'-' -f2)
fi

echo "kernel=${kernelver}" >> clfs-system.config

if [[  ${kernelver} != git ]]; then
  if [[ ${kernelmajor} < 4 ]]; then
    echo "You need to chose a more up-to-date kernel version! Exiting..."
    exit;
  fi

  if [[ ${kernelmajor} < 4 && {kernelminor} < 14 ]]; then
    echo "You need to chose a more up-to-date kernel version! Exiting..."
    exit;
  fi

  if [[ ${kernelrcver} != "" && ${kernelpatch} != "" ]]; then
    echo "You chose a RC version of a kernel. In this case only type in minor and major version."
    echo "RIGHT: 4.16-rc4"
    echo "WRONG: 4.16.0-rc4"
    echo "Exiting..."
    exit;
  fi
fi

printf "\033c"

echo
echo "What do you want the HOSTNAME of your installed system to be called?"
echo

read clfshostname
printf "\033c"

echo "Type in a USERNAME that you will use the final system with: "
echo

read clfsusername
printf "\033c"

CLFS=/mnt/clfs
CLFSUSER=clfs
CLFSHOME=${CLFS}/home
CLFSHOSTNAME=$clfshostname
CLFSUSERNAME=$clfsusername
CLFSROOTDEV=$clfsrootdev
CLFSESPDEV=$clfsespdev
CLFSHOMEDEV=$clfshomedev
CLFSSOURCES=${CLFS}/sources
CLFSTOOLS=${CLFS}/tools
CLFSFILESYSTEM=$clfsfilesystem
CLFSCROSSTOOLS=${CLFS}/cross-tools

cat >> /root/.bashrc << EOF
export CLFS=/mnt/clfs
export CLFSHOME=/mnt/clfs/home
export CLFSHOSTNAME=$clfshostname
export CLFSUSERNAME=$clfsusername
export CLFSSOURCES=/mnt/clfs/sources
export CLFSTOOLS=/mnt/clfs/tools
export CLFSROOTDEV=$clfsrootdev
export CLFSESPDEV=$clfsespdev
export CLFSHOMEDEV=$clfshomedev
export CLFSCROSSTOOLS=/mnt/clfs/cross-tools
export CLFSFILESYSTEM=$clfsfilesystem
export CLFSUSER=clfs
EOF

echo "kernel=$kernelver" > clfs-system.config

echo "hostname=$CLFSHOSTNAME" >> clfs-system.config
echo "username=$CLFSUSERNAME" >> clfs-system.config
echo "clfsrootdev=$CLFSROOTDEV" >> clfs-system.config
echo "clfshomedev=$CLFSHOMEDEV" >> clfs-system.config

echo
mkfs.${CLFSFILESYSTEM} -q ${CLFSROOTDEV}
echo

if [[ $clfsformathomedev = y || $clfsformathomedev = Y || $clfsformathomedev = yes || $clfsformathomedev = Yes || $clfsformathomedev = YES ]]; then
        mkfs.${CLFSFILESYSTEM} -q ${CLFSHOMEDEV}
fi

echo

if [[ $clfsformatespdev = y || $clfsformatespdev = Y || $clfsformatespdev = yes || $clfsformatespdev = Yes || $clfsformatespdev = YES ]]; then
        mkfs.vfat -F32 ${CLFSESPDEV}
fi

echo "espdev=$CLFSESPDEV" >> clfs-system.config

mkdir -pv $CLFS
mount -v ${CLFSROOTDEV} ${CLFS}
mkdir -pv $CLFSHOME
#mkdir -v $CLFSHOME
mount -v ${CLFSHOMEDEV} ${CLFSHOME}

mkdir -v ${CLFSSOURCES}
chmod -v a+wt ${CLFSSOURCES}

echo
cp sources/* ${CLFSSOURCES}

#Download kernel and toolchain
wget http://ftp.gnu.org/gnu/binutils/binutils-2.30.tar.xz -P ${CLFSSOURCES}
wget ftp://gcc.gnu.org/pub/gcc/releases/gcc-8.1.0/gcc-8.1.0.tar.xz -P ${CLFSSOURCES}
if [[ $kernelpatch != "" && $kernelver != git ]]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v$kernelmajor.x/linux-$kernelmajor.$kernelminor.$kernelpatch.tar.xz -P ${CLFSSOURCES}
elif [[ $kernelpatch = "" && $kernelrcver = "" && $kernelver != git ]]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v$kernelmajor.x/linux-$kernelmajor.$kernelminor.tar.xz -P ${CLFSSOURCES}
elif [[ $kernelpatch = "" && $kernelrcver != "" && $kernelver != git ]]; then
    wget https://git.kernel.org/torvalds/t/linux-$kernelmajor.$kernelminor-$kernelrcver.tar.gz -P ${CLFSSOURCES}
elif [[ $kernelver = git ]]; then
    git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
fi

wget https://ftp.gnu.org/gnu/glibc/glibc-2.27.tar.xz -P ${CLFSSOURCES}


echo "We also need to download Python 3.6 because the file exceed GitLabs's upload size limit!"

echo

wget https://www.python.org/ftp/python/3.6.6/Python-3.6.6.tar.xz -P ${CLFSSOURCES}

echo
echo "source packages have been copied"
echo

install -dv ${CLFSTOOLS}
install -dv ${CLFSCROSSTOOLS}
ln -sv ${CLFSCROSSTOOLS} /
ln -sv ${CLFSTOOLS} /

groupadd ${CLFSUSER}
useradd -s /bin/bash -g ${CLFSUSER} -d /home/${CLFSUSER} ${CLFSUSER}
mkdir -pv /home/${CLFSUSER}
chown -v ${CLFSUSER}:${CLFSUSER} /home/${CLFSUSER}
chown -v ${CLFSUSER}:${CLFSUSER} ${CLFSTOOLS}
chown -v ${CLFSUSER}:${CLFSUSER} ${CLFSCROSSTOOLS}
chown -R ${CLFSUSER}:${CLFSUSER} ${CLFSSOURCES}

echo
echo "Sources are owned by clfs:clfs now"
echo

cp -v clfs_1_*.sh clfs_2_*.sh clfs_3_*.sh /home/${CLFSUSER}
cp -v clfs_*.sh ${CLFS}
cp clfs-system.config ${CLFS}
cp -rv bclfs ${CLFS}
cp -rv meta ${CLFS}
cp -v meta/ineedtopee.sh /home/${CLFSUSER}
chown -Rv ${CLFSUSER}:${CLFSUSER} /home/${CLFSUSER}

echo
echo "Check the screen output if everything looks fine"
echo "Compare it to the instructions of the book"
echo
echo "Execute Script #0b"
echo "To login as unprivilidged CLFS user"
echo

source meta/clfs_0b_login_as_clfs_RAHR.sh
