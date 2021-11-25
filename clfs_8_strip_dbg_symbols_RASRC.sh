#!/bin/bash

#Stripping debugging symbols...
/tools/bin/find /{,usr/}{bin,lib,lib64,sbin,libexec} -type f \
   -exec /tools/bin/strip --strip-debug '{}' ';'

rm -f /usr/lib/lib{bfd,opcodes}.a
rm -f /usr/lib/libbz2.a
rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
rm -f /usr/lib/libltdl.a
rm -f /usr/lib/libfl.a
rm -f /usr/lib/libz.a

rm -f /usr/lib64/lib{bfd,opcodes}.a
rm -f /usr/lib64/libbz2.a
rm -f /usr/lib64/lib{com_err,e2p,ext2fs,ss}.a
rm -f /usr/lib64/libltdl.a
rm -f /usr/lib64/libfl.a
rm -f /usr/lib64/libz.a

find /usr/lib /usr/libexec -name \*.la -delete
