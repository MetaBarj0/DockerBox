#!/bin/sh

cd /root/source

git clone https://github.com/openzfs/zfs.git .

tag=zfs-0.8.3
git checkout $tag

./autogen.sh 1>&2 2>/dev/null
