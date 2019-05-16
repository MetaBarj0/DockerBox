#!/bin/sh

cat /etc/group | grep -E '^docker:' 1> /dev/null

if [ $? -eq 1 ]; then
  groupadd docker
fi

cat /etc/shadow | grep -E '^docker:' 1> /dev/null

if [ $? -eq 1 ]; then
  useradd -m -g docker docker
  echo -e 'docker\ndocker' | passwd docker 1> /dev/null 2>&1
fi