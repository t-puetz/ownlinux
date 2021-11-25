#/bin/bash
#Install script needs ncurses and dialog package

if [[ ${EUID} != 0 ]]; then
	exit
fi

basedirectory=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)

declare -f checkRequirements
declare -f isDialogInstalled
declare -f selectPartition
declare -f selectFs
declare -f slectInitSystem
declare -f yesNo
declare -f catchUserInput

sed -i '5481,5485 s/({/(\\{/' /usr/share/texinfo/Texinfo/Parser.pm

checkRequirements() {
	printf "\n"
	printf "Does your system fullfil the requirements to build LFS?: [Y/N]\n"

	while read -n1 -r -p "" && [[ $REPLY != q ]]; do
		case $REPLY in
			Y) break 1;;
			N) printf "$EXIT\n"
			   printf "Fix it!"
			   printf "\n"
			exit 1;;
			*) printf " Try again. Type y or n\n";;
		esac
	done
	printf "\n"
}

isDialogInstalled() {
	printf "\n"
	printf "Are ncurses and dialog installed?: [Y/N]\n"
	while read -n1 -r -p "" && [[ $REPLY != q ]]; do
		case $REPLY in
			Y) break 1;;
			N) printf "$EXIT\n"
			   printf "Fix it!\n"
			   exit 1;;
			*) printf " Try again. Type y or n\n";;
		esac
		done
	printf "\n"
}

selectPartition() {
	devicetitle=$1

	if [[ $2 == "" && $3 == "" ]]; then
		devices=$(lsblk | tail -n $(expr $(lsblk | wc -l) - 1) | awk {'print $1'} | grep "sd[a-z]\|nvme[0-9]n[0-9]p[0-9]" | \
          sed 's/^\(|-\)\|^\(`-\)//g' | sed '/^\s*$/d' | sed 's/^/\/dev\//g' | sed 's/\s/\n/g' | tr '├─' '/' | tr '└─' '/' | \
          sed 's/[/]\+/\//' | sed 's:///////:/:')
		devicecount=$(lsblk | tail -n $(expr $(lsblk | wc -l) - 1) | awk {'print $1'} | grep "sd[a-z]\|nvme[0-9]n[0-9]p[0-9]" | \
          sed 's/^\(|-\)\|^\(`-\)//g' | sed '/^\s*$/d' | sed 's/^/\/dev\//g' | sed 's/\s/\n/g' | tr '├─' '/' | tr '└─' '/' | \
          sed 's/[/]\+/\//' | sed 's:///////:/:' | wc -l)
	elif [[ $2 != ""  && $3 == "" ]]; then
		modarg2=$(echo "$2" | sed 's/\//\\\//g')
		devices=$(echo "$devices" | sed "s/${modarg2}//g" |  sed '/^\s*$/d' | sed 's/\s/\n/g')
		devicecount=$(expr $devicecount - 1)
	elif [[ $3 != "" && $2 != "" ]]; then
		modarg3=$(echo "$3" | sed 's/\//\\\//g')
		devices=$(echo "$devices" | sed "s/${modarg3}//g" | sed '/^\s*$/d' | sed 's/\s/\n/g')
		devicecount=$(expr $devicecount - 1)
	fi

	dialogcmd="dialog --backtitle "
	dialogcmd+=" \"Select\" "
	dialogcmd+=" --radiolist "
	dialogcmd+=" \"${devicetitle}\" "
	dialogcmd+=" 15 45 "
	dialogcmd+=${devicecount}
	dialogcmd+=" "

	devicearray=()
	j=0

	for (( i=1;i<=${devicecount};i++ ))
	do
		j=$(expr ${i} - 1)
		devicearray[${j}]=$(echo ${devices} | cut -d' ' -f${i})
		dialogcmd+=" $i ${devicearray[$j]} off "
	done

	exec 3>&1;

	result=$(${dialogcmd} 2>&1 1>&3)
	exitcode=$?
	exec 3>&-

	chosendrive=$(echo ${devicearray[$(expr ${result} - 1)]})
}

