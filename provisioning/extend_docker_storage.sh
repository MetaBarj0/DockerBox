#!/bin/sh

# resizing existing volumes
pvs -S 'vg_name=vg_docker' -o pv_name --noheadings | xargs pvresize
lvs -S 'lv_name=lv_docker' -o lv_path --noheadings | xargs lvresize -r -l +100%FREE

# detect sd and nvme devices
devices=$(cat /proc/partitions | grep -E  'sd[a-z]+$|nvme[0-9]+n[0-9]+$' | sed -r 's/.+(sd|nvme)/\/dev\/\1/')

# collect devices that aren't used
unused_devices=
for d in $devices; do
  # mounted
  cat /etc/mtab | grep $d 2>/dev/null 1>&2;
  [ $? -eq 0 ] && continue;

  # used in LVM
  pvs | grep $d 2>/dev/null 1>&2
  [ $? -ne 0 ] && unused_devices="$unused_devices $d"
done

# free devices found, add them to docker logical volume
if [ ! -z "$unused_devices" ]; then
  vgextend -A y vg_docker $unused_devices
  lvs -S 'lv_name=lv_docker' -o lv_path --noheadings | xargs lvresize -r -l +100%FREE
fi