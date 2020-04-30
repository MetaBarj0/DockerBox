#!/bin/sh

source=/vagrant/provisioning
target=/root/provisioning

mkdir -p "$target"

cp "${source}/playbook.sh" \
   "${source}/localization.sh" \
   "${source}/extra_packages.sh" \
   "${source}/extend_docker_storage.sh" \
   "${source}/cleanup.sh" \
   "${target}"

find "$target" -type f -name '*.sh' -exec chmod 755 {} \;

PATH="${PATH}":"$target" playbook.sh