selectFs() {
	fsarray=(ext4 xfs btrfs)
	exec 3>&1;
	bulletpoint=$(dialog --backtitle "Choose the filesystem" --radiolist "for your home partition" 10 40 3 1 ${fsarray[0]} on 2 ${fsarray[1]} off 3 ${fsarray[2]} off 2>&1 1>&3);
	exitcode=$?;
	exec 3>&-;
	chosenfs=$(echo ${fsarray[$(expr ${bulletpoint} - 1)]})
}

selectInitSystem() {
	fsarray=(sysvinit openrc runit s6 systemd)
	exec 3>&1;
	bulletpoint=$(dialog --backtitle "Choose the init system" --radiolist "for your distribution" 10 65 5 1 ${fsarray[0]} on 2 ${fsarray[1]} off 3 ${fsarray[2]} off 4 ${fsarray[3]} off 5 ${fsarray[4]} off 2>&1 1>&3);
	exitcode=$?;
	exec 3>&-;a
	choseninit=$(echo ${fsarray[$(expr ${bulletpoint} - 1)]})
}

yesNo() {  
	dialog --title "Format $1?" --yesno "Do you want to format your $1 partition?" 10 25

	if [[ $? == 0 ]]; then
		choice=yes
	elif [[ $? == 1 ]]; then
		choice=no
	fi
}

catchUserInput() {
	question=$1
	dialog --inputbox ${question} 8 40 2>answer
	input=$(cat answer | tr -d '\n')
	rm -f answer
}

printf "\033c"

#Simple script to list version numbers of critical development tools
#This script is from the LFS/LFS developers. It is not my work. Thanks to them :)

printf "\n"
bash ${basedirectory}/meta/version-check.sh 2>errors.log &&
[ -s errors.log ] && echo -e "\nThe following packages could not be found:\n$(cat errors.log)"
printf "\n"

checkRequirements
isDialogInstalled

#Create simple texfile that saves improtant system config parameters
#as variables. A lot of CLFS scripts will need them throughout the building procedure.
touch clfs-system.config

selectPartition ESP
clfsespdev=${chosendrive}

selectPartition ROOT ${clfsespdev}
clfsrootdev=${chosendrive}

selectPartition HOME ${clfsespdev} ${clfsrootdev}
clfshomedev=${chosendrive}

yesNo home
clfsformathomedev=${choice}
echo "formathome=${clfsformathomedev}" >> clfs-system.config

yesNo esp
clfsformatespdev=${choice}
echo "formatesp=${clfsformatespdev}" >> clfs-system.config

selectFs
clfsfilesystem=${chosenfs}
echo "fs=${clfsfilesystem}" >> clfs-system.config

selectInitSystem
clfsinitsystem=${choseninit}
echo "init=${clfsinitsystem}" >> clfs-system.config

if [[ ${clfsfilesystem} != ext4 ]]; then
	echo "Filesystems other than ext4 are not supported for now! Exiting..."
	exit
fi

catchUserInput "Kernel"
kernelver=${input}
echo "kernel=${kernelver}" >> ${basedirectory}/clfs-system.config
input=""

kernelmajor=$(echo ${kernelver} | cut -d'.' -f1)
kernelminor=$(echo ${kernelver} | cut -d'.' -f2 | sed 's/-rc[0-9]//g')
kernelpatch=$(echo ${kernelver} | cut -d'.' -f3)
kernelrcver=""

if [[ -z "${kernelver##*-rc*}" ]]; then
	kernelrcver=$(echo ${kernelver} | cut -d'-' -f2)
fi

if [[  ${kernelver} != git ]]; then
	if [[ ${kernelmajor} < 4 ]]; then
		echo "You need to chose a more up-to-date kernel version! Exiting..."
		exit
	fi

	if [[ ${kernelmajor} < 4 && ${kernelminor} < 20 ]]; then
		echo "You need to chose a more up-to-date kernel version! Exiting..."
		exit
	fi

	if [[ ${kernelrcver} != "" && ${kernelpatch} != "" ]]; then
		echo "You chose a RC version of a kernel. In this case only type in minor and major version."
		echo "RIGHT: 4.20-rc4"
		echo "WRONG: 4.20.0-rc4"
		echo "Exiting..."
		exit
	fi
