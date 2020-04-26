# DockerBox

Alpine Linux based image with docker. Customizable provisioning.
https://app.vagrantup.com/metabarj0/boxes/DockerBox/versions/2.0.0 is the currently supported version.

## configuration

You can customize the VM by creating a .env file from the provided .env.dist
template. Each variable's purpose is described as a comment.

## login

There is 3 accounts :

- root    => vagrant  
- vagrant => vagrant  
- docker  => docker

# TODO

- change default storage controller to NVMe
- add provisionning feature aiming to facilitate disk expansion using LVM
