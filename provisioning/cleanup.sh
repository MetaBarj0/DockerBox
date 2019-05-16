#!/bin/sh

if [ $RM_PACMAN_SYNC_DB -eq 1 ]; then
  db_dir=/var/lib/pacman/sync

  if [ -d "$db_dir" ]; then
    pacman -Scc --noconfirm 1> /dev/null
    rm -rf "$db_dir"
  fi
fi

if [ $VACUUM_JOURNAL_ARCHIVE -eq 1 ]; then
  journalctl --vacuum-size=1K 1> /dev/null 2>&1
fi