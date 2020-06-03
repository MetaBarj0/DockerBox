#!/bin/sh
set -e

cd /root/install

rm -rf *

mkdir extra

cd extra

mkdir nvpair
cp /root/build/module/nvpair/znvpair.ko nvpair

mkdir spl
cp /root/build/module/spl/spl.ko spl

mkdir avl
cp /root/build/module/avl/zavl.ko avl

mkdir unicode
cp /root/build/module/unicode/zunicode.ko unicode

mkdir lua
cp /root/build/module/lua/zlua.ko lua

mkdir zcommon
cp /root/build/module/zcommon/zcommon.ko zcommon

mkdir icp
cp /root/build/module/icp/icp.ko icp

mkdir zfs
cp /root/build/module/zfs/zfs.ko zfs
