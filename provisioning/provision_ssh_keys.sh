#!/bin/sh

if [ -z "$SSH_SECRET_KEY" -a -z "$SSH_PUBLIC_KEY" ]; then
  exit 0
fi

if [ -z "$SSH_SECRET_KEY" -o -z "$SSH_PUBLIC_KEY" ]; then
  echo "warning: missing either secret or public ssh key." 2>&1
  echo "warning: ssh keys won't be setup for the docker user." 2>&1
fi

rm -rf /home/docker/.ssh
mkdir /home/docker/.ssh

chmod 0750 /home/docker/.ssh

echo "$SSH_SECRET_KEY" > /home/docker/.ssh/id_rsa
chmod 0400 /home/docker/.ssh/id_rsa

echo "$SSH_PUBLIC_KEY" > /home/docker/.ssh/id_rsa.pub
chmod 0600 /home/docker/.ssh/id_rsa.pub

chown -R docker:docker /home/docker/.ssh
