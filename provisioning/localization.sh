#!/bin/sh
set -e

function error() {
  echo "$@" 1>&2
}

function setup_zoneinfo() {
  local zone_info="$ZONEINFO_REGION"
  [ ! -z "$ZONEINFO_CITY" ] && zone_info="$zone_info/$ZONEINFO_CITY"

  local r="$(setup-timezone -z "$zone_info" 2>&1 1>/dev/null)"
  [ ! -z "$r" ] && error "$r"
}

function setup_keymap() {
  setup-keymap "$KEYMAP" "$KEYMAP_VARIANT"

  if [ $? -ne 0 ]; then
    error 'Could not change keymap with specified values. Fix in .env file is needed on KEYMAP and KEYMAP_VARIANT variables.'
  fi
}

setup_zoneinfo
setup_keymap