#!/bin/sh
set -e

function error() {
  echo "$@" 1>&2
}

function setup_zoneinfo() {
  # default region is UTC
  local zoneinfo_root=/usr/share/zoneinfo
  local region=

  if [ ! -z "$ZONEINFO_REGION" ]; then
    region="${zoneinfo_root}/${ZONEINFO_REGION}"
  else
    region="${zoneinfo_root}/UTC"
  fi

  if [ ! -d "$region" ] && [ ! -f "$region" ]; then
    error "Error: the region: $ZONEINFO_REGION does not exist."
    exit 1
  fi

  # city must exist in region
  local city=

  if [ ! -z "$ZONEINFO_CITY" ]; then
    if [ -f "${region}/${ZONEINFO_CITY}" ]; then
      city="${region}/${ZONEINFO_CITY}"
    else
      error "Error: the city: $ZONEINFO_CITY does not exist in region: $ZONEINFO_REGION."
      exit 1
    fi
  fi

  # if a region has cities, one must be selected
  if [ -d "$region" ] && [ -z "$ZONEINFO_CITY" ]; then
    error "Error: the region: $ZONEINFO_REGION has cities but none is selected."
    exit 1
  fi

  if [ ! -z "$city" ]; then
    ln -sf "$city" /etc/localtime
  else
    ln -sf "$region" /etc/localtime
  fi
}

function setup_locales() {
  # keep current locales if the variable is not set
  if [ -z "$LOCALES" ]; then
    return 0
  fi

  # comment all currently used locales
  sed -i'' -E 's/^[^#].+/#\0/g' /etc/locale.gen

  local locale=
  for locale in $LOCALES; do
    sed -i'' -E "s/^#${locale} /${locale} /g" /etc/locale.gen
  done

  locale-gen 1> /dev/null
}

function setup_lang_and_keymap() {
  if [ ! -z "$LANG" ]; then
    echo "LANG=$LANG" > /etc/locale.conf
  fi

  if [ ! -z "$KEYMAP" ]; then
    echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
  fi
}

setup_zoneinfo
setup_locales
setup_lang_and_keymap