fi

pickhostname="Hostname"
catchUserInput ${pickhostname}
clfshostname=${input}
echo "hostname=${clfshostname}" >> ${basedirectory}/clfs-system.config
input=""

pickusername="Username"
catchUserInput ${pickusername}
clfsusername=${input}
echo "username=${clfsusername}" >> ${basedirectory}/clfs-system.config
input=""

pickrootpw="RootPassword"
catchUserInput ${pickrootpw}
clfsrootpw=${input}
echo "rootpw=${clfsrootpw}" >> ${basedirectory}/clfs-system.config
input=""

pickuserpw="${clfsusername}Password"
catchUserInput ${pickuserpw}
clfsuserpw=${input}
echo "userpw=${clfsuserpw}" >> ${basedirectory}/clfs-system.config
input=""

#############################################
################ SELECT TIMEZONE ############
#############################################

# START

declare -f fillDirArray
declare -f fillArray
declare -a global_dir_array

startdir=/usr/share/zoneinfo
cd ${startdir}

fillDirArray() {
	local curdir=$1
	local dircount=$(ls -Al ${curdir} | egrep "^d" | awk '{print $9}' | wc -l)
	local dirs=$(ls -Al ${curdir} | egrep "^d" | awk '{print $9}' | tr '\n' ' ' | sed 's/ $//')
	local dirarray=()
	local j=0

	for ((i=1;i<=${dircount};i++))
	do
		j=$(expr ${i} - 1)
		dirarray[${j}]=$(printf "${dirs}" | cut -d';' -f${i})
	done

	printf "${dirarray}"
}

fillArray() {
	local curdir=$1
	local dircount=$(ls -Al ${curdir} | awk '{print $9}' | wc -l)
	local dirs=$(ls -Al ${curdir} | awk '{print $9}' | tr '\n' ' ' | sed 's/ $//')
	local dirarray=()
	local j=0

	for ((i=1;i<=${dircount};i++))
	do
		j=$(expr ${i} - 1)
		dirarray[${j}]=$(printf "${dirs}" | cut -d';' -f${i})
	done

	printf "${dirarray}"
}

printf "\033c"

global_dir_array=($(fillDirArray ${startdir}))
count=0
humancount=1

for globalzone in ${global_dir_array[*]}
do
	printf "${humancount}. ${global_dir_array[${count}]}"
	printf "\n"
	count=$(expr ${count} + 1)
	humancount=$(expr ${count} + 1)
done

printf "Please select your timezone: "
printf "\n"
printf "\n"

read num_globalzone_sel

printf "\033c"

if [[ ${num_globalzone_sel} != 0 ]] && [[ ${num_globalzone_sel} -le ${count} ]]; then
	name_globalzone_sel=${global_dir_array[$(expr ${num_globalzone_sel} - 1)]}
fi

reg_dir_array=($(fillArray ${startdir}/${name_globalzone_sel}))

count=0
humancount=1

for tzone in ${reg_dir_array[*]}
do
	printf "${humancount}. ${reg_dir_array[${count}]}"
	printf "\n"
	count=$(expr ${count} + 1)
	humancount=$(expr ${count} + 1)
done

read num_tzone_sel

if [[ ${num_tzone_sel} != 0 ]] && [[ ${num_tzone_sel} -le ${count} ]]; then
	name_tzone_sel=${reg_dir_array[$(expr ${num_tzone_sel} - 1)]}
fi

timezone=${name_globalzone_sel}/${name_tzone_sel}

# END SELECT TIMEZONE

export CLFS=/mnt/clfs

CLFS=/mnt/clfs
CLFSUSER=clfs
CLFSHOME=${CLFS}/home
CLFSSOURCES=${CLFS}/sources
CLFSTOOLS=${CLFS}/tools
CLFSCXTOOLS=${CLFS}/cross-tools

echo "timezone=${timezone}" >> ${basedirectory}/clfs-system.config

