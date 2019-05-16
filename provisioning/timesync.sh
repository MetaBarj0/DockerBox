#!/bin/sh
set -e

if [ "$NTP_SYNC" -eq 1 ]; then
  timedatectl set-ntp true
fi

hwclock --systohc