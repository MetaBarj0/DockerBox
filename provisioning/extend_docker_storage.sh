#!/bin/sh

# always attempt to resize PV, VG and LV, it's really quick and does nothing if nothing has changed
# then scan for new devices (both IDE and others??)
#   - sdx => ensure what's going on when drive count > 26 ==> ok supported, system counts base 26
#   - nvmexny

# resizing attempt
# - find pv associated to vg_docker volume group and resize them
#   pvs -S 'vg_name=vg_docker' -o pv_name --noheadings | xargs pvresize
# - extend the logical volume with free space
#   lvs -S 'lv_name=lv_docker' -o lv_path --noheadings | xargs lvresize -r -l +100%FREE

# new device detection attempt
# - list block devices
#   devices=$(cat /proc/partitions | grep -E  'sda[a-z]+$|nvme[0-9]+n[0-9]+$' | sed -r 's/.+(sd|nvme)/\/dev\/\1/')
# - eliminate those that are actually used
#   attempting to find a device by grep-ing /etc/mtab looks good enough to find device that are not LVM but used
#   as well, with pvs eliminating device looks good enough
#   unused_device=
#   for d in $devices; do
#     cat /etc/mtab | grep $d 2>/dev/null 1>&2;
#     [ $? -eq 0 ] && break;
#
#     pvs | grep $d 2>/dev/null 1>&2
#     [ $? -ne 0 ] && unused_device="$unused_device $d"
#   done

# unused devices can be added to vg_docker, then, logical volume can be extended too
# vgextend -Ay vg_docker $unused_device
# lvs -S 'lv_name=lv_docker' -o lv_path --noheadings | xargs lvresize -r -l +100%FREE