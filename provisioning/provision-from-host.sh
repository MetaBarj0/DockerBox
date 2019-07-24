#!/bin/sh

source=/vagrant/provisioning
target=/root/provisioning

mkdir -p "$target"

cp "${source}/playbook.sh" \
   "${source}/timesync.sh" \
   "${source}/localization.sh" \
   "${source}/docker_user.sh" \
   "${source}/extra_packages.sh" \
   "${source}/install_extra_pacman_repositories.sh" \
   "${source}/cleanup.sh" \
   "${target}"

find "$target" -type f -name '*.sh' -exec chmod 755 {} \;

PATH="${PATH}":"$target" playbook.sh