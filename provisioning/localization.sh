#!/bin/sh
set -e

zoneinfo_root=/usr/share/zoneinfo

function error() {
    echo "$@" 1>&2
}

# default region is UTC
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