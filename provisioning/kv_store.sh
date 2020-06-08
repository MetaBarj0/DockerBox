#!/bin/sh

dbFile="$KV_DB_FILE"
if [ -z "$dbFile" ]; then exit 0; fi

if [ ! -f "$dbFile" ]; then
  gdbmtool -n "$dbFile" << EOF
list
EOF

  chown docker:docker "$dbFile"
fi

dbFileName="$(basename $dbFile)"
if [ ! -e "/home/docker/${dbFileName}" ]; then
  ln -s "$dbFile" /home/docker/
  chown -h docker:docker "/home/docker/${dbFileName}"
fi

items="$KV_DB_ITEMS"
if [ -z "$items" ]; then exit 0; fi

separator=$(echo "$KV_ITEM_SEPARATOR" | awk -e '{ print substr( $0, 0, 1 ) }')
assignmentOperator=$(echo "$KV_ASSIGNMENT_OPERATOR" | awk -e '{ print substr( $0, 0, 1 ) }')

awkGetItem='{
  for( i = 1; i <= NF; ++i )
    print $i
}'

item=; key=; value=
while read item; do
  key=$(echo "$item" | awk -F "$assignmentOperator" -e '{ print $1 }')
  val=$(echo "$item" | awk -F "$assignmentOperator" -e '{ print $2 }')

  gdbmtool "$dbFile" << EOF
    store "$key" "$val"
EOF
done << EOF
$(echo "$items" | awk -F "$separator" -e "$awkGetItem")
EOF