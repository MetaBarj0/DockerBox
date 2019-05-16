#!/bin/sh

if [ ! -z "$EXTRA_PACKAGES" ]; then
  pacman -Syuq --noconfirm $EXTRA_PACKAGES
fi