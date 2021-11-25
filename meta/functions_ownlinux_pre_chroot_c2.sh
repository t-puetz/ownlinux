#!/bin/bash

declare -f checkBuiltPackage
declare -f get_gcc_ver_c2
declare -f get_pkg_ver_c2
declare -f conv_meta_to_real_pkg_name_c2
declare -f get_glibc_ver_c2
declare -f get_hosts_glibc_ver_c2
declare -f extract_pkg_c2

checkBuiltPackage() 
{
echo
echo "Does everything look alright?: [Y/N]"
echo
while read -n1 -r -p "[Y/N]   " &&  [[ $REPLY != q ]]; do
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

get_gcc_ver_c2()
{
   local glibc_ver=$(ls ${CLFSSOURCES} | grep 'gcc' | grep 'tar' | sed 's/gcc\|gcc-//' | awk '{print $9}' | sed 's/.tar.*//')
   echo "${glibc_ver}"
}

get_pkg_ver_c2()
{
  local pkg_name=$1
  local pkg_ver=$(ls ${CLFSSOURCES} | grep ${pkg_name} | grep tar | sed "s/${pkg_name}\|${pkg_name}-//" | awk '{print $9}' | sed \
      's/.tar.*//' | head -n 1 | sed -E 's/\([[:punct:]][[:digit:]]?\)//g')

  echo "${pkg_ver}"
}

conv_meta_to_real_pkg_name_c2()
{
  local meta_name=$1
  local real_name=$(echo ${meta_name} | sed 's/_x86\|_x64\|cx_\|_headers\|_static\|_final//')

  echo "${real_name}"
}

get_glibc_ver_c2()
{
   local glibc_ver=$(ls ${CLFSSOURCES} | grep 'glibc' | grep 'tar' | sed 's/glibc\|glibc-//' | awk '{print $9}' | sed 's/.tar.*//') 
   echo "${glibc_ver}"
}

get_hosts_glibc_ver_c2()
{
   local glibc_ver=$(ldd --version | head -n 1 | awk '{print $4}') 
   echo "${glibc_ver}"
}


extract_pkg_c2() 
{
  local filename_prefix=$1
  local dirname=$(echo ${filename_prefix} | sed 's/-//g')

   if [ -d ${dirname} ]; then
     rm -rf ${dirname}
   fi

  mkdir ${dirname} && tar xf ${filename_prefix}*.tar.* -C ${dirname} --strip-components 1
  cd ${dirname}
}


if [[ $1 == "exportfcts" ]]; then

  export -f checkBuiltPackage
  export -f get_gcc_ver_c2
  export -f get_pkg_ver_c2
  export -f conv_meta_to_real_pkg_name_c2
  export -f get_glibc_ver_c2
  export -f get_hosts_glibc_ver_c2
  export -f extract_pkg_c2

elif [[ $1 == "unsetfcts" ]]; then

  unset -f checkBuiltPackage
  unset -f get_gcc_ver_c2
  unset -f get_pkg_ver_c2
  unset -f conv_meta_to_real_pkg_name_c2
  unset -f get_glibc_ver_c2
  unset -f get_hosts_glibc_ver_c2
  unset -f extract_pkg_c2
fi