printf "\033c"

mkfs.${clfsfilesystem} -q ${clfsrootdev}
echo "\n"

if [[ ${clfsformathomedev} = "yes" ]]; then
	mkfs.${clfsfilesystem} -q ${clfshomedev}
fi

echo

if [[ ${clfsformatespdev} = "yes" ]]; then
	mkfs.vfat -v -F32 ${clfsespdev}
fi

mkdir -pv ${CLFS}
mount -v ${clfsrootdev} ${CLFS}
mkdir -pv ${CLFSHOME}
mount -v ${clfshomedev} ${CLFSHOME}

mkdir -v ${CLFSSOURCES}
chmod -v a+wt ${CLFSSOURCES}

printf "\n"

cp -rv ${basedirectory}/sources/* ${CLFSSOURCES}

#Download toolchain and kernel
wget http://ftp.gnu.org/gnu/glibc/glibc-2.30.tar.xz -P ${CLFSSOURCES}
wget http://ftp.gnu.org/gnu/binutils/binutils-2.32.tar.bz2 -P ${CLFSSOURCES}
wget ftp://gcc.gnu.org/pub/gcc/releases/gcc-9.2.0/gcc-9.2.0.tar.xz -P ${CLFSSOURCES}
if [[ $kernelpatch != "" ]] && [[ $kernelver != "git" ]]; then
	wget https://cdn.kernel.org/pub/linux/kernel/v$kernelmajor.x/linux-$kernelmajor.$kernelminor.$kernelpatch.tar.xz -P ${CLFSSOURCES}
elif [[ $kernelpatch == "" ]] && [[ $kernelrcver == "" ]] && [[ $kernelver != "git" ]]; then
	wget https://cdn.kernel.org/pub/linux/kernel/v$kernelmajor.x/linux-$kernelmajor.$kernelminor.tar.xz -P ${CLFSSOURCES}
elif [[ $kernelpatch == "" ]] && [[ $kernelrcver != "" ]] && [[ $kernelver != "git" ]]; then
	wget https://git.kernel.org/torvalds/t/linux-$kernelmajor.$kernelminor-$kernelrcver.tar.gz -P ${CLFSSOURCES}
elif [[ $kernelver == "git" ]]; then
	git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
fi

printf "Source packages have been copied to ${CLFS} and are now owned by clfs:clfs\n"

install -dv ${CLFSTOOLS}
ln -sv ${CLFSTOOLS} /
install -dv ${CLFSCXTOOLS}
ln -sv ${CLFSCXTOOLS} /

groupadd ${CLFSUSER}
useradd -s /bin/bash -g ${CLFSUSER} -m -k /dev/null ${CLFSUSER}
mkdir -pv /home/${CLFSUSER}
chown -v ${CLFSUSER}:${CLFSUSER} /home/${CLFSUSER}
chown -v ${CLFSUSER}:${CLFSUSER} ${CLFSTOOLS}
chown -v ${CLFSUSER}:${CLFSUSER} ${CLFSCXTOOLS}
chown -R ${CLFSUSER}:${CLFSUSER} ${CLFSSOURCES}

echo "Sources are owned by lfs:lfs now"

cp -v ${basedirectory}/clfs_{1,2,3}*.sh  /home/${CLFSUSER}
cp -v ${basedirectory}/clfs_{4,5,6,7,8,9,10}*.sh ${CLFS}
mv -v ${basedirectory}/clfs-system.config ${CLFS}
cp -rv ${basedirectory}/meta ${CLFS}
cp -v ${basedirectory}/meta/* /home/${CLFSUSER}
chown -R ${CLFSUSER}:${CLFSUSER} /home/${CLFSUSER}

printf "\n"
printf "All install scripts have been copied to ${CLFS}\n"
printf "Check the screen output if everything looks fine\n"
printf "Executing script 0b to login as unprivilidged CLFS user...\n"
printf "\n"

rm -rf ${basedirectory}/error*.log
rm -rf ${basedirectory}/answer

bash ${basedirectory}/meta/clfs_0b_login_as_clfs_RAHR.sh
