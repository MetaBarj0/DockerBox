#!/bin/sh
set -e

cd /root/build

../source/configure

job_count=$(grep processor /proc/cpuinfo | wc -l)

make -j$job_count