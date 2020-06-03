#!/bin/sh

if [ $(whoami) != 'root' ]; then
  echo 'This utility is meant to be run as root... Aborting.' 1>&2
  exit 1
fi

script_dir="$(pwd -P $0)"

cd "${script_dir}/docker"

echo "building zfs 'virt' kernel modules builder docker image..."
docker build -q -t zfs.builder . 1>/dev/null

echo "running zfs 'virt' kernel module builder container..."
container_id="$(\
docker run --rm -d \
  --mount type=volume,src=source,dst=/root/source \
  --mount type=volume,src=build,dst=/root/build \
  --mount type=volume,src=install,dst=/root/install \
  zfs.builder)"

while true; do
  docker exec $container_id stat /root/done 1>/dev/null 2>&1

  [ $? -eq 0 ] && break;

  sleep 5
done

cd - 2>&1 1>/dev/null

echo "installing zfs 'virt' kernel modules..."
cd /lib/modules/5.4.34-0-virt

rm -rf extra

docker cp ${container_id}:/root/install/extra . 1>/dev/null 2>&1

docker kill $container_id 1>/dev/null

echo installing zfs package...
apk add zfs 1>/dev/null

echo registering zfs services...
rc-update add zfs-import boot 1>/dev/null
rc-update add zfs-share boot 1>/dev/null
rc-update add zfs-zed boot shutdown 1>/dev/null
rc-update add zfs-mount boot 1>/dev/null

echo loading zfs module...
depmod 1>/dev/null
modprobe zfs 1>/dev/null

echo rebuilding initramfs...

cd - 2>&1 1>/dev/null

cd /etc/mkinitfs

grep -q zfs mkinitfs.conf

if [ $? -ne 0 ]; then
  sed -i'' 's/"$/ zfs"/' mkinitfs.conf
  mkinitfs 1>/dev/null
fi

echo cleanup...
docker image rm zfs.builder alpine:3.11 1>/dev/null
docker volume rm source build install 1>/dev/null

cd - 2>&1 1>/dev/null
