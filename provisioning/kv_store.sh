#!/bin/sh

dbFile="$KV_DB_FILE"
if [ -z "$dbFile" ]; then exit 0; fi

if [ ! -f "$dbFile" ]; then
  gdbmtool -n "$dbFile" << EOF
list
EOF

  chown docker:docker "$dbFile"
fi

if [ "$KV_DB_FILE_CREATE_LINK" -eq 1 ]; then
  dbFileName="$(basename $dbFile)"
  if [ ! -e "/home/docker/${dbFileName}" ]; then
    ln -s "$dbFile" /home/docker/
    chown -h docker:docker "/home/docker/${dbFileName}"
  fi
fi

records="$KV_DB_RECORDS"
if [ -z "$records" ]; then exit 0; fi

separator=$(echo "$KV_RECORD_SEPARATOR" | awk -e '{ print substr( $0, 0, 1 ) }')
assignmentOperator=$(echo "$KV_ASSIGNMENT_OPERATOR" | awk -e '{ print substr( $0, 0, 1 ) }')

awkGetRecord='{
  for( i = 1; i <= NF; ++i )
    print $i
}'

record=; key=; value=
while read record; do
  key=$(echo "$record" | awk -F "$assignmentOperator" -e '{ print $1 }')
  val=$(echo "$record" | awk -F "$assignmentOperator" -e '{ print $2 }')

  gdbmtool "$dbFile" << EOF
    store "$key" "$val"
EOF
done << EOF
$(echo "$records" | awk -F "$separator" -e "$awkGetRecord")
EOF