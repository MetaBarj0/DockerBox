#!/bin/sh

if [ ! -z "$EXTRA_PACKAGES" ]; then
  apk add -U --quiet $EXTRA_PACKAGES
fi