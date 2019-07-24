#!/bin/sh

if [ ! -z "$EXTRA_PACMAN_REPOSITORIES" ]; then
  fixed_extra_pacman_repositories="$(echo "$EXTRA_PACMAN_REPOSITORIES" | sed -E '/^Server/s:/*$:/:')"'$repo/$arch'

  # creates a backup of original file on first provisioning
  [ -f /etc/pacman.conf.old ] \
    && cp -f /etc/pacman.conf.old /etc/pacman.conf \
    || cp -f /etc/pacman.conf /etc/pacman.conf.old

  # restores an untouched version of the configuration file and adds repositories
  cp /etc/pacman.conf.old /etc/pacman.conf
  echo "$fixed_extra_pacman_repositories" >> /etc/pacman.conf

  # import and locally signs keys
  if [ ! -z "$EXTRA_PACMAN_KEYS" ]; then
    for key in $EXTRA_PACMAN_KEYS; do
      pacman-key -r $key
      pacman-key --lsign-key $key
    done
  fi
fi