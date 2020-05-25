#!/bin/sh
set -e

cd /root

./source.sh
./build.sh
./install.sh

touch 'done'

while true; do sleep 10; done